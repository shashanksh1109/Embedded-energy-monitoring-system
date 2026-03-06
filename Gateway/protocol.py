"""
protocol.py - Binary Protocol Operations

Handles:
- Binary packet parsing
- Checksum validation
- Data unpacking
"""

import struct

# Packet format: 8s (device_id) I (timestamp) f (value) B (type) B (checksum) 2x (padding)
PACKET_FORMAT = '<8sIfBB2x'
PACKET_SIZE = 20

# Packet type definitions
PACKET_TYPE_TEMP = 0
PACKET_TYPE_POWER = 1
PACKET_TYPE_CONTROL = 2

TYPE_NAMES = {
    PACKET_TYPE_TEMP: 'TEMP',
    PACKET_TYPE_POWER: 'POWER',
    PACKET_TYPE_CONTROL: 'CONTROL'
}


class PacketParser:
    """Handles binary packet parsing and validation"""
    
    @staticmethod
    def validate_checksum(packet_bytes):
        """
        Validate packet checksum
        
        Args:
            packet_bytes: Raw bytes from network
            
        Returns:
            bool: True if checksum valid, False otherwise
        """
        # Checksum is at byte 17, sum bytes 0-16
        calculated = sum(packet_bytes[:17]) % 256
        received = packet_bytes[17]
        return calculated == received
    
    @staticmethod
    def parse(data):
        """
        Parse binary packet into dictionary
        
        Args:
            data: 20-byte binary packet
            
        Returns:
            dict: Parsed packet data or None if error
        """
        try:
            # Unpack binary data
            device_id, timestamp, value, pkt_type, checksum = struct.unpack(PACKET_FORMAT, data)
            
            # Decode device ID (remove null bytes)
            device_id = device_id.decode('utf-8').strip('\x00')
            
            return {
                'device_id': device_id,
                'timestamp': timestamp,
                'value': value,
                'type': pkt_type,
                'checksum': checksum,
                'type_name': TYPE_NAMES.get(pkt_type, f'UNKNOWN({pkt_type})')
            }
        except Exception as e:
            print(f"[PROTOCOL ERROR] Parse failed: {e}")
            return None
    
    @staticmethod
    def get_packet_size():
        """Return expected packet size"""
        return PACKET_SIZE
