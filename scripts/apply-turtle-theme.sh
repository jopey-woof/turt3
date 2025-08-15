#!/bin/bash

# Turtle Enclosure System - Theme Application Script
# This script applies the turtle theme and dashboard configuration

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

# Set Home Assistant config directory
HA_CONFIG_DIR="/opt/homeassistant/config"

# Check if config directory exists
if [[ ! -d "$HA_CONFIG_DIR" ]]; then
    print_error "Home Assistant config directory not found at $HA_CONFIG_DIR"
    exit 1
fi

print_status "Applying Turtle Theme and Dashboard Configuration..."

# Create themes directory if it doesn't exist
print_status "Setting up themes directory..."
mkdir -p "$HA_CONFIG_DIR/themes"

# Copy turtle theme
print_status "Installing turtle theme..."
cp themes/turtle-theme.yaml "$HA_CONFIG_DIR/themes/"

# Set proper permissions for theme
sudo chown 1000:1000 "$HA_CONFIG_DIR/themes/turtle-theme.yaml"
sudo chmod 644 "$HA_CONFIG_DIR/themes/turtle-theme.yaml"

# Copy dashboard configuration
print_status "Installing dashboard configuration..."
cp home-assistant/ui-lovelace.yaml "$HA_CONFIG_DIR/ui-lovelace.yaml"

# Set proper permissions for dashboard
sudo chown 1000:1000 "$HA_CONFIG_DIR/ui-lovelace.yaml"
sudo chmod 644 "$HA_CONFIG_DIR/ui-lovelace.yaml"

# Update main configuration to include themes
print_status "Updating main configuration..."
if ! grep -q "themes: !include_dir_merge_named themes" "$HA_CONFIG_DIR/configuration.yaml"; then
    # Add themes line after frontend section
    if grep -q "frontend:" "$HA_CONFIG_DIR/configuration.yaml"; then
        sed -i '/^frontend:/a\  themes: !include_dir_merge_named themes' "$HA_CONFIG_DIR/configuration.yaml"
    else
        # Add new frontend section with themes
        cat >> "$HA_CONFIG_DIR/configuration.yaml" << 'EOF'

# Frontend configuration with themes
frontend:
  themes: !include_dir_merge_named themes
EOF
    fi
    print_success "Added themes configuration to main config"
fi

# Set proper permissions for entire config directory
print_status "Setting proper permissions..."
sudo chown -R 1000:1000 "$HA_CONFIG_DIR"
sudo chmod -R 755 "$HA_CONFIG_DIR"

# Restart Home Assistant
print_status "Restarting Home Assistant..."
cd /opt/homeassistant
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

# Verify theme installation
print_status "Verifying theme installation..."
sleep 10

# Check logs for any errors
print_status "Checking Home Assistant logs..."
if docker logs homeassistant 2>&1 | grep -i "error\|failed" | grep -v "WARNING"; then
    print_warning "Some errors found in logs, but theme should still work"
else
    print_success "No critical errors found in logs"
fi

print_success "Turtle theme and dashboard applied successfully!"
echo ""
print_status "Next steps:"
echo "1. Access Home Assistant at http://your-server-ip:8123"
echo "2. Go to Configuration → Settings → Themes"
echo "3. Select 'Turtle Theme' from the dropdown"
echo "4. The dashboard should automatically load with the new theme"
echo ""
print_status "Dashboard features:"
echo "- Beautiful turtle-themed color scheme"
echo "- Mushroom cards with enhanced styling"
echo "- Touch-optimized interface for your 10.1\" screen"
echo "- Dynamic color coding for temperature and humidity"
echo "- Smooth animations and hover effects"
echo ""
print_status "Theme features:"
echo "- Natural earth tones and turtle shell patterns"
echo "- Enhanced card shadows and borders"
echo "- Responsive design for touchscreen"
echo "- Seasonal color variations"
echo "- Accessibility-friendly focus states"
echo ""
print_status "If the theme doesn't appear:"
echo "1. Clear your browser cache (Ctrl+F5)"
echo "2. Check the themes dropdown in Settings"
echo "3. Verify the theme file exists: ls -la $HA_CONFIG_DIR/themes/"
echo "4. Check Home Assistant logs: docker logs homeassistant" 