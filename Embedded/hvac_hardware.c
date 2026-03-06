/*
 * hvac_hardware.c - HVAC Hardware Implementation
 * 
 * TODO: Implement real relay control for ESP32
 */

#include <stdio.h>
#include "hvac_hardware.h"

static float current_heater_power = 0.0;
static float current_cooler_power = 0.0;

int initialize_hvac_hardware(void) {
    // TODO: Initialize GPIO pins for relays
    // ESP32: pinMode(HEATER_RELAY_PIN, OUTPUT);
    
    printf("[HVAC_HW] Hardware initialized (simulated)\n");
    return 0;
}

void set_heater_power(float power_percent) {
    // TODO: Control real relay
    // ESP32: digitalWrite(HEATER_RELAY_PIN, power_percent > 50 ? HIGH : LOW);
    
    current_heater_power = power_percent;
    printf("[HVAC_HW] Heater set to: %.1f%%\n", power_percent);
}

void set_cooler_power(float power_percent) {
    // TODO: Control real relay
    
    current_cooler_power = power_percent;
    printf("[HVAC_HW] Cooler set to: %.1f%%\n", power_percent);
}

float get_heater_power(void) {
    return current_heater_power;
}

float get_cooler_power(void) {
    return current_cooler_power;
}