# Turtle Enclosure System Deployment Guide

This guide provides step-by-step instructions for deploying the Turtle Enclosure Automation System on your Ubuntu Server machine.

## 🎯 Prerequisites

Before starting deployment, ensure you have:

- **Ubuntu Server 22.04 LTS** installed on Beelink Mini PC
- **Docker** installed and running
- **Git** installed
- **Sudo privileges** for the deployment user
- **All hardware connected** (see hardware checklist below)

## 📋 Hardware Checklist

Ensure all hardware is connected before deployment:

- [ ] **ROADOM 10.1" Touchscreen Monitor** (1024×600 IPS) - Connected via HDMI
- [ ] **TEMPerHUM PC USB sensor** - Connected to USB hub *(Optional: System works with fallback values)*
- [ ] **Arducam 1080P Day & Night Vision USB Camera** - Connected to USB hub
- [ ] **Sonoff Zigbee USB Dongle Plus** - Connected to USB hub
- [ ] **Anker 4-Port USB 3.0 Hub** - Connected to Mini PC
- [ ] **ZigBee Smart Plugs 4-pack** - Powered and ready for pairing
- [ ] **Vivarium Electronics VE-200 thermostat** - Existing system (will work alongside)

> **Note**: The TEMPerHUM sensor is optional for initial deployment. The system will use safe fallback values (75°F, 70% humidity) until the sensor is connected. You'll receive a notification when the sensor becomes available.

## 🚀 Deployment Steps

### Step 1: Clone the Repository

```bash
# Clone the repository to your home directory
git clone https://github.com/yourusername/turtle-enclosure-system.git
cd turtle-enclosure-system

# Verify the repository structure
ls -la
```

You should see the following directories:
- `kiosk/` - Display and touchscreen configuration
- `hardware/` - USB device and sensor configurations
- `home-assistant/` - Home Assistant configurations
- `themes/` - Custom CSS themes and styling
- `scripts/` - Deployment and utility scripts
- `docker/` - Docker configurations
- `docs/` - Documentation and setup guides

### Step 2: Run the Main Deployment Script

```bash
# Make the deployment script executable
chmod +x scripts/deploy.sh

# Run the deployment script
sudo ./scripts/deploy.sh
```

This script will:
- Update system packages
- Install required software (Chromium, X11, Python packages)
- Create the `turtle` user for kiosk mode
- Configure display and touchscreen settings
- Set up udev rules for USB devices
- Install Home Assistant configuration
- Create Docker Compose setup
- Enable auto-start services
- Set up monitoring and backup scripts

### Step 3: Configure Hardware

```bash
# Run the hardware setup script
sudo ./scripts/setup-hardware.sh
```

This script will:
- Install hardware diagnostic tools
- Test all USB devices and sensors
- Verify camera functionality
- Check touchscreen configuration
- Create device test scripts

### Step 4: Update Configuration Secrets

Edit the secrets file with your actual credentials:

```bash
sudo nano /opt/homeassistant/config/secrets.yaml
```

Update the following values:
- `email_username`: Your Gmail address
- `email_password`: Your Gmail app password
- `email_sender`: Your Gmail address
- `email_recipient`: Where to send alerts
- `homeassistant_token`: Long-lived access token (generate in HA)
- `camera_username`: Camera admin username
- `camera_password`: Camera admin password
- `zigbee_channel`: Zigbee channel (11 recommended)

### Step 5: Reboot the System

```bash
# Reboot to apply all changes
sudo reboot
```

After reboot, the system will:
- Auto-login as the `turtle` user
- Start the graphical environment
- Launch Chromium in kiosk mode
- Display the Home Assistant interface

## 🔧 Post-Deployment Configuration

### Step 6: Access Home Assistant

1. **Via Touchscreen**: The kiosk should automatically display Home Assistant
2. **Via Web Browser**: Navigate to `http://your-server-ip:8123`
3. **Initial Setup**: Complete the Home Assistant onboarding process

### Step 7: Configure Devices

#### TEMPerHUM Sensor
The sensor should be automatically detected. Verify in:
- **Configuration** → **Devices & Services** → **Sensors**
- Look for "Temperature" and "Humidity" entities

#### Arducam Camera
Configure the camera in:
- **Configuration** → **Devices & Services** → **Add Integration**
- Search for "Generic Camera"
- Enter the camera URL (usually `http://localhost:8080`)

#### Zigbee Devices
1. **Add Zigbee Integration**:
   - **Configuration** → **Devices & Services** → **Add Integration**
   - Search for "Zigbee Home Automation"
   - Select your Zigbee dongle device

2. **Pair Smart Plugs**:
   - Put each smart plug in pairing mode
   - They should appear in the Zigbee integration
   - Rename them appropriately (e.g., "Cooling Fan", "Misting System")

### Step 8: Touchscreen Calibration

After deployment, you may need to calibrate the touchscreen for accurate touch input:

1. **Reboot the system**:
   ```bash
   sudo reboot
   ```

2. **Wait for kiosk to start** (about 30-60 seconds)

3. **SSH in again and run calibration**:
   ```bash
   turtle-calibrate
   ```

