#!/bin/bash

# Kiosk Recovery Script
# Diagnoses and fixes common kiosk crash issues

set -e

echo "🐢 Kiosk Recovery Tool"
echo "====================="

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
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

print_status "Checking system status..."

# Check system resources
print_status "System resources:"
echo "   Memory usage: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "   Disk usage: $(df -h / | tail -1 | awk '{print $5}')"
echo "   Load average: $(uptime | awk -F'load average:' '{print $2}')"

# Check display manager
print_status "Checking display manager..."
if systemctl is-active --quiet lightdm; then
    print_success "LightDM is running"
else
    print_warning "LightDM is not running"
    echo "   Starting LightDM..."
    sudo systemctl start lightdm
    sleep 3
fi

# Check kiosk service
print_status "Checking kiosk service..."
KIOSK_STATUS=$(systemctl is-active kiosk 2>/dev/null || echo "unknown")

if [ "$KIOSK_STATUS" = "active" ]; then
    print_success "Kiosk service is active"
elif [ "$KIOSK_STATUS" = "activating" ]; then
    print_warning "Kiosk service is still starting..."
elif [ "$KIOSK_STATUS" = "failed" ]; then
    print_error "Kiosk service has failed"
    echo "   Restarting kiosk service..."
    sudo systemctl restart kiosk
    sleep 5
else
    print_warning "Kiosk service is not running (status: $KIOSK_STATUS)"
    echo "   Starting kiosk service..."
    sudo systemctl start kiosk
    sleep 5
fi

# Check recent kiosk logs
print_status "Recent kiosk logs:"
sudo journalctl -u kiosk -n 10 --no-pager

# Check for common issues
print_status "Checking for common issues..."

# Check if Home Assistant is accessible
if command -v curl &> /dev/null; then
    if curl -s http://localhost:8123 > /dev/null 2>&1; then
        print_success "Home Assistant is accessible"
    else
        print_warning "Home Assistant is not accessible on localhost:8123"
    fi
fi

# Check display configuration
if command -v xrandr &> /dev/null; then
    if [ -n "$DISPLAY" ]; then
        print_status "Display configuration:"
        xrandr --listmonitors 2>/dev/null || echo "   Cannot access display"
    else
        print_warning "No DISPLAY environment variable set"
    fi
fi

# Check for USB device issues
print_status "USB devices:"
lsusb | head -5

# Provide recovery options
echo ""
print_status "Recovery options:"
echo "1. Restart kiosk service: sudo systemctl restart kiosk"
echo "2. Restart display manager: sudo systemctl restart lightdm"
echo "3. Reboot system: sudo reboot"
echo "4. Check detailed logs: sudo journalctl -u kiosk -f"

# Ask user what they want to do
echo ""
read -p "Would you like to restart the kiosk service now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Restarting kiosk service..."
    sudo systemctl restart kiosk
    sleep 3
    
    if systemctl is-active --quiet kiosk; then
        print_success "Kiosk service restarted successfully"
    else
        print_error "Kiosk service failed to start"
        echo "   Check logs: sudo journalctl -u kiosk -n 20"
    fi
fi

echo ""
print_status "Recovery complete. If issues persist, consider rebooting the system." 