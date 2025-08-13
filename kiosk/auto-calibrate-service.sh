#!/bin/bash

# Auto-Calibration Service Script
# Runs automatically after kiosk starts during deployment
# Only calibrates once, then reuses saved values

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

# Check if calibration values are already saved
CALIBRATION_FILE="/opt/turtle-enclosure/saved_calibration.conf"
if [ -f "$CALIBRATION_FILE" ]; then
    echo "✅ Calibration values already saved. Applying saved configuration..."
    
    # Apply saved calibration values
    sudo cp "$CALIBRATION_FILE" /etc/X11/xorg.conf.d/99-calibration.conf
    
    # Merge with touchscreen config if it exists
    if [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
        echo "📝 Merging saved calibration with touchscreen configuration..."
        CALIBRATION_MATRIX=$(grep "CalibrationMatrix" "$CALIBRATION_FILE" | cut -d'"' -f2)
        if [ -n "$CALIBRATION_MATRIX" ]; then
            sudo sed -i "s/Option \"CalibrationMatrix\" \".*\"/Option \"CalibrationMatrix\" \"$CALIBRATION_MATRIX\"/" /etc/X11/xorg.conf.d/10-touchscreen.conf
            sudo rm /etc/X11/xorg.conf.d/99-calibration.conf
            echo "✅ Saved calibration applied to touchscreen configuration"
        fi
    fi
    
    echo "✅ Calibration values restored. No need to recalibrate."
    exit 0
fi

# Check if calibration already exists in X11 config
if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
    echo "✅ Calibration already exists in X11 config. Saving for future use..."
    sudo cp /etc/X11/xorg.conf.d/99-calibration.conf "$CALIBRATION_FILE"
    echo "✅ Calibration values saved for future use."
    exit 0
fi

# Install calibration tools if not present
if ! command -v xinput_calibrator &> /dev/null; then
    echo "📦 Installing touchscreen calibration tools..."
    sudo apt update
    sudo apt install -y xinput-calibrator
fi

echo "📱 Starting automatic calibration (first time only)..."
echo "💡 This will run in the background. Check the kiosk display for calibration interface."

# Run calibration with timeout and error handling
timeout 120 xinput_calibrator 2>&1 | tee /tmp/auto_calibration.log

# Check if calibration succeeded
if [ $? -eq 0 ]; then
    echo "✅ Automatic calibration completed successfully!"
    
    # Save calibration values permanently
    if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
        echo "💾 Saving calibration values for future use..."
        sudo cp /etc/X11/xorg.conf.d/99-calibration.conf "$CALIBRATION_FILE"
        sudo chmod 644 "$CALIBRATION_FILE"
        echo "✅ Calibration values saved permanently"
        
        # Merge calibration with touchscreen config if it exists
        if [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
            echo "📝 Merging calibration with touchscreen configuration..."
            CALIBRATION_MATRIX=$(grep "CalibrationMatrix" /etc/X11/xorg.conf.d/99-calibration.conf | cut -d'"' -f2)
            if [ -n "$CALIBRATION_MATRIX" ]; then
                sudo sed -i "s/Option \"CalibrationMatrix\" \".*\"/Option \"CalibrationMatrix\" \"$CALIBRATION_MATRIX\"/" /etc/X11/xorg.conf.d/10-touchscreen.conf
                sudo rm /etc/X11/xorg.conf.d/99-calibration.conf
                echo "✅ Calibration merged with touchscreen configuration"
            fi
        fi
    fi
else
    echo "⚠️  Automatic calibration failed or timed out."
    echo "💡 Manual calibration may be needed: turtle-calibrate"
    
    # Check if it was a timeout and try with pre-calibrated values
    if grep -q "Timeout waiting for hardware cmd interrupt" /tmp/auto_calibration.log 2>/dev/null; then
        echo "🔧 Hardware timeout detected. Trying with pre-calibrated values..."
        timeout 60 xinput_calibrator --precalib 0 65535 0 65535 2>&1 | tee /tmp/precalib_calibration.log
        
        if [ $? -eq 0 ]; then
            echo "✅ Pre-calibrated values applied successfully!"
            
            # Save the pre-calibrated values
            if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
                sudo cp /etc/X11/xorg.conf.d/99-calibration.conf "$CALIBRATION_FILE"
                sudo chmod 644 "$CALIBRATION_FILE"
                echo "✅ Pre-calibrated values saved for future use"
            fi
        fi
    fi
fi

# Clean up
rm -f /tmp/auto_calibration.log /tmp/precalib_calibration.log

echo "🔄 Auto-calibration service completed" 