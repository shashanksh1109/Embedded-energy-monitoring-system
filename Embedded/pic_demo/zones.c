/*
 * zones.c - Zone Logic Implementation
 *
 * extern Zone zones[3] in zones.h means:
 * "zones array is defined somewhere else,
 *  but all files can access it."
 * It is actually defined HERE in zones.c.
 */

#include "config.h"
#include "zones.h"
#include <xc.h>

// Define the global zones array here
Zone zones[3];

// Initialize all zones to default values
void zones_init(void) {
    unsigned char z;
    for (z = 0; z < 3; z++) {
        zones[z].temp = 22;  // Start at 22°C
        zones[z].occ  = 0;   // Start empty
        zones[z].mode = 'S'; // Start stable
    }
}

// Recalculate HVAC mode based on temperature
void update_zone_mode(unsigned char z) {
    if (zones[z].temp < HEAT_THRESHOLD)
        zones[z].mode = 'H';
    else if (zones[z].temp > COOL_THRESHOLD)
        zones[z].mode = 'C';
    else
        zones[z].mode = 'S';
}

// Update all 6 LEDs based on current zone modes
void update_all_leds(void) {
    HEAT1 = (zones[0].mode == 'H') ? 1 : 0;
    HEAT2 = (zones[1].mode == 'H') ? 1 : 0;
    HEAT3 = (zones[2].mode == 'H') ? 1 : 0;
    COOL1 = (zones[0].mode == 'C') ? 1 : 0;
    COOL2 = (zones[1].mode == 'C') ? 1 : 0;
    COOL3 = (zones[2].mode == 'C') ? 1 : 0;
}

/*
 * Process a keypress (0-11)
 *
 * Key to action mapping:
 *  0,1,2  → Temp UP   for zones 0,1,2
 *  3,4,5  → Temp DOWN for zones 0,1,2
 *  6,7,8  → Occ UP    for zones 0,1,2
 *  9,10,11→ Occ DOWN  for zones 0,1,2
 *
 * key % 3 gives zone number:
 *   key 0 % 3 = 0 → zone 0
 *   key 1 % 3 = 1 → zone 1
 *   key 4 % 3 = 1 → zone 1
 *   key 9 % 3 = 0 → zone 0
 */
void process_keypress(unsigned char key) {
    unsigned char zone = key % 3;

    if (key <= 2) {
        if (zones[zone].temp < TEMP_MAX) zones[zone].temp++;
    } else if (key <= 5) {
        if (zones[zone].temp > TEMP_MIN) zones[zone].temp--;
    } else if (key <= 8) {
        if (zones[zone].occ < OCC_MAX) zones[zone].occ++;
    } else {
        if (zones[zone].occ > OCC_MIN) zones[zone].occ--;
    }

    update_zone_mode(zone);
    update_all_leds();
}