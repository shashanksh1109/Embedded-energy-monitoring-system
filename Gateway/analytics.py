"""
analytics.py - Data Analytics Module

Handles:
- Data storage (thread-safe circular buffer)
- Statistics per ZONE and per packet type, over the last time window only
- Analytics reporting every `interval` seconds
- Persisting analytics snapshots to PostgreSQL (one per zone + metric)
"""

from collections import deque
import threading
import time
from datetime import datetime, timezone


class CircularBuffer:
    """
    Thread-safe circular buffer for sensor data.
    Each packet is stored with the gateway's own receive time, so a window
    can be selected reliably even if a device's clock is wrong.
    """

    def __init__(self, size=1000):
        self.buffer = deque(maxlen=size)   # items: (received_at_epoch, packet)
        self.lock   = threading.Lock()

    def add(self, data):
        """Add a packet to the buffer (thread-safe)."""
        with self.lock:
            self.buffer.append((time.time(), data))

    def get_all(self):
        """Get all buffered packets (thread-safe)."""
        with self.lock:
            return [packet for _, packet in self.buffer]

    def calculate_statistics(self, since=None, until=None, zone_of=None):
        """
        Statistics grouped by (zone_id, type_name).

        Args:
            since, until : epoch seconds; only packets RECEIVED in [since, until)
            zone_of      : function device_id -> zone_id (or None if unknown)

        Only single-value (V1) packets are included. V2 packets (HVAC state)
        carry four values and no 'value' field, so they are skipped here.

        Returns:
            dict {(zone_id, type_name): {'mean','stddev','count','min','max'}}
        """
        with self.lock:
            items = list(self.buffer)

        groups = {}
        for received_at, packet in items:
            if since is not None and received_at < since:
                continue
            if until is not None and received_at >= until:
                continue
            if 'value' not in packet:
                continue                       # V2 packet
            zone_id = zone_of(packet.get('device_id')) if zone_of else None
            if zone_of and zone_id is None:
                continue                       # unregistered device
            key = (zone_id, packet.get('type_name', 'UNKNOWN'))
            groups.setdefault(key, []).append(packet['value'])

        stats = {}
        for key, values in groups.items():
            count    = len(values)
            mean     = sum(values) / count
            variance = sum((x - mean) ** 2 for x in values) / count
            stats[key] = {
                'mean':   mean,
                'stddev': variance ** 0.5,
                'count':  count,
                'min':    min(values),
                'max':    max(values),
            }
        return stats


class AnalyticsEngine:
    """Computes per-zone statistics every `interval` seconds and stores them."""

    def __init__(self, buffer, interval=60, db=None):
        self.buffer   = buffer
        self.interval = interval
        self.db       = db       # DBWriter instance (None if DB unavailable)
        self.running  = False
        self.thread   = None

    def start(self):
        """Start analytics background thread."""
        self.running = True
        self.thread  = threading.Thread(target=self._analytics_loop, daemon=True)
        self.thread.start()
        print(f"[ANALYTICS] Engine started (interval: {self.interval}s)")

    def stop(self):
        """Stop analytics thread."""
        self.running = False

    def _analytics_loop(self):
        """
        Background loop. Each window covers exactly the packets received
        since the previous report. A failure in one report is logged and
        the loop keeps running, so analytics can't silently stop.
        """
        window_start = time.time()
        while self.running:
            time.sleep(self.interval)
            window_end = time.time()
            try:
                self._generate_report(window_start, window_end)
            except Exception as e:
                print(f"[ANALYTICS] Report failed: {e}")
            window_start = window_end

    def _generate_report(self, window_start, window_end):
        """Print and persist one snapshot per (zone, metric) for this window."""
        zone_of = self.db._get_zone_id if self.db else None
        stats = self.buffer.calculate_statistics(
            since=window_start, until=window_end, zone_of=zone_of
        )
        if not stats:
            return

        start_dt = datetime.fromtimestamp(window_start, tz=timezone.utc)
        end_dt   = datetime.fromtimestamp(window_end,   tz=timezone.utc)

        print("\n[ANALYTICS] ─────────────────────────────")
        for (zone_id, type_name), s in sorted(stats.items(), key=lambda kv: (str(kv[0][0]), kv[0][1])):
            print(f"[ANALYTICS] Zone {zone_id} | {type_name}: "
                  f"mean {s['mean']:.2f}, sd {s['stddev']:.2f}, "
                  f"min {s['min']:.2f}, max {s['max']:.2f}, n={s['count']}")

            if self.db and zone_id:
                self.db.write_analytics_snapshot(
                    zone_id      = zone_id,
                    packet_type  = type_name,
                    stats        = s,
                    window_start = start_dt,
                    window_end   = end_dt,
                )
        print("[ANALYTICS] ─────────────────────────────\n")