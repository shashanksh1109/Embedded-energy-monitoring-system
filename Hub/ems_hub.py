#!/usr/bin/env python3
"""
ems_hub.py - EMS hub agent for a Raspberry Pi.

What it does, forever:
  1. PAIRING (first start, or after --reset):
       asks the cloud for a pairing code, shows it on the OLED (and in the
       log), and waits until someone types it in the dashboard.
  2. CONFIG: downloads the hardware setup made in the dashboard (which
       outputs/sensors are on which pins), applies it, scans the I2C bus
       and reports "version N applied".
  3. COMMANDS: every 2 s asks "anything to switch?" and switches GPIO
       outputs (fan, LEDs, relays), then confirms each command.
  4. SENSORS: every 5 s reads every configured sensor and sends a 20-byte
       packet per reading to the gateway (same protocol as the C sensors).

Settings come from /etc/ems-hub.conf (API_URL, GATEWAY_HOST, GATEWAY_PORT).
The secret hub key is kept in ~/.ems-hub/state.json (only readable by you).

Usage:  python3 ems_hub.py           run the hub
        python3 ems_hub.py --reset   forget the pairing (shows a new code)
"""

import json
import os
import socket
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request

API_URL = os.getenv("API_URL", "http://192.168.137.1:8081").rstrip("/")
GATEWAY_HOST = os.getenv("GATEWAY_HOST", "192.168.137.1")
GATEWAY_PORT = int(os.getenv("GATEWAY_PORT", "8080"))
STATE_DIR = os.path.expanduser("~/.ems-hub")
STATE_FILE = os.path.join(STATE_DIR, "state.json")
MODEL = "Raspberry Pi"

COMMAND_EVERY = 2      # seconds
SENSOR_EVERY = 5
CONFIG_EVERY = 15

# Packet types understood by the gateway (Gateway/protocol.py)
PACKET_TYPE = {"TEMP": 0, "POWER": 1, "OCCUPANCY": 3}


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


# ----------------------------------------------------------------------
# Small helpers: state file, cloud API, OLED
# ----------------------------------------------------------------------

def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_state(state):
    os.makedirs(STATE_DIR, mode=0o700, exist_ok=True)
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.chmod(tmp, 0o600)                     # the hub key is a secret
    os.replace(tmp, STATE_FILE)              # atomic: never a half-written file


class ApiError(Exception):
    def __init__(self, status, message=""):
        super().__init__(f"HTTP {status} {message}")
        self.status = status


