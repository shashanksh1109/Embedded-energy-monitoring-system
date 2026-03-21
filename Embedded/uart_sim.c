#define _POSIX_C_SOURCE 200809L

#include "uart_sim.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>

static void build_fifo_path(const char *zone, char *buf, size_t buflen) {
    char zone_lower[32] = {0};
    size_t i;
    for (i = 0; i < strlen(zone) && i < sizeof(zone_lower) - 1; i++) {
        char c = zone[i];
        if (c == ' ')                   zone_lower[i] = '_';
        else if (c >= 'A' && c <= 'Z') zone_lower[i] = c + 32;
        else                            zone_lower[i] = c;
    }
    snprintf(buf, buflen, "%s/uart_%s", UART_FIFO_DIR, zone_lower);
}

int uart_open_write(UARTHandle *handle, const char *zone) {
    memset(handle, 0, sizeof(UARTHandle));
    build_fifo_path(zone, handle->path, sizeof(handle->path));

    if (mkfifo(handle->path, 0666) < 0 && errno != EEXIST) {
        printf("[UART ERROR] mkfifo(%s) failed: %s\n", handle->path, strerror(errno));
        return -1;
    }

    handle->fd = open(handle->path, O_WRONLY | O_NONBLOCK);
    if (handle->fd < 0) {
        if (errno == ENXIO) {
            printf("[UART] No reader connected yet on %s\n", handle->path);
            printf("[UART] Start uart_reader.py to receive UART data\n");
            handle->is_open = 0;
            return 0;
        }
        printf("[UART ERROR] open(write) %s failed: %s\n", handle->path, strerror(errno));
        return -1;
    }

    handle->is_open = 1;
    printf("[UART] FIFO opened for writing: %s (baud: %d)\n", handle->path, UART_BAUD_RATE);
    return 0;
}

int uart_write(UARTHandle *handle, const uint8_t *data, size_t length) {
    if (!handle->is_open || handle->fd < 0) return 0;

    uint8_t marker[UART_START_SIZE] = {UART_START_BYTE1, UART_START_BYTE2};
    ssize_t written = write(handle->fd, marker, UART_START_SIZE);
    if (written < 0) {
        if (errno == EPIPE || errno == EAGAIN) return 0;
        printf("[UART ERROR] write(marker) failed: %s\n", strerror(errno));
        return -1;
    }

    written = write(handle->fd, data, length);
    if (written < 0) {
        if (errno == EPIPE || errno == EAGAIN) return 0;
        printf("[UART ERROR] write(data) failed: %s\n", strerror(errno));
        return -1;
    }

    return (int)written;
}

int uart_open_read(UARTHandle *handle, const char *zone) {
    memset(handle, 0, sizeof(UARTHandle));
    build_fifo_path(zone, handle->path, sizeof(handle->path));

    printf("[UART] Waiting for FIFO: %s\n", handle->path);
    handle->fd = open(handle->path, O_RDONLY);
    if (handle->fd < 0) {
        printf("[UART ERROR] open(read) %s failed: %s\n", handle->path, strerror(errno));
        return -1;
    }

    handle->is_open = 1;
    printf("[UART] FIFO opened for reading: %s\n", handle->path);
    return 0;
}

int uart_read(UARTHandle *handle, uint8_t *buf, size_t length) {
    if (!handle->is_open || handle->fd < 0) return -1;

    uint8_t b1 = 0, b2 = 0;
    while (1) {
        if (read(handle->fd, &b1, 1) != 1) return -1;
        if (b1 != UART_START_BYTE1) continue;
        if (read(handle->fd, &b2, 1) != 1) return -1;
        if (b2 == UART_START_BYTE2) break;
    }

    size_t total = 0;
    while (total < length) {
        ssize_t n = read(handle->fd, buf + total, length - total);
        if (n <= 0) return -1;
        total += (size_t)n;
    }

    return (int)total;
}

void uart_close(UARTHandle *handle) {
    if (handle->is_open && handle->fd >= 0) {
        close(handle->fd);
        handle->fd      = -1;
        handle->is_open = 0;
        printf("[UART] FIFO closed: %s\n", handle->path);
    }
}

void uart_destroy(UARTHandle *handle) {
    if (strlen(handle->path) > 0) {
        unlink(handle->path);
        printf("[UART] FIFO removed: %s\n", handle->path);
    }
}
