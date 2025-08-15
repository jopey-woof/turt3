#!/bin/bash

# Turtle Enclosure System - Recovery Mode Fix Script
# This script fixes the recovery mode issue caused by path mismatches

set -e  # Exit on any error

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

print_status "Starting Recovery Mode Fix..."

# Step 1: Stop all containers and clean up
print_status "Step 1: Stopping all containers..."
cd /home/shrimp/turt3/docker
docker-compose down

# Step 2: Remove any conflicting containers
print_status "Step 2: Removing conflicting containers..."
docker rm -f homeassistant mosquitto influxdb grafana nginx camera-stream backup watchtower 2>/dev/null || true

# Step 3: Create proper directory structure
print_status "Step 3: Creating proper directory structure..."
mkdir -p /home/shrimp/homeassistant/{config,mosquitto/{config,data,log},influxdb/{config},grafana,nginx/{ssl},backup}
mkdir -p /home/shrimp/backups

# Step 4: Create basic Home Assistant configuration
print_status "Step 4: Creating basic Home Assistant configuration..."
cat > /home/shrimp/homeassistant/config/configuration.yaml << 'EOF'
# Basic Home Assistant Configuration
default_config:

# Load frontend
frontend:

# Load themes
themes: !include_dir_merge_named themes

# Load packages
packages: !include_dir_named packages

# HTTP configuration
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1

# Logging
logger:
  default: info
  logs:
    homeassistant.components.http: debug

# Recorder
recorder:
  db_url: sqlite:///home-assistant_v2.db

# History
history:

# Logbook
logbook:

# Map
map:

# Mobile app
mobile_app:

# Person
person:

# Zone
zone:

# Automation
automation: !include automations.yaml

# Script
script: !include scripts.yaml

# Scene
scene: !include scenes.yaml
EOF

# Step 5: Create basic automations, scripts, and scenes files
print_status "Step 5: Creating basic configuration files..."
touch /home/shrimp/homeassistant/config/automations.yaml
touch /home/shrimp/homeassistant/config/scripts.yaml
touch /home/shrimp/homeassistant/config/scenes.yaml

# Step 6: Set proper permissions
print_status "Step 6: Setting proper permissions..."
chown -R 1000:1000 /home/shrimp/homeassistant
chmod -R 755 /home/shrimp/homeassistant

# Step 7: Start core services only
print_status "Step 7: Starting core services..."
docker-compose up -d homeassistant influxdb watchtower

# Step 8: Wait for Home Assistant to start
print_status "Step 8: Waiting for Home Assistant to start..."
sleep 60

# Step 9: Check if Home Assistant is running
print_status "Step 9: Checking Home Assistant status..."
if docker ps | grep -q homeassistant; then
    print_success "Home Assistant is running!"
else
    print_error "Home Assistant failed to start"
    docker logs homeassistant
    exit 1
fi

# Step 10: Test Home Assistant API
print_status "Step 10: Testing Home Assistant API..."
sleep 30
if curl -f http://localhost:8123/api/ >/dev/null 2>&1; then
    print_success "Home Assistant API is responding!"
else
    print_warning "Home Assistant API not responding yet, but container is running"
fi

# Step 11: Install plugins (optional)
read -p "Do you want to install plugins (Mushroom Cards and Kiosk Mode)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Step 11: Installing plugins..."
    
    # Create necessary directories
    mkdir -p /home/shrimp/homeassistant/config/custom_components
    mkdir -p /home/shrimp/homeassistant/config/www/kiosk-mode
    mkdir -p /home/shrimp/homeassistant/config/packages
    
    # Install Mushroom Cards
    cd /home/shrimp/homeassistant/config/custom_components
    if [[ ! -d "mushroom" ]]; then
        git clone https://github.com/piitaya/lovelace-mushroom.git mushroom
    fi
    
    # Install Kiosk Mode Plugin
    cd /home/shrimp/homeassistant/config/www/kiosk-mode
    wget -q https://github.com/NemesisRE/kiosk-mode/releases/latest/download/kiosk-mode.js
    
    # Create plugins configuration
    cat > /home/shrimp/homeassistant/config/packages/plugins.yaml << 'EOF'
# Mushroom Cards and Kiosk Mode Configuration
lovelace:
  mode: storage
  resources:
    - url: /hacsfiles/mushroom/mushroom.js
      type: module
    - url: /local/www/kiosk-mode/kiosk-mode.js
      type: module
EOF
    
    # Update configuration to include plugins
    sed -i '/^frontend:/a\  extra_module_url:\n    - /hacsfiles/mushroom/mushroom.js\n    - /local/www/kiosk-mode/kiosk-mode.js' /home/shrimp/homeassistant/config/configuration.yaml
    
    print_success "Plugins installed successfully!"
fi

# Step 12: Apply theme (optional)
read -p "Do you want to apply the turtle theme? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Step 12: Applying turtle theme..."
    
    # Create themes directory
    mkdir -p /home/shrimp/homeassistant/config/themes
    
    # Copy theme
    cp /home/shrimp/turt3/themes/turtle-theme.yaml /home/shrimp/homeassistant/config/themes/
    
    # Copy dashboard configuration
    cp /home/shrimp/turt3/home-assistant/ui-lovelace.yaml /home/shrimp/homeassistant/config/ui-lovelace.yaml
    
    # Set permissions
    chown 1000:1000 /home/shrimp/homeassistant/config/themes/turtle-theme.yaml
    chown 1000:1000 /home/shrimp/homeassistant/config/ui-lovelace.yaml
    chmod 644 /home/shrimp/homeassistant/config/themes/turtle-theme.yaml
    chmod 644 /home/shrimp/homeassistant/config/ui-lovelace.yaml
    
    print_success "Turtle theme applied successfully!"
fi

# Step 13: Restart Home Assistant to apply changes
print_status "Step 13: Restarting Home Assistant to apply changes..."
docker-compose restart homeassistant

# Step 14: Final verification
print_status "Step 14: Final verification..."
sleep 30

if docker ps | grep -q homeassistant; then
    print_success "✅ Recovery mode fixed successfully!"
    echo ""
    print_status "Home Assistant is now running at: http://10.0.20.69:8123"
    print_status "InfluxDB is running at: http://10.0.20.69:8086"
    echo ""
    print_status "Next steps:"
    echo "1. Access Home Assistant and complete the initial setup"
    echo "2. Configure your devices and sensors"
    echo "3. Set up your dashboard"
    echo "4. The system should no longer go into recovery mode"
else
    print_error "❌ Recovery mode fix failed"
    docker logs homeassistant
    exit 1
fi 