#!/bin/bash

# Turtle Enclosure Touchscreen Calibration (Post-Startup)
# Runs after kiosk starts to calibrate the touchscreen

set -e

echo "🐢 Touchscreen Calibration (Post-Startup)"
echo "=========================================="

# Wait for display to be available
echo "⏳ Waiting for display to be ready..."
sleep 10

# Check if we're in a graphical environment
if [[ -z $DISPLAY ]]; then
    echo "❌ No display detected. Trying to set display..."
    export DISPLAY=:0
    export XAUTHORITY=/home/turtle/.Xauthority
fi

# Check if display is working
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Display not responding. Please run this after the kiosk is fully started."
    exit 1
fi

echo "✅ Display detected: $DISPLAY"

# Install calibration tools if not present
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing touchscreen calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
fi

# Check if calibration has already been done
if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
    echo "📝 Calibration file already exists. Do you want to recalibrate? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "✅ Keeping existing calibration"
        exit 0
    fi
fi

echo "📱 Starting touchscreen calibration..."
echo "💡 Follow the on-screen instructions to calibrate your touchscreen"
echo "🎯 Touch each crosshair as accurately as possible"
echo ""

# Run the calibration
xinput_calibrator --output-type xinput

echo ""
echo "✅ Calibration complete!"
echo "📝 The calibration data has been saved"
echo "🔄 Please reboot the system to apply the new calibration"
echo ""
echo "💡 If calibration didn't work well, you can run this script again" 