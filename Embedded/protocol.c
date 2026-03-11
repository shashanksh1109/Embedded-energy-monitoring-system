/*
 * protocol.c - Binary Packet Protocol Implementation
 *
 * Handles packing, checksum calculation, validation and printing
 * of the 20-byte binary packets used across all sensor types.
 *
 * Packet types supported:
 *   0 = TEMP        (temperature_sensor)
 *   1 = POWER       (power_meter)
 *   2 = CONTROL     (reserved)
 *   3 = OCCUPANCY   (occupancy_sensor)
 *   4 = HVAC_STATE  (hvac_controller)
 */

#include "protocol.h"
#include <stdio.h>
#include <string.h>
#include <time.h>

/* ============================================================
 * PACKET TYPE NAMES
 * Used for human-readable debug output in print_packet()
 * ============================================================ */
static const char* get_type_name(uint8_t type) {
    switch (type) {
        case PACKET_TYPE_TEMP:       return "TEMP";
        case PACKET_TYPE_POWER:      return "POWER";
        case PACKET_TYPE_CONTROL:    return "CONTROL";
        case PACKET_TYPE_OCCUPANCY:  return "OCCUPANCY";
        case PACKET_TYPE_HVAC_STATE: return "HVAC_STATE";
        default:                     return "UNKNOWN";
    }
}

/* ============================================================
 * pack_packet()
 * Fill a Packet struct with sensor data and compute checksum.
 * Call this before sending any data to the gateway.
 * ============================================================ */
void pack_packet(Packet *pkt, const char *dev_id, float val, uint8_t type) {
    memset(pkt, 0, sizeof(Packet));

    // Copy device ID (max 7 chars + null terminator)
    strncpy((char*)pkt->device_id, dev_id, 7);
    pkt->device_id[7] = '\0';

    pkt->timestamp = (uint32_t)time(NULL);
    pkt->value     = val;
    pkt->type      = type;
    pkt->checksum  = calculate_checksum(pkt);
}

/* ============================================================
 * calculate_checksum()
 * Sum bytes 0-16 of the packet, modulo 256.
 * Stored at byte 17 (checksum field).
 * ============================================================ */
uint8_t calculate_checksum(Packet *pkt) {
    uint8_t sum = 0;
    uint8_t *ptr = (uint8_t*)pkt;

    // Sum all bytes except the checksum field itself (byte 17)
    for (int i = 0; i < sizeof(Packet) - 1; i++) {
        sum += ptr[i];
    }
    return sum % 256;
}

/* ============================================================
 * validate_packet()
 * Recalculate checksum and compare against stored value.
 * Returns 1 if valid, 0 if corrupted.
 * ============================================================ */
int validate_packet(Packet *pkt) {
    uint8_t expected = calculate_checksum(pkt);
    return (expected == pkt->checksum) ? 1 : 0;
}

/* ============================================================
 * print_packet()
 * Print packet fields to stdout for debugging.
 * ============================================================ */
void print_packet(Packet *pkt) {
    printf("[PROTOCOL] Device: %-8s | Time: %10u | Value: %8.2f | Type: %-10s | Checksum: %3u\n",
           pkt->device_id,
           pkt->timestamp,
           pkt->value,
           get_type_name(pkt->type),
           pkt->checksum);
}