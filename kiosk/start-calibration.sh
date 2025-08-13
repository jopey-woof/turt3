#!/bin/bash

# Simple calibration starter for Turtle Enclosure
# Run this from within the kiosk session

echo "🐢 Starting Touchscreen Calibration..."
echo "======================================"

# Set display environment
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Check if we're in the right environment
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. Please run this from the turtle user session."
    echo "💡 Try: sudo su - turtle"
    exit 1
fi

echo "✅ Display detected: $DISPLAY"

# Install calibration tool if needed
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
fi

echo "📱 Starting calibration..."
echo "💡 Follow the on-screen instructions"
echo "🎯 Touch each crosshair accurately"
echo ""

# Run calibration
xinput_calibrator --output-type xinput

echo ""
echo "✅ Calibration complete!"
echo "🔄 Reboot to apply: sudo reboot" 