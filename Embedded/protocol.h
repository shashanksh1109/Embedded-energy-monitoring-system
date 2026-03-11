#ifndef PROTOCOL_H
#define PROTOCOL_H

#include <stdint.h>

/*
 * protocol.h - Binary Packet Protocol
 *
 * Defines the 20-byte packet structure used for all sensor communication.
 * Packet format: =8sIfBB (no padding, cross-platform)
 *
 * Byte layout:
 *  [0-7]  device_id  : 8-byte null-terminated string
 *  [8-11] timestamp  : uint32 Unix epoch
 *  [12-15] value     : float (temperature °C, power kW, occupancy count, etc.)
 *  [16]   type       : uint8 packet type (see PACKET_TYPE_* below)
 *  [17]   checksum   : uint8 = sum(bytes[0:17]) % 256
 *  [18-19] padding   : 2 bytes for alignment
 */

typedef struct {
    uint8_t  device_id[8];   // Sensor/device identifier (null-terminated)
    uint32_t timestamp;      // Unix epoch timestamp
    float    value;          // Sensor reading (meaning depends on packet type)
    uint8_t  type;           // Packet type (see PACKET_TYPE_* below)
    uint8_t  checksum;       // Checksum = sum(bytes[0:17]) % 256
} Packet;

/* ============================================================
 * PACKET TYPES
 * Used to identify the kind of data carried in the packet.
 * Both C sensors and Python gateway must stay in sync.
 * ============================================================ */
#define PACKET_TYPE_TEMP       0   // Temperature reading (°C)         — temp_sensor
#define PACKET_TYPE_POWER      1   // Power consumption (kW)           — power_meter
#define PACKET_TYPE_CONTROL    2   // Generic control signal (%)       — reserved
#define PACKET_TYPE_OCCUPANCY  3   // People count (integer as float)  — occupancy_sensor
#define PACKET_TYPE_HVAC_STATE 4   // HVAC output state (heater/cooler %) — hvac_controller

/* ============================================================
 * PROTOCOL FUNCTIONS
 * ============================================================ */

// Pack sensor reading into a binary packet
void pack_packet(Packet *pkt, const char *dev_id, float val, uint8_t type);

// Validate packet integrity via checksum
int validate_packet(Packet *pkt);

// Calculate checksum for a packet (sum of bytes 0-16, mod 256)
uint8_t calculate_checksum(Packet *pkt);

// Print packet contents to stdout (for debugging)
void print_packet(Packet *pkt);

#endif