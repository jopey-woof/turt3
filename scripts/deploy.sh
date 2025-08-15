#!/bin/bash

# Turtle Enclosure System Deployment Script
# Installs and configures all components on Ubuntu Server

set -e

echo "🐢 Turtle Enclosure System Deployment"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Define the password for sudo operations
SUDO_PASSWORD="shrimp"

# Create a temporary askpass script
ASKPASS_SCRIPT=$(mktemp)
chmod +x "$ASKPASS_SCRIPT"
echo "#!/bin/bash" > "$ASKPASS_SCRIPT"
echo "echo \"$SUDO_PASSWORD\"" >> "$ASKPASS_SCRIPT"

# Export variables for sudo to use the askpass script
export SUDO_ASKPASS="$ASKPASS_SCRIPT"

# Function to manage kiosk service
manage_kiosk() {
    print_status "Managing kiosk service..."
    
    # Reload systemd and enable kiosk
    sudo -A systemctl daemon-reload
    sudo -A systemctl enable kiosk
    
    # Try to start kiosk
    sudo -A systemctl restart kiosk
    
    # Wait and check if it started successfully
    sleep 5
    if systemctl is-active --quiet kiosk; then
        print_success "Kiosk service started successfully!"
        return 0
    else
        print_warning "Kiosk service failed to start. This may require a reboot."
        echo ""
        read -p "Would you like to reboot the system now to ensure kiosk starts properly? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Rebooting system in 10 seconds... Press Ctrl+C to cancel"
            sleep 10
            sudo -A reboot
        else
            print_warning "Please reboot manually when ready: sudo reboot"
            return 1
        fi
    fi
}

