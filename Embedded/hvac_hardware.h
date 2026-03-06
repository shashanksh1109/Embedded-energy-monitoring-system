#ifndef HVAC_HARDWARE_H
#define HVAC_HARDWARE_H

/*
 * hvac_hardware.h - HVAC Hardware Interface
 * 
 * Functions for real relay/actuator control (ESP32/Arduino)
 */

#define HEATER_RELAY_PIN 5
#define COOLER_RELAY_PIN 6

// Initialize hardware pins
int initialize_hvac_hardware(void);

// Control heater (0-100% power)
void set_heater_power(float power_percent);

// Control cooler (0-100% power)
void set_cooler_power(float power_percent);

// Read current actuator state
float get_heater_power(void);
float get_cooler_power(void);

#endif