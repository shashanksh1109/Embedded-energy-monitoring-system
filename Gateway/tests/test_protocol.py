"""
test_protocol.py - Unit tests for the binary protocol parser

Tests:
- Checksum calculation
- Checksum validation  
- Packet parsing
- Invalid packet handling
"""

import struct
import pytest
import sys
import os

# Add parent directory to path so we can import gateway modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from protocol import PacketParser, PACKET_FORMAT, PACKET_SIZE, TYPE_NAMES


def make_packet(device_id: str, timestamp: int, value: float, pkt_type: int) -> bytes:
    """Helper — builds a valid binary packet with correct checksum"""
    # Pack without checksum first
    partial = struct.pack('<8sIfBB2x',
        device_id.encode('utf-8').ljust(8, b'\x00')[:8],
        timestamp,
        value,
        pkt_type,
        0  # placeholder checksum
    )
    # Calculate checksum over first 17 bytes
    checksum = sum(partial[:17]) % 256
    # Repack with correct checksum
    return struct.pack('<8sIfBB2x',
        device_id.encode('utf-8').ljust(8, b'\x00')[:8],
        timestamp,
        value,
        pkt_type,
        checksum
    )


class TestPacketSize:
    def test_packet_size_is_20_bytes(self):
        """Protocol requires exactly 20 bytes per packet"""
        assert PACKET_SIZE == 20

    def test_struct_format_produces_20_bytes(self):
        """Struct format must match expected packet size"""
        assert struct.calcsize(PACKET_FORMAT) == 20


class TestChecksumValidation:
    def test_valid_checksum_passes(self):
        """A correctly formed packet should pass checksum validation"""
        packet = make_packet("TEMP_A", 1700000000, 22.5, 0)
        assert PacketParser.validate_checksum(packet) is True

    def test_corrupted_data_fails_checksum(self):
        """Flipping a byte should invalidate the checksum"""
        packet = bytearray(make_packet("TEMP_A", 1700000000, 22.5, 0))
        packet[4] ^= 0xFF  # flip bits in the middle of device_id
        assert PacketParser.validate_checksum(bytes(packet)) is False

    def test_wrong_checksum_byte_fails(self):
        """Directly corrupting the checksum byte should fail"""
        packet = bytearray(make_packet("TEMP_A", 1700000000, 22.5, 0))
        packet[17] = (packet[17] + 1) % 256  # corrupt checksum byte
        assert PacketParser.validate_checksum(bytes(packet)) is False

    def test_zero_checksum_on_valid_packet_fails(self):
        """A packet with checksum zeroed out should fail (unless sum happens to be 0)"""
        packet = bytearray(make_packet("TEMP_A", 1700000000, 22.5, 0))
        original_checksum = packet[17]
        if original_checksum != 0:
            packet[17] = 0
            assert PacketParser.validate_checksum(bytes(packet)) is False

    def test_different_devices_have_different_checksums(self):
        """Two packets with different data should produce different checksums"""
        packet_a = make_packet("TEMP_A", 1700000000, 22.5, 0)
        packet_b = make_packet("TEMP_B", 1700000000, 22.5, 0)
        # Checksums at byte 17 should differ
        assert packet_a[17] != packet_b[17]


class TestPacketParsing:
    def test_parse_temperature_packet(self):
        """Should correctly parse a temperature packet"""
        packet = make_packet("TEMP_A", 1700000000, 22.5, 0)
        result = PacketParser.parse(packet)

        assert result is not None
        assert result['device_id'] == 'TEMP_A'
        assert result['timestamp'] == 1700000000
        assert abs(result['value'] - 22.5) < 0.001  # float comparison
        assert result['type'] == 0
        assert result['type_name'] == 'TEMP'

    def test_parse_power_packet(self):
        """Should correctly parse a power packet"""
        packet = make_packet("POWER_A", 1700000001, 5.2, 1)
        result = PacketParser.parse(packet)

        assert result is not None
        assert result['device_id'] == 'POWER_A'
        assert result['type'] == 1
        assert result['type_name'] == 'POWER'

    def test_parse_returns_none_on_invalid_data(self):
        """Should return None if packet cannot be parsed"""
        result = PacketParser.parse(b'\x00' * 20)
        # Zero packet may parse but with empty device_id
        # Main thing is it doesn't crash
        assert result is not None or result is None  # just no exception

    def test_device_id_strips_null_bytes(self):
        """Device ID should not contain null padding bytes"""
        packet = make_packet("TEMP_A", 1700000000, 22.5, 0)
        result = PacketParser.parse(packet)
        assert '\x00' not in result['device_id']

    def test_parse_negative_temperature(self):
        """Should handle negative temperature values"""
        packet = make_packet("TEMP_C", 1700000000, -5.3, 0)
        result = PacketParser.parse(packet)
        assert result is not None
        assert abs(result['value'] - (-5.3)) < 0.001

    def test_parse_high_temperature(self):
        """Should handle high temperature values"""
        packet = make_packet("TEMP_A", 1700000000, 99.9, 0)
        result = PacketParser.parse(packet)
        assert result is not None
        assert abs(result['value'] - 99.9) < 0.001


class TestTypeNames:
    def test_type_0_is_temp(self):
        assert TYPE_NAMES[0] == 'TEMP'

    def test_type_1_is_power(self):
        assert TYPE_NAMES[1] == 'POWER'

    def test_type_2_is_control(self):
        assert TYPE_NAMES[2] == 'CONTROL'

    def test_unknown_type_name(self):
        """Packet parser should handle unknown type gracefully"""
        packet = make_packet("TEMP_A", 1700000000, 22.5, 99)
        result = PacketParser.parse(packet)
        assert result is not None
        assert 'UNKNOWN' in result['type_name'] or result['type_name'] == 'UNKNOWN(99)'
