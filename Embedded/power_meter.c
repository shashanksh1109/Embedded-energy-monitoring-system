/*
 * power_meter.c - Power Meter Main Program
 *
 * Monitors power consumption and calculates energy costs.
 *
 * IPC: Reads HVACSharedState from shared memory written by hvac_controller.
 *      If shared memory is unavailable (hvac not running), falls back to
 *      simulated random HVAC load.
 *
 * Power calculation:
 *   total_kw = base_load_kw + (hvac_pct / 100.0) * hvac_max_power_kw
 *   energy_kwh += total_kw / 3600.0   (per second interval)
 *   cost_usd    = cumulative_energy_kwh * ELECTRICITY_COST_PER_KWH
 */

#define _POSIX_C_SOURCE 200809L   // expose shm_open, sem_open, ftruncate

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "power_hardware.h"
#include "ipc.h"

#define ELECTRICITY_COST_PER_KWH 0.12   // $0.12 per kWh
#define GATEWAY_PORT             8080
#define DEFAULT_GATEWAY_HOST     "127.0.0.1"

typedef struct {
    char  device_id[16];
    char  zone[16];
    float base_load_kw;       // Constant base load (lights, equipment)
    float hvac_max_power_kw;  // Maximum HVAC power
    int   use_hardware;
} PowerMeterConfig;

// Function declarations
PowerMeterConfig parse_power_config(int argc, char *argv[]);
void run_power_meter_loop(PowerMeterConfig *config);
float get_hvac_percentage(HVACSharedState *shm, sem_t *sem, float *fallback_pct);

// NEW: reads GATEWAY_HOST env var, falls back to 127.0.0.1 (same pattern as network.c)
static const char* get_gateway_host(void) {
    const char *env_host = getenv("GATEWAY_HOST");
    if (env_host) {
        printf("[POWER] Using gateway from environment: %s\n", env_host);
        return env_host;
    }
    return DEFAULT_GATEWAY_HOST;
}

int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   Power Meter Application             ║\n");
    printf("╚════════════════════════════════════════╝\n\n");

    // Parse configuration
    PowerMeterConfig config = parse_power_config(argc, argv);

    // Run monitoring loop
    run_power_meter_loop(&config);

    return 0;
}

PowerMeterConfig parse_power_config(int argc, char *argv[]) {
    PowerMeterConfig config;
    memset(&config, 0, sizeof(PowerMeterConfig));

    if (argc < 3) {
        printf("Usage: %s <device_id> <zone> [--hardware]\n", argv[0]);
        printf("\nExample:\n");
        printf("  %s POWER_1 Zone_A\n", argv[0]);
        printf("  %s POWER_1 Zone_A --hardware\n\n", argv[0]);
        exit(1);
    }

    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';

    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';

    config.base_load_kw      = 2.0;       // 2 kW base load
    config.hvac_max_power_kw = 10.0;      // 10 kW max HVAC

    config.use_hardware = 0;
    if (argc == 4 && strcmp(argv[3], "--hardware") == 0) {
        config.use_hardware = 1;
    }

    printf("[CONFIG] Device ID:    %s\n", config.device_id);
    printf("[CONFIG] Zone:         %s\n", config.zone);
    printf("[CONFIG] Base Load:    %.1f kW\n", config.base_load_kw);
    printf("[CONFIG] HVAC Max:     %.1f kW\n", config.hvac_max_power_kw);
    printf("[CONFIG] Mode:         %s\n\n", config.use_hardware ? "HARDWARE" : "SIMULATION");

    return config;
}

/*
 * get_hvac_percentage()
 * Try to read HVAC load from shared memory (written by hvac_controller).
 * If shared memory is unavailable or data is not valid, fall back to
 * a simulated random walk stored in fallback_pct.
 *
 * Returns the effective HVAC percentage (0-100%).
 */
