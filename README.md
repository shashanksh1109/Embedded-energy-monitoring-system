# 🏢 Embedded Energy Monitoring System

A full-stack distributed IoT platform for real-time building energy monitoring and thermal management — deployed on AWS. Demonstrates embedded systems programming, custom binary protocols, distributed architecture, cloud infrastructure, and CI/CD automation.

[![Language](https://img.shields.io/badge/Language-C%20%7C%20Python%20%7C%20Java%20%7C%20React-blue)](https://github.com/shashanksh1109/Embedded-energy-monitoring-system)
[![Cloud](https://img.shields.io/badge/Cloud-AWS%20ECS%20Fargate-orange)](https://github.com/shashanksh1109/Embedded-energy-monitoring-system)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple)](https://github.com/shashanksh1109/Embedded-energy-monitoring-system)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green)](https://github.com/shashanksh1109/Embedded-energy-monitoring-system)

---

## 🌐 Live Deployment

| Service | URL |
|---|---|
| **Frontend Dashboard** | http://energy-management-frontend-993268716712.s3-website-us-east-1.amazonaws.com |
| **REST API** | http://energy-management-alb-1672504354.us-east-1.elb.amazonaws.com/api |
| **API Health** | http://energy-management-alb-1672504354.us-east-1.elb.amazonaws.com/api/health |
| **Credentials** | username: `admin` / password: `energy123` |

---

## 📋 Table of Contents

- [System Architecture](#-system-architecture)
- [AWS Cloud Architecture](#-aws-cloud-architecture)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Features](#-features)
- [Data Flow](#-data-flow)
- [Quick Start — Local](#-quick-start--local)
- [Quick Start — AWS](#-quick-start--aws)
- [CI/CD Pipeline](#-cicd-pipeline)
- [API Reference](#-api-reference)
- [Known Issues & Resolutions](#-known-issues--resolutions)

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         BUILDING ZONES                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │   Zone A     │    │   Zone B     │    │  Zone C      │          │
│  │ Conference   │    │  Executive   │    │  Basement    │          │
│  │   Room       │    │   Office     │    │  Storage     │          │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘          │
└─────────┼───────────────────┼───────────────────┼───────────────────┘
          │ TCP/IP Binary     │ TCP/IP Binary     │ TCP/IP Binary
          │ Protocol V1/V2    │ Protocol V1/V2    │ Protocol V1/V2
          ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   GATEWAY LAYER (Python)                            │
│  Multi-Threaded TCP Server → Binary Parser → DB Writer              │
│  Analytics Engine (mean/stddev/min/max every 60s)                  │
│  HVAC Orchestration (threshold-based, direct DB writes on AWS)     │
│  Transports: TCP + MQTT + UART (named pipes)                       │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ PostgreSQL (psycopg2)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   DATABASE LAYER (PostgreSQL)                       │
│  10 tables: zones, devices, temperature_readings,                  │
│  occupancy_readings, hvac_state, power_readings,                   │
│  analytics_snapshots, orchestration_events, schedules,             │
│  ml_predictions — UUID PKs, TIMESTAMPTZ, 90-day retention          │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ JPA/Hibernate
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   BACKEND LAYER (Java Spring Boot)                  │
│  REST API: 7 controllers, JWT auth, WebSocket live data            │
│  Swagger/OpenAPI documentation                                     │
│  Port: 8081                                                        │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Axios HTTP + STOMP WebSocket
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   FRONTEND LAYER (React + Vite)                    │
│  Dashboard, Zone Overview, Charts, Analytics, Schedules            │
│  Real-time updates every 5 seconds                                 │
│  Recharts for data visualization                                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ☁️ AWS Cloud Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        GITHUB                           │
│  git push → GitHub Actions CI/CD Pipeline               │
│    ├── Build + test backend (Maven/JUnit)               │
│    ├── Build + test frontend (Vite/Vitest)              │
│    ├── Build + test gateway (pytest)                    │
│    ├── Push Docker images → ECR                         │
│    ├── Deploy ECS services (force-new-deployment)       │
│    └── Build React → sync to S3                        │
└─────────────────┬───────────────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────────────┐
│              AWS (Terraform managed)                    │
│                                                         │
│  VPC (vpc-076cfa94d6c54c2ee)                           │
│  ├── Public Subnet                                      │
│  │     └── ALB → /api/* → ECS backend                 │
│  │                                                      │
│  ├── Private Subnet                                     │
│  │     ├── ECS Fargate Cluster                         │
│  │     │     ├── energy-management-backend  (Spring)   │
│  │     │     ├── energy-management-gateway  (Python)   │
│  │     │     ├── energy-management-sensor   (C binary) │
│  │     │     └── energy-management-power    (C binary) │
│  │     │                                               │
│  │     └── RDS PostgreSQL (db.t3.micro)               │
│  │                                                      │
│  └── S3                                                │
│        └── React frontend (static website hosting)     │
│                                                         │
│  ECR — 5 Docker image repositories                     │
│  CloudWatch — structured logs for all 5 services       │
│  Secrets Manager — DB credentials + JWT secret         │
│  Service Discovery — gateway.energy.local DNS          │
│  IAM — least-privilege task roles                      │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack

### Embedded Layer (C)
- Language: C11 standard
- Networking: POSIX sockets (TCP/IP)
- Protocols: Custom binary V1 (20-byte) and V2 (32-byte) packets
- IPC: POSIX shared memory + named semaphores
- Hardware-ready: DHT22 temperature, VL53L1X occupancy, INA219 power
- Transports: TCP, MQTT (Mosquitto), UART (named pipes simulation)

### Gateway Layer (Python)
- Multi-threaded TCP server
- Binary packet parser (V1/V2 auto-detection)
- PostgreSQL writer (psycopg2)
- MQTT subscriber (paho-mqtt)
- Analytics engine (60-second statistical snapshots)
- HVAC orchestration (direct DB writes on AWS)

### Database (PostgreSQL)
- 10-table normalized schema
- UUID primary keys
- TIMESTAMPTZ for all timestamps
- 90-day automatic data retention

### Backend (Java Spring Boot)
- Spring Boot 3.x, Java 17
- JPA/Hibernate ORM
- JWT authentication (HS512)
- WebSocket for live data push
- Swagger/OpenAPI documentation
- 7 REST controllers, 7 services, 7 repositories

### Frontend (React + Vite)
- React 18, Vite build tool
- Tailwind CSS dark theme
- React Router for navigation
- Axios for REST API calls
- Recharts for data visualization
- STOMP/SockJS for WebSocket

### Infrastructure (AWS + Terraform)
- ECS Fargate (5 services)
- RDS PostgreSQL (db.t3.micro)
- ALB (Application Load Balancer)
- ECR (5 image repositories)
- S3 (frontend static hosting)
- CloudWatch Logs
- Secrets Manager
- Route 53 Service Discovery
- GitHub Actions CI/CD

---

## 📁 Project Structure

```
Energy Management System/
│
├── 📁 Embedded/                    # C Programs (Sensor Layer)
│   ├── main.c                      # Temperature sensor entry point
│   ├── sensor_logic.c              # Sensor orchestration
│   ├── sensor.c / sensor.h         # Temperature generation
│   ├── hvac_controller.c           # PID-based HVAC control
│   ├── power_meter.c               # Power consumption monitoring
│   ├── occupancy_sensor.c          # People counting (ToF sensor)
│   ├── protocol.c / protocol.h     # Binary packet V1 + V2
│   ├── network.c / network.h       # TCP socket operations
│   ├── pid.c / pid.h               # PID controller
│   ├── ipc.c / ipc.h               # POSIX shared memory IPC
│   ├── mqtt_client.c / .h          # MQTT publish
│   ├── uart_sim.c / .h             # UART simulation (named pipes)
│   ├── config.c / config.h         # Argument parsing
│   └── Dockerfile                  # Multi-stage GCC build
│
├── 📁 Gateway/                     # Python Programs (Aggregation)
│   ├── main.py                     # Entry point
│   ├── gateway_server.py           # Orchestration
│   ├── network.py                  # TCP server + client handler
│   ├── protocol.py                 # Binary parser V1/V2
│   ├── db_writer.py                # PostgreSQL writer
│   ├── analytics.py                # Statistical engine
│   ├── process_manager.py          # Process lifecycle
│   ├── orchestration_config.py     # HVAC thresholds
│   ├── mqtt_subscriber.py          # MQTT subscriber
│   ├── uart_reader.py              # UART reader
│   └── Dockerfile
│
├── 📁 Backend/                     # Java Spring Boot REST API
│   └── src/main/java/com/energy/
│       ├── controller/             # 7 REST controllers
│       ├── service/                # 7 business logic services
│       ├── repository/             # 7 JPA repositories
│       ├── model/                  # 7 JPA entity models
│       ├── dto/                    # 7 response DTOs
│       ├── security/               # JWT auth (JwtUtil, JwtFilter)
│       └── config/                 # CORS, Swagger, WebSocket config
│
├── 📁 Frontend/                    # React + Vite Dashboard
│   └── src/
│       ├── pages/                  # Dashboard, ZoneOverview, Charts,
│       │                           # Analytics, Schedules, Login
│       ├── components/             # Layout, Sidebar, StatCard, SparkLine
│       ├── api/                    # axios, auth, temperature, power,
│       │                           # hvac, occupancy, zones, analytics
│       └── context/                # AuthContext (JWT)
│
├── 📁 Database/
│   └── schema.sql                  # 10-table PostgreSQL schema
│
├── 📁 Terraform/                   # AWS Infrastructure as Code
│   ├── vpc.tf                      # VPC, subnets, IGW, NAT
│   ├── ecs.tf                      # ECS cluster, services, task defs
│   ├── rds.tf                      # PostgreSQL RDS instance
│   ├── alb.tf                      # Application Load Balancer
│   ├── ecr.tf                      # ECR repositories
│   ├── s3.tf                       # Frontend + snapshots buckets
│   ├── iam.tf                      # Task roles and policies
│   ├── secrets.tf                  # Secrets Manager
│   └── service_discovery.tf        # Route 53 private DNS
│
├── 📁 .github/workflows/
│   └── deploy.yml                  # GitHub Actions CI/CD pipeline
│
├── docker-compose.yml              # Local 7-container stack
├── start_system.sh                 # Local startup script
└── README.md                       # This file
```

---

## ✨ Features

- **Custom Binary Protocol** — 20-byte V1 (single value) and 32-byte V2 (4 float fields) packets with checksum validation
- **Multi-Transport** — TCP, MQTT, and UART running in parallel simultaneously
- **PID Temperature Control** — Ziegler-Nichols tuned HVAC controller with anti-windup
- **IPC Synchronization** — POSIX shared memory between HVAC and power meter processes
- **Real-Time Analytics** — mean, stddev, min, max calculated per sensor type every 60 seconds
- **Autonomous HVAC Orchestration** — triggers heating/cooling based on configurable temperature thresholds
- **JWT Authentication** — HS512 signed tokens with 24-hour expiry
- **Live Dashboard** — real-time updates every 5 seconds via polling
- **Historical Charts** — 1h/6h/24h/48h views for temperature, power, and HVAC activity
- **AWS Production Deployment** — fully containerized on ECS Fargate with RDS, ALB, S3
- **Infrastructure as Code** — entire AWS stack managed by Terraform
- **CI/CD Pipeline** — automated build, test, and deploy on every git push

---

## 📦 Binary Packet Format

### V1 Packet (20 bytes) — Temperature, Occupancy, Power
```
Byte:  0-7        8-11        12-15      16      17        18-19
       ┌──────────┬───────────┬──────────┬───────┬─────────┬─────────┐
       │device_id │ timestamp │  value   │ type  │checksum │ padding │
       │ 8 bytes  │ uint32    │  float   │ uint8 │  uint8  │ 2 bytes │
       └──────────┴───────────┴──────────┴───────┴─────────┴─────────┘
Checksum = sum(bytes[0:17]) % 256
```

### V2 Packet (32 bytes) — HVAC State
```
Byte:  0-7        8-11        12      13        14-15      16-19   20-23   24-27   28-31
       ┌──────────┬───────────┬───────┬─────────┬──────────┬───────┬───────┬───────┬───────┐
       │device_id │ timestamp │ type  │ version │ padding  │value1 │value2 │value3 │value4 │
       │ 8 bytes  │ uint32    │ uint8 │  = 2    │ 2 bytes  │ float │ float │ float │ float │
       └──────────┴───────────┴───────┴─────────┴──────────┴───────┴───────┴───────┴───────┘
V2 HVAC fields: value1=heater_pct, value2=cooler_pct, value3=current_temp, value4=setpoint
```

---

## 🚀 Quick Start — Local

### Prerequisites
```bash
gcc --version      # GCC 7.0+
python3 --version  # Python 3.7+
java --version     # Java 17+
node --version     # Node 20+
docker --version   # Docker 20+
```

### Run Full Stack
```bash
# Terminal 1: Start everything
./start_system.sh

# Or manually:
cd Gateway && python3 main.py &
cd Embedded && make all && ./temp_sensor TEMP_A Zone_A 22.0 5 &
cd Backend && mvn clean package -DskipTests && java -jar target/*.jar &
cd Frontend && npm install && npm run dev
```

### Run with Docker Compose
```bash
docker compose up --build
```

Open `http://localhost:5173` — login with `admin` / `energy123`.

---

## ☁️ Quick Start — AWS

### Prerequisites
```bash
aws configure          # Set AWS credentials
terraform --version    # Terraform 1.0+
```

### Deploy
```bash
cd Terraform
terraform init
terraform apply -auto-approve
```

### Destroy (saves costs)
```bash
terraform destroy -auto-approve
```

**Running cost:** ~$0.04/hour (~$1/day). Destroy when not demoing.

---

## 🔄 CI/CD Pipeline

Every push to `main` triggers:

```
Push to main
    │
    ├── test-backend    → mvn test → upload JUnit results
    ├── test-frontend   → npm test (Vitest)
    └── test-gateway    → pytest
          │
          ├── deploy-backend   → build JAR → build Docker → push ECR → ECS update
          ├── deploy-frontend  → npm build (with VITE_API_URL) → S3 sync
          ├── deploy-gateway   → build Docker → push ECR → ECS update
          └── deploy-embedded  → build Docker → push ECR → ECS update (sensor + power)
```

### Required GitHub Secrets
| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |

---

## 📡 API Reference

All endpoints require `Authorization: Bearer <token>` header.

### Authentication
```
POST /api/auth/login
Body: {"username": "admin", "password": "energy123"}
Returns: {"token": "eyJ...", "expiresIn": 86400000}
```

### Temperature
```
GET /api/temperature/{zone}/latest
GET /api/temperature/{zone}/recent?hours=1
GET /api/temperature/{zone}/history?hours=24
```

### Power
```
GET /api/power/{zone}/latest
GET /api/power/{zone}/recent?hours=1
GET /api/power/{zone}/sparkline
```

### HVAC
```
GET /api/hvac/{zone}/latest
GET /api/hvac/{zone}/recent?hours=1
GET /api/hvac/{zone}/mode
```

### Zones
```
GET /api/zones
GET /api/zones/{id}
```

### Analytics
```
GET /api/analytics/{zone}/latest?metricType=TEMP
```

---

## 🐛 Known Issues & Resolutions

A full record of 25 technical issues encountered during development is documented in `docs/issues-report.md`. Key highlights:

| Issue | Root Cause | Resolution |
|---|---|---|
| Spring Boot 403 persistent | Docker cached old JAR silently | Build JAR locally, copy into image |
| Sensor DNS failure on AWS | Route53 zone associated with wrong VPC | `aws route53 associate-vpc-with-hosted-zone` |
| Power checksum failures | Float byte `0x02` falsely detected as V2 packet | Validate type byte alongside version byte |
| HVAC subprocess fails in ECS | Fargate containers are isolated — no subprocess spawning | Write HVAC state directly to DB |
| Backend health check timeout | Spring Boot needs 48s to start, startPeriod was 60s | Increased startPeriod to 120s |
| Login error on S3 frontend | VITE_API_URL missing `/api` suffix | Set correct URL with `/api` at build time |

---

## 📊 Performance Metrics

| Metric | Value |
|---|---|
| Packet size (V1) | 20 bytes |
| Packet size (V2) | 32 bytes |
| Sensor sampling rate | Configurable (1–60s) |
| Analytics interval | 60 seconds |
| Dashboard refresh | 5 seconds |
| JWT expiry | 24 hours |
| Max concurrent sensors | 100+ (thread-per-client) |
| AWS uptime | ECS auto-restarts on failure |

---

## 🎓 Skills Demonstrated

**Embedded Systems:** C programming, POSIX sockets, binary protocol design, PID control, IPC shared memory, DHT22/VL53L1X/INA219 hardware interfaces

**Networking:** TCP/IP socket programming, MQTT pub/sub, UART framing, binary packet parsing, checksum validation

**Backend Engineering:** Spring Boot, JPA/Hibernate, JWT security, REST API design, WebSocket, Swagger/OpenAPI

**Frontend Engineering:** React, Vite, Tailwind CSS, Recharts, real-time data polling, protected routes

**Cloud & DevOps:** AWS ECS Fargate, RDS, ALB, ECR, S3, Secrets Manager, Service Discovery, CloudWatch, IAM, Terraform IaC, GitHub Actions CI/CD

**Database:** PostgreSQL schema design, UUID PKs, TIMESTAMPTZ, JPA repositories, JPQL queries

---

## 👤 Author

**Shashank Sakrappa Hakari**
Master of Science in Software Engineering Systems — Northeastern University (GPA: 3.89)

- 📧 sh.s@northeastern.edu
- 💼 [linkedin.com/in/shashank-s-h-651970349](https://www.linkedin.com/in/shashank-s-h-651970349/)
- 🐙 [github.com/shashanksh1109](https://github.com/shashanksh1109)

**Professional Background:** 2 years Embedded Software Engineer at Ducom Aerospace — ARM Cortex-M4 firmware, power management systems, real-time control.

---

*⭐ If you find this project useful, please star the repository!*

**Keywords:** `embedded-systems` `iot` `aws` `ecs-fargate` `terraform` `github-actions` `spring-boot` `react` `postgresql` `docker` `c-programming` `python` `tcp-sockets` `binary-protocol` `pid-controller` `real-time-systems` `energy-monitoring` `smart-building`
