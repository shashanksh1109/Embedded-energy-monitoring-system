"""
protocol.py - Binary Packet Protocol (Python Gateway Side)

Supports two packet versions:

V1 - 20 bytes (legacy)
  Used by: temp_sensor, occupancy_sensor, power_meter
  Format: '<8sIfBB2x'
  [0-7]   device_id  : 8-byte null-terminated string
  [8-11]  timestamp  : uint32 Unix epoch
  [12-15] value      : float (single value)
  [16]    type       : uint8 packet type
  [17]    checksum   : uint8 = sum(bytes[0:17]) % 256
  [18-19] padding    : 2 bytes alignment

V2 - 32 bytes (extended)
  Used by: hvac_controller
  Format: '<8sIBB2xffff'
  [0-7]   device_id  : 8-byte null-terminated string
  [8-11]  timestamp  : uint32 Unix epoch
  [12]    type       : uint8 packet type
  [13]    version    : uint8 = 2
  [14-15] padding    : 2 bytes alignment
  [16-19] value1     : float (primary)
  [20-23] value2     : float (secondary)
  [24-27] value3     : float (tertiary)
  [28-31] value4     : float (quaternary)

Packet types (sync with protocol.h):
  0 = TEMP        V1 — Temperature reading (°C)
  1 = POWER       V1 — Power consumption (kW)
  2 = CONTROL     V1 — Generic control signal (%) reserved
  3 = OCCUPANCY   V1 — People count (integer as float)
  4 = HVAC_STATE  V2 — heater%, cooler%, current_temp, setpoint
  5 = HVAC_TEMP   V2 — Reserved
"""

import struct

# ============================================================
# V1 PACKET FORMAT
# ============================================================
PACKET_FORMAT   = '<8sIfBB2x'
PACKET_SIZE     = 20

# ============================================================
# V2 PACKET FORMAT
# ============================================================
PACKET_V2_FORMAT = '<8sIBB2xffff'
PACKET_V2_SIZE   = 32

# ============================================================
# PROTOCOL VERSION CONSTANTS
# ============================================================
PROTOCOL_V1 = 1
PROTOCOL_V2 = 2

# ============================================================
# PACKET TYPE CONSTANTS
# Keep in sync with protocol.h
# ============================================================
PACKET_TYPE_TEMP       = 0
PACKET_TYPE_POWER      = 1
PACKET_TYPE_CONTROL    = 2
PACKET_TYPE_OCCUPANCY  = 3
PACKET_TYPE_HVAC_STATE = 4
PACKET_TYPE_HVAC_TEMP  = 5

# Human-readable names for logging
TYPE_NAMES = {
    PACKET_TYPE_TEMP:       'TEMP',
    PACKET_TYPE_POWER:      'POWER',
    PACKET_TYPE_CONTROL:    'CONTROL',
    PACKET_TYPE_OCCUPANCY:  'OCCUPANCY',
    PACKET_TYPE_HVAC_STATE: 'HVAC_STATE',
    PACKET_TYPE_HVAC_TEMP:  'HVAC_TEMP',
}

# V2 value field labels per packet type (for logging and DB mapping)
V2_FIELD_LABELS = {
    PACKET_TYPE_HVAC_STATE: ('heater_pct', 'cooler_pct', 'current_temp', 'setpoint'),
    PACKET_TYPE_HVAC_TEMP:  ('current_temp', 'setpoint', '', ''),
}


class PacketParser:
    """
    Handles binary packet parsing and validation for both V1 and V2.
    Detects packet version by size — V1=20 bytes, V2=32 bytes.
    """

    @staticmethod
    def detect_version(data):
        """
        Detect packet version by raw byte size.

        Args:
            data: raw bytes received from network

        Returns:
            int: PROTOCOL_V1 or PROTOCOL_V2
        """
        if len(data) == PACKET_V2_SIZE:
            return PROTOCOL_V2
        return PROTOCOL_V1

    @staticmethod
    def validate_checksum(packet_bytes):
        """
        Validate V1 packet checksum.
        Checksum = sum(bytes[0:17]) % 256, stored at byte 17.
        V2 packets do not use checksum — always returns True for V2.

        Args:
            packet_bytes: raw bytes from network

        Returns:
            bool: True if valid
        """
        if len(packet_bytes) == PACKET_V2_SIZE:
            return True   # V2 uses version field, not checksum
        calculated = sum(packet_bytes[:17]) % 256
        received   = packet_bytes[17]
        return calculated == received

    @staticmethod
    def parse(data):
        """
        Parse a raw binary packet into a dictionary.
        Automatically detects V1 or V2 based on data length.

        Args:
            data: 20-byte (V1) or 32-byte (V2) binary packet

        Returns:
            dict with keys:
                device_id   (str)
                timestamp   (int)
                type        (int)
                type_name   (str)
                version     (int)   — 1 or 2
                value       (float) — V1 only: single value
                value1..4   (float) — V2 only: four values
                occupancy   (int)   — OCCUPANCY packets only
                heater_pct  (float) — HVAC_STATE packets only
                cooler_pct  (float) — HVAC_STATE packets only
                current_temp(float) — HVAC_STATE packets only
                setpoint    (float) — HVAC_STATE packets only
            Returns None on parse error.
        """
        version = PacketParser.detect_version(data)

        if version == PROTOCOL_V2:
            return PacketParser._parse_v2(data)
        else:
            return PacketParser._parse_v1(data)

    @staticmethod
    def _parse_v1(data):
        """Parse a 20-byte V1 packet."""
        try:
            device_id, timestamp, value, pkt_type, checksum = struct.unpack(
                PACKET_FORMAT, data
            )
            device_id = device_id.decode('utf-8').strip('\x00')

            packet = {
                'device_id': device_id,
                'timestamp': timestamp,
                'value':     value,
                'type':      pkt_type,
                'checksum':  checksum,
                'version':   PROTOCOL_V1,
                'type_name': TYPE_NAMES.get(pkt_type, f'UNKNOWN({pkt_type})'),
            }

            # For occupancy packets, cast value to int
            if pkt_type == PACKET_TYPE_OCCUPANCY:
                packet['occupancy'] = int(value)

            return packet

        except Exception as e:
            print(f"[PROTOCOL ERROR] V1 parse failed: {e}")
            return None

    @staticmethod
    def _parse_v2(data):
        """Parse a 32-byte V2 packet."""
        try:
            device_id, timestamp, pkt_type, version, v1, v2, v3, v4 = struct.unpack(
                PACKET_V2_FORMAT, data
            )
            device_id = device_id.decode('utf-8').strip('\x00')

            packet = {
                'device_id': device_id,
                'timestamp': timestamp,
                'type':      pkt_type,
                'version':   version,
                'type_name': TYPE_NAMES.get(pkt_type, f'UNKNOWN({pkt_type})'),
                'value1':    v1,
                'value2':    v2,
                'value3':    v3,
                'value4':    v4,
                'value':     v1,   # convenience alias for logging
            }

            # For HVAC_STATE packets, add named fields for clarity
            if pkt_type == PACKET_TYPE_HVAC_STATE:
                packet['heater_pct']   = v1
                packet['cooler_pct']   = v2
                packet['current_temp'] = v3
                packet['setpoint']     = v4

            return packet

        except Exception as e:
            print(f"[PROTOCOL ERROR] V2 parse failed: {e}")
            return None

    @staticmethod
    def get_packet_size():
        """Return V1 packet size (default recv size)."""
        return PACKET_SIZE

    @staticmethod
    def get_v2_packet_size():
        """Return V2 packet size."""
        return PACKET_V2_SIZE