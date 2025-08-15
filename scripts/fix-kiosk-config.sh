#!/bin/bash

# Fix Kiosk Configuration Script
# This script updates the kiosk configuration to use the new dashboard with kiosk mode

set -e

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

print_status "Fixing kiosk configuration to use new dashboard..."

# Update kiosk configuration to use dashboard with kiosk mode
print_status "Updating kiosk configuration..."

# Create new kiosk configuration
cat > kiosk/ha-config.conf << 'EOF'
# Turtle Enclosure Kiosk Configuration
# Updated to use new dashboard with kiosk mode

# Home Assistant URL with dashboard and kiosk mode
URL=http://localhost:8123/dashboard/dashboard?kiosk

# Kiosk mode settings
KIOSK_MODE=true
FULLSCREEN=true
AUTO_REFRESH=30

# Touchscreen optimization
TOUCH_OPTIMIZED=true
HIDE_CURSOR=true

# Display settings
DISPLAY=:0
RESOLUTION=1024x600

# Browser settings
BROWSER=chromium-browser
BROWSER_ARGS="--kiosk --disable-web-security --disable-features=VizDisplayCompositor --disable-dev-shm-usage --no-sandbox --disable-setuid-sandbox --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --disable-ipc-flooding-protection --disable-hang-monitor --disable-prompt-on-repost --disable-client-side-phishing-detection --disable-component-extensions-with-background-pages --disable-default-apps --disable-extensions --disable-sync --disable-translate --hide-scrollbars --metrics-recording-only --mute-audio --no-first-run --safebrowsing-disable-auto-update --ignore-certificate-errors --ignore-ssl-errors --ignore-certificate-errors-spki-list --user-data-dir=/tmp/chrome-kiosk --disable-features=TranslateUI --disable-ipc-flooding-protection"

# Auto-restart settings
AUTO_RESTART=true
RESTART_INTERVAL=3600

# Logging
LOG_FILE=/var/log/turtle-kiosk.log
LOG_LEVEL=INFO
EOF

print_success "Kiosk configuration updated"

# Update the kiosk service to use the new configuration
print_status "Updating kiosk service..."

# Create updated kiosk service
sudo tee /etc/systemd/system/kiosk.service > /dev/null << 'EOF'
[Unit]
Description=Turtle Enclosure Kiosk
After=network.target graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=turtle
Group=turtle
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/turtle/.Xauthority
WorkingDirectory=/home/turtle
ExecStartPre=/bin/bash -c 'sleep 10'
ExecStart=/bin/bash -c 'source /home/turtle/.bashrc && /usr/bin/chromium-browser --kiosk --disable-web-security --disable-features=VizDisplayCompositor --disable-dev-shm-usage --no-sandbox --disable-setuid-sandbox --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --disable-ipc-flooding-protection --disable-hang-monitor --disable-prompt-on-repost --disable-client-side-phishing-detection --disable-component-extensions-with-background-pages --disable-default-apps --disable-extensions --disable-sync --disable-translate --hide-scrollbars --metrics-recording-only --mute-audio --no-first-run --safebrowsing-disable-auto-update --ignore-certificate-errors --ignore-ssl-errors --ignore-certificate-errors-spki-list --user-data-dir=/tmp/chrome-kiosk --disable-features=TranslateUI --disable-ipc-flooding-protection "http://localhost:8123/dashboard/dashboard?kiosk"'
ExecStop=/bin/bash -c 'pkill -f chromium-browser'
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF

print_success "Kiosk service updated"

# Reload systemd and restart kiosk service
print_status "Reloading systemd and restarting kiosk service..."
sudo systemctl daemon-reload
sudo systemctl restart kiosk

print_success "Kiosk service restarted"

# Create a script to enable kiosk mode in Home Assistant
print_status "Creating Home Assistant kiosk mode configuration script..."

cat > scripts/enable-kiosk-mode.sh << 'EOF'
#!/bin/bash

# Enable Kiosk Mode in Home Assistant
# This script configures Home Assistant to use kiosk mode

print_status() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_status "Enabling kiosk mode in Home Assistant..."

# Wait for Home Assistant to be ready
sleep 30

# Create a configuration to enable kiosk mode
cat > /tmp/kiosk-config.yaml << 'KIOSK_CONFIG'
# Kiosk Mode Configuration
# This enables kiosk mode for the dashboard

# Set dashboard as default view
lovelace:
  mode: storage
  dashboards:
    dashboard:
      mode: storage
      title: Turtle Enclosure
      icon: mdi:turtle
      show_in_sidebar: true
      require_admin: false

# Enable kiosk mode features
frontend:
  themes: !include_dir_merge_named themes
  extra_module_url:
    - /hacsfiles/mushroom/mushroom.js
    - /local/www/kiosk-mode/kiosk-mode.js
KIOSK_CONFIG

print_success "Kiosk mode configuration created"
print_status "Please manually enable kiosk mode in Home Assistant:"
echo "1. Go to http://localhost:8123"
echo "2. Navigate to Settings → Kiosk Mode"
echo "3. Enable 'Full Screen' and 'Auto Refresh'"
echo "4. Set refresh interval to 30 seconds"
echo "5. Save the configuration"
EOF

chmod +x scripts/enable-kiosk-mode.sh

print_success "Kiosk mode configuration script created"

print_status "Configuration complete!"
echo ""
print_status "Next steps:"
echo "1. The kiosk should now load the dashboard with kiosk mode"
echo "2. If it still shows the basic interface, manually enable kiosk mode:"
echo "   - Go to http://localhost:8123"
echo "   - Navigate to Settings → Kiosk Mode"
echo "   - Enable 'Full Screen' and 'Auto Refresh'"
echo "3. The dashboard URL is now: http://localhost:8123/dashboard/dashboard?kiosk"
echo ""
print_status "If you need to manually enable kiosk mode, run:"
echo "   ./scripts/enable-kiosk-mode.sh" 