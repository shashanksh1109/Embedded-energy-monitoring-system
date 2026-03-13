/*
 * hvac_controller.c - HVAC Controller Main Program
 *
 * Controls heating/cooling to maintain target temperature using PID algorithm.
 *
 * Flow:
 *   1. Parse configuration (device_id, zone, setpoint, --hardware flag)
 *   2. Connect to gateway over TCP
 *   3. Run PID control loop:
 *        - Read current temperature (simulated or real hardware)
 *        - Compute PID output
 *        - Drive heater or cooler
 *        - Pack and send HVAC_STATE packet to gateway
 *   4. Cleanup and close socket on exit
 *
 * Packet type sent: PACKET_TYPE_HVAC_STATE (4)
 * Value field:  positive = heater % output
 *               negative = cooler % output
 *
 * Usage:
 *   Simulation: ./hvac_controller HVAC_A Zone_A 20.0
 *   Hardware:   ./hvac_controller HVAC_A Zone_A 20.0 --hardware
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "pid.h"
#include "hvac_hardware.h"
#include "protocol.h"          /* NEW: pack_packet(), PACKET_TYPE_HVAC_STATE */

#define GATEWAY_PORT         8080
#define DEFAULT_GATEWAY_HOST "127.0.0.1"

/* ============================================================
 * CONFIGURATION STRUCT
 * ============================================================ */
typedef struct {
    char  device_id[16];   /* Device identifier (e.g. HVAC_A)  */
    char  zone[16];        /* Zone name (e.g. Zone_A)           */
    float setpoint;        /* Target temperature in Celsius     */
    int   use_hardware;    /* 0 = simulation, 1 = real ESP32    */
} HVACConfig;

/* ============================================================
 * FUNCTION DECLARATIONS
 * ============================================================ */
HVACConfig parse_hvac_config(int argc, char *argv[]);
void       run_hvac_loop(HVACConfig *config, int sockfd);   /* NEW: sockfd param */
float      simulate_temperature_physics(float current_temp, float heater_power,
                                        float cooler_power, float dt);
int        connect_to_gateway(void);                        /* NEW */

/* ============================================================
 * get_gateway_host()
 * Reads GATEWAY_HOST env var, falls back to 127.0.0.1.
 * Same pattern used across all sensor programs (network.c,
 * power_meter.c, occupancy_sensor.c).
 * ============================================================ */
static const char* get_gateway_host(void) {
    const char *env_host = getenv("GATEWAY_HOST");
    if (env_host) {
        printf("[HVAC] Using gateway from environment: %s\n", env_host);
        return env_host;
    }
    return DEFAULT_GATEWAY_HOST;
}

/* ============================================================
 * connect_to_gateway()
 * Opens a TCP connection to the Python gateway.
 * Returns socket fd on success, -1 on failure.
 *
 * NEW: HVAC previously had no network code - it only logged
 * to stdout. This function closes that gap so HVAC_STATE
 * packets flow into the gateway and get persisted to the DB.
 * ============================================================ */
int connect_to_gateway(void) {
    const char *host = get_gateway_host();

    printf("[HVAC] Resolving %s:%d...\n", host, GATEWAY_PORT);

    /* Resolve hostname to IP */
    struct hostent *server = gethostbyname(host);
    if (server == NULL) {
        printf("[HVAC ERROR] Cannot resolve host: %s\n", host);
        return -1;
    }

    /* Create TCP socket */
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("[HVAC ERROR] socket()");
        return -1;
    }

    /* Build server address struct */
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port   = htons(GATEWAY_PORT);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr_list[0], server->h_length);

    /* Connect to gateway */
    if (connect(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[HVAC ERROR] connect()");
        close(sockfd);
        return -1;
    }

    printf("[HVAC] ✓ Connected to gateway at %s:%d\n\n", host, GATEWAY_PORT);
    return sockfd;
}

/* ============================================================
 * main()
 * ============================================================ */
