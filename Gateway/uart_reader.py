"""
uart_reader.py - UART Simulation Reader

Reads binary packets from Linux named pipes (FIFOs) that simulate
UART serial communication from embedded sensors.

Mirrors the C uart_sim.c writer:
  - Opens FIFO for reading
  - Scans for start marker (0xAA 0x55)
  - Reads packet bytes (20 bytes V1 or 32 bytes V2)
  - Parses and persists to DB via DBWriter

One UARTReader instance per zone. Runs in its own background thread.

On real ESP32:
  Replace FIFO reads with: pyserial.Serial('/dev/ttyUSB0', 115200)
  Everything else (framing, parsing, DB write) stays identical.
"""

import os
import struct
import threading
import time
from datetime import datetime, timezone
from protocol import PacketParser, PACKET_SIZE, PACKET_V2_SIZE

# UART frame constants — must match uart_sim.h
UART_FIFO_DIR   = '/tmp'
UART_START_BYTE1 = 0xAA
UART_START_BYTE2 = 0x55


class UARTReader:
    """
    Reads framed binary packets from a FIFO (named pipe).
    Runs in a background thread, one instance per zone.
    """

    def __init__(self, zone, db=None):
        self.zone    = zone                          # e.g. "Zone_A"
        self.db      = db                            # DBWriter instance
        self.parser  = PacketParser()
        self.running = False
        self.thread  = None
        self.fd      = None
        self._pkt_count = 0

        # Build FIFO path — Zone_A → /tmp/uart_zone_a
        zone_lower   = zone.lower().replace(' ', '_')
        self.fifo_path = f"{UART_FIFO_DIR}/uart_{zone_lower}"

    # ============================================================
    # LIFECYCLE
    # ============================================================

    def start(self):
        """Start background reader thread."""
        self.running = True
        self.thread  = threading.Thread(target=self._run, daemon=True)
        self.thread.start()
        print(f"[UART_READER] Started for {self.zone} → {self.fifo_path}")

    def stop(self):
        """Stop reader thread."""
        self.running = False
        print(f"[UART_READER] Stopped ({self._pkt_count} packets received)")

    # ============================================================
    # MAIN LOOP
    # ============================================================

    def _run(self):
        """
        Background thread — waits for FIFO, reads packets forever.
        Reconnects automatically if FIFO is recreated.
        """
        while self.running:
            # Wait for FIFO to exist (sensor may not have started yet)
            if not os.path.exists(self.fifo_path):
                print(f"[UART_READER] Waiting for FIFO: {self.fifo_path}")
                time.sleep(2)
                continue

            try:
                # Open FIFO for reading (blocks until writer opens it)
                print(f"[UART_READER] Opening FIFO: {self.fifo_path}")
                with open(self.fifo_path, 'rb') as f:
                    print(f"[UART_READER] Connected to {self.fifo_path}")
                    while self.running:
                        packet = self._read_packet(f)
                        if packet is None:
                            print(f"[UART_READER] FIFO closed, reconnecting...")
                            break
                        self._handle_packet(packet)

            except Exception as e:
                print(f"[UART_READER] Error: {e}, retrying...")
                time.sleep(1)

    def _read_packet(self, f):
        """
        Read one framed packet from FIFO.
        Scans for start marker (0xAA 0x55) then reads packet bytes.

        Returns parsed packet dict or None on EOF/error.
        """
        # Scan for start marker byte by byte
        b1 = self._read_byte(f)
        if b1 is None:
            return None

        while True:
            if b1 == UART_START_BYTE1:
                b2 = self._read_byte(f)
                if b2 is None:
                    return None
                if b2 == UART_START_BYTE2:
                    break   # found complete start marker
                b1 = b2     # keep scanning
            else:
                b1 = self._read_byte(f)
                if b1 is None:
                    return None

        # Read first 20 bytes (V1 packet size)
        data = self._read_exact(f, PACKET_SIZE)
        if data is None:
            return None

        # Check version byte at position 13 — if 2, read 12 more bytes
        version = data[13] if len(data) > 13 else 1
        if version == 2:
            rest = self._read_exact(f, PACKET_V2_SIZE - PACKET_SIZE)
            if rest is None:
                return None
            data = data + rest

        # Validate checksum (V2 always passes)
        if not self.parser.validate_checksum(data):
            print(f"[UART_READER] Invalid checksum — packet discarded")
            return None

        return self.parser.parse(data)

    def _read_byte(self, f):
        """Read exactly one byte, return None on EOF."""
        b = f.read(1)
        return b[0] if b else None

    def _read_exact(self, f, n):
        """Read exactly n bytes, return None on EOF."""
        data = b''
        while len(data) < n:
            chunk = f.read(n - len(data))
            if not chunk:
                return None
            data += chunk
        return data

    # ============================================================
    # PACKET HANDLER
    # ============================================================

    def _handle_packet(self, packet):
        """Route received UART packet to DB and log."""
        if not packet:
            return

        self._pkt_count += 1
        recorded_at = datetime.now(tz=timezone.utc)

        print(f"[UART_READER] {packet['type_name']}: "
              f"{packet['device_id']} = {packet['value']:.2f} "
              f"(#{self._pkt_count})")

        # Persist to DB using same DBWriter as TCP channel
        if self.db:
            pkt_type  = packet.get('type')
            device_id = packet.get('device_id')
            zone_id   = self.db._get_zone_id(device_id)

            if zone_id is None:
                return

            from protocol import (PACKET_TYPE_TEMP, PACKET_TYPE_OCCUPANCY,
                                   PACKET_TYPE_POWER, PACKET_TYPE_HVAC_STATE)

            if pkt_type == PACKET_TYPE_TEMP:
                self.db._write_temperature(device_id, zone_id,
                                           packet['value'], recorded_at)
            elif pkt_type == PACKET_TYPE_OCCUPANCY:
                self.db._write_occupancy(device_id, zone_id,
                                         int(packet['value']), recorded_at)
            elif pkt_type == PACKET_TYPE_POWER:
                self.db._write_power(device_id, zone_id, packet, recorded_at)
            elif pkt_type == PACKET_TYPE_HVAC_STATE:
                self.db._write_hvac_state(device_id, zone_id, packet, recorded_at)