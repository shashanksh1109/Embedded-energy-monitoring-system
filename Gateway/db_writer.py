"""
db_writer.py - Database Writer Module

Persists all incoming sensor data from the gateway buffer into PostgreSQL.

Responsibilities:
  - Connect to PostgreSQL using env vars (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD)
  - Look up zone_id from device_id on startup (cached, avoids repeated queries)
  - Write temperature, occupancy, hvac_state, power readings to correct tables
  - Write analytics snapshots and orchestration events
  - Retry connection on failure (resilient to DB restart)
  - Run in background thread, non-blocking to gateway

Packet types handled:
  0 = TEMP        → temperature_readings
  1 = POWER       → power_readings
  3 = OCCUPANCY   → occupancy_readings
  4 = HVAC_STATE  → hvac_state
"""

import os
import time
import threading
import psycopg2
import psycopg2.extras
from datetime import datetime, timezone
from protocol import (
    PACKET_TYPE_TEMP,
    PACKET_TYPE_POWER,
    PACKET_TYPE_OCCUPANCY,
    PACKET_TYPE_HVAC_STATE,
)


# ============================================================
# DATABASE CONFIGURATION
# Reads from environment variables (set in docker-compose.yml
# or exported locally before running)
# ============================================================
DB_CONFIG = {
    'host':     os.getenv('DB_HOST',     '127.0.0.1'),
    'port':     int(os.getenv('DB_PORT', '5432')),
    'dbname':   os.getenv('DB_NAME',     'energy_db'),
    'user':     os.getenv('DB_USER',     'energy_user'),
    'password': os.getenv('DB_PASSWORD', 'energy_pass'),
}

RETRY_INTERVAL_SEC = 5   # seconds between reconnect attempts
MAX_RETRIES        = 10  # max reconnect attempts before giving up


