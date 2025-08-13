#!/bin/bash

# Reset Calibration Script
# Allows user to reset saved calibration values for recalibration

set -e

echo "🐢 Reset Touchscreen Calibration"
echo "================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

CALIBRATION_FILE="/opt/turtle-enclosure/saved_calibration.conf"

echo "🔍 Checking for saved calibration values..."

if [ -f "$CALIBRATION_FILE" ]; then
    echo "✅ Found saved calibration values at: $CALIBRATION_FILE"
    echo ""
    echo "⚠️  This will remove the saved calibration values."
    echo "💡 After reset, the system will recalibrate on next boot."
    echo ""
    
    read -p "Are you sure you want to reset calibration? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing saved calibration values..."
        sudo rm "$CALIBRATION_FILE"
        
        # Also remove any existing calibration configs
        sudo rm -f /etc/X11/xorg.conf.d/99-calibration.conf
        
        echo "✅ Calibration values reset successfully!"
        echo "🔄 The system will recalibrate on next boot."
        echo ""
        echo "💡 To recalibrate immediately, run: turtle-calibrate"
    else
        echo "❌ Calibration reset cancelled."
    fi
else
    echo "ℹ️  No saved calibration values found."
    echo "💡 The system will calibrate on next boot."
fi 