"""
mqtt_subscriber.py - MQTT Subscriber Module

Subscribes to all sensor topics from Mosquitto broker.
Runs alongside existing TCP gateway as a parallel data channel.

Topics subscribed:
  energy/+/temperature  → temperature_readings table
  energy/+/occupancy    → occupancy_readings table
  energy/+/hvac         → hvac_state table
  energy/+/power        → power_readings table

The '+' wildcard matches any zone (zone_a, zone_b, zone_c, zone_d).

Broker: localhost:1883 (local) → mosquitto container (Docker)
"""

import os
import json
import threading
import time
from datetime import datetime, timezone
import paho.mqtt.client as mqtt


# ============================================================
# MQTT CONFIGURATION
# ============================================================
MQTT_HOST      = os.getenv('MQTT_BROKER_HOST', 'localhost')
MQTT_PORT      = int(os.getenv('MQTT_BROKER_PORT', '1883'))
MQTT_KEEPALIVE = 60
MQTT_CLIENT_ID = 'energy_gateway_subscriber'

# Topic patterns — '+' matches any single level (zone name)
TOPIC_TEMPERATURE = 'energy/+/temperature'
TOPIC_OCCUPANCY   = 'energy/+/occupancy'
TOPIC_HVAC        = 'energy/+/hvac'
TOPIC_POWER       = 'energy/+/power'


