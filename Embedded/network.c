/*
 * network.c - Network communication implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "network.h"

#define DEFAULT_GATEWAY_HOST "127.0.0.1"
#define GATEWAY_PORT 8080

static const char* get_gateway_host(void) {
    const char* env_host = getenv("GATEWAY_HOST");
    if (env_host) {
        printf("[NETWORK] Using gateway from environment: %s\n", env_host);
        return env_host;
    }
    return DEFAULT_GATEWAY_HOST;
}

static int create_tcp_socket(void) {
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("[NETWORK ERROR] socket()");
        return -1;
    }
    printf("[NETWORK] Socket created (fd=%d)\n", sockfd);
    return sockfd;
}

static int connect_to_server(int sockfd) {
    const char* gateway_host = get_gateway_host();
    struct sockaddr_in server_addr;
    struct hostent *server;
    
    printf("[NETWORK] Resolving %s:%d...\n", gateway_host, GATEWAY_PORT);
    
    server = gethostbyname(gateway_host);
    if (server == NULL) {
        printf("[NETWORK ERROR] Cannot resolve %s\n", gateway_host);
        return -1;
    }
    
    char *ip_addr = inet_ntoa(*((struct in_addr *)server->h_addr_list[0]));
    printf("[NETWORK] Resolved to IP: %s\n", ip_addr);
    
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(GATEWAY_PORT);
    memcpy(&server_addr.sin_addr.s_addr, server->h_addr_list[0], server->h_length);
    
    printf("[NETWORK] Connecting to %s...\n", ip_addr);
    
    if (connect(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("[NETWORK ERROR] connect()");
        return -1;
    }
    
    printf("[NETWORK] Connected to gateway\n");
    return 0;
}

NetworkConnection initialize_network(void) {
    NetworkConnection conn;
    conn.is_connected = 0;
    conn.socket_fd = -1;
    
    conn.socket_fd = create_tcp_socket();
    if (conn.socket_fd < 0) {
        return conn;
    }
    
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
        printf("[NETWORK] Connection closed\n");
        conn->is_connected = 0;
    }
}