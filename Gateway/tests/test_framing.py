"""
test_framing.py - Tests for V1/V2 packet detection on the TCP stream

Run from the Gateway folder:
    python -m pytest tests/ -v
"""

import os
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from network import is_v2_header          # noqa: E402


def v1_packet(device_id, value, pkt_type, timestamp=1760000000):
    """Build a V1 packet exactly like protocol.c pack_packet() does."""
    body = struct.pack('<8sIfB', device_id.encode().ljust(8, b'\x00'),
                       timestamp, value, pkt_type)
    checksum = sum(body[:17]) % 256
    return body + bytes([checksum]) + b'\x00\x00'          # 20 bytes


def v2_packet(device_id, pkt_type, values, timestamp=1760000000):
    """Build a V2 packet exactly like protocol.c pack_packet_v2() does."""
    return (struct.pack('<8sIBB2x', device_id.encode().ljust(8, b'\x00'),
                        timestamp, pkt_type, 2)
            + struct.pack('<4f', *values))                  # 32 bytes


def test_hvac_state_v2_packet_is_detected():
    pkt = v2_packet('HVAC_A', 4, (0.0, 80.0, 22.5, 20.0))
    assert len(pkt) == 32
    assert is_v2_header(pkt[:20])


def test_v1_temperature_is_not_v2():
    assert not is_v2_header(v1_packet('TEMP_A', 22.05, 0))


def test_v1_power_whose_float_has_a_2_at_byte_13_is_not_v2():
    # Find a power value whose float bytes put 0x02 at packet byte 13 —
    # the case that originally caused "power checksum failures".
    for i in range(1, 200000):
        value = i / 1000.0
        raw = struct.pack('<f', value)            # becomes packet bytes 12..15
        if raw[1] == 2:
            pkt = v1_packet('POWER_A', value, 1)
            assert pkt[13] == 2                   # looks like a V2 version byte...
            assert not is_v2_header(pkt)          # ...but is correctly treated as V1
            return
    raise AssertionError('no test value found')


def test_short_data_is_not_v2():
    assert not is_v2_header(b'\x00' * 10)