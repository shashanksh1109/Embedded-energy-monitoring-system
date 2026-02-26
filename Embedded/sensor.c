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
    printf("         Press Ctrl+C to stop\n");
    printf("─────────────────────────────────────────────\n");
    
    while (1) {
        // Generate reading
        float temperature = generate_temperature_reading(config->base_temp, time_elapsed);
        
        // Transmit
        if (transmit_reading(conn, config, temperature) < 0) {
            printf("[SENSOR] ✗ Transmission failed, stopping\n");
            break;
        }
        
        // Log
        packet_count++;
        printf("[SENSOR] #%-4d | %.2f°C | %s | +%ds\n", 
               packet_count, temperature, config->zone, time_elapsed);
        
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