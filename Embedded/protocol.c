/*
 * protocol.c - Binary Packet Protocol Implementation
 *
 * Supports two packet versions:
 *   V1 (20 bytes) — single float value, used by temp/occupancy/power sensors
 *   V2 (32 bytes) — four float values, used by hvac_controller
 *
 * Packet types:
 *   0 = TEMP        (V1) temperature_sensor
 *   1 = POWER       (V1) power_meter
 *   2 = CONTROL     (V1) reserved
 *   3 = OCCUPANCY   (V1) occupancy_sensor
 *   4 = HVAC_STATE  (V2) hvac_controller
 *   5 = HVAC_TEMP   (V2) reserved
 */

#include "protocol.h"
#include <stdio.h>
#include <string.h>
#include <time.h>

static const char* get_type_name(uint8_t type) {
    switch (type) {
        case PACKET_TYPE_TEMP:       return "TEMP";
        case PACKET_TYPE_POWER:      return "POWER";
        case PACKET_TYPE_CONTROL:    return "CONTROL";
        case PACKET_TYPE_OCCUPANCY:  return "OCCUPANCY";
        case PACKET_TYPE_HVAC_STATE: return "HVAC_STATE";
        case PACKET_TYPE_HVAC_TEMP:  return "HVAC_TEMP";
        default:                     return "UNKNOWN";
    }
}

void pack_packet(Packet *pkt, const char *dev_id, float val, uint8_t type) {
    memset(pkt, 0, sizeof(Packet));
    strncpy((char*)pkt->device_id, dev_id, 7);
    pkt->device_id[7] = '\0';
    pkt->timestamp = (uint32_t)time(NULL);
    pkt->value     = val;
    pkt->type      = type;
    pkt->checksum  = calculate_checksum(pkt);
}

uint8_t calculate_checksum(Packet *pkt) {
    uint8_t sum = 0;
    uint8_t *ptr = (uint8_t*)pkt;
    for (int i = 0; i < (int)sizeof(Packet) - 1; i++) {
        sum += ptr[i];
    }
    return sum % 256;
}

int validate_packet(Packet *pkt) {
    uint8_t expected = calculate_checksum(pkt);
    return (expected == pkt->checksum) ? 1 : 0;
}

void print_packet(Packet *pkt) {
    printf("[PROTOCOL V1] Device: %-8s | Time: %10u | Value: %8.2f | Type: %-10s | Checksum: %3u\n",
           pkt->device_id, pkt->timestamp, pkt->value,
           get_type_name(pkt->type), pkt->checksum);
}

void pack_packet_v2(PacketV2 *pkt, const char *dev_id, uint8_t type,
                    float v1, float v2, float v3, float v4) {
    memset(pkt, 0, sizeof(PacketV2));
    strncpy((char*)pkt->device_id, dev_id, 7);
    pkt->device_id[7] = '\0';
    pkt->timestamp = (uint32_t)time(NULL);
    pkt->type      = type;
    pkt->version   = PROTOCOL_V2;
    pkt->value1    = v1;
    pkt->value2    = v2;
    pkt->value3    = v3;
    pkt->value4    = v4;
}

void print_packet_v2(PacketV2 *pkt) {
    printf("[PROTOCOL V2] Device: %-8s | Time: %10u | Type: %-10s | "
           "V1: %7.2f | V2: %7.2f | V3: %7.2f | V4: %7.2f\n",
           pkt->device_id, pkt->timestamp, get_type_name(pkt->type),
           pkt->value1, pkt->value2, pkt->value3, pkt->value4);
}
