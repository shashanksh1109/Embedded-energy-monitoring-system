/*
 * hvac_controller.c - HVAC Controller Main Program
 * 
 * Controls heating/cooling to maintain target temperature using PID algorithm
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "pid.h"
#include "hvac_hardware.h"

typedef struct {
    char device_id[16];
    char zone[16];
    float setpoint;
    int use_hardware;
} HVACConfig;

// Function declarations
HVACConfig parse_hvac_config(int argc, char *argv[]);
void run_hvac_loop(HVACConfig *config);
float simulate_temperature_physics(float current_temp, float heater_power, float cooler_power, float dt);

int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   HVAC Controller Application         ║\n");
    printf("╚════════════════════════════════════════╝\n\n");
    
    // Parse configuration
    HVACConfig config = parse_hvac_config(argc, argv);
    
    // Run control loop
    run_hvac_loop(&config);
    
    return 0;
}

HVACConfig parse_hvac_config(int argc, char *argv[]) {
    HVACConfig config;
    memset(&config, 0, sizeof(HVACConfig));
    
    if (argc < 4) {
        printf("Usage: %s <device_id> <zone> <setpoint> [--hardware]\n", argv[0]);
        printf("\nExample:\n");
        printf("  Simulation: %s HVAC_1 Zone_A 20.0\n", argv[0]);
        printf("  Hardware:   %s HVAC_1 Zone_A 20.0 --hardware\n\n", argv[0]);
        exit(1);
    }
    
    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';
    
    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';
    
    config.setpoint = (float)atof(argv[3]);
    
    config.use_hardware = 0;
    if (argc == 5 && strcmp(argv[4], "--hardware") == 0) {
        config.use_hardware = 1;
    }
    
    printf("[CONFIG] Device ID:  %s\n", config.device_id);
    printf("[CONFIG] Zone:       %s\n", config.zone);
    printf("[CONFIG] Setpoint:   %.1f°C\n", config.setpoint);
    printf("[CONFIG] Mode:       %s\n\n", config.use_hardware ? "HARDWARE" : "SIMULATION");
    
    return config;
}

void run_hvac_loop(HVACConfig *config) {
    // Initialize PID controller (Ziegler-Nichols tuned gains)
    PIDController pid;
    pid_init(&pid, config->setpoint, 2.0, 0.5, 1.0);
    
    // Initialize hardware if needed
    if (config->use_hardware) {
        initialize_hvac_hardware();
    }
    
    printf("[HVAC] Starting control loop...\n");
    printf("[HVAC] Setpoint: %.1f°C\n", config->setpoint);
    printf("[HVAC] PID Gains: Kp=%.1f, Ki=%.1f, Kd=%.1f\n", pid.kp, pid.ki, pid.kd);
    printf("[HVAC] Press Ctrl+C to stop\n");
    printf("═══════════════════════════════════════════════════════════════\n");
    
    // Start with cold temperature
    float current_temp = config->setpoint - 5.0;  // Start 5°C below target
    float heater_power = 0.0;
    float cooler_power = 0.0;
    
    int iteration = 0;
    float dt = 1.0;  // 1 second time step
    
    while (1) {
        iteration++;
        
        // Read temperature
        if (config->use_hardware) {
            // Hardware mode (currently simulated)
            // current_temp = read_hardware_temperature();  // Uncomment for real ESP32
            current_temp = simulate_temperature_physics(current_temp, heater_power, cooler_power, dt);
        } else {
            // Simulation mode
            current_temp = simulate_temperature_physics(current_temp, heater_power, cooler_power, dt);
        }
        
        // Compute PID output
        float pid_output = pid_compute(&pid, current_temp, dt);
        
        // Determine heating or cooling
        if (current_temp < config->setpoint) {
            // Need heating
            heater_power = pid_output;
            cooler_power = 0.0;
        } else {
            // Need cooling
            heater_power = 0.0;
            cooler_power = pid_output;
        }
        
        // Set actuators
        if (config->use_hardware) {
            // set_heater_power(heater_power);  // Uncomment for real ESP32
            // set_cooler_power(cooler_power);
        }
        
        // Display status
        float error = config->setpoint - current_temp;
        printf("[HVAC] #%-4d | Temp:%6.2f°C | Error:%+6.2f°C | Heat:%5.1f%% | Cool:%5.1f%%\n",
               iteration, current_temp, error, heater_power, cooler_power);
        
        // Stop after reaching steady state (for demo)
        /*if (iteration >= 60) {
            printf("═══════════════════════════════════════════════════════════════\n");
            printf("[HVAC] Demo complete (60 iterations)\n");
            printf("[HVAC] Final temperature: %.2f°C (target: %.1f°C)\n", 
                   current_temp, config->setpoint);
            break;
        }
        */
        sleep(1);
    }
}

float simulate_temperature_physics(float current_temp, float heater_power, float cooler_power, float dt) {
    // Heating effect (heater adds heat)
    float heating_rate = 0.01;  // °C per second per % power
    float heat_added = heater_power * heating_rate * dt;
    
    // Cooling effect (cooler removes heat)
    float cooling_rate = 0.01;
    float heat_removed = cooler_power * cooling_rate * dt;
    
    // Natural heat loss (room cools naturally)
    float natural_cooling = 0.02 * dt;  // 0.02°C per second
    
    // Update temperature
    float new_temp = current_temp + heat_added - heat_removed - natural_cooling;
    
    return new_temp;
}