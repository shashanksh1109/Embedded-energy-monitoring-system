/*
 * sensor.c - Sensor operations implementation
 *
 * All sensor-specific functions grouped here:
 * - Temperature generation (simulation mode)
 * - Sensor measurement loop
 * - Data packaging and transmission
 *
 * Reading source (chosen by the --hardware flag):
 *   SIMULATION -> generate_temperature_reading()
 *   HARDWARE   -> read_hardware_temperature()  (Raspberry Pi SoC sensor)
 *
 * Transports (up to three in parallel):
 *   TCP  -> gateway (binary packets, always on)
 *   MQTT -> broker  (JSON, only if a broker is reachable)
 *   UART -> simulated serial pipe (only if a reader is attached)
 */

#include <stdio.h>
#include <unistd.h>
#include <math.h>
#include "sensor.h"
#include "sensor_hardware.h"
#include "protocol.h"
#include "mqtt_client.h"
#include "uart_sim.h"

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
        printf("         Mode: REAL HARDWARE (Raspberry Pi SoC sensor)\n");
    } else {
        printf("         Mode: SOFTWARE SIMULATION\n");
    }

    // Initialize hardware first: fail fast if the sensor is not usable
    if (config->use_hardware) {
        if (initialize_hardware_sensor() < 0) {
            printf("[SENSOR] ✗ Hardware initialization failed, stopping\n");
            return;
        }
    }

    // Initialize MQTT client (optional transport)
    MQTTClient mqtt;
    int mqtt_ok = 0;
    if (mqtt_init(&mqtt, config->device_id, config->zone) == 0) {
        if (mqtt_connect(&mqtt) == 0) {
            mqtt_ok = 1;
            printf("[SENSOR] MQTT connected — dual transport active\n");
        } else {
            printf("[SENSOR] MQTT unavailable — TCP only\n");
        }
    }

    // Initialize UART simulation — retry up to 3 times if no reader yet
    UARTHandle uart;
    int uart_ok = 0;
    for (int i = 0; i < 3 && !uart_ok; i++) {
        if (uart_open_write(&uart, config->zone) == 0) {
            uart_ok = uart.is_open;
            if (!uart_ok && i < 2) {
                printf("[SENSOR] UART: waiting for reader... retry %d/3\n", i+1);
                sleep(2);
            }
        }
    }
    if (uart_ok) {
        printf("[SENSOR] UART simulation active → %s\n", uart.path);
    } else {
        printf("[SENSOR] UART simulation inactive (no reader) → %s\n", uart.path);
    }

    printf("         Press Ctrl+C to stop\n");
    printf("─────────────────────────────────────────────\n");

    while (1) {
        float temperature;

        // Choose sensor source based on configuration
        if (config->use_hardware) {
            temperature = read_hardware_temperature();
        } else {
            temperature = generate_temperature_reading(config->base_temp, time_elapsed);
        }

        // Check for sensor error (-999 means the read failed)
        if (temperature < -100) {
            printf("[SENSOR] ✗ Sensor read error, skipping this reading\n");
            sleep(config->sampling_rate);
            time_elapsed += config->sampling_rate;
            continue;
        }

        // Transmit via TCP (primary transport)
        if (transmit_reading(conn, config, temperature) < 0) {
            printf("[SENSOR] ✗ TCP transmission failed, stopping\n");
            break;
        }

        // Publish via MQTT (optional parallel transport)
        if (mqtt_ok) {
            mqtt_publish_temperature(&mqtt, temperature);
        }

        // Write via UART simulation (optional third transport)
        if (uart_ok) {
            Packet uart_pkt;
            pack_packet(&uart_pkt, config->device_id, temperature, 0);
            uart_write(&uart, (uint8_t*)&uart_pkt, sizeof(Packet));
        }

        // Log
        packet_count++;
        if (config->use_hardware) {
            printf("[SENSOR] #%-4d | %.2f°C | %s | +%ds [HARDWARE]\n",
                   packet_count, temperature, config->zone, time_elapsed);
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

    // Cleanup MQTT and UART
    if (mqtt_ok) {
        mqtt_disconnect(&mqtt);
    }
    uart_close(&uart);
    uart_destroy(&uart);
}

float generate_temperature_reading(float base_temp, int time_elapsed) {
    // Daily temperature cycle (24-hour period)
    float daily_variation = 3.0 * sin(2 * PI * time_elapsed / 86400.0);

    // Random sensor noise (fixed seed: same sequence every run, good for repeatable tests)
    static unsigned int seed = 12345;
    seed = (1103515245 * seed + 12345) % (1U << 31);
    float noise = ((float)seed / (1U << 31)) * 1.0 - 0.5;

    return base_temp + daily_variation + noise;
}