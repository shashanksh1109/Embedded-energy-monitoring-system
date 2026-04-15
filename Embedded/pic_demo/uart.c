/*
 * uart.c - UART Driver Implementation
 *
 * UART = Universal Asynchronous Receiver Transmitter
 * It converts parallel data (8 bits in register)
 * to serial data (one bit at a time on TX pin).
 *
 * Baud rate = how many bits per second.
 * 9600 baud @ 8MHz:
 *   SPBRG = (Fosc / (16 * baud)) - 1
 *         = (8000000 / (16 * 9600)) - 1
 *         = 51
 */

#include "config.h"
#include "uart.h"
#include <xc.h>

void uart_init(void) {
    TRISC6 = 0;     // TX pin as output
    TRISC7 = 1;     // RX pin as input
    SPBRG  = 51;    // 9600 baud @ 8MHz
    TXSTA  = 0x24;  // TXEN=1, BRGH=1, async
    RCSTA  = 0x90;  // SPEN=1, CREN=1
}

// Send one byte, wait for transmit buffer empty first
void uart_send_byte(unsigned char byte) {
    while (!TXIF);  // TXIF=1 when buffer empty
    TXREG = byte;
}

/*
 * Build and send 20-byte V1 packet
 * type: 0=TEMP, 3=OCCUPANCY
 */
void uart_send_packet(const char *device_id,
                      float value,
                      unsigned char type) {
    unsigned char pkt[20];
    unsigned char i;
    unsigned int  checksum = 0;

    // Zero fill
    for (i = 0; i < 20; i++) pkt[i] = 0x00;

    // Bytes 0-7: device ID
    for (i = 0; i < 7 && device_id[i] != '\0'; i++)
        pkt[i] = (unsigned char)device_id[i];

    // Bytes 8-11: timestamp (0 for demo)
    pkt[8] = pkt[9] = pkt[10] = pkt[11] = 0x00;

    // Bytes 12-15: float value (IEEE 754)
    unsigned char *fp = (unsigned char *)&value;
    pkt[12] = fp[0];
    pkt[13] = fp[1];
    pkt[14] = fp[2];
    pkt[15] = fp[3];

    // Byte 16: packet type
    pkt[16] = type;

    // Byte 17: checksum = sum(bytes 0-16) % 256
    for (i = 0; i < 17; i++) checksum += pkt[i];
    pkt[17] = (unsigned char)(checksum % 256);

    // Bytes 18-19: padding already 0x00

    // Transmit all 20 bytes
    for (i = 0; i < 20; i++) uart_send_byte(pkt[i]);
}