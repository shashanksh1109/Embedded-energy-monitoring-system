/*
 * config.c - Configuration handling implementation
 * 
 * All configuration-related functions grouped here:
 * - Parsing command-line arguments
 * - Validating inputs
 * - Displaying configuration
 * - Parsing optional --hardware flag
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"

// Internal helper function (not in header - private to this file)
static int validate_arguments(int argc) {
    // Accept 5 required args, OR 5 required + optional --hardware flag
    if (argc != 5 && argc != 6) {
        printf("[CONFIG ERROR] Invalid argument count\n");
        printf("               Expected: 4 arguments (+ optional --hardware)\n");
        printf("               Received: %d arguments\n", argc - 1);
        return 0;
    }
    return 1;
}

static int check_hardware_flag(int argc, char *argv[]) {
    // Check if last argument is --hardware
    if (argc == 6) {
        if (strcmp(argv[5], "--hardware") == 0) {
            return 1;  // Hardware mode enabled
        } else {
            printf("[CONFIG WARNING] Unknown flag: %s (ignoring)\n", argv[5]);
        }
    }
    return 0;  // Simulation mode (default)
}

SensorConfig parse_configuration(int argc, char *argv[]) {
    SensorConfig config;
    
    // Validate
    if (!validate_arguments(argc)) {
        printf("\nUsage: %s <device_id> <zone> <base_temp> <sample_rate> [--hardware]\n", argv[0]);
        printf("\nExamples:\n");
        printf("  Simulation: %s TEMP_A Zone_A 22.0 5\n", argv[0]);
        printf("  Hardware:   %s TEMP_A Zone_A 22.0 5 --hardware\n\n", argv[0]);
        exit(1);
    }
    
    // Parse positional arguments
    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';
    
    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';
    
    config.base_temp = (float)atof(argv[3]);
    config.sampling_rate = atoi(argv[4]);
    
    // Parse optional hardware flag
    config.use_hardware = check_hardware_flag(argc, argv);
    
    // Display
    print_configuration(&config);
    
    return config;
}

void print_configuration(SensorConfig *config) {
    printf("[CONFIG] Device ID:     %s\n", config->device_id);
    printf("[CONFIG] Zone:          %s\n", config->zone);
    printf("[CONFIG] Base Temp:     %.1f°C\n", config->base_temp);
    printf("[CONFIG] Sampling Rate: %d seconds\n", config->sampling_rate);
    printf("[CONFIG] Sensor Mode:   %s\n", 
           config->use_hardware ? "REAL HARDWARE" : "SIMULATION");
    printf("[CONFIG] ✓ Configuration loaded\n");
}