# Stage 1: Build environment (compile C programs)
FROM gcc:11 AS builder

# Install make and mosquitto dev library (needed for mqtt_client.h)
RUN apt-get update && apt-get install -y \
    make \
    libmosquitto-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy source files
COPY *.c *.h Makefile ./

# Compile all programs
RUN make all

# Stage 2: Runtime environment (smaller, only executables)
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libc6 \
    libmosquitto1 \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy ONLY compiled executables from builder stage
COPY --from=builder /build/temp_sensor ./
COPY --from=builder /build/hvac_controller ./
COPY --from=builder /build/power_meter ./
COPY --from=builder /build/occupancy_sensor ./

# Default command (can be overridden in docker-compose.yml)
CMD ["./temp_sensor", "TEMP_A", "Zone_A", "22.0", "5"]
