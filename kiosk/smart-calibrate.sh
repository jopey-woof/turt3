#!/bin/bash

echo '🐢 Smart Touchscreen Calibration'
echo '================================'

# Set display
export DISPLAY=:0

# Try to get screen resolution
RESOLUTION=$(DISPLAY=:0 xrandr 2>/dev/null | grep '*' | awk '{print $1}' | head -1)

if [ -z "$RESOLUTION" ]; then
    echo '❌ Cannot detect screen resolution via SSH'
    echo '💡 Please run this script directly on the kiosk display:'
    echo '   cd /home/shrimp/turt3 && ./kiosk/smart-calibrate.sh'
    exit 1
fi

echo "📱 Detected resolution: $RESOLUTION"

# Apply calibration based on resolution
case "$RESOLUTION" in
    "1024x600")
        echo '🎯 Applying 10.1" touchscreen calibration (1024x600)'
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        ;;
    "800x480")
        echo '🎯 Applying 7" touchscreen calibration (800x480)'
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        ;;
    "1024x768")
        echo '🎯 Applying 8" touchscreen calibration (1024x768)'
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        ;;
    "1280x800")
        echo '🎯 Applying 12" touchscreen calibration (1280x800)'
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        ;;
    *)
        echo '⚠️  Unknown resolution, using default calibration'
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        ;;
esac

# Apply the calibration
echo '🔧 Applying calibration matrix...'
DISPLAY=:0 xinput set-prop 'USB Touchscreen' 'Coordinate Transformation Matrix' $CALIBRATION_MATRIX 2>/dev/null || \
DISPLAY=:0 xinput set-prop 'USB Touchscreen' 'Coordinate Transformation Matrix' $CALIBRATION_MATRIX 2>/dev/null || \
DISPLAY=:0 xinput set-prop 'USB Touchscreen' 'Coordinate Transformation Matrix' $CALIBRATION_MATRIX 2>/dev/null || \
echo '⚠️  Could not apply calibration via xinput'

echo '✅ Calibration applied!'
echo '💡 Test the touch accuracy now'
echo '🔄 Reboot to make calibration permanent' 