"""
network.py - Network Communication Module

Handles:
- TCP server creation
- Client connection handling
- Data reception
- Smart process orchestration based on temperature
- Database writes for all incoming packets
"""

import socket
import threading
import time
from datetime import datetime, timezone
from protocol import PacketParser, PACKET_TYPE_HVAC_STATE, PACKET_TYPE_HVAC_TEMP


# ------------------------------------------------------------------
# V2 packet detection
#
# Every packet starts with 20 bytes. A V2 packet (32 bytes) has its TYPE at
# byte 12 and VERSION = 2 at byte 13. In a V1 packet, bytes 12-15 are the
# float value instead, so they can look like anything.
#
# Only HVAC packet types are ever sent as V2, so a packet is treated as V2
# only if byte 13 is 2 AND byte 12 is an HVAC type. (The old check accepted
# types 0-3, which are V1-only types, and rejected 4 = HVAC_STATE, so real
# HVAC packets were misread and the stream went out of sync.)
# ------------------------------------------------------------------
V2_PACKET_TYPES = (PACKET_TYPE_HVAC_STATE, PACKET_TYPE_HVAC_TEMP)


def is_v2_header(first20):
    """True if the first 20 bytes are the start of a 32-byte V2 packet."""
    if len(first20) < 14:
        return False
    return first20[13] == 2 and first20[12] in V2_PACKET_TYPES


# ------------------------------------------------------------------
# HVAC decision memory, shared by all client threads.
# zone_id -> (last mode written, monotonic time it was written)
# Used to write hvac_state only when the mode CHANGES, plus a periodic
# heartbeat so the dashboard's "latest" HVAC row stays fresh.
# ------------------------------------------------------------------
_last_hvac      = {}
_last_hvac_lock = threading.Lock()
HVAC_HEARTBEAT_SEC = 60


# ------------------------------------------------------------------
# Who owns the HVAC state?
#
# If a zone has a real HVAC controller reporting its own state (V2
# HVAC_STATE packets), THAT is the truth: it is what the equipment is
# actually doing. The gateway's own HEATING/COOLING/IDLE decision is only
# a fallback for zones whose controller hasn't reported recently.
#
# zone_id -> monotonic time of the last HVAC_STATE packet from a device
# ------------------------------------------------------------------
_device_hvac_seen  = {}
HVAC_DEVICE_FRESH_SEC = 30


def note_device_hvac_report(zone_id):
    """Remember that a real HVAC controller in this zone just reported."""
    with _last_hvac_lock:
        _device_hvac_seen[zone_id] = time.monotonic()


def device_reported_recently(zone_id):
    """True if this zone's HVAC controller reported within HVAC_DEVICE_FRESH_SEC."""
    with _last_hvac_lock:
        seen = _device_hvac_seen.get(zone_id)
    return seen is not None and (time.monotonic() - seen) < HVAC_DEVICE_FRESH_SEC


