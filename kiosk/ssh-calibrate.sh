#!/bin/bash

# SSH-Friendly Touchscreen Calibration Script
# Works with any user for remote deployment

set -e

echo "🐢 SSH Touchscreen Calibration Tool"
echo "==================================="

# Get current user
CURRENT_USER=$(whoami)
echo "👤 Running as: $CURRENT_USER"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Install calibration tools if not present
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing touchscreen calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
fi

# Wait for kiosk service to be fully active
echo "⏳ Waiting for kiosk service to be ready..."
MAX_WAIT=120  # 2 minutes max wait
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    KIOSK_STATUS=$(systemctl is-active kiosk 2>/dev/null || echo "unknown")
    
    if [ "$KIOSK_STATUS" = "active" ]; then
        echo "✅ Kiosk service is active"
        break
    elif [ "$KIOSK_STATUS" = "activating" ]; then
        echo "⏳ Kiosk service is still starting... (${WAIT_COUNT}s)"
        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
    else
        echo "❌ Kiosk service is not running. Status: $KIOSK_STATUS"
        echo "💡 Please ensure the system has been deployed and rebooted."
        exit 1
    fi
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo "❌ Timeout waiting for kiosk service to start"
    echo "💡 Please check kiosk service status: sudo systemctl status kiosk"
    exit 1
fi

# Additional wait for X11 session to be fully ready
echo "⏳ Waiting for X11 session to be ready..."
sleep 10

# Set up display environment
export DISPLAY=:0

# Try multiple methods to get X11 authorization
echo "🔍 Setting up X11 authorization..."

# Method 1: Try turtle user's authorization
if [ -f "/home/turtle/.Xauthority" ]; then
    echo "🔑 Using turtle user's X11 authorization..."
    export XAUTHORITY=/home/turtle/.Xauthority
elif [ -f "/home/$CURRENT_USER/.Xauthority" ]; then
    echo "🔑 Using current user's X11 authorization..."
    export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
else
    echo "⚠️  No X11 authorization found. Attempting to copy from turtle user..."
    if [ -d "/home/turtle" ]; then
        sudo cp /home/turtle/.Xauthority /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
        export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
    fi
fi

# Method 2: Try to copy from running session
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Attempting to get X11 authorization from running session..."
    
    # Try lightdm session
    if pgrep -x "lightdm" > /dev/null; then
        sudo cp /var/run/lightdm/root/:0 /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
        export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
    fi
    
    # Try gdm session
    if pgrep -x "gdm" > /dev/null; then
        sudo cp /var/run/gdm3/:0 /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
        export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
    fi
fi

# Method 3: Try to use xauth to generate authorization
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Attempting to generate X11 authorization..."
    
    # Check if xauth is available
    if command -v xauth &> /dev/null; then
        # Try to add authorization for current display
        xauth add :0 . $(mcookie) 2>/dev/null || true
    fi
fi

# Final check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display after waiting for kiosk to start."
    echo ""
    echo "🔍 Debug info:"
    echo "   Display: $DISPLAY"
    echo "   XAUTHORITY: $XAUTHORITY"
    echo "   LightDM running: $(pgrep -x "lightdm" > /dev/null && echo "Yes" || echo "No")"
    echo "   Kiosk service: $(systemctl is-active kiosk 2>/dev/null || echo "Unknown")"
    echo "   Turtle user exists: $(id turtle >/dev/null 2>&1 && echo "Yes" || echo "No")"
    echo ""
    echo "💡 Try these steps:"
    echo "   1. Check kiosk logs: sudo journalctl -u kiosk -n 20"
    echo "   2. Restart kiosk: sudo systemctl restart kiosk"
    echo "   3. Wait 30 seconds and try again: turtle-calibrate"
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
echo "✅ X11 authorization working"
echo "📱 Starting touchscreen calibration..."
echo "💡 Follow the on-screen instructions to calibrate your touchscreen"
echo "🎯 Touch each crosshair as accurately as possible"
echo ""

# Run the calibration
xinput_calibrator --output-type xinput

echo ""
echo "✅ Calibration complete!"
echo "📝 The calibration data has been saved to your X11 configuration"
echo "🔄 Please reboot the system to apply the new calibration"
echo ""
echo "💡 If calibration didn't work well, you can run this script again"
echo "💡 Or manually edit the calibration matrix in X11 configuration" 