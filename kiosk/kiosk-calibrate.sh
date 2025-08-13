#!/bin/bash

# Kiosk-Integrated Calibration Script
# Runs calibration from within the kiosk session

set -e

echo "🐢 Kiosk Touchscreen Calibration"
echo "================================"

# This script should be run from within the kiosk session
# It can be triggered by pressing a key combination or from the kiosk interface

# Get current user
CURRENT_USER=$(whoami)
echo "👤 Running as: $CURRENT_USER"

# Install calibration tools if not present
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing touchscreen calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
fi

# Set up display environment for kiosk session
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display from kiosk session."
    echo "💡 This script should be run from within the kiosk session."
    echo "   Try pressing Ctrl+Alt+F1 to switch to console, then run this script."
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
echo "✅ Running from kiosk session"
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