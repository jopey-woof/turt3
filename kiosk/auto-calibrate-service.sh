#!/bin/bash

# Auto-Calibration Service Script
# Runs automatically after kiosk starts during deployment

set -e

echo "🐢 Auto-Calibration Service"
echo "=========================="

# Wait for kiosk to be fully ready
echo "⏳ Waiting for kiosk to be ready..."
sleep 30

# Check if kiosk is running
if ! systemctl is-active --quiet kiosk; then
    echo "❌ Kiosk service not running. Skipping calibration."
    exit 0
fi

# Set up display environment
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. Skipping calibration."
    exit 0
fi

echo "✅ Display ready for calibration"

# Check if calibration already exists
if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
    echo "✅ Calibration already exists. Skipping."
    exit 0
fi

# Install calibration tools if not present
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing touchscreen calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
fi

echo "📱 Starting automatic calibration..."
echo "💡 This will run in the background. Check the kiosk display for calibration interface."

# Run calibration with timeout and error handling
timeout 120 xinput_calibrator 2>&1 | tee /tmp/auto_calibration.log

# Check if calibration succeeded
if [ $? -eq 0 ]; then
    echo "✅ Automatic calibration completed successfully!"
    
    # Merge calibration with touchscreen config if it exists
    if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ] && [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
        echo "📝 Merging calibration with touchscreen configuration..."
        CALIBRATION_MATRIX=$(grep "CalibrationMatrix" /etc/X11/xorg.conf.d/99-calibration.conf | cut -d'"' -f2)
        if [ -n "$CALIBRATION_MATRIX" ]; then
            sudo sed -i "s/Option \"CalibrationMatrix\" \".*\"/Option \"CalibrationMatrix\" \"$CALIBRATION_MATRIX\"/" /etc/X11/xorg.conf.d/10-touchscreen.conf
            sudo rm /etc/X11/xorg.conf.d/99-calibration.conf
            echo "✅ Calibration merged with touchscreen configuration"
        fi
    fi
else
    echo "⚠️  Automatic calibration failed or timed out."
    echo "💡 Manual calibration may be needed: turtle-calibrate"
fi

# Clean up
rm -f /tmp/auto_calibration.log

echo "🔄 Auto-calibration service completed" 