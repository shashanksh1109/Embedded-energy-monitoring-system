"""
test_multitenant.py - Tests for the multi-tenant gateway changes (Steps 4-6)

No database is needed: a small fake replaces psycopg2 and records every SQL
statement, so the tests can check exactly what the gateway would send.

Run from the Gateway folder:
    python -m pytest tests/ -v
"""

import os
import sys
import time
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


# ------------------------------------------------------------------
# Fake psycopg2 (installed BEFORE importing db_writer)
# ------------------------------------------------------------------

DEVICES = [
    # thing_name, device uuid, org_id, zone_id
    ('TEMP_A',  'dev-temp-a',  'org-1', 'zone-a'),
    ('TEMP_PI', 'dev-temp-pi', 'org-1', 'zone-a'),
    ('HVAC_A',  'dev-hvac-a',  'org-1', 'zone-a'),
    ('POWER_A', 'dev-power-a', 'org-1', 'zone-a'),
    ('TEMP_X',  'dev-temp-x',  'org-2', 'zone-x'),   # a second customer
]


class FakeCursor:
    def __init__(self):
        self.queries = []
        self._rows = []

    def execute(self, sql, params=None):
        flat = ' '.join(sql.split())
        self.queries.append((flat, params))
        if 'FROM devices' in flat:
            self._rows = list(DEVICES)

    def fetchall(self):
        return self._rows

    def close(self):
        pass


class FakeConnection:
    closed = 0
    autocommit = False

    def __init__(self):
        self._cursor = FakeCursor()

    def cursor(self):
        return self._cursor

    def close(self):
        pass


fake_psycopg2 = types.ModuleType('psycopg2')
fake_psycopg2.OperationalError = type('OperationalError', (Exception,), {})
fake_psycopg2.connect = lambda **kwargs: FakeConnection()
sys.modules['psycopg2'] = fake_psycopg2

import db_writer            # noqa: E402  (must come after the fake)
import analytics            # noqa: E402
import network              # noqa: E402


def new_writer():
    writer = db_writer.DBWriter()
    assert writer.connect()
    return writer


def queries(writer, text):
    return [(q, p) for q, p in writer.cursor.queries if text in q]


# ------------------------------------------------------------------
# db_writer: device registry and inserts
# ------------------------------------------------------------------

def test_registered_device_insert_has_org_and_device_uuid():
    w = new_writer()
    w.write_packet({'device_id': 'TEMP_A', 'timestamp': 1760000000,
                    'value': 22.5, 'type': 0})
    inserts = queries(w, 'INSERT INTO temperature_readings')
    assert len(inserts) == 1
    sql, params = inserts[0]
    assert 'ON CONFLICT (device_id, recorded_at) DO NOTHING' in sql
    assert params[:3] == ('org-1', 'dev-temp-a', 'zone-a')   # not the string "TEMP_A"


def test_unknown_device_is_skipped_and_not_requeried_every_packet():
    w = new_writer()
    loads_after_connect = len(queries(w, 'FROM devices'))
    for i in range(5):
        w.write_packet({'device_id': 'FAKE_DEVICE', 'timestamp': 1760000000 + i,
                        'value': 1.0, 'type': 0})
    assert queries(w, 'INSERT INTO') == []
    # one re-check for the first unknown packet, then the negative cache holds
    assert len(queries(w, 'FROM devices')) == loads_after_connect + 1


def test_power_is_stored_in_watts_with_interval_energy():
    w = new_writer()
    w.write_packet({'device_id': 'POWER_A', 'timestamp': 1760000000,
                    'value': 0.5, 'type': 1})                 # 0.5 kW
    _, params = queries(w, 'INSERT INTO power_readings')[0]
    power_w, energy_wh, interval_s = params[3], params[4], params[5]
    assert power_w == 500.0
    assert interval_s == 1
    assert abs(energy_wh - 500.0 / 3600.0) < 1e-9


def test_last_seen_is_throttled():
    w = new_writer()
    for i in range(3):
        w.write_packet({'device_id': 'TEMP_A', 'timestamp': 1760000000 + i,
                        'value': 22.0, 'type': 0})
    assert len(queries(w, 'UPDATE devices SET last_seen_at')) == 1


