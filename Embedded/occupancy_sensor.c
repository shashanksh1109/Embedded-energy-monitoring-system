/*
 * occupancy_sensor.c - People Counter Main Program
 *
 * Reads occupancy count (people in zone) from VL53L1X ToF sensor
 * and streams packets to the gateway over TCP.
 *
 * Packet type: PACKET_TYPE_OCCUPANCY (3)
 * Value field: people count as float (e.g. 5.0 = 5 people)
 *
 * Usage:
 *   Simulation: ./occupancy_sensor OCC_A Zone_A 5
 *   Hardware:   ./occupancy_sensor OCC_A Zone_A 5 --hardware
 *
 * Arguments:
 *   device_id    : Sensor identifier (e.g. OCC_A)
 *   zone         : Zone name (e.g. Zone_A)
 *   sample_rate  : Seconds between readings (e.g. 5)
 *   --hardware   : Optional flag to use real VL53L1X sensor
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "protocol.h"
#include "occupancy_hardware.h"

#define GATEWAY_PORT         8080
#define DEFAULT_GATEWAY_HOST "127.0.0.1"

/* ============================================================
 * CONFIGURATION STRUCT
 * ============================================================ */
typedef struct {
    char device_id[16];    // Sensor identifier
    char zone[16];         // Zone name
    int  sampling_rate;    // Seconds between readings
    int  use_hardware;     // 0=simulation, 1=real VL53L1X
} OccupancyConfig;

/* ============================================================
 * FUNCTION DECLARATIONS
 * ============================================================ */
OccupancyConfig parse_occupancy_config(int argc, char *argv[]);
int  connect_to_gateway(void);
void run_occupancy_loop(OccupancyConfig *config, int sockfd);

/* ============================================================
 * get_gateway_host()
 * Reads GATEWAY_HOST env var, falls back to 127.0.0.1.
 * Same pattern used across all sensor programs.
 * ============================================================ */
static const char* get_gateway_host(void) {
    const char *env_host = getenv("GATEWAY_HOST");
    if (env_host) {
        printf("[OCCUPANCY] Using gateway from environment: %s\n", env_host);
        return env_host;
    }
    return DEFAULT_GATEWAY_HOST;
}

/* ============================================================
 * main()
 * ============================================================ */
int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   Occupancy Sensor Application        ║\n");
    printf("╚════════════════════════════════════════╝\n\n");

    // Step 1: Parse configuration
    OccupancyConfig config = parse_occupancy_config(argc, argv);

    // Step 2: Connect to gateway
    int sockfd = connect_to_gateway();
    if (sockfd < 0) {
        printf("[OCCUPANCY] ✗ Failed to connect to gateway, exiting\n");
        return 1;
    }

    // Step 3: Run sensor loop
    run_occupancy_loop(&config, sockfd);

    // Step 4: Cleanup
    close(sockfd);
    printf("[OCCUPANCY] Connection closed\n");
    return 0;
}

/* ============================================================
 * parse_occupancy_config()
 * Parses command-line arguments into OccupancyConfig struct.
 * ============================================================ */
OccupancyConfig parse_occupancy_config(int argc, char *argv[]) {
    OccupancyConfig config;
    memset(&config, 0, sizeof(OccupancyConfig));

    if (argc < 4) {
        printf("Usage: %s <device_id> <zone> <sample_rate> [--hardware]\n", argv[0]);
        printf("\nExamples:\n");
        printf("  Simulation: %s OCC_A Zone_A 5\n", argv[0]);
        printf("  Hardware:   %s OCC_A Zone_A 5 --hardware\n\n", argv[0]);
        exit(1);
    }

    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';

    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';

    config.sampling_rate = atoi(argv[3]);

    // Check for optional --hardware flag
    config.use_hardware = 0;
    if (argc == 5 && strcmp(argv[4], "--hardware") == 0) {
        config.use_hardware = 1;
    }

    printf("[CONFIG] Device ID:     %s\n", config.device_id);
    printf("[CONFIG] Zone:          %s\n", config.zone);
    printf("[CONFIG] Sampling Rate: %d seconds\n", config.sampling_rate);
    printf("[CONFIG] Sensor Mode:   %s\n\n",
           config.use_hardware ? "REAL HARDWARE (VL53L1X)" : "SIMULATION");

    return config;
}

/* ============================================================
 * connect_to_gateway()
 * Opens TCP connection to the gateway.
 * Reuses same pattern as network.c in temp_sensor.
 * ============================================================ */
int connect_to_gateway(void) {
    const char *host = get_gateway_host();

    printf("[OCCUPANCY] Resolving %s:%d...\n", host, GATEWAY_PORT);

    struct hostent *server = gethostbyname(host);
    if (server == NULL) {
        printf("[OCCUPANCY ERROR] Cannot resolve host: %s\n", host);
        return -1;
    }

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("[OCCUPANCY ERROR] socket()");
        return -1;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port   = htons(GATEWAY_PORT);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr_list[0], server->h_length);

    if (connect(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[OCCUPANCY ERROR] connect()");
        close(sockfd);
        return -1;
    }

    printf("[OCCUPANCY] ✓ Connected to gateway at %s:%d\n\n", host, GATEWAY_PORT);
    return sockfd;
}

/* ============================================================
 * run_occupancy_loop()
 * Main loop: reads count, packs packet, sends to gateway.
 * ============================================================ */
void run_occupancy_loop(OccupancyConfig *config, int sockfd) {
    int packet_count = 0;

    printf("[OCCUPANCY] Starting occupancy monitoring...\n");

    // Initialize hardware if needed
    if (config->use_hardware) {
        if (initialize_occupancy_hardware() < 0) {
            printf("[OCCUPANCY] ✗ Hardware initialization failed, exiting\n");
            return;
        }
    }

    printf("[OCCUPANCY] Mode: %s\n",
           config->use_hardware ? "REAL HARDWARE (VL53L1X)" : "SOFTWARE SIMULATION");
    printf("[OCCUPANCY] Press Ctrl+C to stop\n");
    printf("─────────────────────────────────────────────\n");

    while (1) {
        int people_count;

        // Choose sensor source based on configuration
        if (config->use_hardware) {
            // HARDWARE MODE: read from VL53L1X ToF sensor
            people_count = read_occupancy_count();
        } else {
            // SIMULATION MODE: read from simulated counter
            people_count = read_occupancy_count();
        }

        // Check for sensor error
        if (people_count < 0) {
            printf("[OCCUPANCY] ✗ Sensor read error, skipping reading\n");
            sleep(config->sampling_rate);
            continue;
        }

        // Pack into binary packet (store count as float)
        Packet pkt;
        pack_packet(&pkt, config->device_id, (float)people_count, PACKET_TYPE_OCCUPANCY);

        // Send to gateway
        ssize_t bytes_sent = send(sockfd, &pkt, sizeof(Packet), 0);
        if (bytes_sent < 0) {
            perror("[OCCUPANCY ERROR] send()");
            printf("[OCCUPANCY] ✗ Transmission failed, stopping\n");
            break;
        }

        // Log
        packet_count++;
        printf("[OCCUPANCY] #%-4d | %d people | %s | [%s]\n",
               packet_count,
               people_count,
               config->zone,
               config->use_hardware ? "HARDWARE" : "SIM");

        sleep(config->sampling_rate);
    }

    printf("─────────────────────────────────────────────\n");
    printf("[OCCUPANCY] Total packets sent: %d\n", packet_count);
}