def api(method, path, hub_key=None, body=None):
    """Call the cloud API; returns parsed JSON or raises ApiError/OSError."""
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(API_URL + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if hub_key:
        req.add_header("X-Hub-Key", hub_key)
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            text = res.read().decode()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as e:
        raise ApiError(e.code, e.read().decode(errors="replace")[:200])


class Screen:
    """The OLED (SSD1306, I2C 0x3C). Everything still works without it."""

    def __init__(self):
        self.device = None
        try:
            from luma.core.interface.serial import i2c
            from luma.oled.device import ssd1306
            from PIL import ImageFont
            self.device = ssd1306(i2c(port=1, address=0x3C), width=128, height=64)
            path = "/usr/share/fonts/truetype/dejavu/"
            self.big = ImageFont.truetype(path + "DejaVuSans-Bold.ttf", 18)
            self.small = ImageFont.truetype(path + "DejaVuSans.ttf", 10)
        except Exception as e:                       # no OLED, or library missing
            log(f"OLED not available ({e}); continuing without it")

    def show(self, title, big, lines=()):
        if not self.device:
            return
        try:
            from luma.core.render import canvas
            with canvas(self.device) as d:
                d.text((0, 0), title, font=self.small, fill="white")
                d.line((0, 13, 127, 13), fill="white")
                d.text((0, 16), big, font=self.big, fill="white")
                for i, line in enumerate(lines[:2]):
                    d.text((0, 40 + 12 * i), line, font=self.small, fill="white")
        except Exception as e:
            log(f"OLED error: {e}")


# ----------------------------------------------------------------------
# Hardware: GPIO through the "pinctrl" tool, I2C through smbus2
# ----------------------------------------------------------------------

def gpio_output(pin, on, active_high=True):
    level = "dh" if (on == active_high) else "dl"
    subprocess.run(["pinctrl", "set", str(pin), "op", level], check=True,
                   capture_output=True, timeout=5)


def gpio_input(pin):
    subprocess.run(["pinctrl", "set", str(pin), "ip", "pd"], check=True,
                   capture_output=True, timeout=5)


def gpio_read(pin):
    out = subprocess.run(["pinctrl", "get", str(pin)], check=True,
                         capture_output=True, text=True, timeout=5).stdout
    return "| hi" in out                           # e.g. "23: ip pd | hi // GPIO23 = input"


def i2c_scan():
    """Addresses that answer on I2C bus 1 (like i2cdetect)."""
    try:
        from smbus2 import SMBus
    except ImportError:
        return []
    found = []
    try:
        with SMBus(1) as bus:
            for addr in range(0x03, 0x78):
                try:
                    bus.read_byte(addr)
                    found.append(addr)
                except OSError:
                    pass
    except OSError:
        pass
    return found


def read_soc_temp():
    with open("/sys/class/thermal/thermal_zone0/temp") as f:
        return int(f.read()) / 1000.0


# GPIO pins (BCM) the hub may drive - the same list the backend allows
USER_GPIO = [4, 5, 6, 12, 13, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]

SUPPORTED_DRIVERS = {"SOC_TEMP", "PIR"}   # BME280 / INA219: coming when the parts are here


def read_sensor(sensor):
    driver = sensor["driver"]
    if driver == "SOC_TEMP":
        return read_soc_temp()
    if driver == "PIR":
        return 1.0 if gpio_read(sensor["gpio"]) else 0.0     # motion = 1 person present
    return None


# ----------------------------------------------------------------------
# Gateway: the same 20-byte V1 packet as Embedded/protocol.c
# ----------------------------------------------------------------------

def build_packet(thing_name, value, packet_type):
    body = struct.pack("<8sIfB", thing_name.encode()[:7], int(time.time()), float(value), packet_type)
    checksum = sum(body[:17]) % 256
    return body + bytes([checksum]) + b"\x00\x00"


class Gateway:
    """One TCP connection to the gateway, reopened automatically."""

    def __init__(self):
        self.sock = None
        self.retry_at = 0
        self.delay = 1

    def send(self, packet):
        if self.sock is None:
            if time.time() < self.retry_at:
                return False
            try:
                self.sock = socket.create_connection((GATEWAY_HOST, GATEWAY_PORT), timeout=5)
                self.delay = 1
                log(f"Connected to gateway {GATEWAY_HOST}:{GATEWAY_PORT}")
            except OSError as e:
                log(f"Gateway not reachable ({e}); retry in {self.delay}s")
                self.retry_at = time.time() + self.delay
                self.delay = min(self.delay * 2, 30)          # exponential backoff
                return False
        try:
            self.sock.sendall(packet)
            return True
        except OSError:
            self.sock.close()
            self.sock = None
            return False


# ----------------------------------------------------------------------
# Pairing
# ----------------------------------------------------------------------

def pair(state, screen):
    """Show a code until someone enters it in the dashboard. Returns the state."""
    while True:
        try:
            start = api("POST", "/api/hubs/start", body={"model": MODEL})
        except (ApiError, OSError) as e:
            log(f"Cloud not reachable ({e}); retrying in 10s")
            screen.show("EMS HUB", "No network", ["Retrying..."])
            time.sleep(10)
            continue

        state = {"hubKey": start["hubKey"]}
        save_state(state)
        code = start["pairingCode"]
        log(f"PAIRING CODE: {code}  (enter it in the dashboard: Add hub)")
        screen.show("EMS HUB - PAIR CODE", code, ["Enter this code on", "the website: Add hub"])

        while True:
            time.sleep(start.get("pollSeconds", 3))
            try:
                status = api("GET", "/api/hubs/status", hub_key=state["hubKey"])
            except (ApiError, OSError) as e:
                log(f"Status check failed ({e})")
                continue
            if status.get("paired"):
                state.update(thingName=status["thingName"], organization=status["organizationName"])
                save_state(state)
                log(f"Paired as {state['thingName']} with {state['organization']}")
                screen.show("EMS HUB", "CONNECTED", [state["organization"][:21], state["thingName"]])
                return state
            if status.get("codeExpired"):
                log("Code expired, getting a new one")
                break                                   # back to start: new key + code


# ----------------------------------------------------------------------
# Main loop
# ----------------------------------------------------------------------

def apply_config(hub_key, cfg, version, outputs_state, old_cfg):
    """Set up pins for the new config; returns {sensor key: thing name}."""
    # 1. Release pins the OLD config drove but the new one doesn't use any more
    #    (an output was moved to another pin, or removed). Without this, the old
    #    pin would stay in its last state - e.g. an LED left ON forever.
    #    After a program RESTART there is no "old config" in memory, but the
    #    pins keep whatever state the previous run left (only a reboot resets
    #    them). So on the first config, release every user pin it doesn't use.
    new_pins = {o["gpio"] for o in cfg.get("outputs", [])}
    new_pins |= {s["gpio"] for s in cfg.get("sensors", []) if s.get("driver") == "PIR"}
    if old_cfg is None:
        for pin in USER_GPIO:
            if pin not in new_pins:
                gpio_input(pin)                # input = not driving anything (off)
        log("Released all unused GPIO pins (first setup since start)")
    else:
        for old in old_cfg.get("outputs", []):
            if old["gpio"] not in new_pins:
                gpio_input(old["gpio"])
                log(f"Released GPIO{old['gpio']} (was '{old['key']}')")

    # 2. Set up the new outputs, all OFF; forget outputs that no longer exist
    outputs_state.clear()
    for out in cfg.get("outputs", []):
        gpio_output(out["gpio"], False, out.get("activeHigh", True))      # start OFF
        outputs_state[out["key"]] = "OFF"
    for s in cfg.get("sensors", []):
        if s["driver"] == "PIR":
            gpio_input(s["gpio"])
        elif s["driver"] not in SUPPORTED_DRIVERS:
            log(f"Sensor '{s['key']}': driver {s['driver']} not supported on the hub yet, skipping")

    scan = i2c_scan()
    api("POST", "/api/hubs/config/applied", hub_key, {"version": version, "scan": {"i2c": scan}})
    if outputs_state:
        api("POST", "/api/hubs/outputs", hub_key, outputs_state)

    reply = api("POST", "/api/hubs/sensors", hub_key, {"sensors": [
        {"localId": s["key"], "type": s["type"], "label": s.get("name", s["key"])}
        for s in cfg.get("sensors", [])
    ]})
    names = {s["localId"]: s["thingName"] for s in reply.get("sensors", [])}
    log(f"Config v{version} applied: {len(cfg.get('outputs', []))} outputs, "
        f"{len(names)} sensors, I2C found {[hex(a) for a in scan]}")
    return names


def run(state, screen):
    hub_key = state["hubKey"]
    gateway = Gateway()
    cfg, version, names, outputs_state = None, None, {}, {}      # None = nothing applied yet
    next_config = next_cmd = next_sensor = 0
    last_reading = None

    while True:
        now = time.time()
        try:
            if now >= next_config:
                next_config = now + CONFIG_EVERY
                got = api("GET", "/api/hubs/config", hub_key)
                if got["version"] != version:
                    old_cfg, cfg = cfg, got["config"]
                    names = apply_config(hub_key, cfg, got["version"], outputs_state, old_cfg)
                    version = got["version"]

            if now >= next_cmd:
                next_cmd = now + COMMAND_EVERY
                outputs = {o["key"]: o for o in (cfg or {}).get("outputs", [])}
                for c in api("GET", "/api/hubs/commands", hub_key).get("commands", []):
                    out = outputs.get(c["target"])
                    try:
                        if out is None:
                            raise ValueError(f"no output '{c['target']}' in config v{version}")
                        gpio_output(out["gpio"], c["action"] == "ON", out.get("activeHigh", True))
                        outputs_state[c["target"]] = c["action"]
                        api("POST", f"/api/hubs/commands/{c['id']}/ack", hub_key,
                            {"success": True, "message": f"GPIO{out['gpio']} {c['action']}"})
                        log(f"{c['target']} -> {c['action']}")
                    except Exception as e:
                        api("POST", f"/api/hubs/commands/{c['id']}/ack", hub_key,
                            {"success": False, "message": str(e)[:200]})
                        log(f"Command failed: {e}")

            if now >= next_sensor:
                next_sensor = now + SENSOR_EVERY
                for s in (cfg or {}).get("sensors", []):
                    thing = names.get(s["key"])
                    if not thing or s["driver"] not in SUPPORTED_DRIVERS:
                        continue
                    value = read_sensor(s)
                    if value is not None:
                        gateway.send(build_packet(thing, value, PACKET_TYPE[s["type"]]))
                        if s["driver"] == "SOC_TEMP":
                            last_reading = value

                on = [k for k, v in outputs_state.items() if v == "ON"]
                screen.show(f"EMS HUB {state.get('thingName', '')}",
                            f"{last_reading:.1f} C" if last_reading is not None else "ONLINE",
                            [state.get("organization", "")[:21], ("ON: " + ", ".join(on))[:21] if on else "All outputs off"])

        except ApiError as e:
            if e.status == 401:
                log("The cloud no longer knows this hub; pairing again")
                return                                      # main() starts pairing
            log(f"Cloud error: {e}")
        except OSError as e:
            log(f"Network error: {e}")
            screen.show("EMS HUB", "OFFLINE", ["Retrying..."])

        time.sleep(0.5)


def main():
    if "--reset" in sys.argv:
        try:
            os.remove(STATE_FILE)
            print("Pairing forgotten. Restart the hub to get a new code.")
        except FileNotFoundError:
            print("This hub was not paired.")
        return

    log(f"EMS hub starting. API {API_URL}, gateway {GATEWAY_HOST}:{GATEWAY_PORT}")
    screen = Screen()
    while True:
        state = load_state()
        if not state.get("thingName"):
            state = pair(state, screen)
        run(state, screen)                 # returns only if the cloud forgot the hub
        save_state({})


if __name__ == "__main__":
    main()
