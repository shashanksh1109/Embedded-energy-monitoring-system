"""
config.py - Configuration Management

Handles all configuration-related operations:
- Load settings
- Validate configuration
- Display configuration
"""

class GatewayConfig:
    """Gateway configuration settings"""
    
    def __init__(self, host='127.0.0.1', port=8080):
        self.host = host
        self.port = port
        self.buffer_size = 1000
        self.analytics_interval = 60  # seconds
    
    def validate(self):
        """Validate configuration parameters"""
        if not (1024 <= self.port <= 65535):
            raise ValueError(f"Invalid port: {self.port}")
        
        if self.buffer_size < 1:
            raise ValueError(f"Invalid buffer size: {self.buffer_size}")
        
        return True
    
    def display(self):
        """Display configuration"""
        print("[CONFIG] Gateway Host:        ", self.host)
        print("[CONFIG] Gateway Port:        ", self.port)
        print("[CONFIG] Buffer Size:         ", self.buffer_size)
        print("[CONFIG] Analytics Interval:  ", self.analytics_interval, "seconds")
        print("[CONFIG] ✓ Configuration loaded\n")


def load_configuration():
    """Load and validate gateway configuration"""
    config = GatewayConfig()
    config.validate()
    config.display()
    return config
