/*
 * occupancy_hardware.c - People Counter Hardware Implementation
 *
 * VL53L1X Time-of-Flight sensor interface for bidirectional
 * people counting via two detection zones (entry/exit).
 *
 * To activate real hardware:
 * 1. Run program with --hardware flag
 * 2. Upload to ESP32 using Arduino IDE or PlatformIO
 * 3. Install Pololu VL53L1X library:
 *    https://github.com/pololu/vl53l1x-arduino
 *
 * Simulation behaviour:
 *   - Starts at 0 people on each run
 *   - Randomly simulates people entering and exiting
 *   - Count stays within 0 to MAX_OCCUPANCY bounds
 *   - Weighted towards small changes to mimic realistic office traffic
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include "occupancy_hardware.h"

/* ============================================================
 * ESP32/ARDUINO HARDWARE INCLUDES
 * Uncomment when compiling for real hardware
 * ============================================================ */
// #include <Wire.h>
// #include <VL53L1X.h>

/* ============================================================
 * HARDWARE SENSOR OBJECT
 * Uncomment when compiling for real hardware
 * ============================================================ */
// VL53L1X sensor;

/* ============================================================
 * INTERNAL STATE
 * ============================================================ */
static int current_count  = 0;   // Current people count
static int hardware_ready = 0;   // 1 if sensor initialized successfully

/* ============================================================
 * initialize_occupancy_hardware()
 * Sets up VL53L1X over I2C. In simulation, resets count to 0.
 * ============================================================ */
int initialize_occupancy_hardware(void) {
    printf("[OCCUPANCY_HW] Initializing VL53L1X ToF sensor...\n");
    printf("[OCCUPANCY_HW] I2C Address: 0x%02X\n", TOF_I2C_ADDRESS);
    printf("[OCCUPANCY_HW] SDA: GPIO%d | SCL: GPIO%d\n", TOF_SDA_PIN, TOF_SCL_PIN);
    printf("[OCCUPANCY_HW] Max detection distance: %dmm\n", TOF_MAX_DISTANCE);

    /* ESP32/Arduino initialization (uncomment when ready):
     *
     * Wire.begin(TOF_SDA_PIN, TOF_SCL_PIN);
     * sensor.setBus(&Wire);
     * sensor.setTimeout(500);
     *
     * if (!sensor.init()) {
     *     printf("[OCCUPANCY_HW] ✗ Failed to initialize VL53L1X\n");
     *     printf("[OCCUPANCY_HW]   Check wiring: SDA→GPIO%d, SCL→GPIO%d\n",
     *            TOF_SDA_PIN, TOF_SCL_PIN);
     *     return -1;
     * }
     *
     * // Configure for long-range, fast detection
     * sensor.setDistanceMode(VL53L1X::Long);
     * sensor.setMeasurementTimingBudget(50000);  // 50ms timing budget
     * sensor.startContinuous(50);                // 50ms between measurements
     */

    // Simulation: seed RNG and reset count on every startup
    srand((unsigned int)time(NULL));
    current_count = 0;

    printf("[OCCUPANCY_HW] Waiting for sensor stabilization...\n");
    sleep(1);

    if (check_occupancy_sensor_health()) {
        hardware_ready = 1;
        printf("[OCCUPANCY_HW] ✓ Sensor initialized successfully (simulated)\n");
        return 0;
    } else {
        printf("[OCCUPANCY_HW] ✗ Sensor initialization failed\n");
        return -1;
    }
}

/* ============================================================
 * read_occupancy_count()
 * Returns current people count in the zone.
 * Hardware: reads two ToF zones to detect entry/exit direction.
 * Simulation: randomly increments/decrements count.
 * ============================================================ */
int read_occupancy_count(void) {

    /* ESP32/Arduino implementation (uncomment when ready):
     *
     * sensor.read();
     * uint16_t distance = sensor.ranging_data.range_mm;
     *
     * // Zone 1 (outer): detects person approaching from outside
     * // Zone 2 (inner): detects person approaching from inside
     * // Entry: zone1 triggers before zone2 → count++
     * // Exit:  zone2 triggers before zone1 → count--
     *
     * static int last_zone = -1;
     * int current_zone = (distance < TOF_MAX_DISTANCE) ? 1 : 0;
     *
     * if (last_zone == 0 && current_zone == 1) {
     *     current_count++;
     *     printf("[OCCUPANCY_HW] Entry detected, count: %d\n", current_count);
     * } else if (last_zone == 1 && current_zone == 0) {
     *     current_count--;
     *     printf("[OCCUPANCY_HW] Exit detected, count: %d\n", current_count);
     * }
     * last_zone = current_zone;
     *
     * // Clamp to valid range
     * if (current_count < 0)             current_count = 0;
     * if (current_count > MAX_OCCUPANCY) current_count = MAX_OCCUPANCY;
     *
     * return current_count;
     */

    // SIMULATION: weighted random walk to mimic realistic office traffic
    // 70% chance of small change (-1/0/+1), 30% chance of no change
    int r = rand() % 10;
    if (r < 3)       current_count -= 1;  // 30% exit
    else if (r < 6)  current_count += 1;  // 30% entry
    // else 40%: no change (person passing by, not entering/exiting)

    // Clamp to valid range
    if (current_count < 0)             current_count = 0;
    if (current_count > MAX_OCCUPANCY) current_count = MAX_OCCUPANCY;

    return current_count;
}

/* ============================================================
 * reset_occupancy_count()
 * Resets count to zero. Call at start of day/shift.
 * ============================================================ */
void reset_occupancy_count(void) {
    current_count = 0;
    printf("[OCCUPANCY_HW] Occupancy count reset to 0\n");
}

/* ============================================================
 * check_occupancy_sensor_health()
 * Verifies sensor is responding. Returns 1=healthy, 0=failed.
 * ============================================================ */
int check_occupancy_sensor_health(void) {
    printf("[OCCUPANCY_HW] Performing sensor health check...\n");

    /* ESP32/Arduino implementation (uncomment when ready):
     *
     * sensor.read();
     * if (sensor.timeoutOccurred()) {
     *     printf("[OCCUPANCY_HW] ✗ Sensor timeout during health check\n");
     *     return 0;
     * }
     * uint16_t distance = sensor.ranging_data.range_mm;
     * if (distance == 0 || distance > 4000) {
     *     printf("[OCCUPANCY_HW] ✗ Sensor reading out of range: %dmm\n", distance);
     *     return 0;
     * }
     */

    // SIMULATION: always healthy
    printf("[OCCUPANCY_HW] Sensor health: OK (simulated)\n");
    return 1;
}