/*
 * power_hardware.c - Power Measurement Hardware Implementation
 * 
 * INA219 current sensor interface (ready for ESP32)
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "power_hardware.h"

// Simulated power values
static float simulated_current = 0.5;  // Amps

int initialize_power_hardware(void) {
    printf("[POWER_HW] Initializing INA219 current sensor...\n");
    
    // ESP32 implementation (uncomment when ready):
    // Wire.begin();
    // ina219.begin();
    // ina219.setCalibration_16V_400mA();
    
    printf("[POWER_HW] I2C Address: 0x%02X\n", INA219_I2C_ADDRESS);
    printf("[POWER_HW] ✓ Sensor initialized (simulated)\n");
    
    return 0;
}

float read_current_amps(void) {
    // ESP32 implementation (uncomment when ready):
    // float current = ina219.getCurrent_mA() / 1000.0;  // Convert mA to A
    // return current;
    
    // Simulation: Add small random variation
    simulated_current += ((rand() % 20) - 10) * 0.01;
    if (simulated_current < 0.1) simulated_current = 0.1;
    if (simulated_current > 2.0) simulated_current = 2.0;
    
    return simulated_current;
}

float read_voltage_volts(void) {
    // ESP32 implementation (uncomment when ready):
    // return ina219.getBusVoltage_V();
    
    // Simulation: Constant 12V with small ripple
    float ripple = ((rand() % 10) - 5) * 0.01;
    return VOLTAGE_RAIL + ripple;
}

float read_power_watts(void) {
    return read_current_amps() * read_voltage_volts();
}