#!/bin/bash

# Apply Known Good Touchscreen Calibration
# Fixes vertical scaling issues that get worse as you move down the screen

set -e

echo "🐢 Applying Known Good Touchscreen Calibration"
echo "=============================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Backup current configuration
echo "📋 Backing up current touchscreen configuration..."
sudo cp /etc/X11/xorg.conf.d/10-touchscreen.conf /etc/X11/xorg.conf.d/10-touchscreen.conf.backup.$(date +%Y%m%d_%H%M%S)

# Apply the known good calibration matrix for 10.1" 1024x600 touchscreen
# This fixes vertical scaling issues that get worse as you move down the screen
echo "🔧 Applying known good calibration matrix..."
sudo sed -i 's|Option "CalibrationMatrix" ""|Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"|' /etc/X11/xorg.conf.d/10-touchscreen.conf

# Verify the change was applied
if grep -q 'CalibrationMatrix "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"' /etc/X11/xorg.conf.d/10-touchscreen.conf; then
    echo "✅ Calibration matrix applied successfully!"
    echo "   Matrix: 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"
    echo "   This fixes vertical scaling issues"
else
    echo "❌ Failed to apply calibration matrix"
    echo "💡 Restoring backup..."
    sudo cp /etc/X11/xorg.conf.d/10-touchscreen.conf.backup.* /etc/X11/xorg.conf.d/10-touchscreen.conf
    exit 1
fi

# Save calibration for future use
echo "💾 Saving calibration for future use..."
sudo mkdir -p /opt/turtle-enclosure
sudo cp /etc/X11/xorg.conf.d/10-touchscreen.conf /opt/turtle-enclosure/saved_calibration.conf
sudo chmod 644 /opt/turtle-enclosure/saved_calibration.conf

echo ""
echo "🎯 Calibration applied successfully!"
echo "🔄 Please reboot the system to apply the calibration"
echo "💡 The vertical scaling issue should now be fixed"
echo "📁 Backup saved as: /etc/X11/xorg.conf.d/10-touchscreen.conf.backup.*" 