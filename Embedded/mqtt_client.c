/*
 * mqtt_client.c - MQTT Client Implementation
 *
 * Publishes sensor data to Mosquitto broker using libmosquitto.
 * Runs alongside existing TCP gateway — both transports active simultaneously.
 *
 * ESP32 hardware note:
 *   Replace mosquitto_* calls with PubSubClient equivalents:
 *   client.publish(topic, payload) → mqtt_publish_*()
 *   client.connect(broker_ip)      → mqtt_connect()
 *   client.loop()                  → mosquitto_loop()
 */

#define _POSIX_C_SOURCE 200809L

#include "mqtt_client.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* ============================================================
 * INTERNAL HELPERS
 * ============================================================ */

/*
 * get_broker_host()
 * Reads MQTT_BROKER_HOST env var, falls back to MQTT_HOST ("localhost").
 * In Docker: set MQTT_BROKER_HOST=mosquitto (service name).
 */
static const char* get_broker_host(void) {
    const char *env = getenv("MQTT_BROKER_HOST");
    if (env) {
        printf("[MQTT] Using broker from environment: %s\n", env);
        return env;
    }
    return MQTT_HOST;
}

/*
 * build_topic()
 * Builds a full topic string from zone and subtopic.
 * e.g. zone="Zone_A", sub="temperature" → "energy/zone_a/temperature"
 * Zone name is lowercased and spaces replaced with underscores.
 */
static void build_topic(const char *zone, const char *subtopic,
                         char *buf, size_t buflen) {
    // Lowercase the zone name for topic
    char zone_lower[32] = {0};
    size_t i;
    for (i = 0; i < strlen(zone) && i < sizeof(zone_lower) - 1; i++) {
        char c = zone[i];
        // Replace spaces with underscores, lowercase letters
        if (c == ' ') zone_lower[i] = '_';
        else if (c >= 'A' && c <= 'Z') zone_lower[i] = c + 32;
        else zone_lower[i] = c;
    }
    snprintf(buf, buflen, "%s/%s/%s", MQTT_TOPIC_PREFIX, zone_lower, subtopic);
}

/*
 * on_connect()
 * Callback fired when broker connection is established or fails.
 * rc=0 means success, non-zero means failure.
 */
static void on_connect(struct mosquitto *mosq, void *userdata, int rc) {
    MQTTClient *client = (MQTTClient*)userdata;
    (void)mosq;

    if (rc == 0) {
        client->connected = 1;
        printf("[MQTT] Connected to broker (client: %s)\n", client->client_id);
    } else {
        client->connected = 0;
        printf("[MQTT ERROR] Connection failed (rc=%d): %s\n",
               rc, mosquitto_connack_string(rc));
    }
}

/*
 * on_disconnect()
 * Callback fired when connection to broker is lost.
 */
static void on_disconnect(struct mosquitto *mosq, void *userdata, int rc) {
    MQTTClient *client = (MQTTClient*)userdata;
    (void)mosq;

    client->connected = 0;
    if (rc != 0) {
        printf("[MQTT] Unexpected disconnect (rc=%d), will retry...\n", rc);
    }
}

/*
 * on_publish()
 * Callback fired when a message is successfully published.
 * mid = message ID assigned by broker.
 */
static void on_publish(struct mosquitto *mosq, void *userdata, int mid) {
    (void)mosq;
    (void)userdata;
    (void)mid;
    // Uncomment for verbose publish confirmation:
    // printf("[MQTT] Message published (mid=%d)\n", mid);
}

/* ============================================================
 * LIFECYCLE FUNCTIONS
 * ============================================================ */

/*
 * mqtt_init()
 * Initialize libmosquitto library and create client instance.
 * Sets up callbacks for connect, disconnect, and publish events.
 */
int mqtt_init(MQTTClient *client, const char *client_id, const char *zone) {
    // Initialize libmosquitto (only needs to be done once globally)
    mosquitto_lib_init();

    // Store client metadata
    strncpy(client->client_id, client_id, sizeof(client->client_id) - 1);
    client->client_id[sizeof(client->client_id) - 1] = '\0';
    strncpy(client->zone, zone, sizeof(client->zone) - 1);
    client->zone[sizeof(client->zone) - 1] = '\0';
    client->connected = 0;

    // Create mosquitto instance
    // true = clean session (no persistent state on broker)
    client->mosq = mosquitto_new(client_id, true, client);
    if (!client->mosq) {
        printf("[MQTT ERROR] mosquitto_new() failed — out of memory\n");
        return -1;
    }

    // Register callbacks
    mosquitto_connect_callback_set(client->mosq, on_connect);
    mosquitto_disconnect_callback_set(client->mosq, on_disconnect);
    mosquitto_publish_callback_set(client->mosq, on_publish);

    printf("[MQTT] Client initialized (id: %s, zone: %s)\n",
           client->client_id, client->zone);
    return 0;
}

/*
 * mqtt_connect()
 * Connect to MQTT broker. Non-blocking — uses mosquitto_loop_start()
 * to handle network I/O in a background thread.
 */