int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   HVAC Controller Application         ║\n");
    printf("╚════════════════════════════════════════╝\n\n");

    /* Step 1: Parse configuration */
    HVACConfig config = parse_hvac_config(argc, argv);

    /* Step 2: Connect to gateway
     * NEW: Previously main() went straight to run_hvac_loop().
     * Now we establish TCP connection first and pass sockfd
     * into the loop so each iteration can send a state packet. */
    int sockfd = connect_to_gateway();
    if (sockfd < 0) {
        printf("[HVAC] ✗ Failed to connect to gateway, exiting\n");
        return 1;
    }

    /* Step 3: Run control loop */
    run_hvac_loop(&config, sockfd);

    /* Step 4: Cleanup */
    close(sockfd);
    printf("[HVAC] Connection closed\n");
    return 0;
}

/* ============================================================
 * parse_hvac_config()
 * Parses command-line arguments into HVACConfig struct.
 * ============================================================ */
HVACConfig parse_hvac_config(int argc, char *argv[]) {
    HVACConfig config;
    memset(&config, 0, sizeof(HVACConfig));

    if (argc < 4) {
        printf("Usage: %s <device_id> <zone> <setpoint> [--hardware]\n", argv[0]);
        printf("\nExample:\n");
        printf("  Simulation: %s HVAC_1 Zone_A 20.0\n", argv[0]);
        printf("  Hardware:   %s HVAC_1 Zone_A 20.0 --hardware\n\n", argv[0]);
        exit(1);
    }

    /* Copy device_id safely - ensure null termination */
    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';

    /* Copy zone safely - ensure null termination */
    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';

    /* Parse setpoint temperature */
    config.setpoint = (float)atof(argv[3]);

    /* Check for optional --hardware flag */
    config.use_hardware = 0;
    if (argc == 5 && strcmp(argv[4], "--hardware") == 0) {
        config.use_hardware = 1;
    }

    printf("[CONFIG] Device ID:  %s\n", config.device_id);
    printf("[CONFIG] Zone:       %s\n", config.zone);
    printf("[CONFIG] Setpoint:   %.1f°C\n", config.setpoint);
    printf("[CONFIG] Mode:       %s\n\n", config.use_hardware ? "HARDWARE" : "SIMULATION");

    return config;
}

/* ============================================================
 * run_hvac_loop()
 * Main PID control loop.
 *
 * Each iteration:
 *   1. Read current temperature (physics sim or real hardware)
 *   2. Compute PID output
 *   3. Apply heater or cooler based on temperature vs setpoint
 *   4. Send HVAC_STATE packet to gateway  <- NEW
 *   5. Sleep 1 second (dt = 1.0)
 *
 * NEW: sockfd parameter added so the loop can transmit
 * HVAC_STATE packets to the gateway on every iteration.
 * ============================================================ */
