#ifndef SENSOR_HARDWARE_H
#define SENSOR_HARDWARE_H

/*
 * sensor_hardware.h - Hardware Sensor Interface
 * 
 * ESP32/Arduino hardware functions for real sensors:
 * - DHT22 temperature/humidity sensor
 * - Sensor initialization and calibration
 * - Health monitoring
 * 
 * NOTE: This code is ESP32-ready but commented out in function calls.
 *       To use: Run with --hardware flag
 */

// ============================================================================
// HARDWARE CONFIGURATION
// ============================================================================

#define DHT_PIN 4           // GPIO pin for DHT22 DATA line
#define DHT_TYPE 22         // DHT22 (AM2302) sensor

// ============================================================================
// HARDWARE FUNCTIONS
// ============================================================================

/**
 * Initialize hardware sensors (DHT22)
 * Must be called before reading sensors
 * 
 * @return: 0 on success, -1 on failure
 */
int initialize_hardware_sensor(void);

/**
 * Read temperature from DHT22 sensor
 * 
 * @return: Temperature in Celsius, -999.0 on error
 */
float read_hardware_temperature(void);

/**
 * Read humidity from DHT22 sensor
 * 
 * @return: Humidity percentage (0-100%), -999.0 on error
 */
float read_hardware_humidity(void);

/**
 * Apply calibration offset to sensor reading
 * 
 * @param raw_value: Raw sensor reading
 * @param offset: Calibration offset to apply
 * @return: Calibrated value
 */
float calibrate_sensor_reading(float raw_value, float offset);

/**
 * Check if sensor is responding correctly
 * 
 * @return: 1 if healthy, 0 if failed
 */
int check_sensor_health(void);

#endif