/*
 * power_meter.c - Power Meter Main Program
 * 
 * Monitors power consumption and calculates energy costs
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include "power_hardware.h"

#define ELECTRICITY_COST_PER_KWH 0.12  // $0.12 per kWh

typedef struct {
    char device_id[16];
    char zone[16];
    float base_load_kw;      // Constant base load (lights, equipment)
    float hvac_max_power_kw; // Maximum HVAC power
    int use_hardware;
} PowerMeterConfig;

// Function declarations
PowerMeterConfig parse_power_config(int argc, char *argv[]);
void run_power_meter_loop(PowerMeterConfig *config);
float calculate_hvac_power(float base_load, float hvac_percentage);

int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   Power Meter Application             ║\n");
    printf("╚════════════════════════════════════════╝\n\n");
    
    // Parse configuration
    PowerMeterConfig config = parse_power_config(argc, argv);
    
    // Run monitoring loop
    run_power_meter_loop(&config);
    
    return 0;
}

PowerMeterConfig parse_power_config(int argc, char *argv[]) {
    PowerMeterConfig config;
    memset(&config, 0, sizeof(PowerMeterConfig));
    
    if (argc < 3) {
        printf("Usage: %s <device_id> <zone> [--hardware]\n", argv[0]);
        printf("\nExample:\n");
        printf("  %s POWER_1 Zone_A\n", argv[0]);
        printf("  %s POWER_1 Zone_A --hardware\n\n", argv[0]);
        exit(1);
    }
    
    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';
    
    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';
    
    config.base_load_kw = 2.0;       // 2 kW base load
    config.hvac_max_power_kw = 10.0; // 10 kW max HVAC
    
    config.use_hardware = 0;
    if (argc == 4 && strcmp(argv[3], "--hardware") == 0) {
        config.use_hardware = 1;
    }
    
    printf("[CONFIG] Device ID:    %s\n", config.device_id);
    printf("[CONFIG] Zone:         %s\n", config.zone);
    printf("[CONFIG] Base Load:    %.1f kW\n", config.base_load_kw);
    printf("[CONFIG] HVAC Max:     %.1f kW\n", config.hvac_max_power_kw);
    printf("[CONFIG] Mode:         %s\n\n", config.use_hardware ? "HARDWARE" : "SIMULATION");
    
    return config;
}

void run_power_meter_loop(PowerMeterConfig *config) {
    // Initialize hardware if needed
    if (config->use_hardware) {
        initialize_power_hardware();
    }
    
    printf("[POWER] Starting power monitoring...\n");
    printf("[POWER] Electricity rate: $%.2f per kWh\n", ELECTRICITY_COST_PER_KWH);
    printf("[POWER] Press Ctrl+C to stop\n");
    printf("═══════════════════════════════════════════════════════════════════════\n");
    
    float cumulative_energy_kwh = 0.0;
    int iteration = 0;
    
    // Simulated HVAC power percentage (varies over time)
    float hvac_percentage = 50.0;
    
    while (1) {
        iteration++;
        
        float current_power_kw;
        
        if (config->use_hardware) {
            // Hardware mode: Read from INA219
            // current_power_kw = read_power_watts() / 1000.0;  // Uncomment for ESP32
            
            // Placeholder for now
            current_power_kw = calculate_hvac_power(config->base_load_kw, hvac_percentage);
        } else {
            // Simulation mode
            current_power_kw = calculate_hvac_power(config->base_load_kw, hvac_percentage);
        }
        
        // Calculate energy consumed (kWh)
        // Power (kW) × Time (hours) = Energy (kWh)
        // 1 second = 1/3600 hours
        float energy_this_interval = current_power_kw / 3600.0;
        cumulative_energy_kwh += energy_this_interval;
        
        // Calculate cost
        float cumulative_cost = cumulative_energy_kwh * ELECTRICITY_COST_PER_KWH;
        
        // Display status
        printf("[POWER] #%-4d | Power:%6.2f kW | Energy:%8.4f kWh | Cost: $%7.4f | HVAC:%5.1f%%\n",
               iteration, current_power_kw, cumulative_energy_kwh, cumulative_cost, hvac_percentage);
        
        // Simulate HVAC load variation (in real system, would read from HVAC controller)
        static unsigned int seed = 54321;
        seed = (1103515245 * seed + 12345) % (1U << 31);
        float variation = ((float)seed / (1U << 31)) * 20.0 - 10.0;  // ±10%
        hvac_percentage += variation;
        
        // Clamp HVAC percentage
        if (hvac_percentage < 0) hvac_percentage = 0;
        if (hvac_percentage > 100) hvac_percentage = 100;
        
        sleep(1);
    }
}

float calculate_hvac_power(float base_load, float hvac_percentage) {
    // HVAC power based on percentage (0-100%)
    // Max HVAC power: 10 kW
    // At 50%: 5 kW
    // At 100%: 10 kW
    float hvac_power = (hvac_percentage / 100.0) * 10.0;
    
    // Total power = base load + HVAC
    return base_load + hvac_power;
}