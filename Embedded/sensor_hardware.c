/*
 * sensor_hardware.c - Real hardware sensor (Raspberry Pi)
 *
 * Reads the Pi's built-in SoC temperature sensor through the Linux
 * thermal sysfs interface. The kernel exposes it as a text file:
 *     /sys/class/thermal/thermal_zone0/temp   ->  "48312\n"
 * The value is in millidegrees Celsius (48312 = 48.312 C).
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "sensor_hardware.h"

#define THERMAL_PATH "/sys/class/thermal/thermal_zone0/temp"

static float temperature_offset = 0.0f;
static float humidity_offset = 0.0f;

/* Open the sysfs file, read one integer, convert to degrees C. */
static float read_soc_temperature(void) {
    FILE *f = fopen(THERMAL_PATH, "r");
    if (f == NULL) {
        perror("[HARDWARE ERROR] fopen " THERMAL_PATH);
        return -999.0f;
    }

    long millidegrees = 0;
    int parsed = fscanf(f, "%ld", &millidegrees);
    fclose(f);

    if (parsed != 1) {
        printf("[HARDWARE ERROR] Could not parse %s\n", THERMAL_PATH);
        return -999.0f;
    }
    return millidegrees / 1000.0f;
}

int initialize_hardware_sensor(void) {
    printf("[HARDWARE] Using Raspberry Pi SoC sensor: %s\n", THERMAL_PATH);
    if (check_sensor_health()) {
        printf("[HARDWARE] Sensor initialized successfully\n");
        return 0;
    }
    printf("[HARDWARE] Sensor initialization failed\n");
    return -1;
}

float read_hardware_temperature(void) {
    float raw = read_soc_temperature();
    if (raw < -100.0f) {
        return raw;  /* pass the -999 error code through to the caller */
    }
    return calibrate_sensor_reading(raw, temperature_offset);
}

float read_hardware_humidity(void) {
    /* The Pi has no humidity sensor. */
    return -999.0f;
}

float calibrate_sensor_reading(float raw_value, float offset) {
    return raw_value + offset;
}

int check_sensor_health(void) {
    float t = read_soc_temperature();
    if (t < -40.0f || t > 100.0f) {
        printf("[HARDWARE] Health check failed: reading %.2f C out of range\n", t);
        return 0;
    }
    printf("[HARDWARE] Health check OK: %.2f C\n", t);
    return 1;
}

void set_temperature_calibration(float offset) {
    temperature_offset = offset;
}

void set_humidity_calibration(float offset) {
    humidity_offset = offset;
}