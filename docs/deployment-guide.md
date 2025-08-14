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

## ⚙️ Pre-Deployment Configuration

**IMPORTANT**: Before running the deployment script, you need to configure several values. The system uses placeholder values that must be updated with your actual information.

### Required Configuration Values

You'll need to configure these values in the files below:

1. **Email Configuration** (for notifications):
   - Gmail address for the turtle system
   - Gmail app password (not your regular password)
   - Personal email for receiving alerts

2. **Home Assistant Token**:
   - Long-lived access token (generated in Home Assistant)

3. **Camera Credentials** (if your camera requires authentication):
   - Camera admin username
   - Camera admin password

4. **System Passwords**:
   - Turtle user password
   - InfluxDB password (for data logging)
   - Grafana password (for monitoring dashboards)

### Step 1: Configure Secrets File

Edit the secrets file with your actual credentials:

```bash
# Clone the repository first
git clone https://github.com/yourusername/turtle-enclosure-system.git
cd turtle-enclosure-system

# Edit the secrets file
nano home-assistant/secrets.yaml
```

**Update these values in `home-assistant/secrets.yaml`:**

```yaml
# Turtle Enclosure System Secrets
# ⚠️  WARNING: DO NOT commit this file with real passwords to version control!

# Email configuration for notifications
email_username: "your-turtle-email@gmail.com"  # CHANGE THIS
email_password: "your-app-password"  # CHANGE THIS - Use Gmail app password
email_sender: "your-turtle-email@gmail.com"  # CHANGE THIS
email_recipient: "your-personal-email@gmail.com"  # CHANGE THIS

# Home Assistant long-lived access token
homeassistant_token: "your-long-lived-access-token"  # CHANGE THIS

# Camera credentials (if your camera requires authentication)
camera_username: "admin"  # CHANGE IF NEEDED
camera_password: "your-camera-password"  # CHANGE THIS

# Zigbee channel (11 is recommended to avoid interference)
zigbee_channel: 11  # CHANGE IF NEEDED
```

**How to get these values:**

1. **Gmail App Password**:
   - Go to your Google Account settings
   - Enable 2-factor authentication
   - Generate an "App Password" for "Mail"
   - Use this app password, not your regular Gmail password

2. **Home Assistant Token**:
   - Will be generated after Home Assistant is running
   - Go to Home Assistant → Profile → Long-Lived Access Tokens
   - Create a new token with a descriptive name

3. **Camera Credentials**:
   - Check your camera's manual for default credentials
   - Common defaults: admin/admin, admin/password, admin/12345

### Step 2: Configure Docker Passwords

Edit the Docker Compose file to set secure passwords:

```bash
nano docker/docker-compose.yml
```

**Update these values:**

```yaml
environment:
  - DOCKER_INFLUXDB_INIT_PASSWORD=your_influxdb_password  # CHANGE THIS
  # ... other settings ...
  - GF_SECURITY_ADMIN_PASSWORD=your_grafana_password  # CHANGE THIS
```

**Recommended passwords:**
- Use strong, unique passwords (12+ characters)
- Include uppercase, lowercase, numbers, and symbols
- Store these passwords securely (password manager recommended)

### Step 3: Configure System User Password

Edit the deployment script to set the turtle user password:

```bash
nano scripts/deploy.sh
```

**Find and update this line:**

```bash
echo "turtle:your_turtle_password" | sudo chpasswd  # CHANGE THIS
```

**Recommended password:**
- Use a strong password for the turtle user
- This user runs the kiosk interface

## 🚀 Deployment Steps

### Step 4: Clone and Deploy

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

### Step 5: Run the Main Deployment Script

```bash
# Make the deployment script executable
chmod +x scripts/deploy.sh

# Run the deployment script
sudo ./scripts/deploy.sh
```

This script will:
- Update system packages
- Install required software (Chromium, X11, Python packages)
- Create the `turtle` user with your configured password
- Configure display and touchscreen settings
- Set up udev rules for USB devices
- Install Home Assistant configuration
- Create Docker Compose setup with your configured passwords
- Enable auto-start services
- Set up monitoring and backup scripts

### Step 6: Configure Hardware

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

### Step 7: Generate Home Assistant Token

After Home Assistant starts for the first time:

1. **Access Home Assistant**:
   - Via touchscreen kiosk, or
   - Via web browser: `http://your-server-ip:8123`

2. **Complete Initial Setup**:
   - Create admin account
   - Set up your location
   - Complete onboarding

3. **Generate Long-Lived Access Token**:
   - Go to **Profile** → **Long-Lived Access Tokens**
   - Click **Create Token**
   - Name it "Turtle Enclosure System"
   - Copy the generated token

4. **Update Secrets File**:
   ```bash
   sudo nano /opt/homeassistant/config/secrets.yaml
   ```
   - Replace `your-long-lived-access-token` with the actual token

5. **Restart Home Assistant**:
   ```bash
   cd /opt/homeassistant && docker-compose restart
   ```

### Step 8: Reboot the System

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

### Step 9: Access Home Assistant

1. **Via Touchscreen**: The kiosk should automatically display Home Assistant
2. **Via Web Browser**: Navigate to `http://your-server-ip:8123`
3. **Initial Setup**: Complete the Home Assistant onboarding process

### Step 10: Configure Devices

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

### Step 11: Touchscreen Calibration

**One-Time Automatic Calibration**: The system will automatically calibrate the touchscreen on the first boot after deployment. Calibration values are saved permanently and reused on subsequent boots.

**What happens:**
1. **First boot** - Automatic calibration runs in background
2. **Calibration values saved** - Stored permanently in `/etc/X11/xorg.conf.d/99-touchscreen-calibration.conf`
3. **Future boots** - Saved values applied automatically, no recalibration needed

**Manual Calibration** (if needed):
```bash
# Run manual calibration
turtle-calibrate
```

**Note**: Once calibrated, the touchscreen will work perfectly on all future boots without needing recalibration.

### Step 12: Configure Dashboard

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
turtle-calibrate
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