float get_hvac_percentage(HVACSharedState *shm, sem_t *sem, float *fallback_pct) {
    // Try shared memory first
    if (shm && sem != SEM_FAILED && shm->is_valid) {
        float hvac_pct = 0.0f;

        sem_wait(sem);   // lock before reading
        // Total HVAC activity = heater + cooler (only one is non-zero at a time)
        hvac_pct = shm->heater_pct + shm->cooler_pct;
        sem_post(sem);   // unlock after reading

        return hvac_pct;
    }

    // Fallback: simulate HVAC load variation (in real system, would read from HVAC controller)
    // Used when hvac_controller is not running
    static unsigned int seed = 54321;
    seed = (1103515245 * seed + 12345) % (1U << 31);
    float variation = ((float)seed / (1U << 31)) * 20.0f - 10.0f;  // ±10%
    *fallback_pct += variation;

    // Clamp HVAC percentage
    if (*fallback_pct < 0)   *fallback_pct = 0;
    if (*fallback_pct > 100) *fallback_pct = 100;

    return *fallback_pct;
}

void run_power_meter_loop(PowerMeterConfig *config) {
    // Initialize hardware if needed
    if (config->use_hardware) {
        initialize_power_hardware();
    }

    // Try to connect to shared memory (written by hvac_controller)
    printf("[POWER] Connecting to HVAC shared memory...\n");
    sem_t           *sem = ipc_open_sem();
    HVACSharedState *shm = ipc_open_shm();

    if (shm && sem != SEM_FAILED) {
        printf("[POWER] ✓ IPC connected — using real HVAC data\n");
    } else {
        printf("[POWER] WARNING: IPC unavailable — using simulated HVAC load\n");
        printf("[POWER]          Start hvac_controller to enable real data\n");
    }

    printf("[POWER] Starting power monitoring...\n");
    printf("[POWER] Electricity rate: $%.2f per kWh\n", ELECTRICITY_COST_PER_KWH);
    printf("[POWER] Gateway: %s:%d\n", get_gateway_host(), GATEWAY_PORT);
    printf("[POWER] Press Ctrl+C to stop\n");
    printf("═══════════════════════════════════════════════════════════════════════\n");

    float cumulative_energy_kwh = 0.0f;
    int   iteration             = 0;
    float fallback_pct          = 50.0f;  // starting point for fallback simulation

    while (1) {
        iteration++;

        float hvac_percentage;
        float current_power_kw;

        if (config->use_hardware) {
            // Hardware mode: Read from INA219 current sensor
            // current_power_kw = read_power_watts() / 1000.0;  // Uncomment for ESP32

            // Placeholder: use IPC or fallback
            hvac_percentage  = get_hvac_percentage(shm, sem, &fallback_pct);
            current_power_kw = config->base_load_kw +
                               (hvac_percentage / 100.0f) * config->hvac_max_power_kw;
        } else {
            // Simulation mode: use real HVAC data from IPC (or fallback)
            hvac_percentage  = get_hvac_percentage(shm, sem, &fallback_pct);
            current_power_kw = config->base_load_kw +
                               (hvac_percentage / 100.0f) * config->hvac_max_power_kw;
        }

        // Calculate energy consumed (kWh)
        // Power (kW) × Time (hours) = Energy (kWh)
        // 1 second = 1/3600 hours
        float energy_this_interval  = current_power_kw / 3600.0f;
        cumulative_energy_kwh      += energy_this_interval;

        // Calculate cost
        float cumulative_cost = cumulative_energy_kwh * ELECTRICITY_COST_PER_KWH;

        // Show IPC status in log
        const char *data_source = (shm && shm->is_valid) ? "IPC" : "SIM";

        // Display status
        printf("[POWER] #%-4d | Power:%6.2f kW | Energy:%8.4f kWh | "
               "Cost: $%7.4f | HVAC:%5.1f%% [%s]\n",
               iteration, current_power_kw, cumulative_energy_kwh,
               cumulative_cost, hvac_percentage, data_source);

        sleep(1);
    }

    // Cleanup IPC (unreachable in normal flow — signal handler would exit first)
    ipc_close_shm(shm);
    ipc_close_sem(sem);
}