#ifndef SENSOR_H
#define SENSOR_H

/*
 * sensor.h - Sensor-specific operations
 * 
 * Handles:
 * - Temperature generation
 * - Sensor loop execution
 * - Packet creation and transmission
 */

#include "config.h"
#include "network.h"

// Sensor functions
void execute_sensor_loop(SensorConfig *config, NetworkConnection *conn);
float generate_temperature_reading(float base_temp, int time_elapsed);

#endif