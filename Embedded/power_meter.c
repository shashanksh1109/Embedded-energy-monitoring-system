/*
 * power_meter.c - Power Meter Main Program
 *
 * Monitors power consumption and sends packets to gateway via TCP.
 */
#define _POSIX_C_SOURCE 200809L
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
#include "protocol.h"

#define ELECTRICITY_COST_PER_KWH 0.12
#define GATEWAY_PORT             8080
#define DEFAULT_GATEWAY_HOST     "127.0.0.1"
#define PACKET_TYPE_POWER        1

typedef struct {
    char  device_id[16];
    char  zone[16];
    float base_load_kw;
    float hvac_max_power_kw;
    int   use_hardware;
} PowerMeterConfig;

static const char* get_gateway_host(void) {
    const char *env_host = getenv("GATEWAY_HOST");
    if (env_host) {
        printf("[POWER] Using gateway from environment: %s\n", env_host);
        return env_host;
    }
    return DEFAULT_GATEWAY_HOST;
}

static int connect_to_gateway(void) {
    const char *host = get_gateway_host();
    struct hostent *server = gethostbyname(host);
    if (!server) {
        printf("[POWER ERROR] Cannot resolve %s\n", host);
        return -1;
    }
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) { perror("[POWER ERROR] socket"); return -1; }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(GATEWAY_PORT);
    memcpy(&addr.sin_addr.s_addr, server->h_addr_list[0], server->h_length);

    if (connect(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("[POWER ERROR] connect");
        return -1;
    }
    printf("[POWER] Connected to gateway\n");
    return sockfd;
}

static float get_hvac_percentage(HVACSharedState *shm, sem_t *sem, float *fallback) {
    if (shm && sem != SEM_FAILED && shm->is_valid) {
        sem_wait(sem);
        float pct = shm->heater_pct > 0 ? shm->heater_pct : shm->cooler_pct;
        sem_post(sem);
        return pct;
    }
    // Fallback simulation
    static unsigned int seed = 54321;
    seed = (1103515245 * seed + 12345) % (1U << 31);
    float variation = ((float)seed / (1U << 31)) * 20.0f - 10.0f;
    *fallback += variation;
    if (*fallback < 0)   *fallback = 0;
    if (*fallback > 100) *fallback = 100;
    return *fallback;
}

PowerMeterConfig parse_power_config(int argc, char *argv[]) {
    PowerMeterConfig config;
    memset(&config, 0, sizeof(PowerMeterConfig));
    if (argc < 3) {
        printf("Usage: %s <device_id> <zone> [--hardware]\n", argv[0]);
        exit(1);
    }
    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    strncpy(config.zone,      argv[2], sizeof(config.zone) - 1);
    config.base_load_kw      = 2.0f;
    config.hvac_max_power_kw = 10.0f;
    config.use_hardware      = (argc == 4 && strcmp(argv[3], "--hardware") == 0);

    printf("[CONFIG] Device ID:  %s\n", config.device_id);
    printf("[CONFIG] Zone:       %s\n", config.zone);
    printf("[CONFIG] Mode:       %s\n\n", config.use_hardware ? "HARDWARE" : "SIMULATION");
    return config;
}

int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   Power Meter Application             ║\n");
    printf("╚════════════════════════════════════════╝\n\n");

    PowerMeterConfig config = parse_power_config(argc, argv);

    // Connect to gateway
    int sockfd = -1;
    while (sockfd < 0) {
        sockfd = connect_to_gateway();
        if (sockfd < 0) {
            printf("[POWER] Retrying in 3s...\n");
            sleep(3);
        }
    }

    // Try IPC
    sem_t           *sem = ipc_open_sem();
    HVACSharedState *shm = ipc_open_shm();
    if (shm && sem != SEM_FAILED)
        printf("[POWER] IPC connected\n");
    else
        printf("[POWER] IPC unavailable — using simulated HVAC load\n");

    printf("[POWER] Starting power monitoring...\n");
    printf("[POWER] Electricity rate: $%.2f per kWh\n", ELECTRICITY_COST_PER_KWH);
    printf("[POWER] Press Ctrl+C to stop\n");
    printf("═══════════════════════════════════════════════════════\n");

    float cumulative_energy_kwh = 0.0f;
    float fallback_pct          = 50.0f;
    int   iteration             = 0;

    while (1) {
        iteration++;

        float hvac_pct       = get_hvac_percentage(shm, sem, &fallback_pct);
        float current_power  = config.base_load_kw +
                               (hvac_pct / 100.0f) * config.hvac_max_power_kw;
        cumulative_energy_kwh += current_power / 3600.0f;
        float cost = cumulative_energy_kwh * ELECTRICITY_COST_PER_KWH;

        // Send packet to gateway
        Packet pkt;
        pack_packet(&pkt, config.device_id, current_power, PACKET_TYPE_POWER);
        ssize_t sent = send(sockfd, &pkt, sizeof(Packet), 0);
        if (sent < 0) {
            perror("[POWER ERROR] send failed, reconnecting");
            close(sockfd);
            sockfd = -1;
            while (sockfd < 0) {
                sockfd = connect_to_gateway();
                if (sockfd < 0) sleep(3);
            }
        }

        const char *src = (shm && shm->is_valid) ? "IPC" : "SIM";
        printf("[POWER] #%-4d | Power:%6.2f kW | Energy:%8.4f kWh | "
               "Cost: $%7.4f | HVAC:%5.1f%% [%s]\n",
               iteration, current_power, cumulative_energy_kwh,
               cost, hvac_pct, src);

        sleep(1);
    }

    close(sockfd);
    ipc_close_shm(shm);
    ipc_close_sem(sem);
    return 0;
}
