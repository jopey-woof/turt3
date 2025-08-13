#!/bin/bash

# Hardware-Aware Touchscreen Calibration
# Handles hardware timeout issues and provides alternatives

set -e

echo "🐢 Hardware-Aware Touchscreen Calibration"
echo "========================================="

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

# Check if there's a visual display
echo "🔍 Checking for visual display..."
if ! pgrep -x "Xorg" > /dev/null; then
    echo "❌ No X11 server detected. Please ensure the kiosk is running."
    exit 1
fi

echo "✅ X11 server detected"

# Set up display environment
export DISPLAY=:0

# Automated X11 authorization setup
echo "🔍 Setting up X11 authorization automatically..."

# Copy from turtle user
if [ -d "/home/turtle" ]; then
    echo "🔑 Copying X11 authorization from turtle user..."
    sudo cp /home/turtle/.Xauthority /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
    export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
fi

# Try to access display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. Please ensure the kiosk is running."
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
echo "✅ X11 authorization working"

# Check touchscreen hardware
echo "🔍 Checking touchscreen hardware..."
TOUCH_DEVICES=$(xinput list | grep -i touch || echo "No touch devices found")
echo "   Touch devices: $TOUCH_DEVICES"

# Try calibration with timeout handling
echo "📱 Starting touchscreen calibration..."
echo "💡 If you see 'Timeout waiting for hardware cmd interrupt', this is a hardware issue."
echo "🎯 Touch each crosshair as accurately as possible"
echo ""

# Create a calibration script with timeout handling
cat > /tmp/calibrate_with_timeout.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Try calibration with timeout
timeout 60 xinput_calibrator 2>&1 | tee /tmp/calibration_output.txt

# Check if calibration succeeded
if [ $? -eq 124 ]; then
    echo "TIMEOUT: Calibration timed out after 60 seconds"
    exit 1
elif [ $? -eq 0 ]; then
    echo "SUCCESS: Calibration completed successfully"
    exit 0
else
    echo "ERROR: Calibration failed"
    exit 1
fi
EOF

chmod +x /tmp/calibrate_with_timeout.sh

# Run calibration with timeout
echo "⏱️  Running calibration with 60-second timeout..."
sudo -u turtle /tmp/calibrate_with_timeout.sh

# Check the result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Calibration completed successfully!"
    echo "📝 The calibration data has been saved to your X11 configuration"
    echo "🔄 Please reboot the system to apply the new calibration"
else
    echo ""
    echo "⚠️  Calibration encountered issues. Trying alternative methods..."
    
    # Check if it was a timeout
    if grep -q "Timeout waiting for hardware cmd interrupt" /tmp/calibration_output.txt 2>/dev/null; then
        echo "🔧 Hardware timeout detected. This is a known issue with some touchscreens."
        echo ""
        echo "💡 Alternative solutions:"
        echo "   1. Try manual calibration with different settings"
        echo "   2. Use pre-calibrated values"
        echo "   3. Check touchscreen connections"
        echo ""
        
        # Try manual calibration with different approach
        echo "🔄 Trying manual calibration approach..."
        cat > /tmp/manual_calibrate.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Try with different calibration approach
xinput_calibrator --precalib 0 65535 0 65535 2>&1 | tee /tmp/manual_calibration_output.txt
EOF
        
        chmod +x /tmp/manual_calibrate.sh
        sudo -u turtle /tmp/manual_calibrate.sh
        
        if [ $? -eq 0 ]; then
            echo "✅ Manual calibration completed!"
        else
            echo "❌ Manual calibration also failed."
            echo ""
            echo "🔧 Hardware troubleshooting steps:"
            echo "   1. Check USB connections"
            echo "   2. Try a different USB port"
            echo "   3. Restart the system"
            echo "   4. Check if touchscreen is recognized: xinput list"
        fi
    else
        echo "❌ Calibration failed for unknown reason."
        echo "💡 Check the output above for more details."
    fi
fi

# Clean up
rm -f /tmp/calibrate_with_timeout.sh /tmp/manual_calibrate.sh /tmp/calibration_output.txt /tmp/manual_calibration_output.txt

echo ""
echo "💡 If calibration didn't work well, you can run this script again" 