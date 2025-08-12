#!/bin/bash

# Turtle Enclosure Hardware Setup Script
# Configures and tests all hardware devices

set -e

echo "🔧 Turtle Enclosure Hardware Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

print_status "Starting hardware configuration..."

# Install additional hardware tools
print_status "Installing hardware tools..."
apt install -y \
    v4l-utils \
    usbutils \
    i2c-tools \
    hdparm \
    smartmontools \
    lshw

# Function to check USB device
check_usb_device() {
    local vendor_id=$1
    local product_id=$2
    local device_name=$3
    
    print_status "Checking for $device_name..."
    if lsusb | grep -q "$vendor_id:$product_id"; then
        print_success "$device_name found"
        lsusb | grep "$vendor_id:$product_id"
        return 0
    else
        print_error "$device_name not found"
        return 1
    fi
}

# Function to check video device
check_video_device() {
    local device_name=$1
    
    print_status "Checking for $device_name..."
    if v4l2-ctl --list-devices | grep -q "$device_name"; then
        print_success "$device_name found"
        v4l2-ctl --list-devices | grep -A 5 "$device_name"
        return 0
    else
        print_error "$device_name not found"
        return 1
    fi
}

# Check TEMPerHUM sensor
print_status "Checking TEMPerHUM sensor..."
if check_usb_device "0c45" "7401" "TEMPerHUM sensor"; then
    # Test sensor reading
    print_status "Testing TEMPerHUM sensor..."
    if [ -f /opt/homeassistant/config/temperhum_reader.py ]; then
        cd /opt/homeassistant/config
        if python3 temperhum_reader.py > /dev/null 2>&1; then
            print_success "TEMPerHUM sensor is working"
            python3 temperhum_reader.py
        else
            print_warning "TEMPerHUM sensor found but reading failed"
        fi
    else
        print_warning "TEMPerHUM reader script not found"
    fi
else
    print_warning "TEMPerHUM sensor not found - using fallback values"
    print_status "System will work with simulated temperature/humidity until sensor arrives"
fi

# Check Arducam camera
print_status "Checking Arducam camera..."
if check_video_device "Arducam"; then
    # Test camera
    print_status "Testing camera..."
    if v4l2-ctl --device=/dev/video0 --list-formats-ext > /dev/null 2>&1; then
        print_success "Camera is working"
        v4l2-ctl --device=/dev/video0 --list-formats-ext | head -10
    else
        print_warning "Camera found but may need configuration"
    fi
fi

# Check Sonoff Zigbee dongle
print_status "Checking Sonoff Zigbee dongle..."
if check_usb_device "10c4" "ea60" "Sonoff Zigbee dongle"; then
    # Check if device file exists
    if [ -e /dev/zigbee-dongle ]; then
        print_success "Zigbee dongle device file exists"
    else
        print_warning "Zigbee dongle found but device file missing"
    fi
fi

# Check Anker USB hub
print_status "Checking Anker USB hub..."
if check_usb_device "0bda" "0411" "Anker USB hub"; then
    print_success "Anker USB hub detected"
fi

# List all USB devices
print_status "Listing all USB devices..."
lsusb

# List all video devices
print_status "Listing all video devices..."
v4l2-ctl --list-devices

# Check device permissions
print_status "Checking device permissions..."
for device in /dev/video* /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        perms=$(stat -c "%a" "$device")
        owner=$(stat -c "%U:%G" "$device")
        print_status "$device: $perms ($owner)"
    fi
done

# Test touchscreen
print_status "Testing touchscreen..."
if command -v xinput > /dev/null 2>&1; then
    if xinput list | grep -i touch > /dev/null 2>&1; then
        print_success "Touchscreen detected"
        xinput list | grep -i touch
    else
        print_warning "No touchscreen detected"
    fi
else
    print_warning "xinput not available (X11 not running)"
fi

# Check display configuration
print_status "Checking display configuration..."
if command -v xrandr > /dev/null 2>&1; then
    if xrandr --listmonitors > /dev/null 2>&1; then
        print_success "Display configuration available"
        xrandr --listmonitors
    else
        print_warning "Display configuration not available (X11 not running)"
    fi
else
    print_warning "xrandr not available"
fi

# Create device test script
print_status "Creating device test script..."
cat > /opt/homeassistant/test_devices.sh << 'EOF'
#!/bin/bash
# Device test script for turtle enclosure

echo "🐢 Turtle Enclosure Device Test"
echo "================================"

# Test TEMPerHUM sensor
echo "Testing TEMPerHUM sensor..."
if [ -f /opt/homeassistant/config/temperhum_reader.py ]; then
    cd /opt/homeassistant/config
    result=$(python3 temperhum_reader.py 2>/dev/null)
    if [ $? -eq 0 ]; then
        if echo "$result" | grep -q "75.0,70.0"; then
            echo "⚠️ TEMPerHUM: Not connected (using fallback: $result)"
        else
            echo "✅ TEMPerHUM: $result"
        fi
    else
        echo "❌ TEMPerHUM: Failed"
    fi
else
    echo "❌ TEMPerHUM: Script not found"
fi

# Test camera
echo "Testing camera..."
if [ -e /dev/video0 ]; then
    if v4l2-ctl --device=/dev/video0 --list-formats-ext > /dev/null 2>&1; then
        echo "✅ Camera: Working"
    else
        echo "❌ Camera: Not responding"
    fi
else
    echo "❌ Camera: Device not found"
fi

# Test Zigbee dongle
echo "Testing Zigbee dongle..."
if [ -e /dev/zigbee-dongle ]; then
    echo "✅ Zigbee dongle: Device file exists"
