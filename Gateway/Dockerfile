# ─── Stage 1: Compile C executables ──────────────────────────────────────────
# Gateway needs hvac_controller and power_meter binaries so it can
# spawn them as child processes when temperature goes out of range.
# Build context is project root, so paths are Embedded/... not just *.c
FROM gcc:11 AS c_builder

RUN apt-get update && apt-get install -y make && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY Embedded/*.c Embedded/*.h Embedded/Makefile ./
RUN make all

# ─── Stage 2: Gateway runtime ─────────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Install Python dependencies
COPY Gateway/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy Python gateway source files
COPY Gateway/*.py ./

# Copy compiled C executables into gateway image at /app/
# These are what process_manager.py will exec when spawning HVAC/power
COPY --from=c_builder /build/hvac_controller ./
COPY --from=c_builder /build/power_meter ./

EXPOSE 8080
CMD ["python3", "main.py"]