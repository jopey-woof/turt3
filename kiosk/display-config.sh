#!/bin/bash

# Turtle Enclosure Display Configuration Script
# Configures the ROADOM 10.1" Touchscreen Monitor (1024×600 IPS)

set -e

echo "🐢 Configuring Turtle Enclosure Display..."

# Create X11 configuration directory
sudo mkdir -p /etc/X11/xorg.conf.d

# Copy the improved touchscreen configuration
sudo cp "$(dirname "$0")/10-touchscreen.conf" /etc/X11/xorg.conf.d/

# Create user for kiosk mode
if ! id "turtle" &>/dev/null; then
    echo "Creating turtle user..."
    sudo useradd -m -s /bin/bash turtle
    sudo usermod -aG video,audio,plugdev turtle
    echo "turtle:turtle123" | sudo chpasswd
fi

# Create .xinitrc for auto-start
cat > /tmp/.xinitrc << 'EOF'
#!/bin/bash
# Auto-start kiosk mode
export DISPLAY=:0
export XAUTHORITY=/home/turtle/.Xauthority

# Wait for display to be ready
sleep 5

# Start kiosk service
systemctl --user start kiosk
EOF

sudo mv /tmp/.xinitrc /home/turtle/
sudo chown turtle:turtle /home/turtle/.xinitrc
sudo chmod +x /home/turtle/.xinitrc

# Create .bash_profile for auto-start X
cat > /tmp/.bash_profile << 'EOF'
#!/bin/bash
if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    exec startx
fi
EOF

sudo mv /tmp/.bash_profile /home/turtle/
sudo chown turtle:turtle /home/turtle/.bash_profile

echo "✅ Display configuration complete!"
echo "📺 Touchscreen configured for 1024x600 resolution"
echo "👤 Turtle user created with auto-login"
echo "🔄 Reboot to apply changes" 