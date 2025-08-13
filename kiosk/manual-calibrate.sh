#!/bin/bash

# Manual Touchscreen Calibration
# Works around hardware timeout issues

set -e

echo "🐢 Manual Touchscreen Calibration"
echo "================================="

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

# Set up display environment
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

echo "🔍 Checking touchscreen hardware..."
TOUCH_DEVICES=$(xinput list | grep -i touch || echo "No touch devices found")
echo "   Touch devices: $TOUCH_DEVICES"

echo ""
echo "📱 Manual Calibration Options:"
echo "1. Try with pre-calibrated values (recommended for hardware timeout issues)"
echo "2. Try with different timeout settings"
echo "3. Try with different calibration parameters"
echo ""

read -p "Choose option (1-3): " choice

case $choice in
    1)
        echo "🔄 Trying calibration with pre-calibrated values..."
        sudo -u turtle bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/turtle/.Xauthority; xinput_calibrator --precalib 0 65535 0 65535'
        ;;
    2)
        echo "🔄 Trying calibration with extended timeout..."
        timeout 120 sudo -u turtle bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/turtle/.Xauthority; xinput_calibrator'
        ;;
    3)
        echo "🔄 Trying calibration with different parameters..."
        sudo -u turtle bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/turtle/.Xauthority; xinput_calibrator --precalib 0 65535 0 65535 --timeout 30'
        ;;
    *)
        echo "❌ Invalid choice. Using default calibration..."
        sudo -u turtle bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/turtle/.Xauthority; xinput_calibrator'
        ;;
esac

echo ""
echo "✅ Calibration attempt completed!"
echo "💡 If you still see timeout errors, try:"
echo "   - Restarting the system"
echo "   - Checking USB connections"
echo "   - Using a different USB port" 