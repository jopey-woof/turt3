#!/bin/bash
# Turtle Enclosure System - Display Fix Script
# This script fixes display resolution and touchscreen input issues

set -e

# Color functions
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

print_status "Fixing display and touchscreen input issues..."

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Stop the kiosk service first
print_status "Stopping kiosk service..."
systemctl stop kiosk || true

# Kill any existing Chromium processes
print_status "Killing existing Chromium processes..."
pkill -f chromium-browser || true
sleep 2

# Check current display configuration
print_status "Checking current display configuration..."
if command -v xrandr >/dev/null 2>&1; then
    print_status "Current monitor configuration:"
    sudo -u turtle DISPLAY=:0 xrandr --listmonitors || print_warning "Could not get monitor info"
fi

# Set proper display resolution for 10.1" touchscreen (1024x600)
print_status "Setting display resolution to 1024x600..."
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-1 --mode 1024x600 --rate 60 || \
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-A-1 --mode 1024x600 --rate 60 || \
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-1-1 --mode 1024x600 --rate 60 || \
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-1-2 --mode 1024x600 --rate 60 || \
print_warning "Could not set resolution, trying alternative..."

# Try alternative resolutions
print_status "Trying alternative resolutions..."
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-1 --mode 1280x720 --rate 60 || \
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-A-1 --mode 1280x720 --rate 60 || \
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-1-1 --mode 1280x720 --rate 60 || \
sudo -u turtle DISPLAY=:0 xrandr --output HDMI-1-2 --mode 1280x720 --rate 60 || \
print_warning "Could not set alternative resolution"

# Apply touchscreen calibration if available
print_status "Applying touchscreen calibration..."
if [ -f "/opt/turtle-enclosure/saved_calibration.conf" ]; then
    print_status "Found saved calibration, applying..."
    cat /opt/turtle-enclosure/saved_calibration.conf | sudo -u turtle DISPLAY=:0 xinput set-prop "eGalax Inc. USB TouchController" "Coordinate Transformation Matrix" || \
    cat /opt/turtle-enclosure/saved_calibration.conf | sudo -u turtle DISPLAY=:0 xinput set-prop "eGalax Inc. USB TouchController" "Coordinate Transformation Matrix" || \
    print_warning "Could not apply saved calibration"
fi

# Check and fix touchscreen input
print_status "Checking touchscreen input devices..."
sudo -u turtle DISPLAY=:0 xinput list | grep -i touch || print_warning "No touchscreen devices found"

# Restart X server if needed
print_status "Checking X server status..."
if ! sudo -u turtle DISPLAY=:0 xset q >/dev/null 2>&1; then
    print_warning "X server not responding, restarting display manager..."
    systemctl restart lightdm
    sleep 10
fi

# Update kiosk service to use proper display settings
print_status "Updating kiosk service configuration..."
cat > /etc/systemd/system/kiosk.service << 'EOF'
[Unit]
Description=Turtle Enclosure Kiosk Display
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
ExecStartPre=/bin/bash -c 'xrandr --output HDMI-1 --mode 1024x600 --rate 60 || xrandr --output HDMI-A-1 --mode 1024x600 --rate 60 || xrandr --output HDMI-1-1 --mode 1024x600 --rate 60 || xrandr --output HDMI-1-2 --mode 1024x600 --rate 60 || true'
ExecStart=/usr/bin/chromium-browser --kiosk --user-data-dir=/tmp/chrome-kiosk --disable-web-security --disable-features=VizDisplayCompositor --disable-dev-shm-usage --no-sandbox --disable-setuid-sandbox --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disable-features=TranslateUI --disable-ipc-flooding-protection --disable-hang-monitor --disable-prompt-on-repost --disable-client-side-phishing-detection --disable-component-extensions-with-background-pages --disable-default-apps --disable-extensions --disable-sync --disable-translate --hide-scrollbars --metrics-recording-only --mute-audio --no-first-run --safebrowsing-disable-auto-update --ignore-certificate-errors --ignore-ssl-errors --ignore-certificate-errors-spki-list --disable-gpu --disable-software-rasterizer "http://localhost:8123?kiosk"
ExecStop=/bin/bash -c 'pkill -f chromium-browser'
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF

# Reload systemd and start kiosk
print_status "Reloading systemd and starting kiosk..."
systemctl daemon-reload
systemctl start kiosk

print_success "Display and touchscreen fixes applied!"
print_status "The kiosk should now display properly with correct resolution and touch input."
print_status "If issues persist, the system may need a reboot to apply all changes." 