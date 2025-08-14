#!/bin/bash

# Hide cursor in kiosk mode
# This script continuously moves the cursor off-screen to hide it

export DISPLAY=:0
export XAUTHORITY=/home/$(whoami)/.Xauthority

# Disable screen saver and power management
xset -dpms
xset s off

# Continuously hide cursor by moving it off-screen
while true; do
  xdotool mousemove 9999 9999 2>/dev/null || true
  sleep 1
done 