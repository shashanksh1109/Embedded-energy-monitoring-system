#ifndef SENSOR_HARDWARE_H
#define SENSOR_HARDWARE_H

/*
 * sensor_hardware.h - Hardware Sensor Interface
 *
 * Real sensor backend for the Raspberry Pi:
 * - Reads the SoC temperature sensor via Linux sysfs
 *   (/sys/class/thermal/thermal_zone0/temp)
 * - Range-based health check
 * - Optional calibration offsets
 *
 * Used when the program runs with the --hardware flag.
 * All read functions return -999.0 on error.
 */

// ============================================================================
// HARDWARE FUNCTIONS
// ============================================================================

/**
 * Check that the hardware sensor is readable and in range.
 * Must be called before reading sensors.
 *
 * @return: 0 on success, -1 on failure
 */
int initialize_hardware_sensor(void);

/**
 * Read temperature from the Pi SoC sensor.
 *
 * @return: Temperature in Celsius, -999.0 on error
 */
float read_hardware_temperature(void);

/**
 * Read humidity. The Pi has no humidity sensor.
 *
 * @return: always -999.0
 */
float read_hardware_humidity(void);

/**
 * Apply calibration offset to a sensor reading.
 *
 * @param raw_value: Raw sensor reading
 * @param offset: Calibration offset to apply
 * @return: Calibrated value
 */
float calibrate_sensor_reading(float raw_value, float offset);

/**
 * Check if the sensor is responding with a plausible value (-40..100 C).
 *
 * @return: 1 if healthy, 0 if failed
 */
int check_sensor_health(void);

/**
 * Set calibration offsets applied to future readings.
 */
void set_temperature_calibration(float offset);
void set_humidity_calibration(float offset);

#endif