#!/bin/bash

# Wait and Calibrate Script
# Automatically waits for system to be ready then calibrates touchscreen

set -e

echo "🐢 Wait and Calibrate Touchscreen"
echo "================================="

echo "⏳ Waiting for system to be fully ready..."
echo "💡 This may take 1-2 minutes after reboot"

# Wait for kiosk service to be active
echo "⏳ Waiting for kiosk service..."
while ! systemctl is-active --quiet kiosk; do
    echo "   Kiosk service not ready yet..."
    sleep 5
done

echo "✅ Kiosk service is active"

# Wait a bit more for X11 session to be fully ready
echo "⏳ Waiting for X11 session to be ready..."
sleep 15

echo "🚀 Starting calibration..."
turtle-calibrate 