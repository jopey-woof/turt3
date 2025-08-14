#!/bin/bash

# Simple Kiosk Starter Script
# Tests if Chromium can start and display Home Assistant

set -e

echo "🐢 Starting Kiosk Test"
echo "======================"

# Set up environment
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus

# Check if Home Assistant is running
echo "🔍 Checking Home Assistant..."
if curl -s -o /dev/null -w '%{http_code}' http://localhost:8123 | grep -q "200"; then
    echo "✅ Home Assistant is running on port 8123"
else
    echo "❌ Home Assistant is not responding on port 8123"
    exit 1
fi

# Check if display is accessible
echo "🔍 Checking display access..."
if xrandr --listmonitors > /dev/null 2>&1; then
    echo "✅ Display is accessible"
else
    echo "❌ Cannot access display"
    exit 1
fi

# Kill any existing Chromium processes
echo "🧹 Cleaning up existing Chromium processes..."
pkill -f chromium-browser || true
sleep 2

# Start Chromium with minimal flags
echo "🚀 Starting Chromium kiosk..."
/usr/bin/chromium-browser \
    --display=:0 \
    --kiosk \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-web-security \
    --disable-features=VizDisplayCompositor \
    --disable-background-timer-throttling \
    --disable-backgrounding-occluded-windows \
    --disable-renderer-backgrounding \
    --disable-features=TranslateUI \
    --disable-ipc-flooding-protection \
    --disable-hang-monitor \
    --disable-prompt-on-repost \
    --disable-client-side-phishing-detection \
    --disable-component-extensions-with-background-pages \
    --disable-default-apps \
    --disable-extensions \
    --disable-sync \
    --disable-translate \
    --hide-scrollbars \
    --metrics-recording-only \
    --mute-audio \
    --no-first-run \
    --safebrowsing-disable-auto-update \
    --ignore-certificate-errors \
    --ignore-ssl-errors \
    --ignore-certificate-errors-spki-list \
    "http://localhost:8123?kiosk" &

echo "✅ Chromium started in background"
echo "💡 Check the display to see if Home Assistant is showing" 