def test_analytics_snapshot_uses_the_zones_organization():
    w = new_writer()
    stats = {'mean': 1.0, 'stddev': 0.0, 'min': 1.0, 'max': 1.0, 'count': 3}
    w.write_analytics_snapshot('zone-x', 'TEMP', stats, None, None)
    _, params = queries(w, 'INSERT INTO analytics_snapshots')[0]
    assert params[0] == 'org-2'


# ------------------------------------------------------------------
# analytics: per zone, per window, V2-safe
# ------------------------------------------------------------------

def test_statistics_are_grouped_per_zone_and_skip_v2_packets():
    buf = analytics.CircularBuffer(size=10)
    buf.add({'device_id': 'TEMP_A', 'type_name': 'TEMP', 'value': 22.0})
    buf.add({'device_id': 'TEMP_A', 'type_name': 'TEMP', 'value': 24.0})
    buf.add({'device_id': 'HVAC_A', 'type_name': 'HVAC_STATE',
             'value1': 0.0, 'value2': 80.0})                  # V2: no 'value'
    buf.add({'device_id': 'TEMP_X', 'type_name': 'TEMP', 'value': 30.0})
    buf.add({'device_id': 'UNKNOWN', 'type_name': 'TEMP', 'value': 99.0})

    zones = {'TEMP_A': 'zone-a', 'HVAC_A': 'zone-a', 'TEMP_X': 'zone-x'}
    stats = buf.calculate_statistics(zone_of=zones.get)       # must not raise

    assert set(stats.keys()) == {('zone-a', 'TEMP'), ('zone-x', 'TEMP')}
    assert stats[('zone-a', 'TEMP')]['mean'] == 23.0
    assert stats[('zone-a', 'TEMP')]['count'] == 2


def test_statistics_only_include_the_requested_window():
    buf = analytics.CircularBuffer(size=10)
    buf.add({'device_id': 'TEMP_A', 'type_name': 'TEMP', 'value': 22.0})
    after_first = time.time()
    time.sleep(0.01)
    buf.add({'device_id': 'TEMP_A', 'type_name': 'TEMP', 'value': 30.0})

    stats = buf.calculate_statistics(since=after_first,
                                     zone_of=lambda d: 'zone-a')
    assert stats[('zone-a', 'TEMP')]['count'] == 1
    assert stats[('zone-a', 'TEMP')]['mean'] == 30.0


# ------------------------------------------------------------------
# network: HVAC decisions
# ------------------------------------------------------------------

class FakeOrchestration:
    temp_target = 22.0
    temp_threshold_low = 21.5
    temp_threshold_high = 22.0

    def is_temperature_too_low(self, t):
        return t < self.temp_threshold_low

    def is_temperature_too_high(self, t):
        return t > self.temp_threshold_high


class RecordingDB:
    def __init__(self, writer):
        self.writer = writer
        self._device_cache = writer._device_cache
        self.hvac_writes = []
        self.events = []

    def _get_zone_id(self, thing_name):
        return self.writer._get_zone_id(thing_name)

    def write_hvac_state_direct(self, **kwargs):
        self.hvac_writes.append(kwargs)

    def write_orchestration_event(self, **kwargs):
        self.events.append(kwargs)


def make_handler(db):
    handler = network.ClientHandler.__new__(network.ClientHandler)
    handler.db = db
    handler.orch_config = FakeOrchestration()
    return handler


def test_hvac_written_only_on_mode_change_and_uses_registry_device():
    network._last_hvac.clear()
    db = RecordingDB(new_writer())
    handler = make_handler(db)

    readings = [48.0, 48.3, 21.8, 21.9, 48.0]   # COOLING, COOLING, IDLE, IDLE, COOLING
    for i, temp in enumerate(readings):
        handler._check_temperature_and_trigger(
            {'device_id': 'TEMP_PI', 'timestamp': 1760000000 + i, 'value': temp})

    assert len(db.hvac_writes) == 3                       # only the 3 mode changes
    assert all(w['device_id'] == 'HVAC_A' for w in db.hvac_writes)   # not "HVAC_PI"
    assert [e['event_type'] for e in db.events] == ['HVAC_COOLING', 'HVAC_COOLING']


def test_hvac_uses_the_temperature_packets_timestamp():
    network._last_hvac.clear()
    db = RecordingDB(new_writer())
    handler = make_handler(db)
    handler._check_temperature_and_trigger(
        {'device_id': 'TEMP_A', 'timestamp': 1760000000, 'value': 30.0})
    assert int(db.hvac_writes[0]['recorded_at'].timestamp()) == 1760000000