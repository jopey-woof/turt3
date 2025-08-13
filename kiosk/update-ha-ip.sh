#!/bin/bash

# Update Home Assistant IP Address Script
# Easily change the Home Assistant URL for the kiosk

set -e

echo "🐢 Update Home Assistant IP Address"
echo "==================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if configuration file exists
if [ ! -f "/etc/turtle-enclosure/ha-config.conf" ]; then
    echo "❌ Home Assistant configuration not found."
    echo "💡 Please run the deployment script first."
    exit 1
fi

# Get current IP
CURRENT_IP=$(grep "HA_PRIMARY_URL" /etc/turtle-enclosure/ha-config.conf | cut -d'"' -f2 | sed 's|http://||' | sed 's|:8123||')
echo "Current Home Assistant IP: $CURRENT_IP"

# Ask for new IP
echo ""
read -p "Enter new Home Assistant IP address (or press Enter to keep current): " NEW_IP

if [ -z "$NEW_IP" ]; then
    echo "Keeping current IP: $CURRENT_IP"
    exit 0
fi

# Validate IP format (basic check)
if [[ ! $NEW_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid IP address format. Please use format: 192.168.1.100"
    exit 1
fi

# Update configuration file
echo "📝 Updating Home Assistant IP to: $NEW_IP"
sudo sed -i "s|HA_PRIMARY_URL=\"http://.*:8123\"|HA_PRIMARY_URL=\"http://$NEW_IP:8123\"|" /etc/turtle-enclosure/ha-config.conf

# Update fallback URLs
sudo sed -i "s|http://10\.0\.20\.69:8123|http://$NEW_IP:8123|g" /etc/turtle-enclosure/ha-config.conf

# Reload systemd and restart kiosk
echo "🔄 Reloading systemd and restarting kiosk..."
sudo systemctl daemon-reload
sudo systemctl restart kiosk

# Check status
sleep 3
if systemctl is-active --quiet kiosk; then
    echo "✅ Kiosk service restarted successfully"
    echo "✅ Home Assistant IP updated to: $NEW_IP"
else
    echo "⚠️  Kiosk service may need manual restart"
    echo "💡 Run: sudo systemctl restart kiosk"
fi 