class MQTTSubscriber:
    """
    Subscribes to all sensor MQTT topics and persists data to PostgreSQL
    via the existing DBWriter instance.
    Runs in its own background thread.
    """

    def __init__(self, db=None):
        self.db        = db         # DBWriter instance (None = no persistence)
        self.client    = None
        self.running   = False
        self.thread    = None
        self.connected = False
        self._msg_count = 0         # total messages received

    # ============================================================
    # LIFECYCLE
    # ============================================================

    def start(self):
        """Initialize MQTT client and start background thread."""
        self.client = mqtt.Client(client_id=MQTT_CLIENT_ID, clean_session=True)

        # Register callbacks
        self.client.on_connect    = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.on_message    = self._on_message

        self.running = True
        self.thread  = threading.Thread(target=self._run, daemon=True)
        self.thread.start()
        print(f"[MQTT_SUB] Subscriber started (broker: {MQTT_HOST}:{MQTT_PORT})")

    def stop(self):
        """Stop background thread and disconnect."""
        self.running = False
        if self.client:
            self.client.disconnect()
            self.client.loop_stop()
        print(f"[MQTT_SUB] Stopped — {self._msg_count} messages received")

    def _run(self):
        """Background thread — connects and runs MQTT loop."""
        try:
            self.client.connect(MQTT_HOST, MQTT_PORT, MQTT_KEEPALIVE)
            self.client.loop_forever()
        except Exception as e:
            print(f"[MQTT_SUB] Connection error: {e}")
            print(f"[MQTT_SUB] Is Mosquitto running? sudo service mosquitto start")

    # ============================================================
    # MQTT CALLBACKS
    # ============================================================

    def _on_connect(self, client, userdata, flags, rc):
        """Called when broker connection is established."""
        if rc == 0:
            self.connected = True
            print(f"[MQTT_SUB] Connected to broker at {MQTT_HOST}:{MQTT_PORT}")

            # Subscribe to all sensor topics
            client.subscribe(TOPIC_TEMPERATURE, qos=1)
            client.subscribe(TOPIC_OCCUPANCY,   qos=1)
            client.subscribe(TOPIC_HVAC,        qos=1)
            client.subscribe(TOPIC_POWER,       qos=1)

            print(f"[MQTT_SUB] Subscribed to:")
            print(f"[MQTT_SUB]   {TOPIC_TEMPERATURE}")
            print(f"[MQTT_SUB]   {TOPIC_OCCUPANCY}")
            print(f"[MQTT_SUB]   {TOPIC_HVAC}")
            print(f"[MQTT_SUB]   {TOPIC_POWER}")
        else:
            self.connected = False
            print(f"[MQTT_SUB] Connection failed (rc={rc})")

    def _on_disconnect(self, client, userdata, rc):
        """Called when broker connection is lost."""
        self.connected = False
        if rc != 0:
            print(f"[MQTT_SUB] Unexpected disconnect (rc={rc}), reconnecting...")

    def _on_message(self, client, userdata, msg):
        """
        Called for every received MQTT message.
        Routes to correct handler based on topic suffix.
        """
        self._msg_count += 1
        topic   = msg.topic
        payload = msg.payload.decode('utf-8').strip()

        # Extract zone from topic (e.g. "energy/zone_a/temperature" → "zone_a")
        parts = topic.split('/')
        if len(parts) != 3:
            return
        zone_raw = parts[1]   # e.g. "zone_a"
        subtopic = parts[2]   # e.g. "temperature"

        # Convert zone_a → Zone_A for DB lookup
        zone = '_'.join(w.capitalize() for w in zone_raw.split('_'))

        recorded_at = datetime.now(tz=timezone.utc)

        try:
            if subtopic == 'temperature':
                self._handle_temperature(zone, payload, recorded_at)
            elif subtopic == 'occupancy':
                self._handle_occupancy(zone, payload, recorded_at)
            elif subtopic == 'hvac':
                self._handle_hvac(zone, payload, recorded_at)
            elif subtopic == 'power':
                self._handle_power(zone, payload, recorded_at)
        except Exception as e:
            print(f"[MQTT_SUB] Error handling {topic}: {e}")

    # ============================================================
    # MESSAGE HANDLERS
    # ============================================================

    def _handle_temperature(self, zone, payload, recorded_at):
        """
        Topic:   energy/<zone>/temperature
        Payload: "22.16" (plain float string)
        """
        value_c = float(payload)
        print(f"[MQTT_SUB] TEMP {zone}: {value_c:.2f}°C")

        if self.db:
            # Derive device_id from zone (e.g. Zone_A → TEMP_A)
            device_id = f"TEMP_{zone.split('_')[-1]}"
            zone_id   = self.db._get_zone_id(device_id)
            if zone_id:
                self.db._write_temperature(device_id, zone_id, value_c, recorded_at)

    def _handle_occupancy(self, zone, payload, recorded_at):
        """
        Topic:   energy/<zone>/occupancy
        Payload: "3" (integer as string)
        """
        count = int(payload)
        print(f"[MQTT_SUB] OCCUPANCY {zone}: {count} people")

        if self.db:
            device_id = f"OCC_{zone.split('_')[-1]}"
            zone_id   = self.db._get_zone_id(device_id)
            if zone_id:
                self.db._write_occupancy(device_id, zone_id, count, recorded_at)

    def _handle_hvac(self, zone, payload, recorded_at):
        """
        Topic:   energy/<zone>/hvac
        Payload: {"heater":31.2,"cooler":0.0,"temp":19.8,"setpoint":20.0}
        """
        data = json.loads(payload)
        print(f"[MQTT_SUB] HVAC {zone}: "
              f"Heat:{data['heater']:.1f}% "
              f"Cool:{data['cooler']:.1f}% "
              f"Temp:{data['temp']:.2f}°C")

        if self.db:
            device_id = f"HVAC_{zone.split('_')[-1]}"
            zone_id   = self.db._get_zone_id(device_id)
            if zone_id:
                # Build packet-like dict for _write_hvac_state
                packet = {
                    'heater_pct':   data['heater'],
                    'cooler_pct':   data['cooler'],
                    'current_temp': data['temp'],
                    'setpoint':     data['setpoint'],
                }
                self.db._write_hvac_state(device_id, zone_id, packet, recorded_at)

    def _handle_power(self, zone, payload, recorded_at):
        """
        Topic:   energy/<zone>/power
        Payload: {"power_kw":5.2,"energy_kwh":0.045,"cost_usd":0.005,"hvac_pct":32.0}
        """
        data = json.loads(payload)
        print(f"[MQTT_SUB] POWER {zone}: "
              f"{data['power_kw']:.2f} kW | "
              f"{data['energy_kwh']:.4f} kWh | "
              f"${data['cost_usd']:.4f}")

        if self.db:
            device_id = f"POWER_{zone.split('_')[-1]}"
            zone_id   = self.db._get_zone_id(device_id)
            if zone_id:
                packet = {'value': data['power_kw']}
                self.db._write_power(device_id, zone_id, packet, recorded_at)