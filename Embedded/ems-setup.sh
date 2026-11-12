#!/usr/bin/env bash
# ems-setup.sh - claim this device ONCE and install it as a service.
# Usage: sudo ./ems-setup.sh <api-url> <claim-code> <gateway-host> [zone-label]
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Please run with sudo"; exit 1; }
[ $# -ge 3 ] || { echo "Usage: sudo $0 <api-url> <claim-code> <gateway-host> [zone-label]"; exit 1; }

API_URL="$1"; CODE="$2"; GATEWAY_HOST="$3"; ZONE_LABEL="${4:-MyZone}"
CONF=/etc/ems-device.conf
RUN_AS="${SUDO_USER:-shashanksh}"
SENSOR_BIN="/home/$RUN_AS/Embedded-energy-monitoring-system/Embedded/temp_sensor"

if [ -f "$CONF" ] && [ "${FORCE:-0}" != "1" ]; then
  echo "Already set up ($CONF exists). Use: sudo FORCE=1 $0 ... to set up again."; exit 1
fi
[ -x "$SENSOR_BIN" ] || { echo "Sensor program not found: $SENSOR_BIN"; exit 1; }

echo "Claiming this device with code $CODE ..."
RESPONSE=$(curl -sS -f -X POST "$API_URL/api/devices/claim" \
  -H "Content-Type: application/json" -d "{\"code\":\"$CODE\"}") \
  || { echo "Claim failed: invalid, used or expired code, or the API is not reachable"; exit 1; }

THING_NAME=$(printf '%s' "$RESPONSE" | python3 -c 'import sys, json; print(json.load(sys.stdin)["thingName"])')
echo "Claimed. This device is now $THING_NAME"

# Remember who we are (the claim code is never stored)
cat > "$CONF" << EOC
THING_NAME=$THING_NAME
GATEWAY_HOST=$GATEWAY_HOST
ZONE_LABEL=$ZONE_LABEL
EOC
chmod 600 "$CONF"

# Run on every boot; restart automatically if it stops
cat > /etc/systemd/system/ems-sensor.service << EOS
[Unit]
Description=EMS temperature sensor ($THING_NAME)
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=$CONF
ExecStart=$SENSOR_BIN \${THING_NAME} \${ZONE_LABEL} 22.0 5 --hardware
Restart=always
RestartSec=5
User=$RUN_AS

[Install]
WantedBy=multi-user.target
EOS

systemctl daemon-reload
systemctl enable --now ems-sensor
echo "Installed. Check it with: systemctl status ems-sensor"
