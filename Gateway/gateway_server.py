"""
gateway_server.py - Gateway Orchestration Logic

Coordinates all gateway modules:
1. Configuration
2. Network server
3. Analytics engine
"""

from config import load_configuration
from network import TCPServer
from analytics import CircularBuffer, AnalyticsEngine


def run_gateway():
    """
    Main gateway orchestration function
    
    Returns:
        int: Exit code (0=success, 1=error)
    """
    print("[ORCHESTRATOR] Starting gateway initialization...\n")
    
    # ========================================
    # STEP 1: Load Configuration
    # ========================================
    print("─── Step 1: Configuration ───")
    try:
        config = load_configuration()
    except Exception as e:
        print(f"[ORCHESTRATOR] ✗ Configuration failed: {e}")
        return 1
    
    # ========================================
    # STEP 2: Initialize Data Storage
    # ========================================
    print("─── Step 2: Data Storage ───")
    buffer = CircularBuffer(size=config.buffer_size)
    print(f"[STORAGE] ✓ Circular buffer initialized (size: {config.buffer_size})\n")
    
    # ========================================
    # STEP 3: Start Analytics Engine
    # ========================================
    print("─── Step 3: Analytics Engine ───")
    analytics = AnalyticsEngine(buffer, interval=config.analytics_interval)
    analytics.start()
    print()
    
    # ========================================
    # STEP 4: Start Network Server
    # ========================================
    print("─── Step 4: Network Server ───")
    server = TCPServer(config, buffer)
    
    try:
        server.start()  # This blocks until shutdown
    except Exception as e:
        print(f"[ORCHESTRATOR] ✗ Server error: {e}")
        return 1
    
    # ========================================
    # STEP 5: Cleanup
    # ========================================
    print("\n─── Step 5: Cleanup ───")
    analytics.stop()
    print("[ORCHESTRATOR] ✓ Gateway shutdown complete")
    
    return 0
