#include "protocol.h"
#include <stdio.h>
#include <string.h>
#include <time.h>

void pack_packet(Packet *pkt, const char *dev_id, float val, uint8_t type) {
    memset(pkt, 0, sizeof(Packet));
    strncpy((char*)pkt->device_id, dev_id, 7);
    pkt->device_id[7] = '\0';
    pkt->timestamp = (uint32_t)time(NULL);
    pkt->value = val;
    pkt->type = type;
    pkt->checksum = calculate_checksum(pkt);
}

uint8_t calculate_checksum(Packet *pkt) {
    uint8_t sum = 0;
    uint8_t *ptr = (uint8_t*)pkt;
    for (int i = 0; i < sizeof(Packet) - 1; i++) {
        sum += ptr[i];
    }
    return sum % 256;
}

int validate_packet(Packet *pkt) {
    uint8_t expected = calculate_checksum(pkt);
    return (expected == pkt->checksum) ? 1 : 0;
}

void print_packet(Packet *pkt) {
    printf("Device: %s, Time: %u, Value: %.2f, Type: %u, Checksum: %u\n",
           pkt->device_id, pkt->timestamp, pkt->value, pkt->type, pkt->checksum);
}