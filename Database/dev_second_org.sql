-- =====================================================================
-- LOCAL TEST DATA: a second customer, used to prove tenant isolation.
-- Run as the table owner (energy_user). Safe to run more than once.
--
-- The second customer deliberately has a zone that is ALSO named "Zone_A",
-- and a temperature reading of 99.9 C that is newer than anything else.
-- If isolation ever failed, the Demo Organization's dashboard would show it.
-- =====================================================================

INSERT INTO organizations (id, name)
VALUES ('00000000-0000-0000-0000-000000000002', 'Second Customer')
ON CONFLICT (id) DO NOTHING;

INSERT INTO buildings (id, org_id, name, address)
VALUES ('00000000-0000-0000-0000-0000000000b2',
        '00000000-0000-0000-0000-000000000002',
        'Second Customer HQ', 'Cambridge, MA')
ON CONFLICT (id) DO NOTHING;

INSERT INTO zones (id, org_id, building_id, name, description, capacity)
VALUES ('00000000-0000-0000-0000-0000000000c2',
        '00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-0000000000b2',
        'Zone_A', 'Second customer''s own Zone_A', 8)
ON CONFLICT (id) DO NOTHING;

INSERT INTO devices (id, org_id, zone_id, thing_name, device_type, display_name, status, claimed_at)
VALUES ('00000000-0000-0000-0000-0000000000d2',
        '00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-0000000000c2',
        'TEMP_X2', 'TEMP', 'Second customer sensor', 'ACTIVE', NOW())
ON CONFLICT (id) DO NOTHING;

-- One hour in the future, so it would be the "latest" reading everywhere
-- if row-level security did not separate the two customers.
INSERT INTO temperature_readings (org_id, device_id, zone_id, temperature_c, recorded_at)
VALUES ('00000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-0000000000d2',
        '00000000-0000-0000-0000-0000000000c2',
        99.9, NOW() + INTERVAL '1 hour')
ON CONFLICT (device_id, recorded_at) DO NOTHING;