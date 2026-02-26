#ifndef CONFIG_H
#define CONFIG_H

/*
 * config.h - Configuration management
 * 
 * Handles:
 * - Command-line argument parsing
 * - Configuration validation
 * - Configuration storage
 */

typedef struct {
    char device_id[16];
    char zone[16];
    float base_temp;
    int sampling_rate;
} SensorConfig;

// Configuration functions
SensorConfig parse_configuration(int argc, char *argv[]);
void print_configuration(SensorConfig *config);

#endif