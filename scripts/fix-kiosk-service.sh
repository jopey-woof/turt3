#!/bin/bash

# Fix kiosk service file by adding missing quote
echo "Fixing kiosk service file..."

# Backup the current service file
sudo cp /etc/systemd/system/kiosk.service /etc/systemd/system/kiosk.service.backup

# Add the missing quote at the end of the URL
sudo sed -i 's|http://localhost:8123/lovelace/dashboard$|http://localhost:8123/lovelace/dashboard"|' /etc/systemd/system/kiosk.service

# Reload systemd and restart kiosk
sudo systemctl daemon-reload
sudo systemctl restart kiosk

echo "Kiosk service fixed and restarted!" 