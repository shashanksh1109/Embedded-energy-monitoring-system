CC = gcc
CFLAGS = -Wall -g -std=c11

# Existing sensor target
SENSOR_TARGET = temp_sensor
SENSOR_SOURCES = main.c sensor_logic.c config.c network.c sensor.c sensor_hardware.c protocol.c
SENSOR_OBJECTS = $(SENSOR_SOURCES:.c=.o)

# NEW: HVAC target
HVAC_TARGET = hvac_controller
HVAC_SOURCES = hvac_controller.c pid.c hvac_hardware.c
HVAC_OBJECTS = $(HVAC_SOURCES:.c=.o)

# Build both
all: $(SENSOR_TARGET) $(HVAC_TARGET)

# Sensor executable
$(SENSOR_TARGET): $(SENSOR_OBJECTS)
	@echo "Linking sensor..."
	$(CC) $(CFLAGS) -o $(SENSOR_TARGET) $(SENSOR_OBJECTS) -lm
	@echo "✓ Sensor build successful"

# HVAC executable
$(HVAC_TARGET): $(HVAC_OBJECTS)
	@echo "Linking HVAC..."
	$(CC) $(CFLAGS) -o $(HVAC_TARGET) $(HVAC_OBJECTS) -lm
	@echo "✓ HVAC build successful"

%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	@echo "Cleaning..."
	rm -f $(SENSOR_TARGET) $(HVAC_TARGET) *.o
	@echo "✓ Clean complete"

rebuild: clean all

.PHONY: all clean rebuild