4. **Follow on-screen instructions**:
   - Touch each crosshair as accurately as possible
   - Complete the calibration process
   - Reboot the system to apply changes

**Note**: The calibration script works with any user and automatically handles X11 authorization. It will work whether you're deploying via SSH or locally.

### Step 9: Configure Dashboard

1. **Access Lovelace**:
   - **Configuration** → **Dashboards** → **Turtle Enclosure**

2. **Add Cards**:
   - **Temperature Card**: Display current temperature
   - **Humidity Card**: Display current humidity
   - **Camera Card**: Show live camera feed
   - **Control Cards**: Smart plug controls
   - **Alert Cards**: System status and notifications

3. **Apply Turtle Theme**:
   - **Configuration** → **Settings** → **Themes**
   - Select "Turtle Theme" from the dropdown

## 🧪 Testing and Verification

### Test All Components

```bash
# Test all hardware devices
/opt/homeassistant/test_devices.sh

# Monitor hardware status
/opt/homeassistant/hardware_monitor.py

# View system information
/opt/homeassistant/system_info.sh
```

### Verify Services

```bash
# Check kiosk service status
sudo systemctl status kiosk

# Check Home Assistant container
docker ps | grep homeassistant

# View kiosk logs
sudo journalctl -u kiosk -f

# View Home Assistant logs
docker logs homeassistant
```

### Test Notifications

1. **Mobile App**: Install Home Assistant mobile app and configure notifications
2. **Email**: Test email alerts by temporarily adjusting temperature thresholds
3. **On-screen**: Verify alerts appear on the touchscreen interface

## 🔄 Maintenance and Updates

### Regular Maintenance

```bash
# Check system status
/opt/homeassistant/system_info.sh

# View recent logs
sudo journalctl -u kiosk --since "1 hour ago"

# Check disk space
df -h

# Check memory usage
free -h
```

### Backup and Restore

```bash
# Manual backup
/opt/homeassistant/backup.sh

# List backups
ls -la /opt/backups/

# Restore from backup (if needed)
sudo tar -xzf /opt/backups/ha_config_YYYYMMDD_HHMMSS.tar.gz -C /opt/homeassistant/
```

### System Updates

```bash
# Update from GitHub
cd /path/to/turtle-enclosure-system
git pull origin main

# Re-run deployment script
sudo ./scripts/deploy.sh

# Restart services
sudo systemctl restart kiosk
cd /opt/homeassistant && docker-compose restart
```

## 🚨 Troubleshooting

### Common Issues

#### Kiosk Not Starting
```bash
# Check kiosk service
sudo systemctl status kiosk

# Restart kiosk
sudo systemctl restart kiosk

# Check display configuration
xrandr --listmonitors
```

#### Home Assistant Not Accessible
```bash
# Check container status
docker ps | grep homeassistant

# Restart container
cd /opt/homeassistant && docker-compose restart

# Check logs
docker logs homeassistant
```

#### Hardware Not Detected
```bash
# Check USB devices
lsusb

# Check video devices
v4l2-ctl --list-devices

# Test specific devices
/opt/homeassistant/test_devices.sh
```

#### Touchscreen Not Working
```bash
# Check touch input
xinput list

# Test touch events
xinput test-xi2 --root

# Recalibrate touchscreen
sudo apt install xinput-calibrator
xinput_calibrator
```

#### Touchscreen Calibration Issues
If you encounter "Authorization required, but no authorization protocol specified" errors:

1. **Use the foolproof calibration script**:
   ```bash
   turtle-calibrate
   ```

2. **If that doesn't work, try the temporary script**:
   ```bash
   sudo /tmp/run_calibration.sh
   ```

3. **Manual troubleshooting**:
   ```bash
   # Check if kiosk is running
   sudo systemctl status kiosk
   
   # Check if display manager is running
   sudo systemctl status lightdm
   
   # Check display availability
   echo $DISPLAY
   xrandr --listmonitors
   ```

4. **If still having issues**:
   - Ensure the kiosk session has started: `sudo systemctl status kiosk`
   - Wait 30-60 seconds after reboot for full startup
   - Try running calibration again: `turtle-calibrate`

### Getting Help

1. **Check Logs**: Review system and service logs
2. **Test Hardware**: Use the provided test scripts
3. **Verify Configuration**: Check all configuration files
4. **Community Support**: Post issues on Home Assistant community forums

## 📞 Support Information

- **System Logs**: `/var/log/turtle-enclosure.log`
- **Home Assistant Config**: `/opt/homeassistant/config/`
- **Kiosk Service**: `sudo systemctl status kiosk`
- **Hardware Monitor**: `/opt/homeassistant/hardware_monitor.py`

## 🎉 Success Criteria

Your Turtle Enclosure System is successfully deployed when:

- [ ] Touchscreen displays Home Assistant interface automatically
- [ ] Temperature and humidity sensors are reading correctly
- [ ] Camera feed is visible in the interface
- [ ] Smart plugs can be controlled via touchscreen
- [ ] Mobile notifications are working
- [ ] Email alerts are configured and tested
- [ ] All automations are functioning properly
- [ ] System reboots and starts automatically

---

**🐢 Your turtle enclosure automation system is now ready to provide a healthy, monitored environment for your Eastern Box Turtle!** 