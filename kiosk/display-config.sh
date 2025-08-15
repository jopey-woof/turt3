#!/bin/bash

echo "🐢 Configuring display and kiosk..."

# Set display resolution
xrandr --output HDMI-1 --mode 1024x600 || echo "Warning: Could not set HDMI-1 to 1024x600. Display might be different."

# Ensure the correct touchscreen calibration is applied
# This uses the same logic as calibrate-10inch.sh
CURRENT_USER=$(whoami)
export DISPLAY=:0
export XAUTHORITY=/home/$CURRENT_USER/.Xauthority

# Apply the calibration matrix
xinput set-prop 'yldzkj USB2IIC_CTP_CONTROL' 'Coordinate Transformation Matrix' 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0

# Hide the cursor for kiosk mode
bash kiosk/hide-cursor.sh

echo "✅ Display and kiosk configured."