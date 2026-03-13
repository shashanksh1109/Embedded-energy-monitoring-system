"""
orchestration_config.py - Orchestration Configuration

Defines thresholds and rules for automatic process spawning.
In Docker, hvac_controller and power_meter are copied into the
gateway image at /app/ so the gateway can exec them directly.
"""

import os


class OrchestrationConfig:
    """Configuration for autonomous process management"""

    def __init__(self, use_hardware=False):
        # Temperature thresholds
        self.temp_threshold_low  = 18.0
        self.temp_threshold_high = 24.0
        self.temp_target         = 20.0

        # Timing parameters
        self.stable_duration     = 30
        self.hvac_startup_delay  = 5

        # Process management
        self.max_restart_attempts   = 3
        self.health_check_interval  = 10

        # Hardware mode
        self.use_hardware = use_hardware

        # Executable paths — /app/ is the WORKDIR inside the gateway container.
        # hvac_controller and power_meter are copied there during Docker build.
        # Falls back to local relative paths for running outside Docker.
        self.hvac_executable  = os.environ.get('HVAC_EXECUTABLE',  '/app/hvac_controller')
        self.power_executable = os.environ.get('POWER_EXECUTABLE', '/app/power_meter')

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