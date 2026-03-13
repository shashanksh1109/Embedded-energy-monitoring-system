-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS zones (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(32) NOT NULL UNIQUE,
    description VARCHAR(128),
    capacity    INTEGER     NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id     VARCHAR(16) NOT NULL UNIQUE,
    zone_id       UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    device_type   VARCHAR(16) NOT NULL,
    use_hardware  BOOLEAN     NOT NULL DEFAULT FALSE,
    description   VARCHAR(128),
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS temperature_readings (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id   VARCHAR(16) NOT NULL,
    zone_id     UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    value_c     FLOAT       NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS occupancy_readings (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id    VARCHAR(16) NOT NULL,
    zone_id      UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    people_count INTEGER     NOT NULL CHECK (people_count >= 0),
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS hvac_state (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id    VARCHAR(16) NOT NULL,
    zone_id      UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    setpoint_c   FLOAT       NOT NULL,
    heater_pct   FLOAT       NOT NULL CHECK (heater_pct  BETWEEN 0 AND 100),
    cooler_pct   FLOAT       NOT NULL CHECK (cooler_pct  BETWEEN 0 AND 100),
    pid_output   FLOAT       NOT NULL,
    current_temp FLOAT       NOT NULL,
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS power_readings (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id   VARCHAR(16) NOT NULL,
    zone_id     UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    power_kw    FLOAT       NOT NULL CHECK (power_kw >= 0),
    energy_kwh  FLOAT       NOT NULL CHECK (energy_kwh >= 0),
    cost_usd    FLOAT       NOT NULL CHECK (cost_usd >= 0),
    hvac_pct    FLOAT       NOT NULL CHECK (hvac_pct BETWEEN 0 AND 100),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS schedules (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name              VARCHAR(64) NOT NULL,
    day_of_week       SMALLINT    NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time        TIME        NOT NULL,
    end_time          TIME        NOT NULL,
    setpoint_c        FLOAT       NOT NULL,
    power_limit_kw    FLOAT       NOT NULL,
    turn_off_if_empty BOOLEAN     NOT NULL DEFAULT TRUE,
    is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

CREATE TABLE IF NOT EXISTS analytics_snapshots (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id      UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    packet_type  VARCHAR(16) NOT NULL,
    mean         FLOAT       NOT NULL,
    stddev       FLOAT       NOT NULL,
    min_val      FLOAT       NOT NULL,
    max_val      FLOAT       NOT NULL,
    sample_count INTEGER     NOT NULL CHECK (sample_count > 0),
    window_start TIMESTAMPTZ NOT NULL,
    window_end   TIMESTAMPTZ NOT NULL,
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orchestration_events (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id     UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    event_type  VARCHAR(32) NOT NULL,
    description VARCHAR(256),
    temperature FLOAT,
    hvac_pid    INTEGER,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ml_predictions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id             UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    model_name          VARCHAR(64) NOT NULL,
    predicted_setpoint  FLOAT,
    predicted_occupancy INTEGER,
    confidence          FLOAT       CHECK (confidence BETWEEN 0.0 AND 1.0),
    features_json       JSONB,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_temp_zone_time   ON temperature_readings (zone_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_occ_zone_time    ON occupancy_readings   (zone_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_hvac_zone_time   ON hvac_state           (zone_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_power_zone_time  ON power_readings       (zone_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_zone   ON analytics_snapshots  (zone_id, packet_type, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_zone_time ON orchestration_events (zone_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_ml_zone_time     ON ml_predictions       (zone_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_schedules_day    ON schedules            (day_of_week, start_time);

CREATE OR REPLACE FUNCTION cleanup_old_sensor_data()
RETURNS void AS $$
BEGIN
    DELETE FROM temperature_readings WHERE recorded_at < NOW() - INTERVAL '90 days';
    DELETE FROM occupancy_readings   WHERE recorded_at < NOW() - INTERVAL '90 days';
    DELETE FROM hvac_state           WHERE recorded_at < NOW() - INTERVAL '90 days';
    DELETE FROM power_readings       WHERE recorded_at < NOW() - INTERVAL '90 days';
    RAISE NOTICE 'Sensor data older than 90 days deleted at %', NOW();
END;
$$ LANGUAGE plpgsql;

INSERT INTO zones (name, description, capacity) VALUES
    ('Zone_A', 'Conference Room',  20),
    ('Zone_B', 'Executive Office', 10),
    ('Zone_C', 'Basement Storage',  5)
ON CONFLICT (name) DO NOTHING;

INSERT INTO devices (device_id, zone_id, device_type, use_hardware, description)
SELECT 'TEMP_A',  id, 'TEMP',      FALSE, 'Temperature sensor - Zone A' FROM zones WHERE name = 'Zone_A'
UNION ALL
SELECT 'OCC_A',   id, 'OCCUPANCY', FALSE, 'Occupancy sensor - Zone A'   FROM zones WHERE name = 'Zone_A'
UNION ALL
SELECT 'HVAC_A',  id, 'HVAC',      FALSE, 'HVAC controller - Zone A'    FROM zones WHERE name = 'Zone_A'
UNION ALL
SELECT 'POWER_A', id, 'POWER',     FALSE, 'Power meter - Zone A'        FROM zones WHERE name = 'Zone_A'
ON CONFLICT (device_id) DO NOTHING;