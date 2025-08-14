#!/bin/bash

# Test Display Access Script
# Useful for troubleshooting display issues on the kiosk system

echo "🔍 Testing Display Access"
echo "========================"

echo "Current user: $(whoami)"
echo "Current DISPLAY: $DISPLAY"
echo "Current XAUTHORITY: $XAUTHORITY"

echo ""
echo "📺 Checking for X sessions..."
ls -la /tmp/.X*-lock 2>/dev/null || echo "No X lock files found"
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "No X11 socket directory found"

echo ""
echo "🐢 Checking turtle user..."
if [ -d /home/turtle ]; then
    echo "Turtle user exists"
    if [ -f /home/turtle/.Xauthority ]; then
        echo "Turtle XAUTHORITY exists"
    else
        echo "Turtle XAUTHORITY not found"
    fi
else
    echo "Turtle user not found"
fi

echo ""
echo "🖥️ Testing display connections..."

# Test current display
echo "Testing current DISPLAY ($DISPLAY):"
if xrandr --listmonitors > /dev/null 2>&1; then
    echo "✅ Current display accessible"
    xrandr --listmonitors
else
    echo "❌ Current display not accessible"
fi

# Test turtle user display
echo ""
echo "Testing turtle user display (:0):"
if sudo -u turtle -H bash -c 'export DISPLAY=:0 && xrandr --listmonitors' > /dev/null 2>&1; then
    echo "✅ Turtle user display accessible"
    sudo -u turtle -H bash -c 'export DISPLAY=:0 && xrandr --listmonitors'
else
    echo "❌ Turtle user display not accessible"
fi

# Test different display numbers
echo ""
echo "Testing different display numbers..."
for display in ":0" ":1" ":0.0" ":1.0"; do
    echo "Testing DISPLAY=$display:"
    if DISPLAY=$display xrandr --listmonitors > /dev/null 2>&1; then
        echo "✅ DISPLAY=$display accessible"
        DISPLAY=$display xrandr --listmonitors
    else
        echo "❌ DISPLAY=$display not accessible"
    fi
done

echo ""
echo "🔧 Kiosk service status:"
sudo systemctl status kiosk --no-pager -l

echo ""
echo "📱 Touchscreen devices:"
xinput list | grep -i touch || echo "No touch devices found"

echo ""
echo "🔌 USB devices:"
lsusb | grep -i touch || echo "No USB touch devices found" 