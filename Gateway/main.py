#!/usr/bin/env python3
"""
main.py - Gateway Application Entry Point

Usage:
  python3 main.py              (simulation mode)
  python3 main.py --hardware   (hardware mode - ESP32)
"""

import sys
from gateway_server import run_gateway

def main():
    print("\n" + "="*50)
    print("  ENERGY MONITORING GATEWAY")
    print("="*50 + "\n")
    
    # Check for --hardware flag
    use_hardware = '--hardware' in sys.argv
    
    if use_hardware:
        print("[MAIN] Hardware mode enabled")
        print("[MAIN] Spawned processes will use real sensors\n")
    else:
        print("[MAIN] Simulation mode (default)")
        print("[MAIN] Use --hardware flag for real sensors\n")
    
    try:
        exit_code = run_gateway(use_hardware=use_hardware)
        print(f"\n[MAIN] Gateway exiting with code: {exit_code}\n")
        return exit_code
    except KeyboardInterrupt:
        print("\n\n[MAIN] Shutdown requested by user")
        return 0
    except Exception as e:
        print(f"\n[MAIN] Fatal error: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())