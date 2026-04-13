"""
orchestration_config.py - Orchestration Configuration

Defines thresholds and rules for automatic process spawning.
Executable paths are resolved relative to this file's location
so the gateway works regardless of which directory it is launched from.
"""

import os

# Resolve the project root directory (one level up from Gateway/)
_HERE         = os.path.dirname(os.path.abspath(__file__))
_PROJECT_ROOT = os.path.dirname(_HERE)


class OrchestrationConfig:
    """Configuration for autonomous process management"""

    def __init__(self, use_hardware=False):
        # Temperature thresholds
        self.temp_threshold_low  = 21.5
        self.temp_threshold_high = 22.0
        self.temp_target         = 22.0

        # Timing parameters
        self.stable_duration    = 30
        self.hvac_startup_delay = 5

        # Process management
        self.max_restart_attempts  = 3
        self.health_check_interval = 10

        # Hardware mode
        self.use_hardware = use_hardware

        # Paths resolved from project root
        self.hvac_executable  = os.path.join(_PROJECT_ROOT, 'Embedded', 'hvac_controller')
        self.power_executable = os.path.join(_PROJECT_ROOT, 'Embedded', 'power_meter')

    def is_temperature_too_low(self, temp):
        """Check if temperature requires heating"""
        return temp < self.temp_threshold_low

    def is_temperature_too_high(self, temp):
        """Check if temperature requires cooling"""
        return temp > self.temp_threshold_high

    def is_temperature_stable(self, temp):
        """Check if temperature is in acceptable range"""
        return self.temp_threshold_low <= temp <= self.temp_threshold_high

    def display(self):
        """Display orchestration configuration"""
        print("[ORCHESTRATION] Temperature Thresholds:")
        print(f"[ORCHESTRATION]   Low:    {self.temp_threshold_low}C (start heating)")
        print(f"[ORCHESTRATION]   High:   {self.temp_threshold_high}C (start cooling)")
        print(f"[ORCHESTRATION]   Target: {self.temp_target}C")
        print(f"[ORCHESTRATION] Stable duration: {self.stable_duration}s")
        print(f"[ORCHESTRATION] Hardware mode: {'ENABLED' if self.use_hardware else 'DISABLED'}")
        print(f"[ORCHESTRATION] HVAC executable:  {self.hvac_executable}")
        print(f"[ORCHESTRATION] Power executable: {self.power_executable}")
        print()
