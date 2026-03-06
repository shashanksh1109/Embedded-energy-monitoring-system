"""
orchestration_config.py - Orchestration Configuration

Defines thresholds and rules for automatic process spawning
"""

class OrchestrationConfig:
    """Configuration for autonomous process management"""
    
    def __init__(self):
        # Temperature thresholds
        self.temp_threshold_low = 18.0      # Below this: start heating
        self.temp_threshold_high = 24.0     # Above this: start cooling
        self.temp_target = 20.0             # Target temperature for HVAC
        
        # Timing parameters
        self.stable_duration = 30           # Seconds temp must be stable before stopping HVAC
        self.hvac_startup_delay = 5         # Seconds to wait before starting HVAC
        
        # Process management
        self.max_restart_attempts = 3       # Max times to restart failed process
        self.health_check_interval = 10     # Seconds between health checks
        
        # Paths to executables
        self.hvac_executable = './Embedded/hvac_controller'
        self.power_executable = './Embedded/power_meter'
    
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
        print(f"[ORCHESTRATION]   Low:    {self.temp_threshold_low}°C (start heating)")
        print(f"[ORCHESTRATION]   High:   {self.temp_threshold_high}°C (start cooling)")
        print(f"[ORCHESTRATION]   Target: {self.temp_target}°C")
        print(f"[ORCHESTRATION] Stable duration: {self.stable_duration}s")
        print()