"""
network.py - Network Communication Module

Handles:
- TCP server creation
- Client connection handling
- Data reception
- Smart process orchestration based on temperature
"""

import socket
import threading
import time
from protocol import PacketParser


class ClientHandler:
    """Handles individual client connection"""
    
    def __init__(self, client_socket, address, buffer, parser, process_mgr, orch_config):
        self.socket = client_socket
        self.address = address
        self.buffer = buffer
        self.parser = parser
        self.process_mgr = process_mgr
        self.orch_config = orch_config
        self.running = True
    
    def handle(self):
        """Main client handling loop"""
        print(f"[NETWORK] Client connected: {self.address}")
        
        try:
            while self.running:
                # Receive packet
                data = self.socket.recv(self.parser.get_packet_size())
                
                if not data:
                    break
                
                if len(data) != self.parser.get_packet_size():
                    print(f"[NETWORK] Invalid packet size: {len(data)} bytes")
                    break
                
                # Validate and parse
                if not self.parser.validate_checksum(data):
                    print("[NETWORK] Invalid checksum")
                    continue
                
                packet = self.parser.parse(data)
                if packet:
                    self.buffer.add(packet)
                    print(f"[GATEWAY] Received {packet['type_name']}: "
                          f"{packet['device_id']} = {packet['value']:.2f}")
                    
                    # Smart orchestration - trigger HVAC if needed
                    if packet['type'] == 0:  # Temperature packet
                        self._check_temperature_and_trigger(packet)
        
        except Exception as e:
            print(f"[NETWORK] Error handling client: {e}")
        finally:
            self.socket.close()
            print(f"[NETWORK] Client disconnected: {self.address}")
    
    def _check_temperature_and_trigger(self, packet):
        """Analyze temperature and trigger HVAC if needed"""
        temp = packet['value']
        device_id = packet['device_id']
        
        # Extract zone from device ID
        if '_' in device_id:
            zone = device_id.split('_')[1]
        else:
            zone = 'A'
        
        # Check if action needed
        if self.orch_config.is_temperature_too_low(temp):
            if not self.process_mgr.is_hvac_running():
                print(f"\n[ORCHESTRATOR] TEMPERATURE ALERT")
                print(f"[ORCHESTRATOR]   Current: {temp:.1f}C")
                print(f"[ORCHESTRATOR]   Threshold: {self.orch_config.temp_threshold_low}C")
                print(f"[ORCHESTRATOR]   Status: Below threshold")
                print(f"[ORCHESTRATOR]   Action: Starting HVAC (heating mode)")
                
                self.process_mgr.spawn_hvac(
                    f'HVAC_{zone}', 
                    f'Zone_{zone}', 
                    self.orch_config.temp_target
                )
                print()
        
        elif self.orch_config.is_temperature_too_high(temp):
            if not self.process_mgr.is_hvac_running():
                print(f"\n[ORCHESTRATOR] TEMPERATURE ALERT")
                print(f"[ORCHESTRATOR]   Current: {temp:.1f}C")
                print(f"[ORCHESTRATOR]   Threshold: {self.orch_config.temp_threshold_high}C")
                print(f"[ORCHESTRATOR]   Status: Above threshold")
                print(f"[ORCHESTRATOR]   Action: Starting HVAC (cooling mode)")
                
                self.process_mgr.spawn_hvac(
                    f'HVAC_{zone}', 
                    f'Zone_{zone}', 
                    self.orch_config.temp_target
                )
                print()
        
        elif self.orch_config.is_temperature_stable(temp):
            # Temperature is acceptable, check if we should stop HVAC
            if self.process_mgr.is_hvac_running():
                # Check if been stable long enough
                runtime = time.time() - self.process_mgr.hvac_start_time
                
                if runtime > self.orch_config.stable_duration:
                    print(f"\n[ORCHESTRATOR] TEMPERATURE STABLE")
                    print(f"[ORCHESTRATOR]   Current: {temp:.1f}C")
                    print(f"[ORCHESTRATOR]   Range: {self.orch_config.temp_threshold_low}-{self.orch_config.temp_threshold_high}C")
                    print(f"[ORCHESTRATOR]   Stable duration: {runtime:.0f}s")
                    print(f"[ORCHESTRATOR]   Action: Stopping HVAC")
                    
                    self.process_mgr.kill_hvac()
                    print()


class TCPServer:
    """Multi-threaded TCP server with smart orchestration"""
    
    def __init__(self, config, buffer, process_mgr, orch_config):
        self.config = config
        self.buffer = buffer
        self.process_mgr = process_mgr
        self.orch_config = orch_config
        self.parser = PacketParser()
        self.server_socket = None
        self.running = False
    
    def start(self):
        """Start TCP server"""
        print("[NETWORK] Initializing TCP server...")
        
        # Create socket
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # Bind to address
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
                
                # Handle client in separate thread
                handler = ClientHandler(
                    client_socket, 
                    address, 
                    self.buffer, 
                    self.parser,
                    self.process_mgr,
                    self.orch_config
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