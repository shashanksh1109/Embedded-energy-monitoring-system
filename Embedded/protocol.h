#ifndef PROTOCOL_H
#define PROTOCOL_H

#include <stdint.h>

typedef struct {
    uint8_t device_id[8];
    uint32_t timestamp;
    float value;
    uint8_t type;
    uint8_t checksum;
} Packet;

void pack_packet(Packet *pkt, const char *dev_id, float val, uint8_t type);
int validate_packet(Packet *pkt);
uint8_t calculate_checksum(Packet *pkt);
void print_packet(Packet *pkt);

#endif