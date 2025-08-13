#!/bin/bash

# Visual Kiosk Calibration Script
# Works with the visually running kiosk regardless of systemd status

set -e

echo "🐢 Visual Kiosk Touchscreen Calibration"
echo "======================================="

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

# Check if there's a visual display (kiosk is running)
echo "🔍 Checking for visual display..."

# Check if there are any X11 processes running
if ! pgrep -x "Xorg" > /dev/null; then
    echo "❌ No X11 server detected. Please ensure the kiosk is running."
    exit 1
fi

echo "✅ X11 server detected"

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
    echo "❌ Cannot access display. The kiosk session may be locked."
    echo ""
    echo "💡 Try these steps:"
    echo "   1. Press Ctrl+Alt+F1 to switch to console"
    echo "   2. Login as your user"
    echo "   3. Run this script again"
    echo "   4. Or try: export DISPLAY=:0 && xinput_calibrator"
    echo ""
    echo "🔍 Debug info:"
    echo "   Display: $DISPLAY"
    echo "   XAUTHORITY: $XAUTHORITY"
    echo "   X11 running: $(pgrep -x "Xorg" > /dev/null && echo "Yes" || echo "No")"
    echo "   LightDM running: $(pgrep -x "lightdm" > /dev/null && echo "Yes" || echo "No")"
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