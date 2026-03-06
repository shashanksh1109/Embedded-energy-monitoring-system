"""
gateway_server.py - Gateway Orchestration Logic

Coordinates all gateway modules:
1. Configuration
2. Network server
3. Analytics engine
4. Process orchestration
"""

from config import load_configuration
from network import TCPServer
from analytics import CircularBuffer, AnalyticsEngine
from orchestration_config import OrchestrationConfig
from process_manager import ProcessManager

def run_gateway(use_hardware=False):
    """
    Main gateway orchestration function
    
    Args:
        use_hardware: If True, spawned processes will use hardware mode
    
    Returns:
        int: Exit code (0=success, 1=error)
    """
    print("[ORCHESTRATOR] Starting gateway initialization...\n")
    
    # STEP 1: Gateway Configuration
    print("--- Step 1: Gateway Configuration ---")
    try:
        config = load_configuration()
    except Exception as e:
        print(f"[ORCHESTRATOR] Configuration failed: {e}")
        return 1
    
    # STEP 2: Orchestration Rules
    print("--- Step 2: Orchestration Configuration ---")
    orch_config = OrchestrationConfig(use_hardware=use_hardware)
    orch_config.display()
    
    # STEP 3: Process Manager
    print("--- Step 3: Process Manager ---")
    process_mgr = ProcessManager(orch_config)
    print("[PROCESS_MGR] Process manager initialized")
    print()
    
    # STEP 4: Data Storage
    print("--- Step 4: Data Storage ---")
    buffer = CircularBuffer(size=config.buffer_size)
    print(f"[STORAGE] Circular buffer initialized (size: {config.buffer_size})\n")
    
    # STEP 5: Analytics
    print("--- Step 5: Analytics Engine ---")
    analytics = AnalyticsEngine(buffer, interval=config.analytics_interval)
    analytics.start()
    print()
    
    # STEP 6: Network Server
    print("--- Step 6: Network Server ---")
    server = TCPServer(config, buffer, process_mgr, orch_config)
    
    try:
        server.start()
    except Exception as e:
        print(f"[ORCHESTRATOR] Server error: {e}")
        return 1
    finally:
        # STEP 7: Cleanup
        print("\n--- Step 7: Cleanup ---")
        analytics.stop()
        process_mgr.cleanup_all()
        print("[ORCHESTRATOR] Gateway shutdown complete")
    
    return 0