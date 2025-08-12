#!/bin/bash

# Turtle Enclosure Display Configuration Script
# Configures the ROADOM 10.1" Touchscreen Monitor (1024×600 IPS)

set -e

echo "🐢 Configuring Turtle Enclosure Display..."

# Create X11 configuration directory
sudo mkdir -p /etc/X11/xorg.conf.d

# Create display configuration
cat > /tmp/10-touchscreen.conf << 'EOF'
Section "InputClass"
    Identifier "Touchscreen"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
    Option "NaturalScrolling" "true"
    Option "ScrollMethod" "twofinger"
EndSection

Section "Monitor"
    Identifier "Touchscreen"
    Option "PreferredMode" "1024x600"
    Option "Primary" "true"
EndSection

Section "Screen"
    Identifier "Screen0"
    Monitor "Touchscreen"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1024x600"
    EndSubSection
EndSection

Section "Device"
    Identifier "Card0"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
EndSection
EOF

sudo mv /tmp/10-touchscreen.conf /etc/X11/xorg.conf.d/

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