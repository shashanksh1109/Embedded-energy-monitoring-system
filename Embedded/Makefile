CC = gcc
CFLAGS = -Wall -g -std=c11

TARGET = temp_sensor

SOURCES = main.c sensor_logic.c config.c network.c sensor.c protocol.c

OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@echo "Linking..."
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS) -lm
	@echo "Build successful"

%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJECTS)

rebuild: clean all

.PHONY: all clean rebuild
