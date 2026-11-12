"""
db_writer.py - Database Writer Module (multi-tenant schema v2)

Persists all incoming sensor data from the gateway into PostgreSQL.

Responsibilities:
  - Connect to PostgreSQL using env vars (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD)
  - Resolve a device's thing_name (e.g. "TEMP_A") to its UUID, organization and zone
    (cached in memory, so most packets need no lookup query)
  - Write temperature, occupancy, hvac_state and power readings with org_id
  - Ignore duplicate readings (same device + same timestamp) instead of failing
  - Keep devices.last_seen_at up to date (throttled), for online/offline status
  - Write analytics snapshots and orchestration events
  - Retry connection on failure (resilient to DB restart)

The gateway connects as the table OWNER, so row-level security policies don't
apply to it: it must read devices and write readings for EVERY organization.
The API connects as a separate role (ems_api) that is always subject to RLS.

Packet types handled:
  0 = TEMP        -> temperature_readings
  1 = POWER       -> power_readings
  3 = OCCUPANCY   -> occupancy_readings
  4 = HVAC_STATE  -> hvac_state
"""

import os
import time
import threading
import psycopg2
from datetime import datetime, timezone
from protocol import (
    PACKET_TYPE_TEMP,
    PACKET_TYPE_POWER,
    PACKET_TYPE_OCCUPANCY,
    PACKET_TYPE_HVAC_STATE,
)


# ============================================================
# DATABASE CONFIGURATION
# ============================================================
DB_CONFIG = {
    'host':     os.getenv('DB_HOST',     '127.0.0.1'),
    'port':     int(os.getenv('DB_PORT', '5432')),
    'dbname':   os.getenv('DB_NAME',     'energy_db'),
    'user':     os.getenv('DB_USER',     'energy_user'),
    'password': os.getenv('DB_PASSWORD', 'energy_pass'),
}

RETRY_INTERVAL_SEC = 5    # seconds between reconnect attempts
MAX_RETRIES        = 10   # max reconnect attempts before giving up

UNKNOWN_RETRY_SEC  = 30   # re-check an unknown device at most this often
LAST_SEEN_EVERY_SEC = 30  # update devices.last_seen_at at most this often per device

POWER_INTERVAL_SEC = 1    # power_meter.c sends one reading per second


