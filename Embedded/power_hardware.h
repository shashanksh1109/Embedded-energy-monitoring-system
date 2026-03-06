#ifndef POWER_HARDWARE_H
#define POWER_HARDWARE_H

/*
 * power_hardware.h - Power Measurement Hardware Interface
 * 
 * For future INA219/INA3221 current sensor integration
 */

#define INA219_I2C_ADDRESS 0x40
#define VOLTAGE_RAIL 12.0  // 12V system

// Initialize power measurement hardware
int initialize_power_hardware(void);

// Read current in Amperes
float read_current_amps(void);

// Read voltage in Volts
float read_voltage_volts(void);

// Calculate power in Watts
float read_power_watts(void);

#endif