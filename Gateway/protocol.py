"""
protocol.py - Binary Packet Protocol (Python Gateway Side)

Mirrors protocol.h on the C side. Handles:
- Binary packet parsing (struct unpacking)
- Checksum validation
- Packet type definitions

Packet format: '<8sIfBB2x' (little-endian, no padding)
Byte layout:
  [0-7]   device_id  : 8-byte null-terminated string
  [8-11]  timestamp  : uint32 Unix epoch
  [12-15] value      : float (meaning depends on packet type)
  [16]    type       : uint8 packet type
  [17]    checksum   : uint8 = sum(bytes[0:17]) % 256
  [18-19] padding    : 2 bytes for alignment

Packet types (must stay in sync with protocol.h):
  0 = TEMP        - Temperature reading (°C)           from temp_sensor
  1 = POWER       - Power consumption (kW)             from power_meter
  2 = CONTROL     - Generic control signal (%)         reserved
  3 = OCCUPANCY   - People count (integer as float)    from occupancy_sensor
  4 = HVAC_STATE  - HVAC output state (heater/cooler %) from hvac_controller
"""

import struct

# ============================================================
# PACKET FORMAT
# Must match the C Packet struct in protocol.h exactly
# ============================================================
PACKET_FORMAT = '<8sIfBB2x'   # little-endian: 8s + I + f + B + B + 2x padding
PACKET_SIZE   = 20            # Total bytes per packet

# ============================================================
# PACKET TYPE CONSTANTS
# Keep in sync with #define PACKET_TYPE_* in protocol.h
# ============================================================
PACKET_TYPE_TEMP       = 0   # Temperature reading (°C)
PACKET_TYPE_POWER      = 1   # Power consumption (kW)
PACKET_TYPE_CONTROL    = 2   # Generic control signal (%) — reserved
PACKET_TYPE_OCCUPANCY  = 3   # People count (integer stored as float)
PACKET_TYPE_HVAC_STATE = 4   # HVAC heater/cooler output (%)

# Human-readable names for each packet type (used in logging)
TYPE_NAMES = {
    PACKET_TYPE_TEMP:       'TEMP',
    PACKET_TYPE_POWER:      'POWER',
    PACKET_TYPE_CONTROL:    'CONTROL',
    PACKET_TYPE_OCCUPANCY:  'OCCUPANCY',
    PACKET_TYPE_HVAC_STATE: 'HVAC_STATE',
}


class PacketParser:
    """
    Handles binary packet parsing and validation.
    One instance shared across all client handler threads.
    """

    @staticmethod
    def validate_checksum(packet_bytes):
        """
        Validate packet integrity.
        Checksum = sum(bytes[0:17]) % 256, stored at byte 17.

        Args:
            packet_bytes: Raw 20-byte packet from network

        Returns:
            bool: True if checksum matches, False if packet is corrupted
        """
        calculated = sum(packet_bytes[:17]) % 256
        received   = packet_bytes[17]
        return calculated == received

    @staticmethod
    def parse(data):
        """
        Unpack a raw 20-byte binary packet into a dictionary.

        Args:
            data: 20-byte binary packet

        Returns:
            dict with keys:
                device_id  (str)
                timestamp  (int)
                value      (float)
                type       (int)
                checksum   (int)
                type_name  (str)  — human-readable type label
                occupancy  (int)  — people count, only set for OCCUPANCY packets
            Returns None on parse error.
        """
        try:
            device_id, timestamp, value, pkt_type, checksum = struct.unpack(
                PACKET_FORMAT, data
            )

            # Decode device ID — strip null bytes
            device_id = device_id.decode('utf-8').strip('\x00')

            packet = {
                'device_id':  device_id,
                'timestamp':  timestamp,
                'value':      value,
                'type':       pkt_type,
                'checksum':   checksum,
                'type_name':  TYPE_NAMES.get(pkt_type, f'UNKNOWN({pkt_type})'),
            }

            # For occupancy packets, cast value to int for readability
            if pkt_type == PACKET_TYPE_OCCUPANCY:
                packet['occupancy'] = int(value)

            return packet

        except Exception as e:
            print(f"[PROTOCOL ERROR] Parse failed: {e}")
            return None

    @staticmethod
    def get_packet_size():
        """Return expected packet size in bytes."""
        return PACKET_SIZE