# Energy Monitor - PIC16F877A
CC     = /opt/microchip/xc8/v2.46/bin/xc8-cc
CHIP   = 16F877A
TARGET = energy_monitor
SRC    = main.c lcd.c keypad.c uart.c zones.c

all:
	$(CC) -mcpu=$(CHIP) -O1 $(SRC) -o $(TARGET).hex
	@echo "Build complete: $(TARGET).hex"

clean:
	rm -f *.hex *.p1 *.d *.lst *.sym *.cmf *.obj *.pre *.hxl
	@echo "Cleaned"