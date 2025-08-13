#!/bin/bash

# Safe Touchscreen Calibration Script
# Runs calibration safely within the kiosk session

set -e

echo "🐢 Safe Touchscreen Calibration"
echo "==============================="

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

# Check if kiosk is running
if ! systemctl is-active --quiet kiosk; then
    echo "❌ Kiosk service is not running."
    echo "💡 Please start the kiosk first: sudo systemctl start kiosk"
    exit 1
fi

echo "✅ Kiosk service is running"

# Set up display environment
export DISPLAY=:0

# Try to get X11 authorization from the running kiosk session
echo "🔍 Setting up X11 authorization..."

# Method 1: Try to copy from turtle user's session
if [ -d "/home/turtle" ]; then
    echo "🔑 Copying X11 authorization from turtle user..."
    sudo cp /home/turtle/.Xauthority /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
    export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
fi

# Method 2: Try to copy from lightdm session
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Attempting to get X11 authorization from lightdm..."
    if pgrep -x "lightdm" > /dev/null; then
        sudo cp /var/run/lightdm/root/:0 /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
        export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
    fi
fi

# Method 3: Try to generate new authorization
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Attempting to generate X11 authorization..."
    if command -v xauth &> /dev/null; then
        xauth add :0 . $(mcookie) 2>/dev/null || true
    fi
fi

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. The kiosk session may be locked or busy."
    echo ""
    echo "💡 Try these steps:"
    echo "   1. Make sure you're running this from within the kiosk session"
    echo "   2. If the kiosk is showing Home Assistant, press Ctrl+Alt+F1 to switch to console"
    echo "   3. Login as your user and run this script"
    echo "   4. Or restart the kiosk: sudo systemctl restart kiosk"
    echo ""
    echo "🔍 Debug info:"
    echo "   Display: $DISPLAY"
    echo "   XAUTHORITY: $XAUTHORITY"
    echo "   Kiosk service: $(systemctl is-active kiosk 2>/dev/null || echo "Unknown")"
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
echo "✅ X11 authorization working"
echo "📱 Starting touchscreen calibration..."
echo "💡 Follow the on-screen instructions to calibrate your touchscreen"
echo "🎯 Touch each crosshair as accurately as possible"
echo ""

# Run the calibration
xinput_calibrator

echo ""
echo "✅ Calibration complete!"
echo "📝 The calibration data has been saved to your X11 configuration"
echo "🔄 Please reboot the system to apply the new calibration"
echo ""
echo "💡 If calibration didn't work well, you can run this script again" 