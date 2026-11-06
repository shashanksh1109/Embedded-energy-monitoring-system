-- =====================================================================
-- EMS schema v2 — multi-tenant (Phase 1, step 1)
--
-- Every customer is an ORGANIZATION. Everything below it carries org_id,
-- and PostgreSQL row-level security (RLS) guarantees one organization
-- can never read or write another organization's rows — even if a
-- Java query forgets to filter.
--
-- Run this file as ONE script (Flyway migration or `psql -f`), not split
-- on semicolons.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. Tenants and people
-- ---------------------------------------------------------------------

CREATE TABLE organizations (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(120) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- One row per person. id = the user's Cognito "sub" (a stable UUID),
-- so we never store passwords ourselves.
CREATE TABLE app_users (
    id            UUID         PRIMARY KEY,
    email         VARCHAR(254) NOT NULL UNIQUE,
    display_name  VARCHAR(120),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Which users belong to which organizations, and with what role.
-- A user can belong to several organizations (e.g. a contractor).
CREATE TABLE memberships (
    org_id      UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES app_users(id)     ON DELETE CASCADE,
    role        VARCHAR(16) NOT NULL CHECK (role IN ('OWNER', 'ADMIN', 'VIEWER')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (org_id, user_id)
);
CREATE INDEX idx_memberships_user ON memberships (user_id);

-- ---------------------------------------------------------------------
-- 2. Places
-- ---------------------------------------------------------------------

CREATE TABLE buildings (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id      UUID         NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name        VARCHAR(120) NOT NULL,
    address     VARCHAR(255),
    timezone    VARCHAR(64)  NOT NULL DEFAULT 'America/New_York',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (org_id, name),
    UNIQUE (org_id, id)                 -- lets child tables reference (org_id, id) together
);

CREATE TABLE zones (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id       UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    building_id  UUID        NOT NULL,
    name         VARCHAR(64) NOT NULL,
    capacity     INTEGER     NOT NULL DEFAULT 0 CHECK (capacity >= 0),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, name),         -- "Room 1" can exist in many buildings
    UNIQUE (org_id, id),
    -- composite FK: a zone can only point at a building of the SAME organization
    FOREIGN KEY (org_id, building_id) REFERENCES buildings (org_id, id) ON DELETE CASCADE
);
CREATE INDEX idx_zones_org ON zones (org_id);

-- ---------------------------------------------------------------------
-- 3. Devices (with claim-code onboarding)
-- ---------------------------------------------------------------------

CREATE TABLE devices (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id            UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    zone_id           UUID,                                -- NULL until the device is placed in a zone
    thing_name        VARCHAR(128) NOT NULL UNIQUE,      -- identity in AWS IoT Core / certificate
    device_type       VARCHAR(32)  NOT NULL CHECK (device_type IN ('TEMP', 'OCCUPANCY', 'HVAC', 'POWER', 'MULTI')),
    display_name      VARCHAR(120),
    status            VARCHAR(16)  NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING', 'ACTIVE', 'DISABLED')),
    claim_code_hash   VARCHAR(128),                       -- store a HASH of the claim code, never the code
    claim_expires_at  TIMESTAMPTZ,
    claimed_at        TIMESTAMPTZ,
    last_seen_at      TIMESTAMPTZ,                        -- updated by ingest; drives "online/offline"
    firmware_version  VARCHAR(32),
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (org_id, id),
    -- a device can only be placed in a zone of its own organization
    -- (MATCH SIMPLE: the check is skipped while zone_id is NULL)
    FOREIGN KEY (org_id, zone_id) REFERENCES zones (org_id, id) ON DELETE SET NULL (zone_id)   -- PostgreSQL 15+
);
CREATE INDEX idx_devices_org  ON devices (org_id);
CREATE INDEX idx_devices_zone ON devices (zone_id);

-- ---------------------------------------------------------------------
-- 4. Readings (time-series). org_id is copied onto every row on purpose:
--    RLS can then check one column instead of joining through zones.
-- ---------------------------------------------------------------------

CREATE TABLE temperature_readings (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    device_id      UUID        NOT NULL,
    zone_id        UUID        NOT NULL,
    temperature_c  DOUBLE PRECISION NOT NULL CHECK (temperature_c BETWEEN -50 AND 150),
    humidity_pct   DOUBLE PRECISION CHECK (humidity_pct BETWEEN 0 AND 100),
    recorded_at    TIMESTAMPTZ NOT NULL,
    received_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- composite FKs: a reading's device and zone must belong to the reading's organization
    FOREIGN KEY (org_id, device_id) REFERENCES devices (org_id, id) ON DELETE CASCADE,
    FOREIGN KEY (org_id, zone_id)   REFERENCES zones   (org_id, id) ON DELETE CASCADE,
    UNIQUE (device_id, recorded_at)                       -- idempotent: a resent reading is stored once
);
CREATE INDEX idx_temp_zone_time ON temperature_readings (zone_id, recorded_at DESC);

CREATE TABLE occupancy_readings (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id           UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    device_id        UUID        NOT NULL,
    zone_id          UUID        NOT NULL,
    occupancy_count  INTEGER     NOT NULL CHECK (occupancy_count >= 0),
    distance_mm      DOUBLE PRECISION,
    recorded_at      TIMESTAMPTZ NOT NULL,
    received_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (org_id, device_id) REFERENCES devices (org_id, id) ON DELETE CASCADE,
    FOREIGN KEY (org_id, zone_id)   REFERENCES zones   (org_id, id) ON DELETE CASCADE,
    UNIQUE (device_id, recorded_at)
);
CREATE INDEX idx_occ_zone_time ON occupancy_readings (zone_id, recorded_at DESC);

CREATE TABLE hvac_state (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id        UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    device_id     UUID        NOT NULL,
    zone_id       UUID        NOT NULL,
    heater_pct    DOUBLE PRECISION NOT NULL CHECK (heater_pct BETWEEN 0 AND 100),
    cooler_pct    DOUBLE PRECISION NOT NULL CHECK (cooler_pct BETWEEN 0 AND 100),
    current_temp  DOUBLE PRECISION NOT NULL,
    setpoint      DOUBLE PRECISION NOT NULL,
    recorded_at   TIMESTAMPTZ NOT NULL,
    received_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (org_id, device_id) REFERENCES devices (org_id, id) ON DELETE CASCADE,
    FOREIGN KEY (org_id, zone_id)   REFERENCES zones   (org_id, id) ON DELETE CASCADE,
    UNIQUE (device_id, recorded_at)
);
CREATE INDEX idx_hvac_zone_time ON hvac_state (zone_id, recorded_at DESC);

CREATE TABLE power_readings (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id       UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    device_id    UUID        NOT NULL,
    zone_id      UUID        NOT NULL,
    power_w      DOUBLE PRECISION NOT NULL CHECK (power_w >= 0),
    energy_wh    DOUBLE PRECISION NOT NULL CHECK (energy_wh >= 0),  -- energy in THIS interval → SUM() it
    interval_s   INTEGER     NOT NULL CHECK (interval_s > 0),
    recorded_at  TIMESTAMPTZ NOT NULL,
    received_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    FOREIGN KEY (org_id, device_id) REFERENCES devices (org_id, id) ON DELETE CASCADE,
    FOREIGN KEY (org_id, zone_id)   REFERENCES zones   (org_id, id) ON DELETE CASCADE,
    UNIQUE (device_id, recorded_at)
);
CREATE INDEX idx_power_zone_time ON power_readings (zone_id, recorded_at DESC);

-- ---------------------------------------------------------------------
-- 5. Row-level security
--
-- The backend runs every request inside a transaction and first does:
--     SET LOCAL app.current_org = '<org uuid the user selected>';
-- (after checking in `memberships` that the user really belongs to it).
-- Every policy below compares org_id with that setting.
--
-- current_setting(..., true) returns NULL when the setting is missing,
-- and `org_id = NULL` is never true — so a request that forgot to set
-- the org sees NOTHING instead of everything. Fail closed.
--
-- FORCE makes the policies apply even to the table owner.
-- ---------------------------------------------------------------------

ALTER TABLE buildings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE buildings            FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON buildings
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

ALTER TABLE zones                ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones                FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON zones
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

ALTER TABLE devices              ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices              FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON devices
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

ALTER TABLE temperature_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE temperature_readings FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON temperature_readings
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

ALTER TABLE occupancy_readings   ENABLE ROW LEVEL SECURITY;
ALTER TABLE occupancy_readings   FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON occupancy_readings
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

ALTER TABLE hvac_state           ENABLE ROW LEVEL SECURITY;
ALTER TABLE hvac_state           FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON hvac_state
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

ALTER TABLE power_readings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE power_readings       FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON power_readings
    USING      (org_id = current_setting('app.current_org', true)::uuid)
    WITH CHECK (org_id = current_setting('app.current_org', true)::uuid);

-- organizations, app_users and memberships are NOT under the org policy:
-- the backend must read memberships to decide which org a user may select.
-- Access to those three tables is controlled in the backend code instead.

-- ---------------------------------------------------------------------
-- 6. Database roles
--
-- ems_api     : used by Spring Boot. Subject to RLS.
-- ems_ingest  : used by the ingest worker. It writes readings for ALL
--               organizations (it looks up org_id from the device), so it
--               bypasses RLS — and gets INSERT/UPDATE only, no DELETE.
-- Set real passwords from Secrets Manager; never hardcode them.
-- ---------------------------------------------------------------------

CREATE ROLE ems_api    LOGIN;
CREATE ROLE ems_ingest LOGIN BYPASSRLS;   -- on RDS, confirm your master user may grant BYPASSRLS

GRANT SELECT, INSERT, UPDATE, DELETE
    ON organizations, app_users, memberships, buildings, zones, devices
    TO ems_api;
GRANT SELECT
    ON temperature_readings, occupancy_readings, hvac_state, power_readings
    TO ems_api;

GRANT SELECT ON devices TO ems_ingest;
GRANT UPDATE (last_seen_at, firmware_version) ON devices TO ems_ingest;
GRANT INSERT
    ON temperature_readings, occupancy_readings, hvac_state, power_readings
    TO ems_ingest;


-- =====================================================================
-- Development seed data for schema v2 (one demo organization).
-- Run AFTER schema_v2_multitenant.sql, on the same connection.
-- =====================================================================

-- Fixed UUID so the gateway and your tests can refer to the demo org.
INSERT INTO organizations (id, name)
VALUES ('00000000-0000-0000-0000-000000000001', 'Demo Organization')
ON CONFLICT (id) DO NOTHING;

-- The tables below have FORCE ROW LEVEL SECURITY, which applies even to
-- the admin user running this script. Tell PostgreSQL which organization
-- these rows belong to, or every INSERT is rejected by the policy.
SET app.current_org = '00000000-0000-0000-0000-000000000001';

INSERT INTO buildings (id, org_id, name, address)
VALUES ('00000000-0000-0000-0000-0000000000b1',
        '00000000-0000-0000-0000-000000000001',
        'Demo Building', 'Boston, MA')
ON CONFLICT (id) DO NOTHING;

INSERT INTO zones (org_id, building_id, name, capacity) VALUES
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000b1', 'Zone_A', 20),
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000b1', 'Zone_B', 10),
    ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-0000000000b1', 'Zone_C',  5)
ON CONFLICT (building_id, name) DO NOTHING;

-- Devices: thing_name = the ID the sensor sends (TEMP_A, TEMP_PI, ...).
INSERT INTO devices (org_id, zone_id, thing_name, device_type, display_name, status, claimed_at)
SELECT z.org_id, z.id, d.thing_name, d.device_type, d.display_name, 'ACTIVE', NOW()
FROM zones z
JOIN (VALUES
        ('TEMP_A',  'TEMP',      'Simulated temperature sensor'),
        ('OCC_A',   'OCCUPANCY', 'Simulated occupancy sensor'),
        ('HVAC_A',  'HVAC',      'Simulated HVAC controller'),
        ('POWER_A', 'POWER',     'Simulated power meter'),
        ('TEMP_PI', 'TEMP',      'Raspberry Pi SoC temperature')
     ) AS d(thing_name, device_type, display_name) ON TRUE
WHERE z.name = 'Zone_A'
ON CONFLICT (thing_name) DO NOTHING;

RESET app.current_org;