void run_hvac_loop(HVACConfig *config, int sockfd) {

    /* Initialize PID controller with Ziegler-Nichols tuned gains:
     * Kp=2.0, Ki=0.5, Kd=1.0 - tuned for HVAC thermal response */
    PIDController pid;
    pid_init(&pid, config->setpoint, 2.0, 0.5, 1.0);

    /* Initialize hardware relay pins if running on real ESP32 */
    if (config->use_hardware) {
        initialize_hvac_hardware();
    }

    printf("[HVAC] Starting control loop...\n");
    printf("[HVAC] Setpoint: %.1f°C\n", config->setpoint);
    printf("[HVAC] PID Gains: Kp=%.1f, Ki=%.1f, Kd=%.1f\n", pid.kp, pid.ki, pid.kd);
    printf("[HVAC] Gateway: %s:%d\n", get_gateway_host(), GATEWAY_PORT);
    printf("[HVAC] Press Ctrl+C to stop\n");
    printf("═══════════════════════════════════════════════════════════════\n");

    /* Start 5 degrees below target to demonstrate heating response */
    float current_temp = config->setpoint - 5.0;
    float heater_power = 0.0;
    float cooler_power = 0.0;

    int   iteration = 0;
    float dt        = 1.0;   /* 1 second time step - matches sleep(1) below */

    while (1) {
        iteration++;

        /* ── Step 1: Read temperature ─────────────────────────── */
        if (config->use_hardware) {
            /* Hardware mode: read from real ESP32/DHT22
             * Uncomment when physical hardware is connected:
             * current_temp = read_hardware_temperature(); */

            /* Placeholder: use physics simulation until ESP32 ready */
            current_temp = simulate_temperature_physics(current_temp, heater_power, cooler_power, dt);
        } else {
            /* Simulation mode: physics-based temperature model */
            current_temp = simulate_temperature_physics(current_temp, heater_power, cooler_power, dt);
        }

        /* ── Step 2: Compute PID output ───────────────────────── */
        /* pid_output range: 0.0 to 100.0 (%) after clamping in pid.c */
        float pid_output = pid_compute(&pid, current_temp, dt);

        /* ── Step 3: Determine heating or cooling ─────────────── */
        if (current_temp < config->setpoint) {
            /* Below setpoint: activate heater, deactivate cooler */
            heater_power = pid_output;
            cooler_power = 0.0;
        } else {
            /* Above setpoint: activate cooler, deactivate heater */
            heater_power = 0.0;
            cooler_power = pid_output;
        }

        /* Set physical actuators (relay control via GPIO on ESP32) */
        if (config->use_hardware) {
            // set_heater_power(heater_power);  // Uncomment for real ESP32
            // set_cooler_power(cooler_power);
        }

        /* ── Step 4: Display status ───────────────────────────── */
        float error = config->setpoint - current_temp;
        printf("[HVAC] #%-4d | Temp:%6.2f°C | Error:%+6.2f°C | Heat:%5.1f%% | Cool:%5.1f%%\n",
               iteration, current_temp, error, heater_power, cooler_power);

        /* ── Step 5: Send HVAC_STATE packet to gateway ────────────
         * NEW: This was missing before - HVAC state was never
         * transmitted to the gateway. Now every iteration sends
         * a packet so the gateway persists it to hvac_state table.
         *
         * Encoding convention for the single float value field:
         *   positive = heater output % (heating mode)
         *   negative = cooler output % (cooling mode)
         *   zero     = system idle
         * ──────────────────────────────────────────────────────── */
        float pid_value = (heater_power > 0) ? heater_power : -cooler_power;
        Packet pkt;
        pack_packet(&pkt, config->device_id, pid_value, PACKET_TYPE_HVAC_STATE);

        ssize_t bytes_sent = send(sockfd, &pkt, sizeof(Packet), 0);
        if (bytes_sent < 0) {
            perror("[HVAC ERROR] send()");
            printf("[HVAC] ✗ Transmission failed, stopping\n");
            break;
        }

        /* Uncomment to stop after 60 iterations (useful for demos):
        if (iteration >= 60) {
            printf("═══════════════════════════════════════════════════════════════\n");
            printf("[HVAC] Demo complete (60 iterations)\n");
            printf("[HVAC] Final temperature: %.2f°C (target: %.1f°C)\n",
                   current_temp, config->setpoint);
            break;
        }
        */

        sleep(1);   /* Wait 1 second before next PID iteration */
    }
}

/* ============================================================
 * simulate_temperature_physics()
 * Simple first-order thermal model of a room.
 *
 * Models three forces acting on room temperature:
 *   1. Heater power  -> raises temperature
 *   2. Cooler power  -> lowers temperature
 *   3. Natural loss  -> room slowly loses heat to environment
 *
 * Rate constants (tunable for different room sizes/insulation):
 *   heating_rate    = 0.01 degrees C/s per % heater power
 *   cooling_rate    = 0.01 degrees C/s per % cooler power
 *   natural_cooling = 0.02 degrees C/s constant ambient heat loss
 * ============================================================ */
float simulate_temperature_physics(float current_temp, float heater_power,
                                   float cooler_power, float dt) {
    /* Heating effect: heater adds thermal energy to the room */
    float heating_rate = 0.01;   /* degrees C per second per % power */
    float heat_added   = heater_power * heating_rate * dt;

    /* Cooling effect: cooler removes thermal energy from the room */
    float cooling_rate = 0.01;
    float heat_removed = cooler_power * cooling_rate * dt;

    /* Natural heat loss: room slowly equilibrates with ambient temperature */
    float natural_cooling = 0.02 * dt;   /* 0.02 degrees C per second */

    /* Net temperature change = heating - cooling - natural loss */
    float new_temp = current_temp + heat_added - heat_removed - natural_cooling;

    return new_temp;
}