#!/bin/bash

# Post-Deployment Touchscreen Calibration Script
# Run this after the turtle enclosure system is deployed and running

set -e

echo "🐢 Post-Deployment Touchscreen Calibration"
echo "=========================================="

# Check if running as turtle user
if [[ $(whoami) != "turtle" ]]; then
    echo "❌ This script must be run as the turtle user."
    echo "💡 Switch to turtle user: sudo su - turtle"
    exit 1
fi

# Check if we're in a graphical environment
if [[ -z $DISPLAY ]]; then
    echo "❌ No display detected. Please run this from a graphical session."
    echo ""
    echo "💡 Make sure you're logged in as turtle user in the kiosk session."
    echo "   If the kiosk isn't running, start it: sudo systemctl start kiosk"
    exit 1
fi

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. X11 authorization issue detected."
    echo ""
    echo "💡 This usually means the kiosk session isn't properly initialized."
    echo "   Try these steps:"
    echo "   1. Reboot the system: sudo reboot"
    echo "   2. Let the kiosk session start automatically"
    echo "   3. Press Ctrl+Alt+F1 to switch to console"
    echo "   4. Login as turtle user"
    echo "   5. Run this script again"
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
echo "✅ Running as turtle user"
echo ""

# Install calibration tools if not present
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing touchscreen calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
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