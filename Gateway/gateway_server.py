"""
gateway_server.py - Gateway Orchestration Logic

Coordinates all gateway modules:
1. Configuration
2. Database connection
3. Network server
4. Analytics engine
5. Process orchestration
6. Cleanup
"""

from config import load_configuration
from network import TCPServer
from analytics import CircularBuffer, AnalyticsEngine
from orchestration_config import OrchestrationConfig
from process_manager import ProcessManager
from db_writer import DBWriter


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

    # STEP 2: Database Connection
    print("--- Step 2: Database Connection ---")
    db = DBWriter()
    if not db.connect():
        print("[ORCHESTRATOR] WARNING: Database unavailable, continuing without persistence")
        db = None
    print()

    # STEP 3: Orchestration Rules
    print("--- Step 3: Orchestration Configuration ---")
    orch_config = OrchestrationConfig(use_hardware=use_hardware)
    orch_config.display()

    # STEP 4: Process Manager
    print("--- Step 4: Process Manager ---")
    process_mgr = ProcessManager(orch_config)
    print("[PROCESS_MGR] Process manager initialized")
    print()

    # STEP 5: Data Storage
    print("--- Step 5: Data Storage ---")
    buffer = CircularBuffer(size=config.buffer_size)
    print(f"[STORAGE] Circular buffer initialized (size: {config.buffer_size})\n")

    # STEP 6: Analytics
    print("--- Step 6: Analytics Engine ---")
    analytics = AnalyticsEngine(buffer, interval=config.analytics_interval, db=db)
    analytics.start()
    print()

    # STEP 7: Network Server
    print("--- Step 7: Network Server ---")
    server = TCPServer(config, buffer, process_mgr, orch_config, db)

    try:
        server.start()
    except Exception as e:
        print(f"[ORCHESTRATOR] Server error: {e}")
        return 1
    finally:
        # STEP 8: Cleanup
        print("\n--- Step 8: Cleanup ---")
        analytics.stop()
        process_mgr.cleanup_all()
        if db:
            db.disconnect()
        print("[ORCHESTRATOR] Gateway shutdown complete")

    return 0