#!/bin/bash

# Apply Known Calibration Values
# Detects touchscreen and applies pre-calibrated values

set -e

echo "🐢 Apply Known Touchscreen Calibration"
echo "======================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Set up display environment
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Check if we can access the display
if ! xrandr --listmonitors > /dev/null 2>&1; then
    echo "❌ Cannot access display. Please ensure the kiosk is running."
    exit 1
fi

echo "🔍 Detecting touchscreen hardware..."

# Get current resolution
CURRENT_RESOLUTION=$(xrandr --current | grep '*' | awk '{print $1}' | head -1)
echo "   Current resolution: $CURRENT_RESOLUTION"

# Get touchscreen devices
TOUCH_DEVICES=$(xinput list | grep -i touch || echo "No touch devices found")
echo "   Touch devices: $TOUCH_DEVICES"

# Get USB device info
USB_DEVICES=$(lsusb | grep -i touch || echo "No USB touch devices found")
echo "   USB devices: $USB_DEVICES"

echo ""
echo "📱 Available Known Calibrations:"
echo "1. ROADOM 10.1\" Touchscreen Monitor (1024x600)"
echo "2. Generic 10.1\" Touchscreen (1024x600)"
echo "3. Generic 7\" Touchscreen (800x480)"
echo "4. Generic 8\" Touchscreen (1024x768)"
echo "5. Generic 12\" Touchscreen (1280x800)"
echo "6. USB Touchscreen (Hardware Timeout)"
echo "7. Auto-detect based on resolution"
echo ""

read -p "Choose calibration (1-7): " choice

case $choice in
    1)
        CALIBRATION_NAME="roadom_10_1_1024x600"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
    2)
        CALIBRATION_NAME="generic_10_1_1024x600"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
    3)
        CALIBRATION_NAME="generic_7_800x480"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
    4)
        CALIBRATION_NAME="generic_8_1024x768"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
    5)
        CALIBRATION_NAME="generic_12_1280x800"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
    6)
        CALIBRATION_NAME="usb_touchscreen_timeout"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
    7)
        # Auto-detect based on resolution
        case $CURRENT_RESOLUTION in
            "1024x600")
                CALIBRATION_NAME="auto_10_1_1024x600"
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                PRECALIB_VALUES="0 65535 0 65535"
                ;;
            "800x480")
                CALIBRATION_NAME="auto_7_800x480"
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                PRECALIB_VALUES="0 65535 0 65535"
                ;;
            "1024x768")
                CALIBRATION_NAME="auto_8_1024x768"
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                PRECALIB_VALUES="0 65535 0 65535"
                ;;
            "1280x800")
                CALIBRATION_NAME="auto_12_1280x800"
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                PRECALIB_VALUES="0 65535 0 65535"
                ;;
            *)
                echo "❌ Unknown resolution: $CURRENT_RESOLUTION"
                echo "💡 Using default calibration values..."
                CALIBRATION_NAME="default"
                CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
                PRECALIB_VALUES="0 65535 0 65535"
                ;;
        esac
        ;;
    *)
        echo "❌ Invalid choice. Using default values..."
        CALIBRATION_NAME="default"
        CALIBRATION_MATRIX="1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"
        PRECALIB_VALUES="0 65535 0 65535"
        ;;
esac

echo "🔄 Applying known calibration: $CALIBRATION_NAME"

# Create calibration configuration
cat > /tmp/known_calibration.conf << EOF
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "yldzkj USB2IIC_CTP_CONTROL"
    Option "CalibrationMatrix" "$CALIBRATION_MATRIX"
EndSection
EOF

# Apply the calibration
sudo cp /tmp/known_calibration.conf /etc/X11/xorg.conf.d/99-calibration.conf

# Save for future use
sudo cp /tmp/known_calibration.conf /opt/turtle-enclosure/saved_calibration.conf
sudo chmod 644 /opt/turtle-enclosure/saved_calibration.conf

# Merge with touchscreen config if it exists
if [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
    echo "📝 Merging with touchscreen configuration..."
    sudo sed -i "s/Option \"CalibrationMatrix\" \".*\"/Option \"CalibrationMatrix\" \"$CALIBRATION_MATRIX\"/" /etc/X11/xorg.conf.d/10-touchscreen.conf
    sudo rm /etc/X11/xorg.conf.d/99-calibration.conf
    echo "✅ Calibration merged with touchscreen configuration"
fi

# Clean up
rm -f /tmp/known_calibration.conf

echo "✅ Known calibration applied successfully!"
echo "🔄 Please reboot the system to apply the calibration"
echo "💡 Calibration values saved for future use" 