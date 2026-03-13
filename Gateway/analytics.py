"""
analytics.py - Data Analytics Module

Handles:
- Data storage (circular buffer)
- Statistical calculations per packet type
- Analytics reporting every 60s
- Persisting analytics snapshots to PostgreSQL
"""

from collections import deque
import threading
import time
from datetime import datetime, timezone
from protocol import TYPE_NAMES


class CircularBuffer:
    """Thread-safe circular buffer for sensor data"""

    def __init__(self, size=1000):
        self.buffer = deque(maxlen=size)
        self.lock   = threading.Lock()

    def add(self, data):
        """Add data to buffer (thread-safe)"""
        with self.lock:
            self.buffer.append(data)

    def get_all(self):
        """Get all buffered data (thread-safe)"""
        with self.lock:
            return list(self.buffer)

    def calculate_statistics(self):
        """
        Calculate statistical metrics grouped by packet type.
        Returns a dict keyed by type_name, each with mean/stddev/min/max/count.
        Returns empty dict if buffer is empty.
        """
        with self.lock:
            if not self.buffer:
                return {}

            # Group values by packet type
            groups = {}
            for d in self.buffer:
                type_name = d.get('type_name', 'UNKNOWN')
                if type_name not in groups:
                    groups[type_name] = []
                groups[type_name].append(d['value'])

            # Calculate stats per type
            stats = {}
            for type_name, values in groups.items():
                count    = len(values)
                mean     = sum(values) / count
                variance = sum((x - mean) ** 2 for x in values) / count
                stddev   = variance ** 0.5
                stats[type_name] = {
                    'mean':   mean,
                    'stddev': stddev,
                    'count':  count,
                    'min':    min(values),
                    'max':    max(values),
                }

            return stats


class AnalyticsEngine:
    """Manages analytics processing and DB persistence"""

    def __init__(self, buffer, interval=60, db=None):
        self.buffer   = buffer
        self.interval = interval
        self.db       = db       # DBWriter instance (None if DB unavailable)
        self.running  = False
        self.thread   = None

    def start(self):
        """Start analytics background thread"""
        self.running = True
        self.thread  = threading.Thread(target=self._analytics_loop, daemon=True)
        self.thread.start()
        print(f"[ANALYTICS] Engine started (interval: {self.interval}s)")

    def stop(self):
        """Stop analytics thread"""
        self.running = False

    def _analytics_loop(self):
        """Background analytics processing loop"""
        while self.running:
            window_start = datetime.now(tz=timezone.utc)
            time.sleep(self.interval)
            window_end = datetime.now(tz=timezone.utc)
            self._generate_report(window_start, window_end)

    def _generate_report(self, window_start, window_end):
        """
        Generate analytics report per packet type.
        Prints to console and persists to DB if available.
        """
        stats = self.buffer.calculate_statistics()

        if not stats:
            return

        print(f"\n[ANALYTICS] ─────────────────────────────")

        for type_name, s in stats.items():
            print(f"[ANALYTICS] Type:   {type_name}")
            print(f"[ANALYTICS] Mean:   {s['mean']:.2f}")
            print(f"[ANALYTICS] StdDev: {s['stddev']:.2f}")
            print(f"[ANALYTICS] Min:    {s['min']:.2f}")
            print(f"[ANALYTICS] Max:    {s['max']:.2f}")
            print(f"[ANALYTICS] Count:  {s['count']} readings")
            print(f"[ANALYTICS] ─────────────────────────────")

            # Persist snapshot to DB per packet type per zone
            # For now uses Zone_A as default — will be per-zone when
            # buffer is split by zone in a future update
            if self.db:
                zone_id = self._get_zone_a_id()
                if zone_id:
                    self.db.write_analytics_snapshot(
                        zone_id      = zone_id,
                        packet_type  = type_name,
                        stats        = s,
                        window_start = window_start,
                        window_end   = window_end
                    )

        print()

    def _get_zone_a_id(self):
        """
        Get Zone_A UUID from db writer zone cache.
        Temporary helper until buffer is split per zone.
        """
        if self.db and self.db._zone_cache:
            # Look up Zone_A's UUID via TEMP_A device (always in Zone_A)
            return self.db._get_zone_id('TEMP_A')
        return None