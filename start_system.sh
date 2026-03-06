#!/bin/bash

# Parse command-line arguments
HARDWARE_FLAG=""
if [ "$1" == "--hardware" ]; then
    HARDWARE_FLAG="--hardware"
    echo "[STARTUP] Hardware mode enabled for all processes"
fi

echo ""
echo "================================================================"
echo "  ENERGY MANAGEMENT SYSTEM - STARTUP"
echo "================================================================"
echo ""

# Build
echo "[STARTUP] Step 1: Building C programs..."
cd Embedded
make all
if [ $? -ne 0 ]; then
    echo "[STARTUP] Build failed"
    exit 1
fi
echo "[STARTUP] Build successful"
echo ""
cd ..

# Start Gateway
echo "[STARTUP] Step 2: Starting Gateway..."
cd Gateway
python3 main.py $HARDWARE_FLAG &
GATEWAY_PID=$!
cd ..

echo "[STARTUP] Gateway started (PID: $GATEWAY_PID)"
echo "[STARTUP] Waiting for initialization..."
sleep 3
echo ""

# Start Sensor
echo "[STARTUP] Step 3: Starting temperature sensor..."
./Embedded/temp_sensor TEMP_A Zone_A 22.0 5 $HARDWARE_FLAG &
SENSOR_PID=$!

echo "[STARTUP] Sensor started (PID: $SENSOR_PID)"
echo ""

# Display status
echo "================================================================"
echo "  SYSTEM ACTIVE"
echo "================================================================"
echo ""
echo "  Mode: $(if [ -n "$HARDWARE_FLAG" ]; then echo "HARDWARE (ESP32)"; else echo "SIMULATION"; fi)"
echo "  Gateway: PID $GATEWAY_PID"
echo "  Sensor:  PID $SENSOR_PID"
echo ""
echo "  Auto-spawn enabled:"
echo "    Temperature < 18C: Start HVAC (heating)"
echo "    Temperature > 24C: Start HVAC (cooling)"
echo "    Temperature stable: Stop HVAC"
echo ""
echo "  Press Ctrl+C to shutdown"
echo ""
echo "================================================================"
echo ""

# Cleanup on exit
cleanup() {
    echo ""
    echo "================================================================"
    echo "  SYSTEM SHUTDOWN"
    echo "================================================================"
    echo ""
    echo "[STARTUP] Terminating processes..."
    
    if kill -0 $SENSOR_PID 2>/dev/null; then
        kill $SENSOR_PID
        echo "[STARTUP] Sensor stopped"
    fi
    
    if kill -0 $GATEWAY_PID 2>/dev/null; then
        kill $GATEWAY_PID
        wait $GATEWAY_PID 2>/dev/null
        echo "[STARTUP] Gateway stopped"
    fi
    
    echo ""
    echo "[STARTUP] Shutdown complete"
    echo ""
    exit 0
}

trap cleanup SIGINT SIGTERM
wait