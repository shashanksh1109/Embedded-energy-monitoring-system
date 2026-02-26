/*
 * sensor_logic.c - Main sensor orchestration logic
 * 
 * This file coordinates the entire sensor workflow:
 * 1. Parse configuration
 * 2. Initialize network
 * 3. Run sensor loop
 * 4. Cleanup
 */

#include <stdio.h>
#include "sensor_logic.h"
#include "config.h"
#include "network.h"
#include "sensor.h"

int run_sensor(int argc, char *argv[]) {
    printf("[ORCHESTRATOR] Starting sensor initialization...\n\n");
    
    // ========================================
    // STEP 1: Configuration
    // ========================================
    printf("─── Step 1: Configuration ───\n");
    SensorConfig config = parse_configuration(argc, argv);
    printf("\n");
    
    // ========================================
    // STEP 2: Network Setup
    // ========================================
    printf("─── Step 2: Network Setup ───\n");
    NetworkConnection conn = initialize_network();
    if (!conn.is_connected) {
        printf("[ORCHESTRATOR] ✗ Network initialization failed\n");
        return 1;
    }
    printf("\n");
    
    // ========================================
    // STEP 3: Sensor Operation
    // ========================================
    printf("─── Step 3: Sensor Operation ───\n");
    execute_sensor_loop(&config, &conn);
    printf("\n");
    
    // ========================================
    // STEP 4: Cleanup
    // ========================================
    printf("─── Step 4: Cleanup ───\n");
    cleanup_network(&conn);
    
    printf("[ORCHESTRATOR] ✓ Sensor shutdown complete\n");
    return 0;
}