else
    echo "❌ Zigbee dongle: Device file missing"
fi

# Test USB devices
echo "Testing USB devices..."
if lsusb | grep -q "0c45:7401"; then
    echo "✅ TEMPerHUM: USB device found"
else
    echo "❌ TEMPerHUM: USB device not found"
fi

if lsusb | grep -q "10c4:ea60"; then
    echo "✅ Zigbee dongle: USB device found"
else
    echo "❌ Zigbee dongle: USB device not found"
fi

echo "Test completed!"
EOF

chmod +x /opt/homeassistant/test_devices.sh
chown turtle:turtle /opt/homeassistant/test_devices.sh

# Create hardware status monitoring
print_status "Creating hardware monitoring..."
cat > /opt/homeassistant/hardware_monitor.py << 'EOF'
#!/usr/bin/env python3
"""
Hardware monitoring script for turtle enclosure
Monitors all hardware devices and reports status
"""

import subprocess
import json
import time
import sys
from datetime import datetime

def run_command(cmd):
    """Run command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout.strip()
    except Exception as e:
        return False, str(e)

def check_usb_device(vendor_id, product_id, name):
    """Check if USB device is present"""
    success, output = run_command(f"lsusb | grep '{vendor_id}:{product_id}'")
    return {
        'name': name,
        'present': success,
        'status': 'Connected' if success else 'Disconnected'
    }

def check_video_device(device_path, name):
    """Check if video device is working"""
    success, output = run_command(f"v4l2-ctl --device={device_path} --list-formats-ext")
    return {
        'name': name,
        'present': success,
        'status': 'Working' if success else 'Not responding'
    }

def check_temperhum():
    """Check TEMPerHUM sensor"""
    success, output = run_command("cd /opt/homeassistant/config && python3 temperhum_reader.py")
    if success:
        try:
            temp, hum = output.split(',')
            return {
                'name': 'TEMPerHUM Sensor',
                'present': True,
                'status': 'Working',
                'temperature': float(temp),
                'humidity': float(hum)
            }
        except:
            return {
                'name': 'TEMPerHUM Sensor',
                'present': True,
                'status': 'Reading error',
                'temperature': None,
                'humidity': None
            }
    else:
        return {
            'name': 'TEMPerHUM Sensor',
            'present': False,
            'status': 'Not found',
            'temperature': None,
            'humidity': None
        }

def main():
    """Main monitoring function"""
    devices = []
    
    # Check USB devices
    devices.append(check_usb_device("0c45", "7401", "TEMPerHUM USB"))
    devices.append(check_usb_device("10c4", "ea60", "Zigbee Dongle"))
    devices.append(check_usb_device("0bda", "0411", "Anker USB Hub"))
    
    # Check video devices
    devices.append(check_video_device("/dev/video0", "Arducam Camera"))
    
    # Check TEMPerHUM sensor specifically
    devices.append(check_temperhum())
    
    # Create status report
    report = {
        'timestamp': datetime.now().isoformat(),
        'devices': devices,
        'summary': {
            'total': len(devices),
            'connected': sum(1 for d in devices if d['present']),
            'working': sum(1 for d in devices if d.get('status') == 'Working')
        }
    }
    
    # Output as JSON
    print(json.dumps(report, indent=2))
    
    # Return exit code based on status
    if report['summary']['connected'] == report['summary']['total']:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

chmod +x /opt/homeassistant/hardware_monitor.py
chown turtle:turtle /opt/homeassistant/hardware_monitor.py

# Create system information script
print_status "Creating system information script..."
cat > /opt/homeassistant/system_info.sh << 'EOF'
#!/bin/bash
# System information for turtle enclosure

echo "🐢 Turtle Enclosure System Information"
echo "======================================"

echo "System Information:"
echo "  OS: $(lsb_release -d | cut -f2)"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo "  Uptime: $(uptime -p)"

echo ""
echo "Hardware Information:"
echo "  CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "  Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  Disk: $(df -h / | tail -1 | awk '{print $2}')"

echo ""
echo "USB Devices:"
lsusb

echo ""
echo "Video Devices:"
v4l2-ctl --list-devices 2>/dev/null || echo "No video devices found"

echo ""
echo "Network Interfaces:"
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"

echo ""
echo "Running Services:"
systemctl list-units --type=service --state=running | grep -E "(kiosk|homeassistant|docker)"

echo ""
echo "Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Recent Logs:"
journalctl -u kiosk --since "1 hour ago" --no-pager | tail -10
EOF

chmod +x /opt/homeassistant/system_info.sh
chown turtle:turtle /opt/homeassistant/system_info.sh

print_success "Hardware setup completed!"
echo ""
echo "🔧 Hardware Status:"
echo "  - TEMPerHUM sensor: $(check_usb_device "0c45" "7401" "TEMPerHUM" > /dev/null && echo "✅ Found" || echo "❌ Not found")"
echo "  - Arducam camera: $(check_video_device "/dev/video0" "Arducam" > /dev/null && echo "✅ Found" || echo "❌ Not found")"
echo "  - Zigbee dongle: $(check_usb_device "10c4" "ea60" "Zigbee" > /dev/null && echo "✅ Found" || echo "❌ Not found")"
echo ""
echo "📋 Useful Commands:"
echo "  - Test devices: /opt/homeassistant/test_devices.sh"
echo "  - Monitor hardware: /opt/homeassistant/hardware_monitor.py"
echo "  - System info: /opt/homeassistant/system_info.sh"
echo "  - View USB devices: lsusb"
echo "  - View video devices: v4l2-ctl --list-devices"
echo ""
print_success "Hardware configuration complete! 🔧" 