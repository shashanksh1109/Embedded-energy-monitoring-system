#ifndef SENSOR_LOGIC_H
#define SENSOR_LOGIC_H

/*
 * sensor_logic.h - Main sensor orchestration
 * 
 * This module coordinates all other modules:
 * - Configuration
 * - Network
 * - Sensor operations
 */

// Main orchestration function called by main.c
int run_sensor(int argc, char *argv[]);

#endif