class DBWriter:
    """
    Handles all PostgreSQL write operations for the gateway.
    Runs its own background thread for async writes.
    """

    def __init__(self):
        self.conn       = None
        self.cursor     = None
        self.connected  = False
        self.lock       = threading.Lock()   # thread-safe writes
        self._zone_cache = {}                # device_id → zone_id (UUID)

    # ============================================================
    # CONNECTION MANAGEMENT
    # ============================================================

    def connect(self):
        """
        Connect to PostgreSQL with retry logic.
        Retries up to MAX_RETRIES times before giving up.

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

                # Pre-load zone cache on connect
                self._load_zone_cache()
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
        """Check connection health and reconnect if dropped."""
        try:
            self.conn.isolation_level  # lightweight health check
        except Exception:
            print("[DB] Connection lost, reconnecting...")
            self.connected = False
            self.connect()

    # ============================================================
    # ZONE CACHE
    # Maps device_id → zone_id UUID to avoid repeated DB lookups
    # ============================================================

    def _load_zone_cache(self):
        """Load device_id → zone_id mapping from devices table."""
        try:
            self.cursor.execute(
                "SELECT device_id, zone_id FROM devices;"
            )
            rows = self.cursor.fetchall()
            self._zone_cache = {row[0]: str(row[1]) for row in rows}
            print(f"[DB] Zone cache loaded: {list(self._zone_cache.keys())}")
        except Exception as e:
            print(f"[DB] Failed to load zone cache: {e}")

    def _get_zone_id(self, device_id):
        """
        Get zone_id UUID for a device_id.
        Returns None if device not registered in DB.
        """
        if device_id not in self._zone_cache:
            # Try to reload cache (new device may have been added)
            self._load_zone_cache()
        return self._zone_cache.get(device_id)

    # ============================================================
    # PACKET ROUTER
    # Routes incoming packets to the correct write function
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
        device_id = packet.get('device_id')
        zone_id   = self._get_zone_id(device_id)

        if zone_id is None:
            print(f"[DB] Unknown device '{device_id}', skipping write")
            return

        # Convert Unix timestamp to timezone-aware datetime
        recorded_at = datetime.fromtimestamp(
            packet['timestamp'], tz=timezone.utc
        )

        try:
            with self.lock:
                self._reconnect_if_needed()

                if pkt_type == PACKET_TYPE_TEMP:
                    self._write_temperature(device_id, zone_id, packet['value'], recorded_at)

                elif pkt_type == PACKET_TYPE_OCCUPANCY:
                    self._write_occupancy(device_id, zone_id, int(packet['value']), recorded_at)

                elif pkt_type == PACKET_TYPE_POWER:
                    self._write_power(device_id, zone_id, packet, recorded_at)

                elif pkt_type == PACKET_TYPE_HVAC_STATE:
                    self._write_hvac_state(device_id, zone_id, packet, recorded_at)

                else:
                    print(f"[DB] Unknown packet type {pkt_type}, skipping")

        except Exception as e:
            print(f"[DB] Write error for {device_id} type={pkt_type}: {e}")

    # ============================================================
    # WRITE FUNCTIONS (one per table)
    # ============================================================

    def _write_temperature(self, device_id, zone_id, value_c, recorded_at):
        """Insert a temperature reading into temperature_readings."""
        self.cursor.execute(
            """
            INSERT INTO temperature_readings (device_id, zone_id, value_c, recorded_at)
            VALUES (%s, %s, %s, %s)
            """,
            (device_id, zone_id, value_c, recorded_at)
        )
        print(f"[DB] Wrote TEMP: {device_id} = {value_c:.2f}°C")

    def _write_occupancy(self, device_id, zone_id, people_count, recorded_at):
        """Insert an occupancy reading into occupancy_readings."""
        self.cursor.execute(
            """
            INSERT INTO occupancy_readings (device_id, zone_id, people_count, recorded_at)
            VALUES (%s, %s, %s, %s)
            """,
            (device_id, zone_id, people_count, recorded_at)
        )
        print(f"[DB] Wrote OCCUPANCY: {device_id} = {people_count} people")

    def _write_power(self, device_id, zone_id, packet, recorded_at):
        """
        Insert a power reading into power_readings.
        Power packets carry kW in the value field.
        energy_kwh and cost_usd are recalculated here since
        the binary packet only carries one float value field.
        """
        power_kw   = packet['value']
        # Energy = power * time (1 second = 1/3600 hours)
        energy_kwh = power_kw / 3600.0
        cost_usd   = energy_kwh * 0.12   # $0.12 per kWh
        hvac_pct   = 0.0                 # not available in current packet format

        self.cursor.execute(
            """
            INSERT INTO power_readings
                (device_id, zone_id, power_kw, energy_kwh, cost_usd, hvac_pct, recorded_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (device_id, zone_id, power_kw, energy_kwh, cost_usd, hvac_pct, recorded_at)
        )
        print(f"[DB] Wrote POWER: {device_id} = {power_kw:.2f} kW")

    def _write_hvac_state(self, device_id, zone_id, packet, recorded_at):
        """
        Insert HVAC state into hvac_state.
        V2 packets carry full state: heater_pct, cooler_pct, current_temp, setpoint.
        """
        # Use proper V2 fields if available, fallback for legacy
        heater_pct   = packet.get('heater_pct',   packet.get('value1', 0.0))
        cooler_pct   = packet.get('cooler_pct',   packet.get('value2', 0.0))
        current_temp = packet.get('current_temp', packet.get('value3', 0.0))
        setpoint_c   = packet.get('setpoint',     packet.get('value4', 0.0))
        pid_output   = heater_pct if heater_pct > 0 else -cooler_pct

        self.cursor.execute(
            """
            INSERT INTO hvac_state
                (device_id, zone_id, setpoint_c, heater_pct, cooler_pct,
                 pid_output, current_temp, recorded_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (device_id, zone_id, setpoint_c, heater_pct, cooler_pct,
             pid_output, current_temp, recorded_at)
        )
        print(f"[DB] Wrote HVAC_STATE: {device_id} | "
              f"Heat:{heater_pct:.1f}% Cool:{cooler_pct:.1f}% "
              f"Temp:{current_temp:.2f}°C Setpoint:{setpoint_c:.1f}°C")

    # ============================================================
    # ANALYTICS + EVENTS
    # Called directly by analytics engine and orchestrator
    # ============================================================

    def write_analytics_snapshot(self, zone_id, packet_type, stats,
                                  window_start, window_end):
        """
        Persist an analytics snapshot from the analytics engine.

        Args:
            zone_id     : UUID string
            packet_type : e.g. 'TEMP', 'OCCUPANCY'
            stats       : dict with mean, stddev, min, max, count
            window_start: datetime start of analytics window
            window_end  : datetime end of analytics window
        """
        if not self.connected:
            return
        try:
            with self.lock:
                self.cursor.execute(
                    """
                    INSERT INTO analytics_snapshots
                        (zone_id, packet_type, mean, stddev, min_val, max_val,
                         sample_count, window_start, window_end)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        zone_id, packet_type,
                        stats['mean'], stats['stddev'],
                        stats['min'],  stats['max'],
                        stats['count'],
                        window_start,  window_end
                    )
                )
            print(f"[DB] Wrote analytics snapshot: {packet_type} zone={zone_id}")
        except Exception as e:
            print(f"[DB] Analytics write error: {e}")

    def write_orchestration_event(self, zone_id, event_type,
                                   description, temperature=None, hvac_pid=None):
        """
        Persist an orchestration event (HVAC start/stop, temp alert).

        Args:
            zone_id     : UUID string
            event_type  : HVAC_STARTED, HVAC_STOPPED, TEMP_ALERT_LOW, TEMP_ALERT_HIGH
            description : human-readable detail string
            temperature : float that triggered event (optional)
            hvac_pid    : OS PID of spawned HVAC process (optional)
        """
        if not self.connected:
            return
        try:
            with self.lock:
                self.cursor.execute(
                    """
                    INSERT INTO orchestration_events
                        (zone_id, event_type, description, temperature, hvac_pid)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (zone_id, event_type, description, temperature, hvac_pid)
                )
            print(f"[DB] Wrote event: {event_type} zone={zone_id}")
        except Exception as e:
            print(f"[DB] Event write error: {e}")