class DBWriter:
    """
    Handles all PostgreSQL write operations for the gateway.
    All writes share one connection, protected by self.lock.
    """

    def __init__(self):
        self.conn      = None
        self.cursor    = None
        self.connected = False
        self.lock      = threading.Lock()

        # thing_name -> {'id', 'org_id', 'zone_id'}   (ACTIVE devices placed in a zone)
        self._device_cache = {}
        # thing_name -> zone_id   (kept so existing callers keep working)
        self._zone_cache = {}
        # zone_id -> org_id   (for analytics snapshots and events, which only know the zone)
        self._zone_org = {}

        self._unknown_until = {}   # thing_name -> time before which we don't re-query
        self._last_seen_sent = {}  # device uuid -> time we last updated last_seen_at

    # ============================================================
    # CONNECTION MANAGEMENT
    # ============================================================

    def connect(self):
        """
        Connect to PostgreSQL with retry logic.

        Returns:
            bool: True if connected, False if all retries failed
        """
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                print(f"[DB] Connecting to PostgreSQL at "
                      f"{DB_CONFIG['host']}:{DB_CONFIG['port']} "
                      f"(attempt {attempt}/{MAX_RETRIES})...")

                self.conn = psycopg2.connect(**DB_CONFIG)
                self.conn.autocommit = True   # each write committed immediately
                self.cursor = self.conn.cursor()

                self.connected = True
                print(f"[DB] Connected to {DB_CONFIG['dbname']} successfully")

                self._load_device_cache()
                return True

            except psycopg2.OperationalError as e:
                print(f"[DB] Connection failed: {e}")
                if attempt < MAX_RETRIES:
                    print(f"[DB] Retrying in {RETRY_INTERVAL_SEC}s...")
                    time.sleep(RETRY_INTERVAL_SEC)

        print(f"[DB] Could not connect after {MAX_RETRIES} attempts")
        return False

    def disconnect(self):
        """Close database connection cleanly."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        self.connected = False
        print("[DB] Disconnected from PostgreSQL")

    def _reconnect_if_needed(self):
        """Reconnect if the connection was closed."""
        if self.conn is None or self.conn.closed:
            print("[DB] Connection lost, reconnecting...")
            self.connected = False
            self.connect()

    # ============================================================
    # DEVICE CACHE
    # thing_name -> device UUID, org_id, zone_id
    # ============================================================

    def _load_device_cache(self):
        """Load every ACTIVE device that has been placed in a zone."""
        try:
            self.cursor.execute(
                """
                SELECT thing_name, id, org_id, zone_id
                FROM devices
                WHERE status = 'ACTIVE' AND zone_id IS NOT NULL
                """
            )
            device_cache, zone_cache, zone_org = {}, {}, {}
            for thing_name, dev_id, org_id, zone_id in self.cursor.fetchall():
                device_cache[thing_name] = {
                    'id':      str(dev_id),
                    'org_id':  str(org_id),
                    'zone_id': str(zone_id),
                }
                zone_cache[thing_name] = str(zone_id)
                zone_org[str(zone_id)] = str(org_id)

            self._device_cache = device_cache
            self._zone_cache   = zone_cache
            self._zone_org     = zone_org
            print(f"[DB] Device cache loaded: {sorted(device_cache.keys())}")
        except Exception as e:
            print(f"[DB] Failed to load device cache: {e}")

    def _get_device(self, thing_name):
        """
        Return {'id', 'org_id', 'zone_id'} for a thing_name, or None if the
        device is unknown, disabled, or not placed in a zone.

        Unknown names are re-checked at most every UNKNOWN_RETRY_SEC, so a
        flood of fake device IDs can't turn into a flood of DB queries.
        """
        device = self._device_cache.get(thing_name)
        if device:
            return device

        now = time.monotonic()
        if self._unknown_until.get(thing_name, 0) > now:
            return None                      # recently checked: still unknown

        self._load_device_cache()            # maybe it was just registered
        device = self._device_cache.get(thing_name)
        if device is None:
            self._unknown_until[thing_name] = now + UNKNOWN_RETRY_SEC
        else:
            self._unknown_until.pop(thing_name, None)
        return device

    def _get_zone_id(self, thing_name):
        """Kept for existing callers: zone UUID for a thing_name, or None."""
        device = self._get_device(thing_name)
        return device['zone_id'] if device else None

    def _touch_last_seen(self, device):
        """Update devices.last_seen_at, at most once per LAST_SEEN_EVERY_SEC per device."""
        now  = time.monotonic()
        last = self._last_seen_sent.get(device['id'])
        if last is not None and now - last < LAST_SEEN_EVERY_SEC:
            return
        self.cursor.execute(
            "UPDATE devices SET last_seen_at = NOW() WHERE id = %s",
            (device['id'],)
        )
        self._last_seen_sent[device['id']] = now

    # ============================================================
    # PACKET ROUTER
    # ============================================================

    def write_packet(self, packet):
        """
        Route a parsed packet dict to the correct DB table.

        Args:
            packet: dict from PacketParser.parse() with keys:
                    device_id, timestamp, value, type, type_name
        """
        if not self.connected:
            return

        pkt_type  = packet.get('type')
        thing     = packet.get('device_id')

        if self._get_device(thing) is None:
            print(f"[DB] Unknown or inactive device '{thing}', skipping write")
            return

        recorded_at = datetime.fromtimestamp(packet['timestamp'], tz=timezone.utc)

        try:
            with self.lock:
                self._reconnect_if_needed()

                if pkt_type == PACKET_TYPE_TEMP:
                    self._write_temperature(thing, None, packet['value'], recorded_at)

                elif pkt_type == PACKET_TYPE_OCCUPANCY:
                    self._write_occupancy(thing, None, int(packet['value']), recorded_at)

                elif pkt_type == PACKET_TYPE_POWER:
                    self._write_power(thing, None, packet, recorded_at)

                elif pkt_type == PACKET_TYPE_HVAC_STATE:
                    self._write_hvac_state(thing, None, packet, recorded_at)

                else:
                    print(f"[DB] Unknown packet type {pkt_type}, skipping")

        except Exception as e:
            print(f"[DB] Write error for {thing} type={pkt_type}: {e}")

    # ============================================================
    # WRITE FUNCTIONS (one per table)
    #
    # Signature kept as (thing_name, zone_id, ...) so mqtt_subscriber.py and
    # uart_reader.py keep working. The zone_id argument is ignored: the
    # device's own zone and organization from the registry are used instead.
    #
    # ON CONFLICT (device_id, recorded_at) DO NOTHING: if a device resends
    # the same reading, it is stored once instead of raising an error.
    # ============================================================

    def _write_temperature(self, thing_name, _zone_id, temperature_c, recorded_at):
        device = self._get_device(thing_name)
        if device is None:
            return
        self.cursor.execute(
            """
            INSERT INTO temperature_readings
                (org_id, device_id, zone_id, temperature_c, recorded_at)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (device_id, recorded_at) DO NOTHING
            """,
            (device['org_id'], device['id'], device['zone_id'], temperature_c, recorded_at)
        )
        self._touch_last_seen(device)
        print(f"[DB] Wrote TEMP: {thing_name} = {temperature_c:.2f}°C")

    def _write_occupancy(self, thing_name, _zone_id, occupancy_count, recorded_at):
        device = self._get_device(thing_name)
        if device is None:
            return
        self.cursor.execute(
            """
            INSERT INTO occupancy_readings
                (org_id, device_id, zone_id, occupancy_count, distance_mm, recorded_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (device_id, recorded_at) DO NOTHING
            """,
            (device['org_id'], device['id'], device['zone_id'],
             occupancy_count, None, recorded_at)
        )
        self._touch_last_seen(device)
        print(f"[DB] Wrote OCCUPANCY: {thing_name} = {occupancy_count} people")

    def _write_power(self, thing_name, _zone_id, packet, recorded_at):
        """
        The power packet carries kW. We store watts, plus the energy used in
        THIS interval, so total energy over any range is simply SUM(energy_wh).
        """
        device = self._get_device(thing_name)
        if device is None:
            return
        power_w   = packet['value'] * 1000.0
        energy_wh = power_w * POWER_INTERVAL_SEC / 3600.0
        self.cursor.execute(
            """
            INSERT INTO power_readings
                (org_id, device_id, zone_id, power_w, energy_wh, interval_s, recorded_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (device_id, recorded_at) DO NOTHING
            """,
            (device['org_id'], device['id'], device['zone_id'],
             power_w, energy_wh, POWER_INTERVAL_SEC, recorded_at)
        )
        self._touch_last_seen(device)
        print(f"[DB] Wrote POWER: {thing_name} = {power_w:.0f} W")

    def _write_hvac_state(self, thing_name, _zone_id, packet, recorded_at):
        """V2 packets carry heater_pct, cooler_pct, current_temp, setpoint."""
        device = self._get_device(thing_name)
        if device is None:
            return
        heater_pct   = packet.get('heater_pct',   packet.get('value1', 0.0))
        cooler_pct   = packet.get('cooler_pct',   packet.get('value2', 0.0))
        current_temp = packet.get('current_temp', packet.get('value3', 0.0))
        setpoint     = packet.get('setpoint',     packet.get('value4', 0.0))
        self.cursor.execute(
            """
            INSERT INTO hvac_state
                (org_id, device_id, zone_id, heater_pct, cooler_pct,
                 current_temp, setpoint, recorded_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (device_id, recorded_at) DO NOTHING
            """,
            (device['org_id'], device['id'], device['zone_id'],
             heater_pct, cooler_pct, current_temp, setpoint, recorded_at)
        )
        self._touch_last_seen(device)
        print(f"[DB] Wrote HVAC_STATE: {thing_name} | "
              f"Heat:{heater_pct:.1f}% Cool:{cooler_pct:.1f}% "
              f"Temp:{current_temp:.2f}°C Setpoint:{setpoint:.1f}°C")

    # ============================================================
    # HVAC STATE FROM THE GATEWAY'S OWN DECISION
    # Called by network.py after each temperature packet.
    # ============================================================

    def write_hvac_state_direct(self, zone_id, device_id, heater_pct, cooler_pct,
                                current_temp, setpoint, recorded_at=None):
        """
        Write HVAC state decided by the gateway (e.g. device_id='HVAC_A').
        recorded_at should be the temperature packet's timestamp, so the HVAC
        timeline uses the same clock as the readings that caused it.
        """
        if not self.connected:
            return
        device = self._get_device(device_id)
        if device is None:
            print(f"[DB] HVAC device '{device_id}' not registered, skipping HVAC state")
            return
        if recorded_at is None:
            recorded_at = datetime.now(tz=timezone.utc)
        try:
            with self.lock:
                self._reconnect_if_needed()
                self.cursor.execute(
                    """
                    INSERT INTO hvac_state
                        (org_id, device_id, zone_id, heater_pct, cooler_pct,
                         current_temp, setpoint, recorded_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (device_id, recorded_at) DO NOTHING
                    """,
                    (device['org_id'], device['id'], device['zone_id'],
                     heater_pct, cooler_pct, current_temp, setpoint, recorded_at)
                )
            mode = 'HEATING' if heater_pct > 0 else ('COOLING' if cooler_pct > 0 else 'IDLE')
            print(f"[DB] Wrote HVAC state: {device_id} = {mode} "
                  f"({current_temp:.1f}C -> {setpoint:.1f}C)")
        except Exception as e:
            print(f"[DB] HVAC state write error: {e}")

    # ============================================================
    # ANALYTICS + EVENTS
    # These callers only know the zone, so the organization comes from
    # the zone -> org map built with the device cache.
    # ============================================================

    def write_analytics_snapshot(self, zone_id, packet_type, stats,
                                 window_start, window_end):
        if not self.connected:
            return
        org_id = self._zone_org.get(str(zone_id))
        if org_id is None:
            print(f"[DB] Analytics: zone {zone_id} unknown, skipping snapshot")
            return
        try:
            with self.lock:
                self._reconnect_if_needed()
                self.cursor.execute(
                    """
                    INSERT INTO analytics_snapshots
                        (org_id, zone_id, metric_type, mean_val, stddev_val,
                         min_val, max_val, sample_count, window_start, snapshot_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (org_id, zone_id, packet_type,
                     stats['mean'], stats['stddev'], stats['min'], stats['max'],
                     stats['count'], window_start, window_end)
                )
            print(f"[DB] Wrote analytics snapshot: {packet_type} zone={zone_id}")
        except Exception as e:
            print(f"[DB] Analytics write error: {e}")

    def write_orchestration_event(self, zone_id, event_type,
                                  description, temperature=None, hvac_pid=None):
        if not self.connected:
            return
        org_id = self._zone_org.get(str(zone_id))
        if org_id is None:
            print(f"[DB] Event: zone {zone_id} unknown, skipping event")
            return
        try:
            with self.lock:
                self._reconnect_if_needed()
                self.cursor.execute(
                    """
                    INSERT INTO orchestration_events
                        (org_id, zone_id, event_type, trigger_value, action_taken)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (org_id, zone_id, event_type, temperature, description)
                )
            print(f"[DB] Wrote event: {event_type} zone={zone_id}")
        except Exception as e:
            print(f"[DB] Event write error: {e}")