int mqtt_connect(MQTTClient *client) {
    const char *host = get_broker_host();

    printf("[MQTT] Connecting to broker at %s:%d...\n", host, MQTT_PORT);

    int rc = mosquitto_connect(client->mosq, host, MQTT_PORT, MQTT_KEEPALIVE);
    if (rc != MOSQ_ERR_SUCCESS) {
        printf("[MQTT ERROR] mosquitto_connect() failed: %s\n",
               mosquitto_strerror(rc));
        return -1;
    }

    // Start background network thread (handles reconnects, pings, ACKs)
    rc = mosquitto_loop_start(client->mosq);
    if (rc != MOSQ_ERR_SUCCESS) {
        printf("[MQTT ERROR] mosquitto_loop_start() failed: %s\n",
               mosquitto_strerror(rc));
        return -1;
    }

    // Wait briefly for connection to establish
    int retries = 5;
    while (!client->connected && retries-- > 0) {
        sleep(1);
    }

    if (!client->connected) {
        printf("[MQTT WARNING] Could not connect to broker — running without MQTT\n");
        return -1;
    }

    return 0;
}

/*
 * mqtt_disconnect()
 * Stop background thread, disconnect from broker, free resources.
 */
void mqtt_disconnect(MQTTClient *client) {
    if (client->mosq) {
        mosquitto_loop_stop(client->mosq, true);
        mosquitto_disconnect(client->mosq);
        mosquitto_destroy(client->mosq);
        client->mosq = NULL;
        client->connected = 0;
    }
    mosquitto_lib_cleanup();
    printf("[MQTT] Disconnected and cleaned up\n");
}

/* ============================================================
 * PUBLISH FUNCTIONS
 * ============================================================ */

/*
 * mqtt_publish_temperature()
 * Topic:   energy/<zone>/temperature
 * Payload: "22.16" (plain float string)
 */
int mqtt_publish_temperature(MQTTClient *client, float value) {
    if (!client->connected) return -1;

    char topic[64];
    char payload[32];

    build_topic(client->zone, "temperature", topic, sizeof(topic));
    snprintf(payload, sizeof(payload), "%.2f", value);

    int rc = mosquitto_publish(client->mosq, NULL, topic,
                                (int)strlen(payload), payload,
                                MQTT_QOS, MQTT_RETAIN);
    if (rc != MOSQ_ERR_SUCCESS) {
        printf("[MQTT ERROR] publish temperature failed: %s\n",
               mosquitto_strerror(rc));
        return -1;
    }

    printf("[MQTT] Published → %s : %s°C\n", topic, payload);
    return 0;
}

/*
 * mqtt_publish_occupancy()
 * Topic:   energy/<zone>/occupancy
 * Payload: "3" (integer as string)
 */
int mqtt_publish_occupancy(MQTTClient *client, int count) {
    if (!client->connected) return -1;

    char topic[64];
    char payload[16];

    build_topic(client->zone, "occupancy", topic, sizeof(topic));
    snprintf(payload, sizeof(payload), "%d", count);

    int rc = mosquitto_publish(client->mosq, NULL, topic,
                                (int)strlen(payload), payload,
                                MQTT_QOS, MQTT_RETAIN);
    if (rc != MOSQ_ERR_SUCCESS) {
        printf("[MQTT ERROR] publish occupancy failed: %s\n",
               mosquitto_strerror(rc));
        return -1;
    }

    printf("[MQTT] Published → %s : %s people\n", topic, payload);
    return 0;
}

/*
 * mqtt_publish_hvac()
 * Topic:   energy/<zone>/hvac
 * Payload: {"heater":31.2,"cooler":0.0,"temp":19.8,"setpoint":20.0}
 */
int mqtt_publish_hvac(MQTTClient *client, float heater, float cooler,
                      float temp, float setpoint) {
    if (!client->connected) return -1;

    char topic[64];
    char payload[128];

    build_topic(client->zone, "hvac", topic, sizeof(topic));
    snprintf(payload, sizeof(payload),
             "{\"heater\":%.1f,\"cooler\":%.1f,\"temp\":%.2f,\"setpoint\":%.1f}",
             heater, cooler, temp, setpoint);

    int rc = mosquitto_publish(client->mosq, NULL, topic,
                                (int)strlen(payload), payload,
                                MQTT_QOS, MQTT_RETAIN);
    if (rc != MOSQ_ERR_SUCCESS) {
        printf("[MQTT ERROR] publish hvac failed: %s\n",
               mosquitto_strerror(rc));
        return -1;
    }

    printf("[MQTT] Published → %s : %s\n", topic, payload);
    return 0;
}

/*
 * mqtt_publish_power()
 * Topic:   energy/<zone>/power
 * Payload: {"power_kw":5.2,"energy_kwh":0.045,"cost_usd":0.005,"hvac_pct":32.0}
 */
int mqtt_publish_power(MQTTClient *client, float power_kw,
                       float energy_kwh, float cost_usd, float hvac_pct) {
    if (!client->connected) return -1;

    char topic[64];
    char payload[128];

    build_topic(client->zone, "power", topic, sizeof(topic));
    snprintf(payload, sizeof(payload),
             "{\"power_kw\":%.2f,\"energy_kwh\":%.4f,\"cost_usd\":%.4f,\"hvac_pct\":%.1f}",
             power_kw, energy_kwh, cost_usd, hvac_pct);

    int rc = mosquitto_publish(client->mosq, NULL, topic,
                                (int)strlen(payload), payload,
                                MQTT_QOS, MQTT_RETAIN);
    if (rc != MOSQ_ERR_SUCCESS) {
        printf("[MQTT ERROR] publish power failed: %s\n",
               mosquitto_strerror(rc));
        return -1;
    }

    printf("[MQTT] Published → %s : %s\n", topic, payload);
    return 0;
}