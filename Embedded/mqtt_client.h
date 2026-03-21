#ifndef MQTT_CLIENT_H
#define MQTT_CLIENT_H

/*
 * mqtt_client.h - MQTT Client Interface
 *
 * Publishes sensor data to Mosquitto broker alongside existing TCP gateway.
 * This is an additional transport layer — TCP gateway still works unchanged.
 *
 * Topic structure:
 *   energy/<zone>/temperature   — float °C           (temp_sensor)
 *   energy/<zone>/occupancy     — int people count    (occupancy_sensor)
 *   energy/<zone>/hvac          — JSON state          (hvac_controller)
 *   energy/<zone>/power         — JSON power data     (power_meter)
 *
 * Broker: localhost:1883 (local) → mosquitto container (Docker)
 *
 * Library: libmosquitto (apt install libmosquitto-dev)
 * Link:    -lmosquitto
 *
 * Hardware note:
 *   On real ESP32, replace libmosquitto calls with Arduino PubSubClient:
 *   https://github.com/knolleary/pubsubclient
 *   The topic structure and payload format remain identical.
 */

#include <mosquitto.h>
#include <stdint.h>

/* ============================================================
 * MQTT CONFIGURATION
 * ============================================================ */
#define MQTT_HOST           "localhost"   // broker host (Docker: "mosquitto")
#define MQTT_PORT           1883          // default MQTT port
#define MQTT_KEEPALIVE      60            // seconds between pings
#define MQTT_QOS            1             // QoS 1 = at least once delivery
#define MQTT_RETAIN         0             // don't retain last message
#define MQTT_TOPIC_PREFIX   "energy"      // root topic prefix

/* ============================================================
 * MQTT CLIENT STRUCT
 * One instance per sensor process.
 * ============================================================ */
typedef struct {
    struct mosquitto *mosq;         // libmosquitto handle
    char              client_id[32]; // unique client ID (e.g. "temp_sensor_TEMP_A")
    char              zone[16];      // zone name (e.g. "Zone_A" → "zone_a" in topic)
    int               connected;     // 1 = connected, 0 = disconnected
} MQTTClient;

/* ============================================================
 * LIFECYCLE FUNCTIONS
 * ============================================================ */

/**
 * mqtt_init()
 * Initialize libmosquitto and create client instance.
 * Must be called once before any other mqtt_* function.
 *
 * @param client    : pointer to MQTTClient struct to initialize
 * @param client_id : unique identifier (e.g. "temp_sensor_TEMP_A")
 * @param zone      : zone name (e.g. "Zone_A")
 * @return 0 on success, -1 on failure
 */
int mqtt_init(MQTTClient *client, const char *client_id, const char *zone);

/**
 * mqtt_connect()
 * Connect to MQTT broker. Reads MQTT_HOST from MQTT_BROKER_HOST
 * environment variable if set, otherwise uses default.
 *
 * @param client : initialized MQTTClient
 * @return 0 on success, -1 on failure
 */
int mqtt_connect(MQTTClient *client);

/**
 * mqtt_disconnect()
 * Gracefully disconnect from broker and free resources.
 *
 * @param client : connected MQTTClient
 */
void mqtt_disconnect(MQTTClient *client);

/* ============================================================
 * PUBLISH FUNCTIONS (one per sensor type)
 * ============================================================ */

/**
 * mqtt_publish_temperature()
 * Publish temperature reading to energy/<zone>/temperature
 * Payload: plain float as string e.g. "22.16"
 *
 * @param client : connected MQTTClient
 * @param value  : temperature in Celsius
 * @return 0 on success, -1 on failure
 */
int mqtt_publish_temperature(MQTTClient *client, float value);

/**
 * mqtt_publish_occupancy()
 * Publish people count to energy/<zone>/occupancy
 * Payload: integer as string e.g. "3"
 *
 * @param client : connected MQTTClient
 * @param count  : number of people
 * @return 0 on success, -1 on failure
 */
int mqtt_publish_occupancy(MQTTClient *client, int count);

/**
 * mqtt_publish_hvac()
 * Publish HVAC state to energy/<zone>/hvac
 * Payload: JSON e.g. {"heater":31.2,"cooler":0.0,"temp":19.8,"setpoint":20.0}
 *
 * @param client   : connected MQTTClient
 * @param heater   : heater output percentage (0-100)
 * @param cooler   : cooler output percentage (0-100)
 * @param temp     : current temperature
 * @param setpoint : target temperature
 * @return 0 on success, -1 on failure
 */
int mqtt_publish_hvac(MQTTClient *client, float heater, float cooler,
                      float temp, float setpoint);

/**
 * mqtt_publish_power()
 * Publish power data to energy/<zone>/power
 * Payload: JSON e.g. {"power_kw":5.2,"energy_kwh":0.045,"cost_usd":0.005,"hvac_pct":32.0}
 *
 * @param client     : connected MQTTClient
 * @param power_kw   : current power consumption
 * @param energy_kwh : cumulative energy consumed
 * @param cost_usd   : cumulative cost
 * @param hvac_pct   : HVAC load percentage
 * @return 0 on success, -1 on failure
 */
int mqtt_publish_power(MQTTClient *client, float power_kw,
                       float energy_kwh, float cost_usd, float hvac_pct);

#endif