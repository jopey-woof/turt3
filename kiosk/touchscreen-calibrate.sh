#!/bin/bash

# Turtle Enclosure Touchscreen Calibration Script
# Fixes touch point drift and calibration issues

set -e

echo "🐢 Touchscreen Calibration Tool"
echo "================================"

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

# Check if we're in a graphical environment
if [[ -z $DISPLAY ]]; then
    echo "❌ No display detected. Please run this from a graphical session."
    echo "💡 Try: sudo systemctl restart lightdm"
    exit 1
fi

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