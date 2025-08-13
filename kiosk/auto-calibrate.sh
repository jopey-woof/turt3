#!/bin/bash

# Fully Automated Touchscreen Calibration
# Works for any user, handles all X11 authorization automatically

set -e

echo "🐢 Automated Touchscreen Calibration"
echo "===================================="

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

# Method 1: Try to copy from turtle user (most reliable)
if [ -d "/home/turtle" ]; then
    echo "🔑 Copying X11 authorization from turtle user..."
    sudo cp /home/turtle/.Xauthority /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
    export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
fi

# Method 2: Try to copy from lightdm session
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Copying X11 authorization from lightdm session..."
    if pgrep -x "lightdm" > /dev/null; then
        sudo cp /var/run/lightdm/root/:0 /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
        export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
    fi
fi

# Method 3: Try to copy from any running X11 session
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Searching for X11 authorization in running sessions..."
    
    # Look for X11 authorization in common locations
    for auth_file in /var/run/lightdm/root/:0 /tmp/.X11-unix/X0 /tmp/.X0-lock; do
        if [ -f "$auth_file" ]; then
            echo "   Found authorization at: $auth_file"
            sudo cp "$auth_file" /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
            export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
            break
        fi
    done
fi

# Method 4: Generate new authorization using xauth
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Generating new X11 authorization..."
    if command -v xauth &> /dev/null; then
        # Try to add authorization for the current display
        xauth add :0 . $(mcookie) 2>/dev/null || true
        
        # Also try to copy from turtle user again with different method
        if [ -d "/home/turtle" ]; then
            sudo cp /home/turtle/.Xauthority /home/$CURRENT_USER/.Xauthority 2>/dev/null || true
            export XAUTHORITY=/home/$CURRENT_USER/.Xauthority
        fi
    fi
fi

# Method 5: Try to use sudo to run calibration as turtle user
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "🔄 Attempting to run calibration as turtle user..."
    
    # Create a temporary script to run calibration as turtle user
    cat > /tmp/calibrate_as_turtle.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority
xinput_calibrator --output-type xinput
EOF
    
    chmod +x /tmp/calibrate_as_turtle.sh
    
    # Run the calibration as turtle user
    sudo -u turtle /tmp/calibrate_as_turtle.sh
    
    # Clean up
    rm /tmp/calibrate_as_turtle.sh
    
    echo ""
    echo "✅ Calibration complete!"
    echo "📝 The calibration data has been saved to your X11 configuration"
    echo "🔄 Please reboot the system to apply the new calibration"
    exit 0
fi

# If we get here, we should have X11 access
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Still cannot access display after all attempts."
    echo ""
    echo "🔍 Debug info:"
    echo "   Display: $DISPLAY"
    echo "   XAUTHORITY: $XAUTHORITY"
    echo "   X11 running: $(pgrep -x "Xorg" > /dev/null && echo "Yes" || echo "No")"
    echo "   LightDM running: $(pgrep -x "lightdm" > /dev/null && echo "Yes" || echo "No")"
    echo "   Turtle user exists: $(id turtle >/dev/null 2>&1 && echo "Yes" || echo "No")"
    echo ""
    echo "💡 The kiosk may need to be restarted. Try: sudo systemctl restart kiosk"
    exit 1
fi

echo "✅ Display detected: $DISPLAY"
echo "✅ X11 authorization working"
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