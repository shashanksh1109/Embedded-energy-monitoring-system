#ifndef LCD_H
#define LCD_H

#include <xc.h>

// PICGenios LCD pins (from board source code):
// EN  = RE1 (active LOW - LCD reads when RE1=0)
// RS  = RE2 (0=command, 1=data)
// Data = PORTD (8-bit, RD0-RD7)

#define LCD_EN      RE1   // Enable (active LOW)
#define LCD_RS      RE2   // Register Select
#define LCD_DATA    PORTD // 8-bit data bus

#define LCD_EN_DIR  TRISE1
#define LCD_RS_DIR  TRISE2

void lcd_init(void);
void lcd_clear(void);
void lcd_set_cursor(unsigned char row, unsigned char col);
void lcd_send_char(char ch);
void lcd_send_string(const char *str);
void lcd_send_cmd(unsigned char cmd);

#endif