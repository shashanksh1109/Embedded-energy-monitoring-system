#!/usr/bin/env python3
"""
serial_bridge.py - Serial to TCP Bridge (Windows)
Reads 20-byte packets from COM7 (PICsimLAB via com0com)
Forwards to AWS gateway via TCP
"""

import serial
import socket
import time
import sys

# Configuration
SERIAL_PORT  = 'COM7'
BAUD_RATE    = 9600
PACKET_SIZE  = 20
GATEWAY_HOST = 'energy-management-nlb-37d1544f90cf9633.elb.us-east-1.amazonaws.com'
GATEWAY_PORT = 8080
RECONNECT_DELAY = 5

def open_serial():
    while True:
        try:
            ser = serial.Serial(
                port     = SERIAL_PORT,
                baudrate = BAUD_RATE,
                bytesize = serial.EIGHTBITS,
                parity   = serial.PARITY_NONE,
                stopbits = serial.STOPBITS_ONE,
                timeout  = 1
            )
            print(f"[SERIAL] Opened {SERIAL_PORT} at {BAUD_RATE} baud")
            return ser
        except Exception as e:
            print(f"[SERIAL] Failed: {e}, retrying in {RECONNECT_DELAY}s...")
            time.sleep(RECONNECT_DELAY)

def connect_gateway():
    while True:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            sock.connect((GATEWAY_HOST, GATEWAY_PORT))
            print(f"[TCP] Connected to {GATEWAY_HOST}:{GATEWAY_PORT}")
            return sock
        except Exception as e:
            print(f"[TCP] Failed: {e}, retrying in {RECONNECT_DELAY}s...")
            time.sleep(RECONNECT_DELAY)

def validate_checksum(packet):
    calculated = sum(packet[:17]) % 256
    received   = packet[17]
    return calculated == received

def run_bridge():
    print("=" * 50)
    print("  PIC16F877A → AWS Bridge")
    print("=" * 50)
    print(f"  Serial : {SERIAL_PORT} @ {BAUD_RATE} baud")
    print(f"  Gateway: {GATEWAY_HOST}:{GATEWAY_PORT}")
    print("=" * 50 + "\n")

    ser    = open_serial()
    sock   = connect_gateway()
    buffer = bytearray()
    count  = 0

    while True:
        try:
            data = ser.read(PACKET_SIZE)
            if not data:
                continue

            buffer.extend(data)

            while len(buffer) >= PACKET_SIZE:
                packet = bytes(buffer[:PACKET_SIZE])
                buffer = buffer[PACKET_SIZE:]

                if not validate_checksum(packet):
                    print(f"[BRIDGE] Bad checksum, skipping")
                    continue

                sock.sendall(packet)
                count += 1

                device_id = packet[:8].decode('utf-8', errors='ignore').strip('\x00')
                pkt_type  = packet[16]
                type_name = {0:'TEMP', 1:'POWER', 3:'OCC'}.get(pkt_type, f'TYPE{pkt_type}')
                print(f"[BRIDGE] #{count} {type_name}: {device_id}")

        except serial.SerialException as e:
            print(f"[SERIAL] Error: {e} — reopening...")
            try: ser.close()
            except: pass
            ser = open_serial()

        except socket.error as e:
            print(f"[TCP] Error: {e} — reconnecting...")
            try: sock.close()
            except: pass
            sock = connect_gateway()

        except KeyboardInterrupt:
            print("\n[BRIDGE] Shutting down...")
            try: ser.close()
            except: pass
            try: sock.close()
            except: pass
            sys.exit(0)

if __name__ == '__main__':
    run_bridge()