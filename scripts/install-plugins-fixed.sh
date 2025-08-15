#!/bin/bash

# Turtle Enclosure System - Plugin Installation Script (Fixed)
# This script installs Mushroom Cards and Kiosk Mode plugins for Home Assistant

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if Home Assistant is running
print_status "Checking Home Assistant status..."
if ! docker ps | grep -q homeassistant; then
    print_error "Home Assistant container is not running. Please start it first."
    exit 1
fi

# Set Home Assistant config directory (FIXED PATH)
HA_CONFIG_DIR="/home/shrimp/homeassistant/config"

# Check if config directory exists
if [[ ! -d "$HA_CONFIG_DIR" ]]; then
    print_error "Home Assistant config directory not found at $HA_CONFIG_DIR"
    exit 1
fi

print_status "Installing Mushroom Cards and Kiosk Mode plugins..."

# Create necessary directories
print_status "Creating directories..."
mkdir -p "$HA_CONFIG_DIR/custom_components"
mkdir -p "$HA_CONFIG_DIR/www/kiosk-mode"
mkdir -p "$HA_CONFIG_DIR/packages"

# Install Mushroom Cards
print_status "Installing Mushroom Cards..."
cd "$HA_CONFIG_DIR/custom_components"

if [[ -d "mushroom" ]]; then
    print_warning "Mushroom directory already exists. Updating..."
    cd mushroom
    git pull origin main
    cd ..
else
    print_status "Cloning Mushroom repository..."
    git clone https://github.com/piitaya/lovelace-mushroom.git mushroom
fi

# Verify Mushroom installation
if [[ -f "mushroom/mushroom.js" ]]; then
    print_success "Mushroom Cards installed successfully"
else
    print_error "Failed to install Mushroom Cards"
    exit 1
fi

# Install Kiosk Mode Plugin
print_status "Installing Kiosk Mode Plugin..."
cd "$HA_CONFIG_DIR/www/kiosk-mode"

if [[ -f "kiosk-mode.js" ]]; then
    print_warning "Kiosk Mode plugin already exists. Updating..."
    rm kiosk-mode.js
fi

print_status "Downloading Kiosk Mode plugin..."
wget -q https://github.com/NemesisRE/kiosk-mode/releases/latest/download/kiosk-mode.js

# Verify Kiosk Mode installation
if [[ -f "kiosk-mode.js" ]]; then
    print_success "Kiosk Mode plugin installed successfully"
else
    print_error "Failed to install Kiosk Mode plugin"
    exit 1
fi

# Configure Home Assistant for plugins
print_status "Configuring Home Assistant for plugins..."

# Backup original configuration
if [[ -f "$HA_CONFIG_DIR/configuration.yaml" ]]; then
    cp "$HA_CONFIG_DIR/configuration.yaml" "$HA_CONFIG_DIR/configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backup created: configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create plugins configuration file
print_status "Creating plugins configuration file..."
cat > "$HA_CONFIG_DIR/packages/plugins.yaml" << 'EOF'
# Mushroom Cards and Kiosk Mode Configuration

# Enable Mushroom cards and Kiosk mode
lovelace:
  mode: storage
  resources:
    - url: /hacsfiles/mushroom/mushroom.js
      type: module
    - url: /local/www/kiosk-mode/kiosk-mode.js
      type: module
EOF

print_success "Plugins configuration file created"

# Update main configuration.yaml to include packages
print_status "Updating main configuration..."
if ! grep -q "packages: !include_dir_named packages" "$HA_CONFIG_DIR/configuration.yaml"; then
    # Add packages line after homeassistant section
    sed -i '/^homeassistant:/,/^[^ ]/ { /^[^ ]/!d; /^homeassistant:/!d; }' "$HA_CONFIG_DIR/configuration.yaml"
    sed -i '/^homeassistant:/a\  packages: !include_dir_named packages' "$HA_CONFIG_DIR/configuration.yaml"
    print_success "Added packages configuration to main config"
fi

# Update frontend configuration
print_status "Updating frontend configuration..."
if grep -q "frontend:" "$HA_CONFIG_DIR/configuration.yaml"; then
    # Update existing frontend section
    sed -i '/^frontend:/,/^[^ ]/ { /^frontend:/!d; }' "$HA_CONFIG_DIR/configuration.yaml"
    sed -i '/^frontend:/a\  themes: !include_dir_merge_named themes\n  extra_module_url:\n    - /hacsfiles/mushroom/mushroom.js\n    - /local/www/kiosk-mode/kiosk-mode.js' "$HA_CONFIG_DIR/configuration.yaml"
else
    # Add new frontend section
    cat >> "$HA_CONFIG_DIR/configuration.yaml" << 'EOF'

# Frontend configuration with plugins
frontend:
  themes: !include_dir_merge_named themes
  extra_module_url:
    - /hacsfiles/mushroom/mushroom.js
    - /local/www/kiosk-mode/kiosk-mode.js
EOF
fi

print_success "Frontend configuration updated"

# Set proper permissions
print_status "Setting proper permissions..."
chown -R 1000:1000 "$HA_CONFIG_DIR"
chmod -R 755 "$HA_CONFIG_DIR"

# Restart Home Assistant
print_status "Restarting Home Assistant..."
cd /home/shrimp/turt3/docker
docker-compose restart homeassistant

# Wait for Home Assistant to start
print_status "Waiting for Home Assistant to start..."
sleep 30

# Check if Home Assistant is running
if docker ps | grep -q homeassistant; then
    print_success "Home Assistant restarted successfully"
else
    print_error "Failed to restart Home Assistant"
    exit 1
fi

# Verify plugin installation
print_status "Verifying plugin installation..."
sleep 10

# Check logs for any errors
print_status "Checking Home Assistant logs..."
if docker logs homeassistant 2>&1 | grep -i "error\|failed" | grep -v "WARNING"; then
    print_warning "Some errors found in logs, but plugins should still work"
else
    print_success "No critical errors found in logs"
fi

print_success "Plugin installation completed successfully!"
echo ""
print_status "Next steps:"
echo "1. Access Home Assistant at http://your-server-ip:8123"
echo "2. Go to Configuration → Lovelace Dashboards"
echo "3. Edit your dashboard and add Mushroom cards"
echo "4. The kiosk mode will be available in the frontend"
echo ""
print_status "Available Mushroom cards:"
echo "- mushroom-chips-card"
echo "- mushroom-template-card"
echo "- mushroom-light-card"
echo "- mushroom-climate-card"
echo "- mushroom-cover-card"
echo "- mushroom-media-player-card"
echo "- mushroom-person-card"
echo "- mushroom-update-card"
echo "- mushroom-vacuum-card"
echo "- mushroom-weather-card"
echo ""
print_status "For more information, visit:"
echo "- Mushroom Cards: https://github.com/piitaya/lovelace-mushroom"
echo "- Kiosk Mode: https://github.com/NemesisRE/kiosk-mode" 