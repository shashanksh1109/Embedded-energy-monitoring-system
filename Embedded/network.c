/*
 * network.c - Network communication implementation
 * 
 * All networking functions grouped here:
 * - Socket creation
 * - Connection establishment
 * - Data transmission
 */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "network.h"

#define GATEWAY_HOST "127.0.0.1"
#define GATEWAY_PORT 8080

// Internal helper functions (private to this file)
static int create_tcp_socket(void) {
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("[NETWORK ERROR] socket()");
        return -1;
    }
    printf("[NETWORK] ✓ Socket created (fd=%d)\n", sockfd);
    return sockfd;
}

static int connect_to_server(int sockfd) {
    struct sockaddr_in server_addr;
    
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(GATEWAY_PORT);
    
    if (inet_pton(AF_INET, GATEWAY_HOST, &server_addr.sin_addr) <= 0) {
        perror("[NETWORK ERROR] inet_pton()");
        return -1;
    }
    
    printf("[NETWORK] Connecting to %s:%d...\n", GATEWAY_HOST, GATEWAY_PORT);
    
    if (connect(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[NETWORK ERROR] connect()");
        return -1;
    }
    
    printf("[NETWORK] ✓ Connected to gateway\n");
    return 0;
}

// Public functions (declared in network.h)

NetworkConnection initialize_network(void) {
    NetworkConnection conn;
    conn.is_connected = 0;
    conn.socket_fd = -1;
    
    // Step 1: Create socket
    conn.socket_fd = create_tcp_socket();
    if (conn.socket_fd < 0) {
        return conn;
    }
    
    // Step 2: Connect
    if (connect_to_server(conn.socket_fd) < 0) {
        close(conn.socket_fd);
        return conn;
    }
    
    conn.is_connected = 1;
    return conn;
}

int send_packet_to_gateway(NetworkConnection *conn, Packet *pkt) {
    ssize_t bytes_sent = send(conn->socket_fd, pkt, sizeof(Packet), 0);
    
    if (bytes_sent < 0) {
        perror("[NETWORK ERROR] send()");
        return -1;
    }
    
    if (bytes_sent != sizeof(Packet)) {
        printf("[NETWORK ERROR] Partial send: %zd/%zu bytes\n", 
               bytes_sent, sizeof(Packet));
        return -1;
    }
    
    return 0;
}

void cleanup_network(NetworkConnection *conn) {
    if (conn->is_connected && conn->socket_fd >= 0) {
        close(conn->socket_fd);
        printf("[NETWORK] ✓ Connection closed\n");
        conn->is_connected = 0;
    }
}