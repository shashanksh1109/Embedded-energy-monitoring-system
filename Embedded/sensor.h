#ifndef SENSOR_H
#define SENSOR_H

#include "config.h"
#include "network.h"

// ============================================================================
// CONFIGURATION - Choose sensor mode
// ============================================================================

#define USE_SIMULATION 1   // Set to 0 to use real hardware

// ============================================================================
// SENSOR DATA ACQUISITION - Public Interface
// ============================================================================

// Main sensor loop
void execute_sensor_loop(SensorConfig *config, NetworkConnection *conn);

// SOFTWARE SIMULATION - Mathematical model
float generate_temperature_reading(float base_temp, int time_elapsed);

// HARDWARE INTERFACE - Real sensor reading (ESP32/Arduino)
// float read_hardware_temperature(int gpio_pin);  // Uncomment when hardware ready

#endif