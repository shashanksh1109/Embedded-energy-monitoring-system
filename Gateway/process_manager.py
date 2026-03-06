"""
process_manager.py - Process Lifecycle Management

Manages spawning, monitoring, and terminating child processes
"""

import subprocess
import time

class ProcessManager:
    """Manages HVAC and Power Meter processes"""
    
    def __init__(self, config):
        self.config = config
        self.hvac_process = None
        self.power_process = None
        self.hvac_start_time = None
        self.restart_count = {'hvac': 0, 'power': 0}
    
    def spawn_hvac(self, device_id, zone, setpoint):
        """Spawn HVAC controller process"""
        if self.is_hvac_running():
            print("[PROCESS_MGR] HVAC already running, skipping spawn")
            return False
        
        try:
            print(f"[PROCESS_MGR] Spawning HVAC controller")
            print(f"[PROCESS_MGR]   Device: {device_id}")
            print(f"[PROCESS_MGR]   Zone: {zone}")
            print(f"[PROCESS_MGR]   Setpoint: {setpoint}C")
            print(f"[PROCESS_MGR]   Mode: {'HARDWARE' if self.config.use_hardware else 'SIMULATION'}")
            
            # Build command with optional --hardware flag
            command = [self.config.hvac_executable, device_id, zone, str(setpoint)]
            if self.config.use_hardware:
                command.append('--hardware')
            
            self.hvac_process = subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            
            self.hvac_start_time = time.time()
            self.restart_count['hvac'] = 0
            
            print(f"[PROCESS_MGR] HVAC started (PID: {self.hvac_process.pid})")
            
            # Also spawn power meter
            self.spawn_power_meter(f"POWER_{zone}", zone)
            
            return True
            
        except Exception as e:
            print(f"[PROCESS_MGR] Failed to spawn HVAC: {e}")
            return False
    
    def kill_hvac(self):
        """Terminate HVAC controller gracefully"""
        if not self.hvac_process:
            return
        
        try:
            print(f"[PROCESS_MGR] Stopping HVAC (PID: {self.hvac_process.pid})")
            
            # Graceful shutdown
            self.hvac_process.terminate()
            
            try:
                self.hvac_process.wait(timeout=5)
                print("[PROCESS_MGR] HVAC stopped gracefully")
            except subprocess.TimeoutExpired:
                print("[PROCESS_MGR] HVAC timeout, forcing stop")
                self.hvac_process.kill()
                self.hvac_process.wait()
                print("[PROCESS_MGR] HVAC force-stopped")
            
            self.hvac_process = None
            
            # Also stop power meter
            self.kill_power_meter()
            
        except Exception as e:
            print(f"[PROCESS_MGR] Error stopping HVAC: {e}")
    
    def is_hvac_running(self):
        """Check if HVAC process is alive"""
        if not self.hvac_process:
            return False
        return self.hvac_process.poll() is None
    
    def spawn_power_meter(self, device_id, zone):
        """Spawn power meter process"""
        if self.is_power_running():
            return False
        
        try:
            print(f"[PROCESS_MGR] Spawning power meter for {zone}")
            print(f"[PROCESS_MGR]   Mode: {'HARDWARE' if self.config.use_hardware else 'SIMULATION'}")
            
            # Build command with optional --hardware flag
            command = [self.config.power_executable, device_id, zone]
            if self.config.use_hardware:
                command.append('--hardware')
            
            self.power_process = subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            
            print(f"[PROCESS_MGR] Power meter started (PID: {self.power_process.pid})")
            return True
            
        except Exception as e:
            print(f"[PROCESS_MGR] Failed to spawn power meter: {e}")
            return False
    
    def kill_power_meter(self):
        """Terminate power meter"""
        if not self.power_process:
            return
        
        try:
            print(f"[PROCESS_MGR] Stopping power meter (PID: {self.power_process.pid})")
            self.power_process.terminate()
            self.power_process.wait(timeout=5)
            print("[PROCESS_MGR] Power meter stopped")
            self.power_process = None
        except Exception as e:
            print(f"[PROCESS_MGR] Error stopping power meter: {e}")
    
    def is_power_running(self):
        """Check if power meter is alive"""
        if not self.power_process:
            return False
        return self.power_process.poll() is None
    
    def monitor_health(self):
        """Check health of managed processes"""
        if self.hvac_process and self.hvac_process.poll() is not None:
            exit_code = self.hvac_process.poll()
            print(f"[PROCESS_MGR] WARNING: HVAC died unexpectedly (exit code: {exit_code})")
            
            if self.restart_count['hvac'] < self.config.max_restart_attempts:
                print(f"[PROCESS_MGR] Attempting restart ({self.restart_count['hvac'] + 1}/{self.config.max_restart_attempts})")
                self.restart_count['hvac'] += 1
            else:
                print(f"[PROCESS_MGR] Max restart attempts reached")
        
        if self.power_process and self.power_process.poll() is not None:
            exit_code = self.power_process.poll()
            print(f"[PROCESS_MGR] WARNING: Power meter died (exit code: {exit_code})")
    
    def cleanup_all(self):
        """Stop all managed processes"""
        print("\n[PROCESS_MGR] Cleaning up all processes")
        self.kill_hvac()
        self.kill_power_meter()
        print("[PROCESS_MGR] All processes stopped")