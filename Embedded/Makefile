CC     = gcc
CFLAGS = -Wall -g -std=c11

SENSOR_TARGET  = temp_sensor
SENSOR_SOURCES = main.c sensor_logic.c config.c network.c sensor.c sensor_hardware.c protocol.c
SENSOR_OBJECTS = $(SENSOR_SOURCES:.c=.o)

HVAC_TARGET  = hvac_controller
HVAC_SOURCES = hvac_controller.c pid.c hvac_hardware.c protocol.c ipc.c
HVAC_OBJECTS = $(HVAC_SOURCES:.c=.o)

POWER_TARGET  = power_meter
POWER_SOURCES = power_meter.c power_hardware.c ipc.c protocol.c
POWER_OBJECTS = $(POWER_SOURCES:.c=.o)

OCCUPANCY_TARGET  = occupancy_sensor
OCCUPANCY_SOURCES = occupancy_sensor.c occupancy_hardware.c protocol.c
OCCUPANCY_OBJECTS = $(OCCUPANCY_SOURCES:.c=.o)

all: $(SENSOR_TARGET) $(HVAC_TARGET) $(POWER_TARGET) $(OCCUPANCY_TARGET)

$(SENSOR_TARGET): $(SENSOR_OBJECTS)
	@echo "Linking sensor..."
	$(CC) $(CFLAGS) -o $(SENSOR_TARGET) $(SENSOR_OBJECTS) -lm
	@echo "Sensor build successful"

$(HVAC_TARGET): $(HVAC_OBJECTS)
	@echo "Linking HVAC..."
	$(CC) $(CFLAGS) -o $(HVAC_TARGET) $(HVAC_OBJECTS) -lm -lrt -lpthread
	@echo "HVAC build successful"

$(POWER_TARGET): $(POWER_OBJECTS)
	@echo "Linking power meter..."
	$(CC) $(CFLAGS) -o $(POWER_TARGET) $(POWER_OBJECTS) -lm -lrt -lpthread
	@echo "Power meter build successful"

$(OCCUPANCY_TARGET): $(OCCUPANCY_OBJECTS)
	@echo "Linking occupancy sensor..."
	$(CC) $(CFLAGS) -o $(OCCUPANCY_TARGET) $(OCCUPANCY_OBJECTS) -lm
	@echo "Occupancy sensor build successful"

%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	@echo "Cleaning..."
	rm -f $(SENSOR_TARGET) $(HVAC_TARGET) $(POWER_TARGET) $(OCCUPANCY_TARGET) *.o
	@echo "Clean complete"

rebuild: clean all

.PHONY: all clean rebuild