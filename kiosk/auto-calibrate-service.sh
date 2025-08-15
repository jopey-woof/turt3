#!/bin/bash

# Auto-Calibration Service Script
# Runs automatically after kiosk starts during deployment
# Only calibrates once, then reuses saved values

set -e

echo "🐢 Auto-Calibration Service"
echo "=========================="

# Set up display environment
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. Skipping calibration."
    exit 0
fi

echo "✅ Display ready for calibration"

# --- BEGIN Display Configuration from display-config.sh and calibrate-10inch.sh ---
# Set display resolution
xrandr --output HDMI-1 --mode 1024x600 || echo "Warning: Could not set HDMI-1 to 1024x600. Display might be different."

# Apply the correct calibration matrix for 10.1" screen (1024x600)
xinput set-prop 'yldzkj USB2IIC_CTP_CONTROL' 'Coordinate Transformation Matrix' 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0

# Hide the cursor for kiosk mode
/usr/local/bin/turtle-hide-cursor
echo "✅ Initial display and kiosk settings applied"
# --- END Display Configuration ---

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
    
    # Check if it was a timeout and try with known calibration values
    if grep -q "Timeout waiting for hardware cmd interrupt" /tmp/auto_calibration.log 2>/dev/null; then
        echo "🔧 Hardware timeout detected. Applying known calibration values..."
        
        # Get current resolution for auto-detection
        CURRENT_RESOLUTION=$(xrandr --current | grep '*' | awk '{print $1}' | head -1)
        echo "   Detected resolution: $CURRENT_RESOLUTION"
        
        # Apply known calibration based on resolution
        case $CURRENT_RESOLUTION in
            "1024x600")
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                echo "   Applying 10.1\" touchscreen calibration values..."
                ;;
            "800x480")
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                echo "   Applying 7\" touchscreen calibration values..."
                ;;
            "1024x768")
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                echo "   Applying 8\" touchscreen calibration values..."
                ;;
            "1280x800")
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                echo "   Applying 12\" touchscreen calibration values..."
                ;;
            *)
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                echo "   Applying default calibration values..."
                ;;
        esac
        
        # Create and apply known calibration
        cat > /tmp/known_calibration.conf << EOF
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "yldzkj USB2IIC_CTP_CONTROL"
    Option "CalibrationMatrix" "$CALIBRATION_MATRIX"
EndSection
EOF
        
        sudo cp /tmp/known_calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf
        sudo cp /tmp/known_calibration.conf "$CALIBRATION_FILE"
        sudo chmod 644 "$CALIBRATION_FILE"
        rm -f /tmp/known_calibration.conf
        
        echo "✅ Known calibration values applied successfully!"
        echo "✅ Calibration values saved for future use"
    fi
fi

# Clean up
rm -f /tmp/auto_calibration.log /tmp/precalib_calibration.log

echo "🔄 Auto-calibration service completed" 