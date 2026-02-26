import socket
import struct
import threading
import time
from collections import deque

PACKET_FORMAT = '8sIfBB2x'  # 2x = 2 bytes of padding
PACKET_SIZE = struct.calcsize(PACKET_FORMAT)

class CircularBuffer:
    def __init__(self, size=1000):
        self.buffer = deque(maxlen=size)
    
    def add(self, data):
        self.buffer.append(data)
    
    def calculate_stats(self):
        if not self.buffer:
            return None
        values = [d['value'] for d in self.buffer]
        mean = sum(values) / len(values)
        variance = sum((x - mean) ** 2 for x in values) / len(values)
        stddev = variance ** 0.5
        return {'mean': mean, 'stddev': stddev, 'count': len(values)}

class Gateway:
    def __init__(self, host='127.0.0.1', port=8080):
        self.host = host
        self.port = port
        self.buffer = CircularBuffer()
        self.running = False
    
    def validate_checksum(self, packet_bytes):
    # Manually extract checksum byte at position 17
    
     received = packet_bytes[17]
    
    # Calculate: sum bytes 0-16 (device_id + timestamp + value + type)
     calculated = sum(packet_bytes[:17]) % 256
    
     #print(f"[DEBUG] Byte 17 = {received} (0x{received:02x})")
     #print(f"[DEBUG] Checksum - Calculated: {calculated}, Received: {received}")
     return calculated == received
    
    def parse_packet(self, data):
        try:
            device_id, timestamp, value, pkt_type, checksum = struct.unpack(PACKET_FORMAT, data)
            device_id = device_id.decode('utf-8').strip('\x00')
            
            print(f"[DEBUG] Parsed: device_id={device_id}, timestamp={timestamp}, value={value:.2f}, type={pkt_type}, checksum={checksum}")
            
            return {
                'device_id': device_id,
                'timestamp': timestamp,
                'value': value,
                'type': pkt_type
            }
        except Exception as e:
            print(f"[ERROR] Parse error: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def handle_client(self, client_socket, addr):
        print(f"[GATEWAY] Client connected: {addr}")
        
        while self.running:
            try:
                data = client_socket.recv(PACKET_SIZE)
                if not data:
                    print("[GATEWAY] No data received, client disconnected")
                    break
                    
                if len(data) != PACKET_SIZE:
                    print(f"[GATEWAY] Invalid packet size: expected {PACKET_SIZE}, got {len(data)}")
                    break
                
                print(f"[DEBUG] Received {len(data)} bytes: {data.hex()}")
                
                if not self.validate_checksum(data):
                    print("[GATEWAY] Invalid checksum - packet rejected")
                    continue
                
                packet = self.parse_packet(data)
                if packet:
                    self.buffer.add(packet)
                    
                    type_names = {0: 'TEMP', 1: 'POWER', 2: 'CONTROL'}
                    type_name = type_names.get(packet['type'], f'UNKNOWN({packet["type"]})')
                    
                    print(f"[GATEWAY] ✓ Received {type_name}: {packet['device_id']} = {packet['value']:.2f}")
            
            except Exception as e:
                print(f"[ERROR] {e}")
                import traceback
                traceback.print_exc()
                break
        
        client_socket.close()
        print(f"[GATEWAY] Client disconnected: {addr}")
    
    def analytics_thread(self):
        while self.running:
            time.sleep(60)
            stats = self.buffer.calculate_stats()
            if stats:
                print(f"[ANALYTICS] Mean={stats['mean']:.2f}, StdDev={stats['stddev']:.2f}, Count={stats['count']}")
    
    def start(self):
        self.running = True
        
        print(f"[INFO] Packet format: {PACKET_FORMAT}")
        print(f"[INFO] Packet size: {PACKET_SIZE} bytes")
        
        analytics = threading.Thread(target=self.analytics_thread, daemon=True)
        analytics.start()
        
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind((self.host, self.port))
        server.listen(5)
        print(f"[GATEWAY] Listening on {self.host}:{self.port}")
        
        while self.running:
            try:
                client, addr = server.accept()
                thread = threading.Thread(target=self.handle_client, args=(client, addr))
                thread.start()
            except KeyboardInterrupt:
                print("\n[GATEWAY] Shutting down...")
                self.running = False
                break
        
        server.close()

if __name__ == '__main__':
    gateway = Gateway()
    gateway.start()