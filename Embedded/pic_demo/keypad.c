/*
 * keypad.c - Keypad Driver
 *
 * How this keypad works in PICGenios:
 * - Rows are on PORTD (RD0-RD3) — set as OUTPUT, drive LOW one at a time
 * - Cols are on PORTB (RB0-RB2) — set as INPUT with pullups, read which goes LOW
 *
 * When a key is pressed it connects a ROW pin to a COL pin.
 * We drive one row LOW at a time and check which col reads LOW.
 */
#include "config.h"
#include "keypad.h"
#include <xc.h>

void keypad_init(void) {
    // RD0-RD3 as output (rows)
    TRISD &= 0xF0;      // RD0-3 output
    PORTD |= 0x0F;      // Set rows HIGH initially

    // RB0-RB2 as input (cols) with pullups
    TRISB |= 0x07;      // RB0-2 input
    //OPTION_REGbits.nRBPU = 0; // Enable PORTB pullups
}

unsigned char keypad_scan(void) {
    unsigned char row, col;

    // Row order: RD3=row0, RD2=row1, RD1=row2, RD0=row3
    unsigned char row_pins[4] = {3, 2, 1, 0}; // RD bit numbers

    for (row = 0; row < 4; row++) {
        // Drive all rows HIGH first
        PORTD |= 0x0F;

        // Drive current row LOW
        PORTD &= ~(1 << row_pins[row]);

        __delay_us(10);

        // Read cols RB0-RB2 (active LOW when pressed)
        for (col = 0; col < 3; col++) {
            if (!(PORTB & (1 << col))) {
                __delay_ms(20);    // Debounce

                // Wait for release
                while (!(PORTB & (1 << col)));
                __delay_ms(10);

                // Restore rows
                PORTD |= 0x0F;

                return (unsigned char)(row * 3 + col);
            }
        }
    }

    // Restore rows HIGH
    PORTD |= 0x0F;
    return 0xFF;  // No key pressed
}