/*
 * hvac_controller.c - HVAC Controller Main Program
 *
 * Controls heating/cooling to maintain target temperature using PID algorithm.
 * Sends V2 packets to gateway with full state:
 *   value1 = heater_pct
 *   value2 = cooler_pct
 *   value3 = current_temp
 *   value4 = setpoint
 *
 * IPC: Writes HVACSharedState to shared memory every iteration so
 *      power_meter can read real HVAC load instead of simulating randomly.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <time.h>
#include "pid.h"
#include "hvac_hardware.h"
#include "protocol.h"
#include "ipc.h"
#include "mqtt_client.h"

#define GATEWAY_PORT         8080
#define DEFAULT_GATEWAY_HOST "127.0.0.1"

typedef struct {
    char  device_id[16];
    char  zone[16];
    float setpoint;
    int   use_hardware;
} HVACConfig;

// Function declarations
HVACConfig parse_hvac_config(int argc, char *argv[]);
int  connect_to_gateway(void);
void run_hvac_loop(HVACConfig *config, int sockfd);
float simulate_temperature_physics(float current_temp, float heater_power,
                                   float cooler_power, float dt);

// Global IPC handles (needed by signal handler for cleanup)
static HVACSharedState *g_shm_state = NULL;
static sem_t           *g_sem       = NULL;
static MQTTClient       g_mqtt;
static int              g_mqtt_ok   = 0;

// Signal handler — clean up shared memory and MQTT on Ctrl+C or kill
static void handle_signal(int sig) {
    (void)sig;
    printf("\n[HVAC] Shutting down...\n");
    if (g_shm_state) ipc_close_shm(g_shm_state);
    ipc_destroy_shm();
    if (g_sem) ipc_close_sem(g_sem);
    if (g_mqtt_ok) mqtt_disconnect(&g_mqtt);
    exit(0);
}

// NEW: reads GATEWAY_HOST env var, falls back to 127.0.0.1 (same pattern as network.c)
static const char* get_gateway_host(void) {
    const char *env_host = getenv("GATEWAY_HOST");
    if (env_host) {
        printf("[HVAC] Using gateway from environment: %s\n", env_host);
        return env_host;
    }
    return DEFAULT_GATEWAY_HOST;
}

int main(int argc, char *argv[]) {
    printf("\n╔════════════════════════════════════════╗\n");
    printf("║   HVAC Controller Application         ║\n");
    printf("╚════════════════════════════════════════╝\n\n");

    // Parse configuration
    HVACConfig config = parse_hvac_config(argc, argv);

    // Set up signal handler for clean IPC shutdown
    signal(SIGINT,  handle_signal);
    signal(SIGTERM, handle_signal);

    // Initialize IPC — create shared memory and semaphore
    printf("[HVAC] Initializing IPC...\n");
    g_sem = ipc_create_sem();
    if (g_sem == SEM_FAILED) {
        printf("[HVAC] WARNING: Semaphore creation failed, running without IPC\n");
    }
    g_shm_state = ipc_create_shm();
    if (!g_shm_state) {
        printf("[HVAC] WARNING: Shared memory creation failed, running without IPC\n");
    }

    // Connect to gateway
    int sockfd = connect_to_gateway();
    if (sockfd < 0) {
        printf("[HVAC] ✗ Failed to connect to gateway, running without telemetry\n");
        sockfd = -1;  // Continue running even without gateway connection
    }

    // Run control loop
    run_hvac_loop(&config, sockfd);

    // Cleanup
    if (sockfd >= 0) close(sockfd);
    if (g_shm_state) ipc_close_shm(g_shm_state);
    if (g_sem) ipc_close_sem(g_sem);
    if (g_mqtt_ok) mqtt_disconnect(&g_mqtt);
    ipc_destroy_shm();
    return 0;
}

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

    strncpy(config.device_id, argv[1], sizeof(config.device_id) - 1);
    config.device_id[sizeof(config.device_id) - 1] = '\0';

    strncpy(config.zone, argv[2], sizeof(config.zone) - 1);
    config.zone[sizeof(config.zone) - 1] = '\0';

    config.setpoint = (float)atof(argv[3]);

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

/*
 * connect_to_gateway()
 * Opens TCP connection to the gateway.
 * Returns socket fd on success, -1 on failure.
 */
int connect_to_gateway(void) {
    const char *host = get_gateway_host();

    printf("[HVAC] Resolving %s:%d...\n", host, GATEWAY_PORT);

    struct hostent *server = gethostbyname(host);
    if (server == NULL) {
        printf("[HVAC ERROR] Cannot resolve host: %s\n", host);
        return -1;
    }

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("[HVAC ERROR] socket()");
        return -1;
    }

    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port   = htons(GATEWAY_PORT);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr_list[0], server->h_length);

    if (connect(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[HVAC ERROR] connect()");
        close(sockfd);
        return -1;
    }

    printf("[HVAC] ✓ Connected to gateway at %s:%d\n\n", host, GATEWAY_PORT);
    return sockfd;
}

