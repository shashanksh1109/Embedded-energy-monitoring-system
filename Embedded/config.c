/*
 * config.c - Configuration handling implementation
 * 
 * All configuration-related functions grouped here:
 * - Parsing command-line arguments
 * - Validating inputs
 * - Displaying configuration
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"

// Internal helper function (not in header - private to this file)
static int validate_arguments(int argc) {
    if (argc != 5) {
        printf("[CONFIG ERROR] Invalid argument count\n");
        printf("               Expected: 4 arguments\n");
        printf("               Received: %d arguments\n", argc - 1);
        return 0;
    }
    return 1;
}

SensorConfig parse_configuration(int argc, char *argv[]) {
    SensorConfig config;
    
    // Validate
    if (!validate_arguments(argc)) {
        printf("\nUsage: %s <device_id> <zone> <base_temp> <sample_rate>\n", argv[0]);
        printf("\nExample:\n");
        printf("  %s TEMP_A Zone_A 22.0 5\n\n", argv[0]);
        exit(1);
    }
    
    // Parse each argument
    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';
    
    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';
    
    config.base_temp = (float)atof(argv[3]);
    config.sampling_rate = atoi(argv[4]);
    
    // Display
    print_configuration(&config);
    
    return config;
}

void print_configuration(SensorConfig *config) {
    printf("[CONFIG] Device ID:     %s\n", config->device_id);
    printf("[CONFIG] Zone:          %s\n", config->zone);
    printf("[CONFIG] Base Temp:     %.1f°C\n", config->base_temp);
    printf("[CONFIG] Sampling Rate: %d seconds\n", config->sampling_rate);
    printf("[CONFIG] ✓ Configuration loaded\n");
}