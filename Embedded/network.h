#ifndef NETWORK_H
#define NETWORK_H

/*
 * network.h - Network communication
 * 
 * Handles:
 * - TCP socket creation
 * - Connection management
 * - Data transmission
 */

#include "protocol.h"

typedef struct {
    int socket_fd;
    int is_connected;
} NetworkConnection;

// Network functions
NetworkConnection initialize_network(void);
int send_packet_to_gateway(NetworkConnection *conn, Packet *pkt);
void cleanup_network(NetworkConnection *conn);

#endif