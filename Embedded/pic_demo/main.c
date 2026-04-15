/*
 * main.c - Energy Monitor Main Program
 * PIC16F877A on PICGenios board (PICsimLAB)
 *
 * Coordinates all modules:
 * 1. Initialize all hardware
 * 2. Main loop:
 *    - Scan keypad
 *    - Update LCD every 2 seconds (cycle zones)
 *    - Send UART packets every 5 seconds
 *
 * PIN MAPPING (confirmed from PICsimLAB board source):
 * LCD:     RE1=EN(active LOW), RE2=RS, PORTD=data
 * Keypad:  RD3-RD0=rows(output), RB0-RB2=cols(input)
 * Heater:  RC5 (Zone indicators via PORTD LEDs)
 * Cooler:  RC2
 * UART:    RC6=TX, RC7=RX
 */

#include "config.h"
#include <xc.h>
#include <stdio.h>
#include "lcd.h"
#include "keypad.h"
#include "uart.h"
#include "zones.h"

// CONFIG bits
#pragma config FOSC  = HS
#pragma config WDTE  = OFF
#pragma config PWRTE = OFF
#pragma config BOREN = ON
#pragma config LVP   = OFF
#pragma config CPD   = OFF
#pragma config WRT   = OFF
#pragma config CP    = OFF

// Timing counters (incremented every 1ms in main loop)
unsigned int  disp_counter = 0;
unsigned int  uart_counter = 0;
unsigned char current_zone = 0;

// Device IDs sent in UART packets
const char *temp_ids[3] = {"TEMP_A", "TEMP_B", "TEMP_C"};
const char *occ_ids[3]  = {"OCC_A",  "OCC_B",  "OCC_C" };

/*
 * Show one zone on LCD
 * Line 1: "Zone1 T:22C  S"
 * Line 2: "Occ:0 people  "
 *
 * NOTE: Before writing to LCD we must restore PORTD
 * because PORTD is shared between LCD data and keypad rows.
 * keypad_scan() leaves PORTD with row pattern.
 * lcd functions overwrite PORTD completely so this is fine.
 */
void lcd_show_zone(unsigned char z) {
    char line1[17];
    char line2[17];

    sprintf(line1, "Zone%u T:%2dC  %c  ",
            (unsigned int)(z + 1),
            zones[z].temp,
            zones[z].mode);

    sprintf(line2, "Occ:%-2d people   ",
            zones[z].occ);

    lcd_set_cursor(0, 0);
    lcd_send_string(line1);
    lcd_set_cursor(1, 0);
    lcd_send_string(line2);

    // After LCD write, restore PORTD rows HIGH for keypad
    PORTD |= 0x0F;
}

// Send UART packets for all 3 zones
void send_uart_all_zones(void) {
    unsigned char z;
    for (z = 0; z < 3; z++) {
        uart_send_packet(temp_ids[z],
                         (float)zones[z].temp, 0);
        __delay_ms(10);
        uart_send_packet(occ_ids[z],
                         (float)zones[z].occ, 3);
        __delay_ms(10);
    }
    // Restore PORTD rows after UART (PORTD used for LCD data)
    PORTD |= 0x0F;
}

void main(void) {
    // ── Port Directions ──────────────────────────────
    TRISA = 0x00;   // All output
    TRISB = 0x07;   // RB0-2 input (keypad cols), RB3-7 output
    TRISC = 0xC0;   // RC6=TX output, RC7=RX input
    TRISD = 0x00;   // All output (LCD data + keypad rows)
    TRISE = 0x00;   // All output (RE1=EN, RE2=RS for LCD)

    // ── Initial Port States ──────────────────────────
    PORTA = 0x00;
    PORTB = 0x07;   // Cols HIGH (pullup state)
    PORTC = 0x00;
    PORTD = 0x0F;   // Rows HIGH initially
    PORTE = 0x00;

    // ── Disable ADC ─────────────────────────────────
    // 0x06 = PORTA/E all digital
    ADCON1 = 0x06;

    // ── Enable PORTB internal pullups ────────────────
    // nRBPU=0 enables pullups on input pins
    OPTION_REGbits.nRBPU = 0;

    // ── Initialize all modules ───────────────────────
    zones_init();
    lcd_init();
    uart_init();
    keypad_init();

    // ── Startup message ──────────────────────────────
    lcd_set_cursor(0, 0);
    lcd_send_string("Energy Monitor  ");
    lcd_set_cursor(1, 0);
    lcd_send_string(" 3-Zone System  ");
    __delay_ms(2000);
    lcd_clear();

    // ── Show initial zone state ──────────────────────
    update_all_leds();
    lcd_show_zone(0);

    // ── Main Loop ────────────────────────────────────
    // Each iteration ~1ms
    while (1) {
        // 1. Scan keypad
        unsigned char key = keypad_scan();
        if (key != 0xFF) {
            process_keypress(key);
            lcd_show_zone(current_zone);
        }

        // 2. Cycle LCD zone every 2000ms
        disp_counter++;
        if (disp_counter >= 2000) {
            disp_counter  = 0;
            current_zone  = (current_zone + 1) % 3;
            lcd_show_zone(current_zone);
        }

        // 3. Send UART every 5000ms
        uart_counter++;
        if (uart_counter >= 5000) {
            uart_counter = 0;
            send_uart_all_zones();
        }

        __delay_ms(1);
    }
}