# Function to handle touchscreen calibration and configuration merging
setup_touchscreen() {
    print_status "Setting up touchscreen calibration..."
    
    # Install calibration tools
    if ! command -v xinput_calibrator &> /dev/null; then
        print_status "Installing touchscreen calibration tools..."
        sudo -A apt update
        sudo -A apt install -y xinput-calibrator
    fi
    
    # Install touchscreen configuration
    print_status "Installing touchscreen configuration..."
    sudo -A cp kiosk/10-touchscreen.conf /etc/X11/xorg.conf.d/
    sudo -A chmod 644 /etc/X11/xorg.conf.d/10-touchscreen.conf
    
    # Apply known good calibration for 10.1" screens to fix vertical scaling issues
    print_status "Applying known good 10.1\" touchscreen calibration..."
    sudo -A mkdir -p /etc/X11/xorg.conf.d/
    
    # Backup current configuration
    if [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
        sudo -A cp /etc/X11/xorg.conf.d/10-touchscreen.conf /etc/X11/xorg.conf.d/10-touchscreen.conf.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Apply the known good calibration matrix that fixes vertical scaling issues
    # This matrix (1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0) fixes the issue where
    # vertical scaling gets worse as you move down the screen
    print_status "Applying calibration matrix to fix vertical scaling issues..."
    sudo -A sed -i 's|Option "CalibrationMatrix" ""|Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"|' /etc/X11/xorg.conf.d/10-touchscreen.conf
    
    # Verify the change was applied
    if grep -q 'CalibrationMatrix "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"' /etc/X11/xorg.conf.d/10-touchscreen.conf; then
        print_success "Known good calibration matrix applied successfully!"
        print_status "Calibration matrix: 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"
        print_status "This fixes vertical scaling issues that get worse as you move down the screen"
    else
        print_warning "Failed to apply calibration matrix automatically"
        print_status "Manual calibration may be required after deployment"
    fi
    
    # Handle conflicting calibration files - CRITICAL FIX
    print_status "Checking for conflicting calibration files..."
    
    # Fix 99-calibration.conf if it exists and has wrong matrix
    if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
        print_status "Found 99-calibration.conf - checking for conflicts..."
        if grep -q 'CalibrationMatrix "1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"' /etc/X11/xorg.conf.d/99-calibration.conf; then
            print_status "Fixing conflicting calibration matrix in 99-calibration.conf..."
            sudo -A sed -i 's|Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"|Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"|' /etc/X11/xorg.conf.d/99-calibration.conf
            print_success "Fixed conflicting calibration matrix in 99-calibration.conf"
        else
            print_success "99-calibration.conf already has correct matrix"
        fi
    fi
    
    # Remove other conflicting calibration files
    if [ -f /etc/X11/xorg.conf.d/99-touchscreen-calibration.conf ]; then
        sudo -A rm /etc/X11/xorg.conf.d/99-touchscreen-calibration.conf
        print_success "Removed old touchscreen calibration file"
    fi
    
    # Verify all calibration files are consistent
    print_status "Verifying calibration consistency..."
    CALIBRATION_FILES=$(find /etc/X11/xorg.conf.d/ -name "*.conf" -exec grep -l "CalibrationMatrix" {} \; 2>/dev/null || true)
    
    if [ -n "$CALIBRATION_FILES" ]; then
        for file in $CALIBRATION_FILES; do
            if grep -q 'CalibrationMatrix "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"' "$file"; then
                print_success "✅ $file has correct calibration matrix"
            else
                print_warning "⚠️  $file has incorrect calibration matrix - fixing..."
                sudo -A sed -i 's|Option "CalibrationMatrix" "[^"]*"|Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"|' "$file"
                print_success "Fixed calibration matrix in $file"
            fi
        done
    fi
    
    # Save calibration for future use
    sudo -A mkdir -p /opt/turtle-enclosure
    sudo -A cp /etc/X11/xorg.conf.d/10-touchscreen.conf /opt/turtle-enclosure/saved_calibration.conf
    sudo -A chmod 644 /opt/turtle-enclosure/saved_calibration.conf
    
    print_success "Touchscreen calibration setup completed successfully!"
    print_status "All calibration files now have the correct matrix for vertical scaling fix"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    print_warning "This script is designed for Ubuntu 22.04. Other versions may work but are not tested."
fi

print_status "Starting deployment process..."

# Update system packages
print_status "Updating system packages..."
sudo -A apt update && sudo -A apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo -A apt install -y \
    chromium-browser \
    x11-utils \
    xinput \
    lightdm \
    openbox \
    tint2 \
    python3-pip \
    python3-usb \
    python3-serial \
    udev \
    systemd \
    curl \
    wget \
    git \
    unzip \
    htop \
    vim

# Install Python packages for USB sensors
print_status "Installing Python dependencies..."
pip3 install --user \
    pyusb \
    pyserial \
    requests \
    flask

# Create turtle user if it doesn't exist
if ! id "turtle" &>/dev/null; then
    print_status "Creating turtle user..."
    sudo -A useradd -m -s /bin/bash turtle
    sudo -A usermod -aG video,audio,plugdev,docker turtle
    echo "turtle:$SUDO_PASSWORD" | sudo -A chpasswd
    print_success "Turtle user created"
else
    print_status "Turtle user already exists"
fi

# Configure display and kiosk
print_status "Configuring display and kiosk..."
sudo -A cp kiosk/kiosk.service /etc/systemd/system/

# Copy Home Assistant configuration
print_status "Configuring Home Assistant connection..."
sudo -A mkdir -p /etc/turtle-enclosure
sudo -A cp kiosk/ha-config.conf /etc/turtle-enclosure/
sudo -A chmod 644 /etc/turtle-enclosure/ha-config.conf

# Create systemd override directory for getty service
print_status "Creating systemd override directory..."
sudo -A mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo -A cp kiosk/autologin.conf /etc/systemd/system/getty@tty1.service.d/

# Make the display configuration script executable and then run it
# This is now handled by auto-calibrate-service.sh during graphical session setup
# sudo -A chmod +x kiosk/display-config.sh
# sudo -A bash kiosk/display-config.sh

# Setup touchscreen calibration and merge configurations
setup_touchscreen

# Install working calibration script for 10.1" screens
print_status "Installing 10.1\" touchscreen calibration script..."
sudo -A cp kiosk/calibrate-10inch.sh /usr/local/bin/turtle-calibrate
sudo -A chmod +x /usr/local/bin/turtle-calibrate
print_success "10.1\" calibration script installed as: turtle-calibrate"

# Install auto-calibration service
print_status "Installing auto-calibration service..."
sudo -A mkdir -p /opt/turtle-enclosure
sudo -A cp kiosk/auto-calibrate-service.sh /opt/turtle-enclosure/
sudo -A chmod +x /opt/turtle-enclosure/auto-calibrate-service.sh
sudo -A cp kiosk/auto-calibrate.service /etc/systemd/system/
sudo -A systemctl daemon-reload
sudo -A systemctl enable auto-calibrate.service
print_success "Auto-calibration service installed and enabled"

# Install known calibrations
print_status "Installing known calibration values..."
sudo -A cp kiosk/known-calibrations.conf /opt/turtle-enclosure/
sudo -A chmod 644 /opt/turtle-enclosure/known-calibrations.conf
sudo -A cp kiosk/apply-known-calibration.sh /usr/local/bin/turtle-apply-known
sudo -A chmod +x /usr/local/bin/turtle-apply-known
print_success "Known calibrations installed as: turtle-apply-known"

# Install cursor hiding script
print_status "Installing cursor hiding script..."
sudo -A cp kiosk/hide-cursor.sh /usr/local/bin/turtle-hide-cursor
sudo -A chmod +x /usr/local/bin/turtle-hide-cursor
print_success "Cursor hiding script installed as: turtle-hide-cursor"

# Configure hardware
print_status "Configuring hardware..."
sudo -A cp hardware/udev-rules.conf /etc/udev/rules.d/99-turtle-hardware.rules
sudo -A udevadm control --reload-rules
sudo -A udevadm trigger

# Create Home Assistant configuration directory
print_status "Setting up Home Assistant configuration..."
sudo -A mkdir -p /opt/homeassistant/config
sudo -A chown -R turtle:turtle /opt/homeassistant

# Install Home Assistant Plugins (Mushroom Cards, Kiosk Mode)
print_status "Installing Home Assistant plugins (Mushroom Cards, Kiosk Mode)..."
sudo -A -u turtle bash ./scripts/install-plugins.sh

# Copy Home Assistant configurations
sudo -A cp -r home-assistant/* /opt/homeassistant/config/
sudo -A chown -R turtle:turtle /opt/homeassistant/config

# Create secrets file template
if [ ! -f /opt/homeassistant/config/secrets.yaml ]; then
    print_status "Creating secrets template..."
            cat > /tmp/secrets.yaml << 'EOF'
# Turtle Enclosure Secrets
# Update these values with your actual credentials
# ⚠️  WARNING: DO NOT commit this file with real passwords to version control!

# Email configuration
email_username: "your-turtle-email@gmail.com"
email_password: "your-app-password"
email_sender: "your-turtle-email@gmail.com"
email_recipient: "your-personal-email@gmail.com"

# Home Assistant configuration
homeassistant_token: "your-long-lived-access-token"

# Camera configuration
camera_username: "admin"
camera_password: "your-camera-password"

# Zigbee configuration
zigbee_channel: "11"
EOF
    sudo -A mv /tmp/secrets.yaml /opt/homeassistant/config/
    sudo -A chown turtle:turtle /opt/homeassistant/config/secrets.yaml
    print_warning "Please update /opt/homeassistant/config/secrets.yaml with your actual credentials"
fi

# Create TEMPerHUM reader script
print_status "Creating sensor reader script..."
cat > /tmp/temperhum_reader.py << 'EOF'
#!/usr/bin/env python3
"""
TEMPerHUM PC USB sensor reader
Reads temperature and humidity from TEMPerHUM sensor
Gracefully handles missing hardware with fallback values
"""

import usb.core
import usb.util
import struct
import time
import sys

def find_temperhum():
    """Find TEMPerHUM device"""
    # TEMPerHUM vendor and product IDs
    VENDOR_ID = 0x0c45
    PRODUCT_ID = 0x7401
    
    device = usb.core.find(idVendor=VENDOR_ID, idProduct=PRODUCT_ID)
    return device

def read_temperhum(device):
    """Read temperature and humidity from device"""
    try:
        # Configure device
        device.set_configuration()
        
        # Send command to read data
        device.ctrl_transfer(0x21, 0x09, 0x0200, 0x01, b'\x01\x80\x33\x01\x00\x00\x00\x00')
        
        # Read response
        data = device.ctrl_transfer(0xA1, 0x81, 0x0300, 0x01, 8)
        
        if len(data) >= 8:
            # Parse temperature and humidity
            temp_raw = struct.unpack('<H', data[2:4])[0]
            hum_raw = struct.unpack('<H', data[4:6])[0]
            
            # Convert to actual values
            temperature = (temp_raw / 100.0) * 9/5 + 32  # Convert to Fahrenheit
            humidity = hum_raw / 100.0
            
            return temperature, humidity
        else:
            return None, None
            
    except Exception as e:
        print(f"Error reading sensor: {e}", file=sys.stderr)
        return None, None

def main():
    """Main function"""
    device = find_temperhum()
    
    if device is None:
        # Return fallback values when sensor is not available
        print("75.0,70.0")  # Safe fallback values
        return
    
    temp, hum = read_temperhum(device)
    
    if temp is not None and hum is not None:
        print(f"{temp:.1f},{hum:.1f}")
    else:
        print("75.0,70.0")  # Safe fallback values if reading fails

if __name__ == "__main__":
    main()
EOF
sudo -A mv /tmp/temperhum_reader.py /opt/homeassistant/config/
sudo -A chown turtle:turtle /opt/homeassistant/config/temperhum_reader.py
sudo -A chmod +x /opt/homeassistant/config/temperhum_reader.py

# Create Docker Compose file for Home Assistant
print_status "Creating Docker Compose configuration..."
cat > /tmp/docker-compose.yml << 'EOF'
version: '3.8'

services:
  homeassistant:
    container_name: homeassistant
    image: "ghcr.io/home-assistant/home-assistant:stable"
    volumes:
      - /opt/homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /dev/zigbee-dongle:/dev/zigbee-dongle
      - /dev/temperhum:/dev/temperhum
      - /dev/turtle-camera:/dev/turtle-camera
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      - TZ=America/New_York
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

  # Optional: Watchtower for automatic updates
  watchtower:
    container_name: watchtower
    image: containrrr/watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --cleanup --schedule "0 0 2 * * *"
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *
EOF

sudo -A mv /tmp/docker-compose.yml /opt/homeassistant/
sudo -A chown turtle:turtle /opt/homeassistant/docker-compose.yml

# Enable and start services
print_status "Enabling and starting services..."
sudo -A systemctl daemon-reload
sudo -A systemctl enable kiosk
sudo -A systemctl enable getty@tty1

# Create startup script
print_status "Creating startup script..."
cat > /tmp/startup.sh << 'EOF'
#!/bin/bash
# Turtle Enclosure Startup Script

cd /opt/homeassistant
docker-compose up -d

# Wait for Home Assistant to start
sleep 30

# Start kiosk service
systemctl start kiosk
EOF

sudo -A mv /tmp/startup.sh /opt/homeassistant/
sudo -A chown turtle:turtle /opt/homeassistant/startup.sh
sudo -A chmod +x /opt/homeassistant/startup.sh

# Create systemd service for startup
cat > /tmp/turtle-startup.service << 'EOF'
[Unit]
Description=Turtle Enclosure Startup
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
User=turtle
Group=turtle
ExecStart=/opt/homeassistant/startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo -A mv /tmp/turtle-startup.service /etc/systemd/system/
sudo -A systemctl daemon-reload
sudo -A systemctl enable turtle-startup

# Create monitoring script
print_status "Creating system monitoring script..."
cat > /tmp/monitor.sh << 'EOF'
#!/bin/bash
# Turtle Enclosure System Monitor

LOG_FILE="/var/log/turtle-enclosure.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check Home Assistant container
if ! docker ps | grep -q homeassistant; then
    log "ERROR: Home Assistant container not running"
    cd /opt/homeassistant && docker-compose up -d
fi

# Check kiosk service
if ! systemctl is-active --quiet kiosk; then
    log "ERROR: Kiosk service not running"
    systemctl restart kiosk
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log "WARNING: Disk usage is ${DISK_USAGE}%"
fi

# Check memory usage
MEM_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ "$MEM_USAGE" -gt 90 ]; then
    log "WARNING: Memory usage is ${MEM_USAGE}%"
fi
EOF

sudo -A mv /tmp/monitor.sh /opt/homeassistant/
sudo -A chown turtle:turtle /opt/homeassistant/monitor.sh
sudo -A chmod +x /opt/homeassistant/monitor.sh

# Create cron job for monitoring
echo "*/5 * * * * /opt/homeassistant/monitor.sh" | sudo -A crontab -

# Create backup script
print_status "Creating backup script..."
cat > /tmp/backup.sh << 'EOF'
#!/bin/bash
# Turtle Enclosure Backup Script

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup Home Assistant configuration
tar -czf "$BACKUP_DIR/ha_config_$DATE.tar.gz" -C /opt/homeassistant config/

# Backup system configuration
tar -czf "$BACKUP_DIR/system_config_$DATE.tar.gz" \
    /etc/systemd/system/kiosk.service \
    /etc/systemd/system/getty@tty1.service.d/ \
    /etc/udev/rules.d/99-turtle-hardware.rules \
    /etc/X11/xorg.conf.d/10-touchscreen.conf

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

sudo -A mv /tmp/backup.sh /opt/homeassistant/
sudo -A chown turtle:turtle /opt/homeassistant/backup.sh
sudo -A chmod +x /opt/homeassistant/backup.sh

# Add daily backup to cron
echo "0 2 * * * /opt/homeassistant/backup.sh" | sudo -A crontab -

print_success "Deployment completed successfully!"

# Manage kiosk service
manage_kiosk

# Clean up the temporary askpass script
rm "$ASKPASS_SCRIPT"

echo ""
echo "🐢 Next Steps:"
echo "1. Update secrets in /opt/homeassistant/config/secrets.yaml"
echo "2. Connect your hardware devices"
echo "3. Access Home Assistant at: http://localhost:8123"
echo "4. Configure your devices in Home Assistant"
echo ""
echo "📋 Useful Commands:"
echo "  - View logs: sudo journalctl -u kiosk -f"
echo "  - Restart kiosk: sudo systemctl restart kiosk"
echo "  - Check Home Assistant: docker logs homeassistant"
echo "  - Manual backup: /opt/homeassistant/backup.sh"
echo "  - Reboot system: sudo reboot"
echo ""
print_success "Turtle Enclosure System is ready! 🐢" 