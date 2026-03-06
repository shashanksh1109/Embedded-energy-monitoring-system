CC = gcc
CFLAGS = -Wall -g -std=c11

TARGET = temp_sensor

SOURCES = main.c \
          sensor_logic.c \
          config.c \
          network.c \
          sensor.c \
          sensor_hardware.c \
          protocol.c

OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@echo "Linking..."
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS) -lm
	@echo "✓ Build successful: $(TARGET)"

%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	@echo "Cleaning..."
	rm -f $(TARGET) $(OBJECTS)
	@echo "✓ Clean complete"

rebuild: clean all

.PHONY: all clean rebuild