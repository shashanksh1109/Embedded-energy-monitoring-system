"""
analytics.py - Data Analytics Module

Handles:
- Data storage (circular buffer)
- Statistical calculations
- Analytics reporting
"""

from collections import deque
import threading
import time


class CircularBuffer:
    """Thread-safe circular buffer for sensor data"""
    
    def __init__(self, size=1000):
        self.buffer = deque(maxlen=size)
        self.lock = threading.Lock()
    
    def add(self, data):
        """Add data to buffer (thread-safe)"""
        with self.lock:
            self.buffer.append(data)
    
    def get_all(self):
        """Get all buffered data (thread-safe)"""
        with self.lock:
            return list(self.buffer)
    
    def calculate_statistics(self):
        """Calculate statistical metrics"""
        with self.lock:
            if not self.buffer:
                return None
            
            values = [d['value'] for d in self.buffer]
            count = len(values)
            mean = sum(values) / count
            variance = sum((x - mean) ** 2 for x in values) / count
            stddev = variance ** 0.5
            
            return {
                'mean': mean,
                'stddev': stddev,
                'count': count,
                'min': min(values),
                'max': max(values)
            }


class AnalyticsEngine:
    """Manages analytics processing"""
    
    def __init__(self, buffer, interval=60):
        self.buffer = buffer
        self.interval = interval
        self.running = False
        self.thread = None
    
    def start(self):
        """Start analytics thread"""
        self.running = True
        self.thread = threading.Thread(target=self._analytics_loop, daemon=True)
        self.thread.start()
        print(f"[ANALYTICS] Engine started (interval: {self.interval}s)")
    
    def stop(self):
        """Stop analytics thread"""
        self.running = False
    
    def _analytics_loop(self):
        """Background analytics processing"""
        while self.running:
            time.sleep(self.interval)
            self._generate_report()
    
    def _generate_report(self):
        """Generate and display analytics report"""
        stats = self.buffer.calculate_statistics()
        if stats:
            print(f"\n[ANALYTICS] ─────────────────────────────")
            print(f"[ANALYTICS] Mean:   {stats['mean']:.2f}°C")
            print(f"[ANALYTICS] StdDev: {stats['stddev']:.2f}°C")
            print(f"[ANALYTICS] Min:    {stats['min']:.2f}°C")
            print(f"[ANALYTICS] Max:    {stats['max']:.2f}°C")
            print(f"[ANALYTICS] Count:  {stats['count']} readings")
            print(f"[ANALYTICS] ─────────────────────────────\n")
