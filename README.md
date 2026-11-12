<div align="center">

![banner](https://raw.githubusercontent.com/shashanksh1109/shashanksh1109/main/banner.svg)

# Smart Building Energy Monitoring - Multi-Tenant IoT Platform

**From C firmware and a Raspberry Pi hub to a multi-tenant cloud service on AWS.**

*Custom binary protocol | Raspberry Pi hub | PostgreSQL row-level security | Spring Boot | React | Amazon Cognito | Terraform | ECS Fargate*

</div>

---

## What it does

A customer can, entirely from the browser:

1. **Sign up** with their email (verified by a code) and create their **organization**.
2. Add **zones** (rooms) to their building.
3. Plug in a **Raspberry Pi hub**: its OLED shows a pairing code; entering the code on the website adds the hub to *their* organization.
4. Describe the **hardware wiring** on a web page (which LED, fan or sensor is on which GPIO pin). The hub downloads it and applies it - no code changes.
5. Watch **live sensor data** per zone, and switch **outputs** (fan, LEDs, relays) with ON/OFF buttons that show the state **confirmed by the hub**.

Every organization's data is isolated **inside PostgreSQL** with row-level security.

---

## Architecture

```
                         Browser (any customer, anywhere)
                                      |
                 S3 static site (React) + Amazon Cognito (sign-up / login)
                                      |  HTTPS to Cognito, HTTP to the API
                                      v
   +------------------- AWS VPC (Terraform) -------------------------------+
   |                                                                       |
   |   ALB --> Spring Boot API (ECS Fargate)                               |
   |             - verifies Cognito JWTs (RS256, JWKS)                     |
   |             - org from memberships -> set_config('app.current_org')  |
   |             - connects as role ems_api (row-level security applies)   |
   |                              |                                        |
   |                              v                                        |
   |                     PostgreSQL 15 (RDS)  <-- schema loaded by Lambda  |
   |                              ^                                        |
   |   NLB --> Python gateway (ECS Fargate)                                |
   |             - 20/32-byte binary packets, checksum, device registry    |
   |             - writes readings per organization, per-zone analytics    |
   +-------------------------------^--------------------------------------+
                                   |  TCP readings          ^ HTTP polling
                                   |                        | (pair, config, commands)
                     Raspberry Pi hub (Python, systemd)  ---+
                       - OLED pairing code, GPIO outputs, sensor drivers
                       - simulated C devices also run on ECS for demo data
```

---

## Key engineering decisions

| Area | Decision | Why |
|---|---|---|
| Tenant isolation | PostgreSQL **row-level security** on every tenant table; the API connects as a non-owner role and sets `app.current_org` on every pooled connection | Isolation is enforced by the database, even if a query forgets a filter. Missing org = sees nothing (fail closed). Proven with a second tenant holding a same-named zone and a newer reading |
| Cross-tenant links | **Composite foreign keys** `(org_id, id)` | A zone can never point at another organization's building, a reading at another organization's device |
| Accounts | **Amazon Cognito**; backend verifies RS256 access tokens (issuer, expiry, `token_use`, `client_id`) | No passwords stored by the app; 60-minute tokens with silent refresh |
| Onboarding | Sign-up -> email code -> create organization (one transaction, advisory lock against double-submits) | Self-service, no manual database work |
| Hub pairing | **Code shown on the device**, typed in the dashboard ("device code" flow); hub keeps a 32-byte secret key; only SHA-256 hashes stored | Works for headless devices; the code expires in 10 minutes |
| Remote control | Hub **polls** for commands every 2 s; commands expire after 30 s; dashboard shows the **confirmed** state | Home routers block inbound connections; no stale command ever fires late |
| Hardware config | Versioned JSON config edited on the web, **validated server-side** (free GPIO pins only, no pin/I2C address reused) | Rewiring needs no code changes; a bad config can never reach a hub |
| Pin safety | Hub releases pins a new config no longer uses, and all unused pins on start | An output moved or removed can never stay stuck ON |
| Device protocol | Fixed 20-byte (V1) / 32-byte (V2) little-endian packets with checksum | Compact, simple to parse on constrained devices |
| HVAC control | PID per direction + **dead band with hysteresis**; local control keeps running when the network is down | Mode switches cut from ~556 to ~22 per 10 minutes in simulation |
| Reliability | Exponential-backoff reconnect (C controller, hub), `systemd` restart, idempotent inserts (`ON CONFLICT DO NOTHING`) | Devices recover on their own; resent readings are stored once |
| Infrastructure | Terraform: VPC, ALB, NLB, ECS Fargate, RDS, Cognito, Secrets Manager, Lambda schema loader | Reproducible from an empty AWS account |

---

## Repository layout

```
Embedded/     C programs: temperature sensor, HVAC controller (PID, dead band, reconnect), power meter
Gateway/      Python TCP gateway: binary protocol, device registry, analytics, HVAC fallback logic (+ pytest)
Backend/      Spring Boot API: Cognito JWT, tenant context, RLS-backed repositories, hubs, devices, onboarding
Frontend/     React + Vite dashboard: sign-up, zones, devices, hubs (buttons, hardware setup editor)
Hub/          Raspberry Pi hub agent (ems_hub.py) and its systemd service
Database/     schema.sql (tables, RLS policies, roles, demo seed); dev-only helper scripts
Terraform/    AWS infrastructure (VPC, ECS, RDS, ALB/NLB, Cognito, secrets, schema-loader Lambda)
tools/        factory_provision.py - creates factory devices with label codes
scripts/      aws-up.sh / aws-down.sh
```

---

## Data model (PostgreSQL)

- **Tenancy:** `organizations`, `app_users` (Cognito `sub`), `memberships` (OWNER / ADMIN / VIEWER)
- **Places:** `buildings`, `zones`
- **Devices:** `devices` (PENDING / ACTIVE / DISABLED, `last_seen_at`), `device_claims`, `factory_devices`
- **Hubs:** `hubs`, `hub_sensors`, `hub_commands`, `hub_outputs`, `hub_configs` (versioned JSON + I2C scan)
- **Time series:** `temperature_readings`, `occupancy_readings`, `power_readings` (watts + per-interval energy), `hvac_state`, `analytics_snapshots`, `orchestration_events`

Tenant tables carry `org_id` and a `tenant_isolation` policy. Tables a device must reach **before** its organization is known (`hubs`, `device_claims`, ...) have no RLS; every user-facing query on them filters by organization in code.

---

## Run it locally

Prerequisites: Docker Desktop, Java 17+, Maven, Node 20+.

```bash
# Database, gateway, simulated devices, backend
docker compose up --build -d

# Frontend (http://localhost:5173)
cd Frontend && npm install && npm run dev
```

- Without Cognito settings, the login page uses the built-in demo login (`admin` / `energy123`, Demo Organization).
- With Cognito: put `COGNITO_ISSUER` and `COGNITO_CLIENT_ID` in `.env` (repo root) and `VITE_COGNITO_CLIENT_ID` / `VITE_COGNITO_REGION` in `Frontend/.env.local`.
- `Database/dev_roles.sql` gives the `ems_api` role a local-only password; `Database/dev_second_org.sql` adds a second tenant for isolation tests.

Tests:

```bash
cd Gateway && python -m pytest tests -v     # protocol, multi-tenant writes, framing, HVAC ownership
cd Backend && mvn test
```

---

## Deploy to AWS

```bash
cd Terraform && terraform init && cd ..
./scripts/aws-up.sh      # infrastructure, images, frontend build (with Cognito client ID), ECS rollout
./scripts/aws-down.sh    # tear everything down (the stack costs a few dollars per day while running)
```

The schema-loader Lambda loads `Database/schema.sql` into a fresh RDS instance and sets the `ems_api` password from Secrets Manager. Check it with `terraform output schema_load_result`.

---

## Set up a Raspberry Pi hub

1. Copy `Hub/ems_hub.py` to `~/ems-hub/` on the Pi (Python venv with `luma.oled` and `smbus2` for the OLED and I2C scan).
2. Create `/etc/ems-hub.conf`:
   ```
   API_URL=http://<ALB address>
   GATEWAY_HOST=<NLB address>
   GATEWAY_PORT=8080
   ```
3. Install `Hub/ems-hub.service` into `/etc/systemd/system/` and run `sudo systemctl enable --now ems-hub`.
4. The OLED shows a pairing code: **Hubs -> + Add hub** on the website.
5. **Hardware setup**: add outputs and sensors with their pins; the hub applies them within ~15 s.

Supported on the hub today: Pi CPU temperature, PIR motion sensor, GPIO outputs (LED / fan via transistor / relay). BME280 and INA219 configurations are accepted and validated, with drivers still to come.

---

## Known limitations

- The site and API use **HTTP**; HTTPS (CloudFront + ACM + a domain) is planned.
- Devices on the raw TCP gateway are identified by thing name only; the planned fix is **MQTT over TLS with per-device certificates** (AWS IoT Core).
- One building per organization in the UI; no "invite member" yet (memberships already support several users and roles).
- Commands reach hubs by polling (~2 s latency), not push.
- A single NAT gateway (one availability zone) for private-subnet egress.

## Roadmap

- HTTPS with a custom domain
- Invite members and role management in the UI
- BME280 / INA219 drivers on the hub; one-line hub installer
- MQTT over TLS (AWS IoT Core) for device connectivity
- Flyway migrations for the backend schema

---

## Author

**Shashank Sakrappa Hakari** - M.S. Software Engineering Systems, Northeastern University

[LinkedIn](https://www.linkedin.com/in/shashanksh232/) | [GitHub](https://github.com/shashanksh1109)