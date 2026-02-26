#!/usr/bin/env python3
"""
main.py - Gateway Application Entry Point

This is the ONLY file you run: python3 main.py
All logic is delegated to gateway_server.py
"""

import sys
from gateway_server import run_gateway

def main():
    print("\n" + "="*50)
    print("  ENERGY MONITORING GATEWAY")
    print("="*50 + "\n")
    
    try:
        exit_code = run_gateway()
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