void run_hvac_loop(HVACConfig *config, int sockfd) {
    // Initialize PID controller (Ziegler-Nichols tuned gains)
    PIDController pid;
    pid_init(&pid, config->setpoint, 2.0, 0.5, 1.0);

    // Initialize hardware if needed
    if (config->use_hardware) {
        initialize_hvac_hardware();
    }

    // Initialize MQTT client
    if (mqtt_init(&g_mqtt, config->device_id, config->zone) == 0) {
        if (mqtt_connect(&g_mqtt) == 0) {
            g_mqtt_ok = 1;
            printf("[HVAC] MQTT connected — dual transport active\n");
        } else {
            printf("[HVAC] MQTT unavailable — TCP only\n");
        }
    }

    printf("[HVAC] Starting control loop...\n");
    printf("[HVAC] Setpoint: %.1f°C\n", config->setpoint);
    printf("[HVAC] PID Gains: Kp=%.1f, Ki=%.1f, Kd=%.1f\n", pid.kp, pid.ki, pid.kd);
    printf("[HVAC] Gateway: %s:%d\n", get_gateway_host(), GATEWAY_PORT);
    printf("[HVAC] Protocol: V2 (heater%%, cooler%%, temp, setpoint)\n");
    printf("[HVAC] Press Ctrl+C to stop\n");
    printf("═══════════════════════════════════════════════════════════════\n");

    // Start 5°C below target
    float current_temp  = config->setpoint - 5.0f;
    float heater_power  = 0.0f;
    float cooler_power  = 0.0f;
    int   iteration     = 0;
    float dt            = 1.0f;  // 1 second time step

    while (1) {
        iteration++;

        // Read temperature
        if (config->use_hardware) {
            // Hardware mode (currently simulated)
            // current_temp = read_hardware_temperature();  // Uncomment for real ESP32
            current_temp = simulate_temperature_physics(current_temp, heater_power, cooler_power, dt);
        } else {
            // Simulation mode
            current_temp = simulate_temperature_physics(current_temp, heater_power, cooler_power, dt);
        }

        // Compute PID output
        float pid_output = pid_compute(&pid, current_temp, dt);

        // Determine heating or cooling
        if (current_temp < config->setpoint) {
            // Need heating
            heater_power = pid_output;
            cooler_power = 0.0f;
        } else {
            // Need cooling
            heater_power = 0.0f;
            cooler_power = pid_output;
        }

        // Set actuators
        if (config->use_hardware) {
            // set_heater_power(heater_power);  // Uncomment for real ESP32
            // set_cooler_power(cooler_power);
        }

        // Write state to shared memory (for power_meter to read)
        if (g_shm_state && g_sem != SEM_FAILED) {
            sem_wait(g_sem);                          // lock
            g_shm_state->heater_pct   = heater_power;
            g_shm_state->cooler_pct   = cooler_power;
            g_shm_state->current_temp = current_temp;
            g_shm_state->setpoint     = config->setpoint;
            g_shm_state->timestamp    = (uint32_t)time(NULL);
            g_shm_state->is_valid     = 1;            // mark as ready to read
            sem_post(g_sem);                          // unlock
        }

        // Publish via MQTT
        if (g_mqtt_ok) {
            mqtt_publish_hvac(&g_mqtt, heater_power, cooler_power,
                              current_temp, config->setpoint);
        }

        // Send V2 packet to gateway
        // value1=heater_pct, value2=cooler_pct, value3=current_temp, value4=setpoint
        if (sockfd >= 0) {
            PacketV2 pkt;
            pack_packet_v2(&pkt, config->device_id, PACKET_TYPE_HVAC_STATE,
                           heater_power, cooler_power, current_temp, config->setpoint);

            ssize_t sent = send(sockfd, &pkt, sizeof(PacketV2), 0);
            if (sent < 0) {
                perror("[HVAC ERROR] send()");
                printf("[HVAC] ✗ Gateway connection lost\n");
                sockfd = -1;  // Stop trying to send
            }
        }

        // Display status
        float error = config->setpoint - current_temp;
        printf("[HVAC] #%-4d | Temp:%6.2f°C | Error:%+6.2f°C | Heat:%5.1f%% | Cool:%5.1f%%\n",
               iteration, current_temp, error, heater_power, cooler_power);

        // Stop after reaching steady state (for demo)
        /*if (iteration >= 60) {
            printf("═══════════════════════════════════════════════════════════════\n");
            printf("[HVAC] Demo complete (60 iterations)\n");
            printf("[HVAC] Final temperature: %.2f°C (target: %.1f°C)\n",
                   current_temp, config->setpoint);
            break;
        }
        */
        sleep(1);
    }
}

float simulate_temperature_physics(float current_temp, float heater_power,
                                   float cooler_power, float dt) {
    // Heating effect (heater adds heat)
    float heating_rate = 0.01f;  // °C per second per % power
    float heat_added   = heater_power * heating_rate * dt;

    // Cooling effect (cooler removes heat)
    float cooling_rate = 0.01f;
    float heat_removed = cooler_power * cooling_rate * dt;

    // Natural heat loss (room cools naturally)
    float natural_cooling = 0.02f * dt;  // 0.02°C per second

    // Update temperature
    float new_temp = current_temp + heat_added - heat_removed - natural_cooling;

    return new_temp;
}