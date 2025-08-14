#!/bin/bash

# Simple 10.1" Touchscreen Calibration Script
# Based on successful calibration for 1024x600 screens

set -e

echo "🐢 10.1\" Touchscreen Calibration"
echo "================================="

# Set display environment
export DISPLAY=:0

# Copy X11 authorization if needed
if [ ! -f "/home/shrimp/.Xauthority" ]; then
    echo "🔑 Setting up X11 authorization..."
    sudo cp /var/run/lightdm/root/:0 /home/shrimp/.Xauthority 2>/dev/null || true
    sudo chown shrimp:shrimp /home/shrimp/.Xauthority 2>/dev/null || true
fi

export XAUTHORITY=/home/shrimp/.Xauthority

# Apply calibration for 10.1" screen (1024x600)
echo "🎯 Applying 10.1\" touchscreen calibration..."
echo "   Resolution: 1024x600"
echo "   Y-axis scaling: 0.8 (fixes vertical misalignment)"

# Apply the calibration matrix
xinput set-prop 'yldzkj USB2IIC_CTP_CONTROL' 'Coordinate Transformation Matrix' 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0

echo "✅ Calibration applied successfully!"
echo "💡 Test the touch accuracy now"
echo "🔄 Reboot to make calibration permanent" 