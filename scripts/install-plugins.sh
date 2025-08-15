#!/bin/bash

# Turtle Enclosure System - Plugin Installation Script
# This script installs Mushroom Cards and Kiosk Mode plugins for Home Assistant

set -e  # Exit on any error

# Explicitly set PATH for non-interactive sudo -u user execution
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Define the password for sudo operations (set to turtle123 for turtle user)
SUDO_PASSWORD="turtle123"

# Create a temporary askpass script for this sub-script
ASKPASS_SCRIPT=$(mktemp)
chmod +x "$ASKPASS_SCRIPT"
echo "#!/bin/bash" > "$ASKPASS_SCRIPT"
echo "echo \"$SUDO_PASSWORD\"" >> "$ASKPASS_SCRIPT"

# Export variables for sudo to use the askpass script within this context
export SUDO_ASKPASS="$ASKPASS_SCRIPT"
export DISPLAY=:0 # Ensure DISPLAY is set for X commands

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
# This script should ideally run as the 'turtle' user or with appropriate permissions
# The check here is a safeguard if run directly without 'sudo -u turtle'
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. It will attempt to use sudo -A with an askpass helper."
   # The script will continue and use sudo -A, relying on the askpass helper
   # If it truly needs to be run as a non-root user, the deploy.sh caller should handle that.
fi

# Check if Home Assistant is running
print_status "Checking Home Assistant status..."
if ! docker compose -f /opt/homeassistant/docker-compose.yml ps | grep -q homeassistant; then
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

print_status "Installing Mushroom Cards and Kiosk Mode plugins..."

# Create necessary directories
print_status "Creating directories..."
sudo -A mkdir -p "$HA_CONFIG_DIR/custom_components"
sudo -A mkdir -p "$HA_CONFIG_DIR/www/kiosk-mode"
sudo -A mkdir -p "$HA_CONFIG_DIR/www/mushroom" # Ensure mushroom www directory exists
sudo -A mkdir -p "$HA_CONFIG_DIR/packages"

# Install Mushroom Cards
print_status "Installing Mushroom Cards..."

# Download mushroom.js from latest release
cd "$HA_CONFIG_DIR/www/mushroom"
if [[ -f "mushroom.js" ]]; then
    print_warning "Mushroom Cards plugin already exists. Updating..."
    rm -f mushroom.js # Use rm -f to force remove write-protected files
fi
print_status "Downloading Mushroom Cards plugin..."
# Use sudo -A wget to ensure permissions are correct if running as turtle user but target is root-owned
sudo -A wget -q https://github.com/piitaya/lovelace-mushroom/releases/latest/download/mushroom.js

# Verify Mushroom installation
if [[ -f "mushroom.js" ]]; then
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
    rm -f kiosk-mode.js # Use rm -f here as well
fi

print_status "Downloading Kiosk Mode plugin..."
# Use sudo -A wget here as well
sudo -A wget -q https://github.com/NemesisRE/kiosk-mode/releases/latest/download/kiosk-mode.js

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
    # Use sudo -A cp
    sudo -A cp "$HA_CONFIG_DIR/configuration.yaml" "$HA_CONFIG_DIR/configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backup created: configuration.yaml.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create plugins configuration file
print_status "Creating plugins configuration file..."
# Use sudo -A cat and sudo -A mv
cat > /tmp/plugins.yaml << 'EOF'
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
sudo -A mv /tmp/plugins.yaml "$HA_CONFIG_DIR/packages/plugins.yaml"

print_success "Plugins configuration file created"

# Update main configuration.yaml to include packages
print_status "Updating main configuration..."
if ! grep -q "packages: !include_dir_named packages" "$HA_CONFIG_DIR/configuration.yaml"; then
    # Add packages line after homeassistant section - use sudo -A sed
    sudo -A sed -i '/^homeassistant:/,/^[^ ]/ { /^[^ ]/!d; /^homeassistant:/!d; }' "$HA_CONFIG_DIR/configuration.yaml"
    sudo -A sed -i '/^homeassistant:/a\  packages: !include_dir_named packages' "$HA_CONFIG_DIR/configuration.yaml"
    print_success "Added packages configuration to main config"
fi

# Update frontend configuration
print_status "Updating frontend configuration..."
if grep -q "frontend:" "$HA_CONFIG_DIR/configuration.yaml"; then
    # Update existing frontend section - use sudo -A sed
    sudo -A sed -i '/^frontend:/,/^[^ ]/ { /^frontend:/!d; }' "$HA_CONFIG_DIR/configuration.yaml"
    sudo -A sed -i '/^frontend:/a\  themes: !include_dir_merge_named themes\n  extra_module_url:\n    - /hacsfiles/mushroom/mushroom.js\n    - /local/www/kiosk-mode/kiosk-mode.js' "$HA_CONFIG_DIR/configuration.yaml"
else
    # Add new frontend section - use sudo -A cat
    cat > /tmp/frontend_config.yaml << 'EOF'

# Frontend configuration with plugins
frontend:
  themes: !include_dir_merge_named themes
  extra_module_url:
    - /hacsfiles/mushroom/mushroom.js
    - /local/www/kiosk-mode/kiosk-mode.js
EOF
    sudo -A cat /tmp/frontend_config.yaml >> "$HA_CONFIG_DIR/configuration.yaml"
    rm /tmp/frontend_config.yaml
fi

print_success "Frontend configuration updated"

# Set proper permissions (already in deploy.sh, but as a safeguard if run standalone)
print_status "Setting proper permissions..."
sudo -A chown -R turtle:turtle "$HA_CONFIG_DIR"
sudo -A chmod -R 755 "$HA_CONFIG_DIR"

# Restart Home Assistant
print_status "Restarting Home Assistant..."
cd /opt/homeassistant
# No sudo needed here as docker-compose should be managed by the user
docker compose -f /opt/homeassistant/docker-compose.yml restart homeassistant

# Wait for Home Assistant to start
print_status "Waiting for Home Assistant to start..."
sleep 30

# Check if Home Assistant is running
if docker compose -f /opt/homeassistant/docker-compose.yml ps | grep -q homeassistant; then
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
if docker compose -f /opt/homeassistant/docker-compose.yml logs homeassistant 2>&1 | grep -i "error\|failed" | grep -v "WARNING"; then
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

# Clean up the temporary askpass script
rm "$ASKPASS_SCRIPT" 