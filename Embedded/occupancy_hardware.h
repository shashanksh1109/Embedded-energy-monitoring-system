#ifndef OCCUPANCY_HARDWARE_H
#define OCCUPANCY_HARDWARE_H

/*
 * occupancy_hardware.h - People Counter Hardware Interface
 *
 * Supports VL53L1X Time-of-Flight (ToF) sensor for accurate
 * bidirectional people counting (entry/exit detection).
 *
 * Hardware: VL53L1X connected via I2C to ESP32
 *   - SDA → GPIO 21
 *   - SCL → GPIO 22
 *   - XSHUT → GPIO 15 (optional, for reset)
 *   - INT → GPIO 34 (optional, for interrupt-driven reads)
 *
 * How it works:
 *   Two ToF zones (inner/outer) detect direction of movement.
 *   If outer zone triggers first → person entering (count++)
 *   If inner zone triggers first → person exiting (count--)
 *
 * Library: Pololu VL53L1X Arduino Library
 *   https://github.com/pololu/vl53l1x-arduino
 */

/* ============================================================
 * HARDWARE CONFIGURATION
 * ============================================================ */
#define TOF_SDA_PIN       21       // I2C SDA GPIO pin
#define TOF_SCL_PIN       22       // I2C SCL GPIO pin
#define TOF_XSHUT_PIN     15       // Sensor reset pin (optional)
#define TOF_I2C_ADDRESS   0x29     // Default VL53L1X I2C address
#define TOF_MAX_DISTANCE  1200     // Max detection distance in mm (1.2m doorway)
#define MAX_OCCUPANCY     100      // Maximum room capacity (safety clamp)

/* ============================================================
 * HARDWARE FUNCTIONS
 * ============================================================ */

/**
 * Initialize VL53L1X ToF sensor over I2C.
 * Must be called once before any reads.
 *
 * @return: 0 on success, -1 on failure
 */
int initialize_occupancy_hardware(void);

/**
 * Read current people count from ToF sensor.
 * Tracks entries and exits bidirectionally.
 *
 * @return: Current occupancy count (0 to MAX_OCCUPANCY)
 *          Returns -1 on sensor read error
 */
int read_occupancy_count(void);

/**
 * Reset the occupancy count to zero.
 * Call at start of each day or shift.
 */
void reset_occupancy_count(void);

/**
 * Check if the ToF sensor is responding correctly.
 *
 * @return: 1 if healthy, 0 if failed
 */
int check_occupancy_sensor_health(void);

#endif