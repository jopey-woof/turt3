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
    echo ""
    echo "💡 To fix this:"
    echo "   1. Make sure you're logged in as turtle user"
    echo "   2. Ensure the kiosk service is running: sudo systemctl status kiosk"
    echo "   3. If needed, restart the display manager: sudo systemctl restart lightdm"
    echo "   4. Log in again and try running this script"
    exit 1
fi

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. X11 authorization issue detected."
    echo ""
    echo "💡 This usually means you're not running from the correct user session."
    echo "   Try these steps:"
    echo "   1. Switch to turtle user: sudo su - turtle"
    echo "   2. Set display: export DISPLAY=:0"
    echo "   3. Run this script again"
    echo ""
    echo "   Or run the calibration from the turtle user's desktop session."
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
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