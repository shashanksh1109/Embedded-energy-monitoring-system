"""
utils.py - Utility Functions

Common helper functions used across modules
"""

from datetime import datetime


def format_timestamp(unix_timestamp):
    """Convert Unix timestamp to readable format"""
    return datetime.fromtimestamp(unix_timestamp).strftime('%Y-%m-%d %H:%M:%S')


def format_packet_info(packet):
    """Format packet data for logging"""
    return (f"Device: {packet['device_id']}, "
            f"Value: {packet['value']:.2f}, "
            f"Type: {packet['type_name']}, "
            f"Time: {format_timestamp(packet['timestamp'])}")


def print_separator(char='-', length=50):
    """Print a separator line"""
    print(char * length)
