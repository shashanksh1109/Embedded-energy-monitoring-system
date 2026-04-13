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
from protocol import PacketParser


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

                # Check version byte at position 13 (V2 packets have version=2 there)
                # V1 packets have checksum at byte 17 — byte 13 is part of the float value
                # V2 packets explicitly set version=2 at byte 13
                pkt_type_byte = data[12] if len(data) > 12 else 0xFF
                version_byte  = data[13] if len(data) > 13 else 0
                version = version_byte

                if version == 2 and pkt_type_byte in (0, 1, 2, 3):
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

                    # Smart orchestration - trigger HVAC if temperature packet
                    if packet['type'] == 0:  # Temperature packet
                        self._check_temperature_and_trigger(packet)

        except Exception as e:
            print(f"[NETWORK] Error handling client: {e}")
        finally:
            self.socket.close()
            print(f"[NETWORK] Client disconnected: {self.address}")

    def _check_temperature_and_trigger(self, packet):
        """Analyze temperature and trigger HVAC if needed.
        In ECS we cannot spawn subprocesses — write hvac_state and
        orchestration_events directly to the DB instead.
        """
        temp      = packet['value']
        device_id = packet['device_id']
        zone_suffix = device_id.split('_')[1] if '_' in device_id else 'A'
        hvac_device = f'HVAC_{zone_suffix}'

        if not self.db:
            return
        zone_id = self.db._get_zone_id(device_id)
        if not zone_id:
            return

        if self.orch_config.is_temperature_too_low(temp):
            print(f"\n[ORCHESTRATOR] TEMPERATURE ALERT: {temp:.1f}C below {self.orch_config.temp_threshold_low}C → HEATING")
            self.db.write_hvac_state_direct(
                zone_id=zone_id, device_id=hvac_device,
                heater_pct=80.0, cooler_pct=0.0,
                current_temp=temp, setpoint=self.orch_config.temp_target
            )
            self.db.write_orchestration_event(
                zone_id=zone_id, event_type='HVAC_HEATING',
                description=f'Temp {temp:.1f}C below {self.orch_config.temp_threshold_low}C',
                temperature=temp
            )

        elif self.orch_config.is_temperature_too_high(temp):
            print(f"\n[ORCHESTRATOR] TEMPERATURE ALERT: {temp:.1f}C above {self.orch_config.temp_threshold_high}C → COOLING")
            self.db.write_hvac_state_direct(
                zone_id=zone_id, device_id=hvac_device,
                heater_pct=0.0, cooler_pct=80.0,
                current_temp=temp, setpoint=self.orch_config.temp_target
            )
            self.db.write_orchestration_event(
                zone_id=zone_id, event_type='HVAC_COOLING',
                description=f'Temp {temp:.1f}C above {self.orch_config.temp_threshold_high}C',
                temperature=temp
            )

        elif self.orch_config.is_temperature_stable(temp):
            self.db.write_hvac_state_direct(
                zone_id=zone_id, device_id=hvac_device,
                heater_pct=0.0, cooler_pct=0.0,
                current_temp=temp, setpoint=self.orch_config.temp_target
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