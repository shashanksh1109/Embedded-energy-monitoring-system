/*
 * zones.h - Zone Logic Header
 * Manages state of 3 building zones.
 * Each zone has temperature, occupancy, and HVAC mode.
 *
 * Heater LEDs: RD0=Z1, RD1=Z2, RD2=Z3 (PORTD)
 * Cooler LEDs: RA0=Z1, RA1=Z2, RA2=Z3 (PORTA)
 *
 * HVAC modes:
 *   'H' = Heating  (temp < 19°C)
 *   'C' = Cooling  (temp > 25°C)
 *   'S' = Stable   (19°C - 25°C)
 */
#ifndef ZONES_H
#define ZONES_H

#include <xc.h>

// Thresholds
#define TEMP_MIN        15
#define TEMP_MAX        35
#define OCC_MIN          0
#define OCC_MAX         30
#define HEAT_THRESHOLD  19
#define COOL_THRESHOLD  25

// Heater LEDs on PORTD
#define HEAT1   RD0
#define HEAT2   RD1
#define HEAT3   RD2

// Cooler LEDs on PORTA
#define COOL1   RA0
#define COOL2   RA1
#define COOL3   RA2

// Zone data structure
typedef struct {
    int  temp;   // Temperature in degrees C
    int  occ;    // Occupancy (people count)
    char mode;   // 'H', 'C', or 'S'
} Zone;

// Global zone array - accessible from all files
extern Zone zones[3];

void zones_init(void);
void update_zone_mode(unsigned char z);
void update_all_leds(void);
void process_keypress(unsigned char key);

#endif