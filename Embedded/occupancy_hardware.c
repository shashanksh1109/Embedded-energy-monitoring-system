/*
 * occupancy_hardware.c - People Counter Hardware Implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "occupancy_hardware.h"

static int current_count = 0;
static int hardware_ready = 0;

int initialize_occupancy_hardware(void) {
    printf("[OCCUPANCY_HW] Initializing VL53L1X ToF sensor...\n");
    printf("[OCCUPANCY_HW] I2C Address: 0x%02X\n", TOF_I2C_ADDRESS);
    printf("[OCCUPANCY_HW] SDA: GPIO%d | SCL: GPIO%d\n", TOF_SDA_PIN, TOF_SCL_PIN);
    /* ESP32 (uncomment when ready):
     * Wire.begin(TOF_SDA_PIN, TOF_SCL_PIN);
     * sensor.setBus(&Wire);
     * if (!sensor.init()) { return -1; }
     * sensor.setDistanceMode(VL53L1X::Long);
     * sensor.setMeasurementTimingBudget(50000);
     * sensor.startContinuous(50);
     */
    sleep(1);
    if (check_occupancy_sensor_health()) {
        hardware_ready = 1;
        current_count  = 0;
        printf("[OCCUPANCY_HW] Sensor initialized successfully (simulated)\n");
        return 0;
    }
    printf("[OCCUPANCY_HW] Sensor initialization failed\n");
    return -1;
}

int read_occupancy_count(void) {
    /* ESP32 (uncomment when ready):
     * sensor.read();
     * uint16_t distance = sensor.ranging_data.range_mm;
     * static int last_zone = -1;
     * int current_zone = (distance < TOF_MAX_DISTANCE) ? 1 : 0;
     * if (last_zone == 0 && current_zone == 1) current_count++;
     * else if (last_zone == 1 && current_zone == 0) current_count--;
     * last_zone = current_zone;
     * if (current_count < 0) current_count = 0;
     * if (current_count > MAX_OCCUPANCY) current_count = MAX_OCCUPANCY;
     * return current_count;
     */
    // SIMULATION: randomly simulate people entering and exiting
    int change = (rand() % 5) - 2;
    current_count += change;
    if (current_count < 0)             current_count = 0;
    if (current_count > MAX_OCCUPANCY) current_count = MAX_OCCUPANCY;
    return current_count;
}

void reset_occupancy_count(void) {
    current_count = 0;
    printf("[OCCUPANCY_HW] Occupancy count reset to 0\n");
}

int check_occupancy_sensor_health(void) {
    printf("[OCCUPANCY_HW] Performing sensor health check...\n");
    /* ESP32 (uncomment when ready):
     * sensor.read();
     * if (sensor.timeoutOccurred()) return 0;
     * uint16_t distance = sensor.ranging_data.range_mm;
     * if (distance == 0 || distance > 4000) return 0;
     */
    printf("[OCCUPANCY_HW] Sensor health: OK (simulated)\n");
    return 1;
}
