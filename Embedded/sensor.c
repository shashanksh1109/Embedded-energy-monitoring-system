/*
 * sensor.c - Sensor operations implementation
 * 
 * All sensor-specific functions grouped here:
 * - Temperature generation algorithms
 * - Sensor measurement loop
 * - Data packaging and transmission
 */

#include <stdio.h>
#include <unistd.h>
#include <math.h>
#include "sensor.h"
#include "sensor_hardware.h"  // NEW: Include hardware interface
#include "protocol.h"

#define PI 3.14159265

// Internal helper (private)
static int transmit_reading(NetworkConnection *conn, SensorConfig *config, float temperature) {
    // Create packet using protocol.c
    Packet pkt;
    pack_packet(&pkt, config->device_id, temperature, 0);
    
    // Send using network.c
    return send_packet_to_gateway(conn, &pkt);
}

// Public functions (declared in sensor.h)

void execute_sensor_loop(SensorConfig *config, NetworkConnection *conn) {
    int time_elapsed = 0;
    int packet_count = 0;
    
    printf("[SENSOR] Starting measurement loop...\n");
    
    // Display mode
    if (config->use_hardware) {
        printf("         Mode: REAL HARDWARE (ESP32/DHT22)\n");
    } else {
        printf("         Mode: SOFTWARE SIMULATION\n");
    }
    
    printf("         Press Ctrl+C to stop\n");
    printf("─────────────────────────────────────────────\n");
    
    // Initialize hardware if needed (COMMENTED - uncomment when ESP32 ready)
    // if (config->use_hardware) {
    //     if (initialize_hardware_sensor() < 0) {
    //         printf("[SENSOR] ✗ Hardware initialization failed\n");
    //         return;
    //     }
    // }
    
    while (1) {
        float temperature;
        
        // Choose sensor source based on configuration
        if (config->use_hardware) {
            // HARDWARE MODE (function call commented until ESP32 ready)
            // temperature = read_hardware_temperature();
            
            // PLACEHOLDER: Simulate hardware for now
            temperature = read_hardware_temperature();  // This compiles and runs!
            
        } else {
            // SIMULATION MODE (active)
            temperature = generate_temperature_reading(config->base_temp, time_elapsed);
        }
        
        // Check for sensor error
        if (temperature < -100) {
            printf("[SENSOR] ✗ Sensor read error, skipping this reading\n");
            sleep(config->sampling_rate);
            continue;
        }
        
        // Transmit
        if (transmit_reading(conn, config, temperature) < 0) {
            printf("[SENSOR] ✗ Transmission failed, stopping\n");
            break;
        }
        
        // Log
        packet_count++;
        if (config->use_hardware) {
            printf("[SENSOR] #%-4d | %.2f°C | %s | [HARDWARE]\n", 
                   packet_count, temperature, config->zone);
        } else {
            printf("[SENSOR] #%-4d | %.2f°C | %s | +%ds [SIM]\n", 
                   packet_count, temperature, config->zone, time_elapsed);
        }
        
        // Wait
        sleep(config->sampling_rate);
        time_elapsed += config->sampling_rate;
    }
    
    printf("─────────────────────────────────────────────\n");
    printf("[SENSOR] Total packets sent: %d\n", packet_count);
}

float generate_temperature_reading(float base_temp, int time_elapsed) {
    // Daily temperature cycle (24-hour period)
    float daily_variation = 3.0 * sin(2 * PI * time_elapsed / 86400.0);
    
    // Random sensor noise
    static unsigned int seed = 12345;
    seed = (1103515245 * seed + 12345) % (1U << 31);
    float noise = ((float)seed / (1U << 31)) * 1.0 - 0.5;
    
    return base_temp + daily_variation + noise;
}