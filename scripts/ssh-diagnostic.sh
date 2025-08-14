#!/bin/bash

# SSH Diagnostic Script for Kiosk Display Issues
# Run this on the kiosk system via SSH

echo "🔍 SSH Diagnostic for Kiosk Display Issues"
echo "=========================================="
echo ""

echo "📋 System Information:"
echo "  Hostname: $(hostname)"
echo "  User: $(whoami)"
echo "  Date: $(date)"
echo ""

echo "🔧 Kiosk Service Status:"
if sudo systemctl is-active --quiet kiosk; then
    echo "  ✅ Kiosk service is running"
    echo "  Service details:"
    sudo systemctl status kiosk --no-pager -l | head -10
else
    echo "  ❌ Kiosk service is not running"
    echo "  Attempting to start kiosk service..."
    sudo systemctl start kiosk
    sleep 3
    if sudo systemctl is-active --quiet kiosk; then
        echo "  ✅ Kiosk service started successfully"
    else
        echo "  ❌ Failed to start kiosk service"
        echo "  Service logs:"
        sudo journalctl -u kiosk --no-pager -l | tail -10
    fi
fi

echo ""
echo "🐢 Turtle User Check:"
if [ -d /home/turtle ]; then
    echo "  ✅ Turtle user exists"
    if [ -f /home/turtle/.Xauthority ]; then
        echo "  ✅ Turtle XAUTHORITY exists"
        ls -la /home/turtle/.Xauthority
    else
        echo "  ❌ Turtle XAUTHORITY not found"
    fi
else
    echo "  ❌ Turtle user not found"
fi

echo ""
echo "📺 X11 Session Check:"
echo "  X lock files:"
ls -la /tmp/.X*-lock 2>/dev/null || echo "    No X lock files found"
echo "  X11 socket directory:"
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "    No X11 socket directory found"

echo ""
echo "🖥️ Display Environment Tests:"

# Test current environment
echo "  Current DISPLAY: '$DISPLAY'"
echo "  Current XAUTHORITY: '$XAUTHORITY'"

# Test turtle user display access
echo ""
echo "  Testing turtle user display access:"
if sudo -u turtle -H bash -c 'export DISPLAY=:0 && xrandr --listmonitors' > /dev/null 2>&1; then
    echo "    ✅ Turtle user can access display :0"
    echo "    Monitor info:"
    sudo -u turtle -H bash -c 'export DISPLAY=:0 && xrandr --listmonitors'
else
    echo "    ❌ Turtle user cannot access display :0"
fi

# Test different display numbers
echo ""
echo "  Testing different display numbers:"
for display in ":0" ":1" ":0.0" ":1.0"; do
    echo "    Testing DISPLAY=$display:"
    if sudo -u turtle -H bash -c "export DISPLAY=$display && xrandr --listmonitors" > /dev/null 2>&1; then
        echo "      ✅ Accessible"
        sudo -u turtle -H bash -c "export DISPLAY=$display && xrandr --listmonitors"
    else
        echo "      ❌ Not accessible"
    fi
done

echo ""
echo "📱 Hardware Detection:"
echo "  Touchscreen devices:"
xinput list | grep -i touch || echo "    No touch devices found"

echo "  USB devices:"
lsusb | grep -i touch || echo "    No USB touch devices found"

echo ""
echo "🔧 Display Manager Status:"
if sudo systemctl is-active --quiet lightdm; then
    echo "  ✅ LightDM is running"
elif sudo systemctl is-active --quiet gdm; then
    echo "  ✅ GDM is running"
elif sudo systemctl is-active --quiet sddm; then
    echo "  ✅ SDDM is running"
else
    echo "  ❌ No display manager detected as running"
fi

echo ""
echo "💡 Recommendations:"
echo "1. If kiosk service is not running, it needs to be started"
echo "2. If turtle user cannot access display, X11 permissions may need fixing"
echo "3. If no touch devices found, hardware may not be connected"
echo "4. Try running: sudo systemctl restart kiosk"
echo "5. Try running: sudo systemctl restart lightdm"

echo ""
echo "🔍 Additional Debug Info:"
echo "  Turtle user processes:"
ps aux | grep turtle | grep -v grep || echo "    No turtle processes found"

echo "  X11 processes:"
ps aux | grep -E "(X|lightdm|gdm|sddm)" | grep -v grep || echo "    No X11 processes found" 