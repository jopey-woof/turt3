# Turtle Enclosure System Troubleshooting Guide

This guide helps you diagnose and resolve common issues with your Turtle Enclosure Automation System.

## 🔍 Quick Diagnostic Commands

### System Status Check
```bash
# Check all services
sudo systemctl status kiosk
docker ps
sudo journalctl -u kiosk --since "1 hour ago"

# Check hardware
/opt/homeassistant/test_devices.sh
/opt/homeassistant/hardware_monitor.py
/opt/homeassistant/system_info.sh
```

### Network and Connectivity
```bash
# Check network
ip addr show
ping -c 3 google.com
curl -I http://localhost:8123

# Check ports
netstat -tlnp | grep :8123
netstat -tlnp | grep :3000
```

## 🚨 Common Issues and Solutions

### 1. Kiosk Display Issues

#### Problem: Screen is blank or not displaying Home Assistant
**Symptoms:**
- Black screen on touchscreen
- No browser window visible
- Error messages in kiosk logs

**Solutions:**
```bash
# Check kiosk service status
sudo systemctl status kiosk

# Restart kiosk service
sudo systemctl restart kiosk

# Check display configuration
xrandr --listmonitors
xrandr --output HDMI-1 --mode 1024x600

# Check X11 is running
ps aux | grep X
echo $DISPLAY

# Manual browser test
sudo -u turtle chromium-browser --kiosk http://localhost:8123
```

#### Problem: Touchscreen not responding
**Symptoms:**
- Touch input not working
- Cursor doesn't move with touch
- Touch events not registered

**Solutions:**
```bash
# Check touch input devices
xinput list

# Test touch events
xinput test-xi2 --root

# Recalibrate touchscreen
turtle-calibrate

# Check touch device permissions
ls -la /dev/input/event*
sudo chmod 666 /dev/input/event*
```

### 2. Home Assistant Issues

#### Problem: Home Assistant not accessible
**Symptoms:**
- Can't access http://localhost:8123
- Container not running
- Connection refused errors

**Solutions:**
```bash
# Check container status
docker ps | grep homeassistant

# Restart Home Assistant
cd /opt/homeassistant
docker-compose restart homeassistant

# Check logs
docker logs homeassistant

# Check configuration
docker exec -it homeassistant python -m homeassistant --config /config --script check_config

# Manual container start
docker run -d --name homeassistant --restart unless-stopped \
  -v /opt/homeassistant/config:/config \
  --network host \
  ghcr.io/home-assistant/home-assistant:stable
```

#### Problem: Sensors not reading correctly
**Symptoms:**
- Temperature/humidity showing 0 or incorrect values
- Sensor entities not appearing
- Command line sensor errors

**Solutions:**
```bash
# Test TEMPerHUM sensor directly
cd /opt/homeassistant/config
python3 temperhum_reader.py

# Check USB device
lsusb | grep 0c45:7401

# Check device permissions
ls -la /dev/temperhum
sudo chmod 666 /dev/temperhum

# Test sensor in Home Assistant
docker exec -it homeassistant python3 -c "
import subprocess
result = subprocess.run(['python3', '/config/temperhum_reader.py'], 
                       capture_output=True, text=True)
print(f'Output: {result.stdout}')
print(f'Error: {result.stderr}')
"
```

### 3. Hardware Detection Issues

#### Problem: USB devices not detected
**Symptoms:**
- Devices not appearing in lsusb
- Device files missing
- Permission denied errors

**Solutions:**
```bash
# Check all USB devices
lsusb
dmesg | grep -i usb

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Check device files
ls -la /dev/zigbee-dongle /dev/temperhum /dev/turtle-camera

# Manual device creation
sudo mknod /dev/zigbee-dongle c 188 0
sudo chmod 666 /dev/zigbee-dongle
```

#### Problem: Camera not working
**Symptoms:**
- No video feed
- Camera entity unavailable
- Video device not found

**Solutions:**
```bash
# Check video devices
v4l2-ctl --list-devices
v4l2-ctl --device=/dev/video0 --list-formats-ext

# Test camera capture
ffmpeg -f v4l2 -i /dev/video0 -frames:v 1 test.jpg

# Check camera permissions
ls -la /dev/video*
sudo chmod 666 /dev/video0

# Restart camera service
docker restart camera-stream
```

### 4. Zigbee Integration Issues

#### Problem: Zigbee devices not pairing
**Symptoms:**
- Smart plugs not appearing
- Pairing fails
- Dongle not recognized

**Solutions:**
```bash
# Check Zigbee dongle
lsusb | grep 10c4:ea60
ls -la /dev/zigbee-dongle

# Check Zigbee integration logs
docker logs homeassistant | grep -i zigbee

# Reset Zigbee network
# In Home Assistant: Configuration > Devices & Services > ZHA > Configure > Reset
```