class ClientHandler:
    """Handles individual client connection"""

    def __init__(self, client_socket, address, buffer, parser, process_mgr, orch_config, db=None):
        self.socket      = client_socket
        self.address     = address
        self.buffer      = buffer
        self.parser      = parser
        self.process_mgr = process_mgr
        self.orch_config = orch_config
        self.db          = db       # DBWriter instance (None if DB unavailable)
        self.running     = True

    def _recv_exact(self, n):
        """Read exactly n bytes from socket, handling partial reads."""
        data = b''
        while len(data) < n:
            chunk = self.socket.recv(n - len(data))
            if not chunk:
                return None
            data += chunk
        return data

    def handle(self):
        """Main client handling loop"""
        print(f"[NETWORK] Client connected: {self.address}")

        try:
            while self.running:
                # Read first 20 bytes (V1 packet size)
                data = self._recv_exact(self.parser.get_packet_size())
                if not data:
                    break

                # Is this the start of a 32-byte V2 (HVAC) packet?
                if is_v2_header(data):
                    # Read remaining 12 bytes to complete the 32-byte V2 packet
                    rest = self._recv_exact(self.parser.get_v2_packet_size() - self.parser.get_packet_size())
                    if not rest:
                        break
                    data = data + rest

                if not data:
                    break

                # Validate checksum (V2 always passes)
                if not self.parser.validate_checksum(data):
                    print("[NETWORK] Invalid checksum")
                    continue

                # Parse packet (auto-detects V1 or V2)
                packet = self.parser.parse(data)
                if packet:
                    # Store in circular buffer (in-memory analytics)
                    self.buffer.add(packet)

                    # Log differently for V1 and V2
                    if packet['version'] == 2:
                        print(f"[GATEWAY] Received {packet['type_name']} (V2): "
                              f"{packet['device_id']} | "
                              f"Heat:{packet.get('heater_pct', 0):.1f}% "
                              f"Cool:{packet.get('cooler_pct', 0):.1f}% "
                              f"Temp:{packet.get('current_temp', 0):.2f}°C "
                              f"Setpoint:{packet.get('setpoint', 0):.1f}°C")
                    else:
                        print(f"[GATEWAY] Received {packet['type_name']}: "
                              f"{packet['device_id']} = {packet['value']:.2f}")

                    # Persist to database
                    if self.db:
                        self.db.write_packet(packet)

                    # A real HVAC controller reported its state: it owns this zone's HVAC
                    if packet['type'] == PACKET_TYPE_HVAC_STATE and self.db:
                        hvac_zone = self.db._get_zone_id(packet['device_id'])
                        if hvac_zone:
                            note_device_hvac_report(hvac_zone)

                    # Smart orchestration - trigger HVAC if temperature packet
                    if packet['type'] == 0:  # Temperature packet
                        self._check_temperature_and_trigger(packet)

        except Exception as e:
            print(f"[NETWORK] Error handling client: {e}")
        finally:
            self.socket.close()
            print(f"[NETWORK] Client disconnected: {self.address}")

    def _hvac_device_for_zone(self, zone_id):
        """Find the registered HVAC device in the same zone (e.g. 'HVAC_A')."""
        for thing_name, dev in self.db._device_cache.items():
            if dev['zone_id'] == zone_id and thing_name.startswith('HVAC'):
                return thing_name
        return None

    def _check_temperature_and_trigger(self, packet):
        """Decide HEATING / COOLING / IDLE from a temperature packet.

        Only used as a FALLBACK: if this zone's HVAC controller has reported
        its own state recently, the controller is the source of truth and
        nothing is written here.

        In ECS we cannot spawn subprocesses, so the decision is written to
        hvac_state (and orchestration_events) directly. To avoid a DB write
        for every packet, hvac_state is written only when the mode changes,
        plus once every HVAC_HEARTBEAT_SEC so the latest row stays current.
        """
        if not self.db:
            return

        temp      = packet['value']
        device_id = packet['device_id']

        zone_id = self.db._get_zone_id(device_id)
        if not zone_id:
            return

        hvac_device = self._hvac_device_for_zone(zone_id)
        if not hvac_device:
            return                       # no HVAC registered in this zone

        if device_reported_recently(zone_id):
            return                       # the real controller owns HVAC state here

        # Same clock as the temperature reading that caused the decision
        recorded_at = datetime.fromtimestamp(packet['timestamp'], tz=timezone.utc)
        target      = self.orch_config.temp_target

        if self.orch_config.is_temperature_too_low(temp):
            mode, heater, cooler = 'HEATING', 80.0, 0.0
            reason = f'Temp {temp:.1f}C below {self.orch_config.temp_threshold_low}C'
        elif self.orch_config.is_temperature_too_high(temp):
            mode, heater, cooler = 'COOLING', 0.0, 80.0
            reason = f'Temp {temp:.1f}C above {self.orch_config.temp_threshold_high}C'
        else:
            mode, heater, cooler = 'IDLE', 0.0, 0.0
            reason = f'Temp {temp:.1f}C within range'

        now = time.monotonic()
        with _last_hvac_lock:
            last_mode, last_time = _last_hvac.get(zone_id, (None, 0.0))
            changed   = (mode != last_mode)
            heartbeat = (now - last_time) >= HVAC_HEARTBEAT_SEC
            if not (changed or heartbeat):
                return                   # same mode, written recently: skip
            _last_hvac[zone_id] = (mode, now)

        self.db.write_hvac_state_direct(
            zone_id=zone_id, device_id=hvac_device,
            heater_pct=heater, cooler_pct=cooler,
            current_temp=temp, setpoint=target,
            recorded_at=recorded_at,
        )

        if changed and mode != 'IDLE':
            print(f"\n[ORCHESTRATOR] {reason} -> {mode}")
            self.db.write_orchestration_event(
                zone_id=zone_id, event_type=f'HVAC_{mode}',
                description=reason, temperature=temp,
            )


class TCPServer:
    """Multi-threaded TCP server with smart orchestration"""

    def __init__(self, config, buffer, process_mgr, orch_config, db=None):
        self.config        = config
        self.buffer        = buffer
        self.process_mgr   = process_mgr
        self.orch_config   = orch_config
        self.db            = db       # DBWriter instance (None if DB unavailable)
        self.parser        = PacketParser()
        self.server_socket = None
        self.running       = False

    def start(self):
        """Start TCP server"""
        print("[NETWORK] Initializing TCP server...")

        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.config.host, self.config.port))
        self.server_socket.listen(5)

        print(f"[NETWORK] Server listening on {self.config.host}:{self.config.port}\n")

        self.running = True
        self._accept_connections()

    def _accept_connections(self):
        """Accept incoming connections"""
        while self.running:
            try:
                client_socket, address = self.server_socket.accept()

                # Pass db into each client handler
                handler = ClientHandler(
                    client_socket,
                    address,
                    self.buffer,
                    self.parser,
                    self.process_mgr,
                    self.orch_config,
                    self.db            # NEW: pass db writer
                )
                thread = threading.Thread(target=handler.handle, daemon=True)
                thread.start()

            except KeyboardInterrupt:
                print("\n[NETWORK] Shutdown signal received")
                break
            except Exception as e:
                print(f"[NETWORK] Error accepting connection: {e}")

        self._shutdown()

    def _shutdown(self):
        """Clean shutdown"""
        self.running = False
        if self.server_socket:
            self.server_socket.close()
        print("[NETWORK] Server shut down cleanly")