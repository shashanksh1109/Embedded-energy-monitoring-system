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
#define RECONNECT_MAX_SEC 30   // longest wait between reconnect attempts

/*
 * Dead band (hysteresis) around the setpoint, in degrees C.
 *
 * Without it, the controller switched between heating and cooling every
 * second, because the temperature was always slightly above or below the
 * exact setpoint. Now:
 *   - start HEATING only when temp < setpoint - HVAC_DEADBAND_C
 *   - start COOLING only when temp > setpoint + HVAC_DEADBAND_C
 *   - stop (go IDLE) once the temperature reaches the setpoint
 * Inside the band, the controller rests.
 */
#define HVAC_DEADBAND_C 0.5f

typedef enum { HVAC_IDLE, HVAC_HEATING, HVAC_COOLING } HVACMode;

static const char *hvac_mode_name(HVACMode m) {
    return m == HVAC_HEATING ? "HEAT" : (m == HVAC_COOLING ? "COOL" : "IDLE");
}

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
        printf("[HVAC] ✗ Gateway not reachable yet, will keep retrying\n");
        sockfd = -1;  // The control loop keeps running and reconnects later
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
    // Two PID controllers, one per direction. pid_compute() only returns
    // 0..100 for "how far BELOW the setpoint", so cooling uses a mirrored
    // setpoint: error = (-setpoint) - (-temp) = temp - setpoint.
    // Each one is reset when its mode starts, so heating's accumulated
    // integral can never leak into cooling (and vice versa).
    PIDController pid;          // heating
    PIDController pid_cool;     // cooling
    pid_init(&pid,      config->setpoint,  2.0, 0.5, 1.0);
    pid_init(&pid_cool, -config->setpoint, 2.0, 0.5, 1.0);
    HVACMode mode = HVAC_IDLE;

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
    printf("[HVAC] Dead band: +/-%.1f°C around the setpoint\n", HVAC_DEADBAND_C);
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

    // Reconnect state (see the send section below)
    time_t next_retry   = 0;     // earliest time to try connecting again
    int    retry_delay  = 1;     // seconds; doubles after each failed attempt

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

        // Choose the mode with hysteresis (see HVAC_DEADBAND_C)
        if (mode != HVAC_HEATING && current_temp < config->setpoint - HVAC_DEADBAND_C) {
            mode = HVAC_HEATING;
            pid_reset(&pid);
        } else if (mode != HVAC_COOLING && current_temp > config->setpoint + HVAC_DEADBAND_C) {
            mode = HVAC_COOLING;
            pid_reset(&pid_cool);
        } else if (mode == HVAC_HEATING && current_temp >= config->setpoint) {
            mode = HVAC_IDLE;                       // reached target: rest
        } else if (mode == HVAC_COOLING && current_temp <= config->setpoint) {
            mode = HVAC_IDLE;
        }

        // Compute the output for the active mode only
        if (mode == HVAC_HEATING) {
            heater_power = pid_compute(&pid, current_temp, dt);
            cooler_power = 0.0f;
        } else if (mode == HVAC_COOLING) {
            heater_power = 0.0f;
            cooler_power = pid_compute(&pid_cool, -current_temp, dt);
        } else {
            heater_power = 0.0f;
            cooler_power = 0.0f;
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

        // (Re)connect to the gateway if we are not connected.
        // Retries back off 1s, 2s, 4s ... up to RECONNECT_MAX_SEC, so a
        // gateway restart no longer silences this controller forever.
        if (sockfd < 0 && time(NULL) >= next_retry) {
            sockfd = connect_to_gateway();
            if (sockfd >= 0) {
                retry_delay = 1;                       // reset after success
            } else {
                next_retry  = time(NULL) + retry_delay;
                retry_delay = (retry_delay * 2 > RECONNECT_MAX_SEC)
                              ? RECONNECT_MAX_SEC : retry_delay * 2;
            }
        }

        // Send V2 packet to gateway
        // value1=heater_pct, value2=cooler_pct, value3=current_temp, value4=setpoint
        if (sockfd >= 0) {
            PacketV2 pkt;
            pack_packet_v2(&pkt, config->device_id, PACKET_TYPE_HVAC_STATE,
                           heater_power, cooler_power, current_temp, config->setpoint);

            // MSG_NOSIGNAL: if the gateway has gone away, return an error
            // instead of raising SIGPIPE (which would kill the process).
            ssize_t sent = send(sockfd, &pkt, sizeof(PacketV2), MSG_NOSIGNAL);
            if (sent != (ssize_t)sizeof(PacketV2)) {
                perror("[HVAC ERROR] send()");
                printf("[HVAC] ✗ Gateway connection lost, will reconnect\n");
                close(sockfd);
                sockfd     = -1;
                next_retry = time(NULL) + retry_delay;
            }
        }

        // Display status
        float error = config->setpoint - current_temp;
        printf("[HVAC] #%-4d | %s | Temp:%6.2f°C | Error:%+6.2f°C | Heat:%5.1f%% | Cool:%5.1f%%\n",
               iteration, hvac_mode_name(mode), current_temp, error, heater_power, cooler_power);

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