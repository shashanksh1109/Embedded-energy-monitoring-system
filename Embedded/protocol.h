#ifndef PROTOCOL_H
#define PROTOCOL_H

#include <stdint.h>

/*
 * protocol.h - Binary Packet Protocol
 *
 * Two packet versions supported:
 *
 * V1 - 20 bytes (legacy, used by temp_sensor, occupancy_sensor, power_meter)
 * ─────────────────────────────────────────────────────────────────
 *  [0-7]   device_id  : 8-byte null-terminated string
 *  [8-11]  timestamp  : uint32 Unix epoch
 *  [12-15] value      : float (single value)
 *  [16]    type       : uint8 packet type
 *  [17]    checksum   : uint8 = sum(bytes[0:17]) % 256
 *  [18-19] padding    : 2 bytes alignment
 *
 * V2 - 32 bytes (extended, used by hvac_controller)
 * ─────────────────────────────────────────────────────────────────
 *  [0-7]   device_id  : 8-byte null-terminated string
 *  [8-11]  timestamp  : uint32 Unix epoch
 *  [12]    type       : uint8 packet type
 *  [13]    version    : uint8 protocol version (2)
 *  [14-15] padding    : 2 bytes alignment
 *  [16-19] value1     : float (primary value)
 *  [20-23] value2     : float (secondary value)
 *  [24-27] value3     : float (tertiary value)
 *  [28-31] value4     : float (quaternary value)
 *  Note: checksum not used in V2 (version field serves as integrity marker)
 */

/* ============================================================
 * PROTOCOL VERSIONS
 * ============================================================ */
#define PROTOCOL_V1  1    // Legacy single-value packet
#define PROTOCOL_V2  2    // Extended multi-value packet

/* ============================================================
 * V1 PACKET STRUCT (20 bytes)
 * Used by: temp_sensor, occupancy_sensor, power_meter
 * ============================================================ */
typedef struct {
    uint8_t  device_id[8];   // Sensor identifier (null-terminated)
    uint32_t timestamp;      // Unix epoch timestamp
    float    value;          // Single sensor reading
    uint8_t  type;           // Packet type (PACKET_TYPE_*)
    uint8_t  checksum;       // sum(bytes[0:17]) % 256
} Packet;

/* ============================================================
 * V2 PACKET STRUCT (32 bytes)
 * Used by: hvac_controller
 * ============================================================ */
typedef struct {
    uint8_t  device_id[8];   // Sensor identifier (null-terminated)
    uint32_t timestamp;      // Unix epoch timestamp
    uint8_t  type;           // Packet type (PACKET_TYPE_*)
    uint8_t  version;        // Protocol version = PROTOCOL_V2
    uint8_t  padding[2];     // Alignment padding
    float    value1;         // Primary value   (meaning depends on type)
    float    value2;         // Secondary value (meaning depends on type)
    float    value3;         // Tertiary value  (meaning depends on type)
    float    value4;         // Quaternary value (meaning depends on type)
} PacketV2;

/*
 * V2 value field mapping per packet type:
 *
 * PACKET_TYPE_HVAC_STATE (4):
 *   value1 = heater_pct   (0-100%)
 *   value2 = cooler_pct   (0-100%)
 *   value3 = current_temp (°C)
 *   value4 = setpoint     (°C)
 *
 * PACKET_TYPE_HVAC_TEMP (5):  (reserved for future use)
 *   value1 = current_temp (°C)
 *   value2 = setpoint     (°C)
 *   value3 = 0.0
 *   value4 = 0.0
 */

/* ============================================================
 * PACKET TYPE CONSTANTS
 * Both V1 and V2 packets use the same type field.
 * ============================================================ */
#define PACKET_TYPE_TEMP       0   // V1 — Temperature reading (°C)
#define PACKET_TYPE_POWER      1   // V1 — Power consumption (kW)
#define PACKET_TYPE_CONTROL    2   // V1 — Generic control signal (%) reserved
#define PACKET_TYPE_OCCUPANCY  3   // V1 — People count (integer as float)
#define PACKET_TYPE_HVAC_STATE 4   // V2 — HVAC full state (heater%, cooler%, temp, setpoint)
#define PACKET_TYPE_HVAC_TEMP  5   // V2 — Reserved for future HVAC temp extension

/* ============================================================
 * V1 PROTOCOL FUNCTIONS
 * ============================================================ */

// Pack a V1 packet
void pack_packet(Packet *pkt, const char *dev_id, float val, uint8_t type);

// Validate V1 packet checksum
int validate_packet(Packet *pkt);

// Calculate V1 checksum
uint8_t calculate_checksum(Packet *pkt);

// Print V1 packet contents (debug)
void print_packet(Packet *pkt);

/* ============================================================
 * V2 PROTOCOL FUNCTIONS
 * ============================================================ */

// Pack a V2 packet with 4 float values
void pack_packet_v2(PacketV2 *pkt, const char *dev_id, uint8_t type,
                    float v1, float v2, float v3, float v4);

// Print V2 packet contents (debug)
void print_packet_v2(PacketV2 *pkt);

#endif