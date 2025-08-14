#!/bin/bash

# Fix Touchscreen Calibration
# Applies the known good calibration matrix to fix vertical scaling issues

set -e

echo "🐢 Fixing Touchscreen Calibration"
echo "=================================="

# Apply the known good calibration matrix that fixes vertical scaling issues
# This matrix (1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0) fixes the issue where
# vertical scaling gets worse as you move down the screen
echo "🔧 Applying known good calibration matrix..."

# Backup current configuration
if [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
    echo "📋 Backing up current touchscreen configuration..."
    sudo cp /etc/X11/xorg.conf.d/10-touchscreen.conf /etc/X11/xorg.conf.d/10-touchscreen.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

# Apply the calibration matrix
sudo sed -i 's|Option "CalibrationMatrix" ""|Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"|' /etc/X11/xorg.conf.d/10-touchscreen.conf

# Verify the change was applied
if grep -q 'CalibrationMatrix "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"' /etc/X11/xorg.conf.d/10-touchscreen.conf; then
    echo "✅ Known good calibration matrix applied successfully!"
    echo "   Matrix: 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"
    echo "   This fixes vertical scaling issues that get worse as you move down the screen"
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
echo "🎯 Touchscreen calibration fixed successfully!"
echo "🔄 Please reboot the system to apply the calibration"
echo "💡 The vertical scaling issue should now be fixed"
echo "📁 Backup saved as: /etc/X11/xorg.conf.d/10-touchscreen.conf.backup.*" 