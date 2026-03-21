CC     = gcc
CFLAGS = -Wall -g -std=c11

# ─── Sensor (Temperature) ─────────────────────────────────────────────────────
SENSOR_TARGET  = temp_sensor
SENSOR_SOURCES = main.c sensor_logic.c config.c network.c sensor.c \
                 sensor_hardware.c protocol.c mqtt_client.c uart_sim.c
SENSOR_OBJECTS = $(SENSOR_SOURCES:.c=.o)

# ─── HVAC Controller ──────────────────────────────────────────────────────────
HVAC_TARGET  = hvac_controller
HVAC_SOURCES = hvac_controller.c pid.c hvac_hardware.c protocol.c ipc.c mqtt_client.c
HVAC_OBJECTS = $(HVAC_SOURCES:.c=.o)

# ─── Power Meter ──────────────────────────────────────────────────────────────
POWER_TARGET  = power_meter
POWER_SOURCES = power_meter.c power_hardware.c ipc.c protocol.c mqtt_client.c
POWER_OBJECTS = $(POWER_SOURCES:.c=.o)

# ─── Occupancy Sensor ─────────────────────────────────────────────────────────
OCCUPANCY_TARGET  = occupancy_sensor
OCCUPANCY_SOURCES = occupancy_sensor.c occupancy_hardware.c protocol.c mqtt_client.c
OCCUPANCY_OBJECTS = $(OCCUPANCY_SOURCES:.c=.o)

# ─── Build All ────────────────────────────────────────────────────────────────
all: $(SENSOR_TARGET) $(HVAC_TARGET) $(POWER_TARGET) $(OCCUPANCY_TARGET)

# ─── Link Rules ───────────────────────────────────────────────────────────────
$(SENSOR_TARGET): $(SENSOR_OBJECTS)
	@echo "Linking sensor..."
	$(CC) $(CFLAGS) -o $(SENSOR_TARGET) $(SENSOR_OBJECTS) -lm -lmosquitto
	@echo "Sensor build successful"

$(HVAC_TARGET): $(HVAC_OBJECTS)
	@echo "Linking HVAC..."
	$(CC) $(CFLAGS) -o $(HVAC_TARGET) $(HVAC_OBJECTS) -lm -lrt -lpthread -lmosquitto
	@echo "HVAC build successful"

$(POWER_TARGET): $(POWER_OBJECTS)
	@echo "Linking power meter..."
	$(CC) $(CFLAGS) -o $(POWER_TARGET) $(POWER_OBJECTS) -lm -lrt -lpthread -lmosquitto
	@echo "Power meter build successful"

$(OCCUPANCY_TARGET): $(OCCUPANCY_OBJECTS)
	@echo "Linking occupancy sensor..."
	$(CC) $(CFLAGS) -o $(OCCUPANCY_TARGET) $(OCCUPANCY_OBJECTS) -lm -lmosquitto
	@echo "Occupancy sensor build successful"

# ─── Compile Rule (all .c -> .o) ──────────────────────────────────────────────
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# ─── Utility Targets ──────────────────────────────────────────────────────────
clean:
	@echo "Cleaning..."
	rm -f $(SENSOR_TARGET) $(HVAC_TARGET) $(POWER_TARGET) $(OCCUPANCY_TARGET) *.o
	@echo "Clean complete"

rebuild: clean all

.PHONY: all clean rebuild