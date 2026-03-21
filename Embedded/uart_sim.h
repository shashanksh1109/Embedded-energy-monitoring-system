#ifndef UART_SIM_H
#define UART_SIM_H

/*
 * uart_sim.h - UART Simulation Interface
 *
 * Simulates a UART serial port using Linux named pipes (FIFOs).
 * Mimics ESP32 UART0 TX → PC RX communication at 115200 baud.
 *
 * How it works:
 *   Writer (sensor):  opens FIFO for writing, sends binary packets
 *   Reader (gateway): opens FIFO for reading, receives binary packets
 *
 * FIFO path: /tmp/uart_<zone> (e.g. /tmp/uart_zone_a)
 *
 * On real ESP32:
 *   Replace uart_write() with: Serial.write(buffer, length)
 *   Replace uart_read()  with: Serial.readBytes(buffer, length)
 *   Baud rate set via:         Serial.begin(115200)
 *
 * Packet format:
 *   Same 20-byte V1 or 32-byte V2 binary packets used by TCP transport.
 *   UART adds a 2-byte start marker (0xAA 0x55) before each packet
 *   for frame synchronization — essential on noisy serial lines.
 *
 * Frame layout:
 *   [0x AA] [0x55] [packet bytes...]
 *    start   start   20 or 32 bytes
 *    byte1   byte2
 */

#include <stdint.h>
#include <stddef.h>

/* ============================================================
 * UART CONFIGURATION
 * ============================================================ */
#define UART_FIFO_DIR     "/tmp"           // directory for FIFO files
#define UART_BAUD_RATE    115200           // simulated baud rate (informational)
#define UART_START_BYTE1  0xAA            // frame start marker byte 1
#define UART_START_BYTE2  0x55            // frame start marker byte 2
#define UART_START_SIZE   2               // bytes in start marker

/* ============================================================
 * UART HANDLE
 * One instance per sensor process.
 * ============================================================ */
typedef struct {
    int  fd;              // file descriptor for FIFO
    char path[64];        // FIFO path e.g. /tmp/uart_zone_a
    int  is_open;         // 1 = open, 0 = closed
} UARTHandle;

/* ============================================================
 * WRITER FUNCTIONS (used by sensors)
 * ============================================================ */

/**
 * uart_open_write()
 * Create FIFO and open for writing.
 * Called by sensor process on startup.
 *
 * @param handle : pointer to UARTHandle to initialize
 * @param zone   : zone name (e.g. "Zone_A") — used to build FIFO path
 * @return 0 on success, -1 on failure
 */
int uart_open_write(UARTHandle *handle, const char *zone);

/**
 * uart_write()
 * Write a binary packet to FIFO with start marker prefix.
 * Mimics ESP32 Serial.write().
 *
 * @param handle : open UARTHandle (write mode)
 * @param data   : pointer to packet bytes
 * @param length : number of bytes to write
 * @return bytes written on success, -1 on failure
 */
int uart_write(UARTHandle *handle, const uint8_t *data, size_t length);

/* ============================================================
 * READER FUNCTIONS (used by gateway uart_reader.py via Python)
 * These C functions are provided for completeness and testing.
 * The gateway uses uart_reader.py (Python) for actual reading.
 * ============================================================ */

/**
 * uart_open_read()
 * Open existing FIFO for reading.
 * Called by reader process after writer has created the FIFO.
 *
 * @param handle : pointer to UARTHandle to initialize
 * @param zone   : zone name (e.g. "Zone_A")
 * @return 0 on success, -1 on failure
 */
int uart_open_read(UARTHandle *handle, const char *zone);

/**
 * uart_read()
 * Read one framed packet from FIFO.
 * Scans for start marker (0xAA 0x55) then reads packet bytes.
 *
 * @param handle : open UARTHandle (read mode)
 * @param buf    : buffer to store packet bytes
 * @param length : number of bytes to read after start marker
 * @return bytes read on success, -1 on failure
 */
int uart_read(UARTHandle *handle, uint8_t *buf, size_t length);

/**
 * uart_close()
 * Close FIFO file descriptor.
 * Called by both writer and reader on exit.
 *
 * @param handle : open UARTHandle
 */
void uart_close(UARTHandle *handle);

/**
 * uart_destroy()
 * Unlink (delete) the FIFO file.
 * Called only by the writer (creator) on exit.
 *
 * @param handle : UARTHandle with path to unlink
 */
void uart_destroy(UARTHandle *handle);

#endif