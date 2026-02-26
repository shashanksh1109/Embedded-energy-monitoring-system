/*
 * main.c - Program entry point
 * 
 * This file contains ONLY the main() function.
 * All actual logic is delegated to sensor_logic.c
 */

#include <stdio.h>
#include "sensor_logic.h"

int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   Temperature Sensor Application      ║\n");
    printf("╚════════════════════════════════════════╝\n\n");
    
    // Delegate everything to sensor_logic.c
    int result = run_sensor(argc, argv);
    
    printf("\n[MAIN] Application exiting with code: %d\n\n", result);
    return result;
}