#### Problem: Smart plugs losing connection
**Symptoms:**
- Devices showing as unavailable
- Intermittent connectivity
- Power monitoring not working

**Solutions:**
```bash
# Check device status in Home Assistant
# Configuration > Devices & Services > ZHA > Devices

# Restart Zigbee integration
# Configuration > Devices & Services > ZHA > Configure > Restart

# Check for interference
# Move Zigbee dongle away from WiFi router
# Change Zigbee channel in configuration
```

### 5. Notification Issues

#### Problem: Mobile notifications not working
**Symptoms:**
- No push notifications
- Mobile app not connecting
- Notification errors in logs

**Solutions:**
```bash
# Check mobile app configuration
# In Home Assistant: Configuration > Devices & Services > Mobile App

# Test notifications
# Developer Tools > Services > notify.mobile_app

# Check external URL configuration
# Configuration > Settings > General > External URL
```

#### Problem: Email notifications failing
**Symptoms:**
- Email alerts not received
- SMTP errors in logs
- Authentication failures

**Solutions:**
```bash
# Check email configuration
cat /opt/homeassistant/config/secrets.yaml | grep email

# Test email manually
# Developer Tools > Services > notify.email

# Verify Gmail app password
# Use 2FA and generate app-specific password
```

### 6. Performance Issues

#### Problem: System running slowly
**Symptoms:**
- High CPU/memory usage
- Slow response times
- Browser freezing

**Solutions:**
```bash
# Check system resources
htop
free -h
df -h

# Check container resource usage
docker stats

# Restart services
sudo systemctl restart kiosk
cd /opt/homeassistant && docker-compose restart

# Clear browser cache
sudo rm -rf /home/turtle/.config/chromium-kiosk/Default/Cache/*
```

#### Problem: High disk usage
**Symptoms:**
- Disk space warnings
- System becoming unresponsive
- Log files growing large

**Solutions:**
```bash
# Check disk usage
df -h
du -sh /opt/homeassistant/*

# Clean up old logs
sudo journalctl --vacuum-time=7d

# Clean up Docker
docker system prune -f

# Clean up old backups
find /opt/backups -name "*.tar.gz" -mtime +7 -delete
```

## 🔧 Advanced Troubleshooting

### Debug Mode

Enable debug logging in Home Assistant:
```yaml
# In configuration.yaml
logger:
  default: debug
  logs:
    homeassistant.components.zha: debug
    homeassistant.components.usb: debug
    custom_components: debug
```

### Manual Device Testing

Test individual components:
```bash
# Test TEMPerHUM sensor
python3 /opt/homeassistant/config/temperhum_reader.py

# Test camera
v4l2-ctl --device=/dev/video0 --stream-mmap --stream-count=1

# Test Zigbee dongle
ls -la /dev/zigbee-dongle
stty -F /dev/zigbee-dongle 115200
```

### Network Diagnostics

```bash
# Check network interfaces
ip addr show

# Test connectivity
ping -c 3 8.8.8.8
nslookup google.com

# Check firewall
sudo ufw status
sudo iptables -L
```

## 📞 Getting Help

### Before Seeking Help

1. **Collect Information:**
   ```bash
   /opt/homeassistant/system_info.sh > system_info.txt
   /opt/homeassistant/hardware_monitor.py > hardware_status.json
   sudo journalctl -u kiosk --since "1 day ago" > kiosk_logs.txt
   docker logs homeassistant > ha_logs.txt
   ```

2. **Document the Issue:**
   - What were you doing when the problem occurred?
   - What error messages did you see?
   - What have you already tried?

3. **Check Recent Changes:**
   - Did you recently update the system?
   - Did you change any configuration?
   - Did you add new hardware?

### Where to Get Help

1. **Home Assistant Community Forums**
   - Post in the appropriate category
   - Include logs and configuration
   - Be specific about your setup

2. **GitHub Issues**
   - Create an issue in the repository
   - Include all diagnostic information
   - Follow the issue template

3. **Local Support**
   - Check system logs first
   - Use the provided diagnostic scripts
   - Review this troubleshooting guide

## 🛠️ Maintenance Commands

### Regular Maintenance
```bash
# Daily health check
/opt/homeassistant/hardware_monitor.py

# Weekly backup
/opt/homeassistant/backup.sh

# Monthly system update
cd /path/to/turtle-enclosure-system
git pull origin main
sudo ./scripts/deploy.sh
```

### Emergency Recovery
```bash
# Emergency restart
sudo reboot

# Emergency service restart
sudo systemctl restart kiosk
cd /opt/homeassistant && docker-compose restart

# Emergency backup
tar -czf emergency_backup_$(date +%Y%m%d_%H%M%S).tar.gz /opt/homeassistant/config/
```

---

**Remember: Most issues can be resolved by checking logs, testing hardware, and restarting services. When in doubt, start with the diagnostic commands and work through the troubleshooting steps systematically.** 