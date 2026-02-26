"""
network.py - Network Communication Module

Handles:
- TCP server creation
- Client connection handling
- Data reception
"""

import socket
import threading
from protocol import PacketParser


class ClientHandler:
    """Handles individual client connection"""
    
    def __init__(self, client_socket, address, buffer, parser):
        self.socket = client_socket
        self.address = address
        self.buffer = buffer
        self.parser = parser
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
                    print("[NETWORK] ✗ Invalid checksum")
                    continue
                
                packet = self.parser.parse(data)
                if packet:
                    self.buffer.add(packet)
                    print(f"[GATEWAY] ✓ Received {packet['type_name']}: "
                          f"{packet['device_id']} = {packet['value']:.2f}")
        
        except Exception as e:
            print(f"[NETWORK] Error handling client: {e}")
        finally:
            self.socket.close()
            print(f"[NETWORK] Client disconnected: {self.address}")


class TCPServer:
    """Multi-threaded TCP server"""
    
    def __init__(self, config, buffer):
        self.config = config
        self.buffer = buffer
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
        
        print(f"[NETWORK] ✓ Server listening on {self.config.host}:{self.config.port}\n")
        
        self.running = True
        self._accept_connections()
    
    def _accept_connections(self):
        """Accept incoming connections"""
        while self.running:
            try:
                client_socket, address = self.server_socket.accept()
                
                # Handle client in separate thread
                handler = ClientHandler(client_socket, address, self.buffer, self.parser)
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
        print("[NETWORK] ✓ Server shut down cleanly")
