<div align="center">

![banner](https://raw.githubusercontent.com/shashanksh1109/shashanksh1109/main/banner.svg)

# 🏢 Distributed Smart Building Energy Management System

**A full-stack IoT platform built from bare-metal C firmware to AWS cloud infrastructure.**

*Custom binary protocol · FreeRTOS-style concurrency · PostgreSQL time-series · Spring Boot API · React dashboard · Terraform IaC · GitHub Actions CI/CD*

[![Language](https://img.shields.io/badge/Language-C%20%7C%20Python%20%7C%20Java%20%7C%20React-blue)](https://github.com/shashanksh1109/embedded-energy-monitoring-system)
[![Cloud](https://img.shields.io/badge/Cloud-AWS%20ECS%20Fargate-orange)](https://github.com/shashanksh1109/embedded-energy-monitoring-system)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple)](https://github.com/shashanksh1109/embedded-energy-monitoring-system)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green)](https://github.com/shashanksh1109/embedded-energy-monitoring-system)
[![Status](https://img.shields.io/badge/Status-Live%20on%20AWS-success)](https://github.com/shashanksh1109/embedded-energy-monitoring-system)

</div>

---

## 🧠 What Makes This Different

Most engineers build either embedded systems *or* cloud applications. This project covers the full stack — from a **custom 18-byte binary protocol in C** running on embedded sensor nodes, all the way to a **Terraform-provisioned AWS stack** with ECS Fargate, RDS PostgreSQL, and a live React dashboard.

Every layer was designed, debugged, and deployed independently:

| Layer | Decision | Why |
|:---|:---|:---|
| Binary over JSON | 20-byte packet vs ~80-byte JSON | 75% bandwidth reduction, O(1) parsing, no heap allocation |
| TCP + MQTT + UART | Three transports simultaneously | Different sensor classes need different transport guarantees |
| PID HVAC control | Ziegler-Nichols tuned, anti-windup | Deterministic thermal regulation matching real building controllers |
| ECS Fargate over EC2 | Serverless containers | No AMI management, per-task IAM, auto-restart on failure |
| Terraform IaC | Full AWS stack version-controlled | Reproducible, destroyable, zero manual console clicks |

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
│  Swagger/OpenAPI documentation · Port: 8081                        │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Axios HTTP + STOMP WebSocket
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   FRONTEND LAYER (React + Vite)                    │
│  Dashboard, Zone Overview, Charts, Analytics, Schedules            │
│  Real-time updates every 5 seconds · Recharts visualization        │
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
│  VPC                                                    │
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
- 10-table normalized schema · UUID primary keys
- TIMESTAMPTZ for all timestamps · 90-day automatic data retention

### Backend (Java Spring Boot)
- Spring Boot 3.x, Java 17 · JPA/Hibernate ORM
- JWT authentication (HS512) · WebSocket for live data push
- Swagger/OpenAPI documentation
- 7 REST controllers, 7 services, 7 repositories

### Frontend (React + Vite)
- React 18, Vite build tool · Tailwind CSS dark theme
- Axios for REST API · Recharts for data visualization
- STOMP/SockJS for WebSocket

### Infrastructure (AWS + Terraform)
- ECS Fargate (5 services) · RDS PostgreSQL (db.t3.micro)
- ALB · ECR (5 image repositories) · S3 (frontend static hosting)
- CloudWatch Logs · Secrets Manager · Route 53 Service Discovery
- GitHub Actions CI/CD

---

## 📁 Project Structure

```
Energy Management System/
│
├── 📁 Embedded/                    # C Programs (Sensor Layer)
│   ├── main.c                      # Temperature sensor entry point
│   ├── sensor_logic.c              # Sensor orchestration
│   ├── hvac_controller.c           # PID-based HVAC control
│   ├── power_meter.c               # Power consumption monitoring
│   ├── protocol.c / protocol.h     # Binary packet V1 + V2
│   ├── network.c / network.h       # TCP socket operations
│   ├── pid.c / pid.h               # PID controller
│   ├── ipc.c / ipc.h               # POSIX shared memory IPC
│   ├── mqtt_client.c / .h          # MQTT publish
│   ├── uart_sim.c / .h             # UART simulation (named pipes)
│   └── Dockerfile                  # Multi-stage GCC build
│
├── 📁 Gateway/                     # Python Programs (Aggregation)
│   ├── gateway_server.py           # Orchestration
│   ├── network.py                  # TCP server + client handler
│   ├── protocol.py                 # Binary parser V1/V2
│   ├── db_writer.py                # PostgreSQL writer
│   ├── analytics.py                # Statistical engine
│   ├── mqtt_subscriber.py          # MQTT subscriber
│   └── Dockerfile
│
├── 📁 Backend/                     # Java Spring Boot REST API
│   └── src/main/java/com/energy/
│       ├── controller/             # 7 REST controllers
│       ├── service/                # 7 business logic services
│       ├── repository/             # 7 JPA repositories
│       ├── model/                  # 7 JPA entity models
│       ├── security/               # JWT auth (JwtUtil, JwtFilter)
│       └── config/                 # CORS, Swagger, WebSocket config
│
├── 📁 Frontend/                    # React + Vite Dashboard
│   └── src/
│       ├── pages/                  # Dashboard, ZoneOverview, Charts,
│       │                           # Analytics, Schedules, Login
│       ├── components/             # Layout, Sidebar, StatCard
│       └── api/                    # axios, auth, temperature, power
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
└── README.md
```

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
       │device_id │ timestamp │ type  │version=2│ padding  │value1 │value2 │value3 │value4 │
       │ 8 bytes  │ uint32    │ uint8 │  uint8  │ 2 bytes  │ float │ float │ float │ float │
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

### Run with Docker Compose
```bash
docker compose up --build
```

Open `http://localhost:5173`

### Run manually
```bash
cd Gateway && python3 main.py &
cd Embedded && make all && ./temp_sensor TEMP_A Zone_A 22.0 5 &
cd Backend && mvn clean package -DskipTests && java -jar target/*.jar &
cd Frontend && npm install && npm run dev
```

---

## ☁️ Deploy to AWS

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

### Destroy
```bash
terraform destroy -auto-approve
```

> ⚠️ Running cost: ~$0.04/hour (~$1/day). Destroy when not demoing.

---

## 🔄 CI/CD Pipeline

Every push to `main` triggers:

```
Push to main
    │
    ├── test-backend    → mvn test
    ├── test-frontend   → npm test (Vitest)
    └── test-gateway    → pytest
          │
          ├── deploy-backend   → build JAR → Docker → ECR → ECS update
          ├── deploy-frontend  → npm build → S3 sync
          ├── deploy-gateway   → Docker → ECR → ECS update
          └── deploy-embedded  → Docker → ECR → ECS update
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
Body: {"username": "admin", "password": "your_password"}
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

### Zones & Analytics
```
GET /api/zones
GET /api/zones/{id}
GET /api/analytics/{zone}/latest?metricType=TEMP
```

---

## 🐛 Key Engineering Challenges

A full record of 25 technical issues encountered is documented in `docs/issues-report.md`. Key highlights:

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
| Analytics interval | 60 seconds |
| Dashboard refresh | 5 seconds |
| JWT expiry | 24 hours |
| Max concurrent sensors | 100+ (thread-per-client) |
| CI/CD ops effort reduction | 90% vs manual deployment |

---

## 🎓 Skills Demonstrated

**Embedded Systems:** C programming, POSIX sockets, binary protocol design, PID control, IPC shared memory, DHT22/VL53L1X/INA219 hardware interfaces

**Networking:** TCP/IP socket programming, MQTT pub/sub, UART framing, binary packet parsing, checksum validation

**Backend:** Spring Boot, JPA/Hibernate, JWT security, REST API design, WebSocket, Swagger/OpenAPI

**Frontend:** React, Vite, Tailwind CSS, Recharts, real-time data polling, protected routes

**Cloud & DevOps:** AWS ECS Fargate, RDS, ALB, ECR, S3, Secrets Manager, Service Discovery, CloudWatch, IAM, Terraform IaC, GitHub Actions CI/CD

**Database:** PostgreSQL schema design, UUID PKs, TIMESTAMPTZ, JPA repositories, JPQL queries

---

## 👤 Author

**Shashank Sakrappa Hakari**

M.S. Software Engineering Systems — Northeastern University (GPA: 3.89)

📧 sh.s@northeastern.edu &nbsp;·&nbsp;
💼 [LinkedIn](https://www.linkedin.com/in/shashank-s-h-651970349/) &nbsp;·&nbsp;
🌐 [Portfolio](https://shashanksh1109.github.io) &nbsp;·&nbsp;
🐙 [GitHub](https://github.com/shashanksh1109)

---

`embedded-systems` `iot` `aws` `ecs-fargate` `terraform` `github-actions` `spring-boot` `react` `postgresql` `docker` `c-programming` `python` `tcp-sockets` `binary-protocol` `pid-controller` `real-time-systems` `energy-monitoring` `smart-building`
