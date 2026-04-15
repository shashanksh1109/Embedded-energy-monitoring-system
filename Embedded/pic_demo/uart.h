/*
 * uart.h - UART Driver Header
 * TX = RC6, RX = RC7
 * 9600 baud @ 8MHz
 *
 * Sends 20-byte V1 binary packets to gateway:
 * [0-7]  device_id (8 bytes)
 * [8-11] timestamp (uint32, 0 for demo)
 * [12-15] value    (float)
 * [16]   type      (0=TEMP, 3=OCC)
 * [17]   checksum  (sum bytes 0-16 % 256)
 * [18-19] padding  (0x00)
 */
#ifndef UART_H
#define UART_H

#include <xc.h>

void uart_init(void);
void uart_send_byte(unsigned char byte);
void uart_send_packet(const char *device_id,
                      float value,
                      unsigned char type);

#endif