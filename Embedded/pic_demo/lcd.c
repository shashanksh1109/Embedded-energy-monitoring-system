#include "config.h"
#include "lcd.h"
#include <xc.h>

// EN is active LOW:
// LCD reads data on falling edge of EN (HIGH→LOW)
void lcd_send_cmd(unsigned char cmd) {
    LCD_RS   = 0;       // Command mode
    LCD_DATA = cmd;     // Put data on bus
    LCD_EN   = 0;       // Pulse EN LOW (active)
    __delay_ms(2);
    LCD_EN   = 1;       // EN back HIGH
    __delay_ms(2);
}

void lcd_send_char(char ch) {
    LCD_RS   = 1;       // Data mode
    LCD_DATA = (unsigned char)ch;
    LCD_EN   = 0;       // Pulse EN LOW
    __delay_ms(2);
    LCD_EN   = 1;       // EN back HIGH
    __delay_ms(2);
}

void lcd_send_string(const char *str) {
    while (*str) lcd_send_char(*str++);
}

void lcd_set_cursor(unsigned char row, unsigned char col) {
    lcd_send_cmd((row == 0 ? 0x80 : 0xC0) + col);
}

void lcd_clear(void) {
    lcd_send_cmd(0x01);
    __delay_ms(2);
}

void lcd_init(void) {
    // Set directions
    LCD_EN_DIR = 0;   // RE1 output
    LCD_RS_DIR = 0;   // RE2 output
    TRISD      = 0x00; // PORTD all output
    TRISE      = 0x00; // PORTE all output

    // Make PORTE digital
    ADCON1 = 0x06;

    // Initial states
    LCD_EN   = 1;   // EN idle HIGH (active LOW device)
    LCD_RS   = 0;
    LCD_DATA = 0;

    __delay_ms(25);

    // Initialize sequence
    lcd_send_cmd(0x38); // 8-bit, 2 lines, 5x8
    lcd_send_cmd(0x0C); // Display on, cursor off
    lcd_send_cmd(0x06); // Auto increment
    lcd_send_cmd(0x01); // Clear
    __delay_ms(2);
}