# Turtle Enclosure System Deployment Guide

## Overview
This guide covers the deployment of the Turtle Enclosure System, including Home Assistant, touchscreen kiosk, and hardware integration.

## Prerequisites
- Ubuntu 22.04 LTS (recommended)
- Internet connection
- sudo privileges
- Docker and Docker Compose installed

## Quick Deployment

### 1. Clone the Repository
```bash
git clone https://github.com/jopey-woof/turt3.git
cd turt3
```

### 2. Run the Deployment Script
```bash
bash scripts/deploy.sh
```

The deployment script will automatically:
- Install all required packages
- Configure the touchscreen with correct calibration
- Set up Home Assistant
- Configure the kiosk display
- Create system services

## Touchscreen Calibration

### Automatic Calibration (Recommended)
The deployment script now includes **comprehensive touchscreen calibration** that automatically:

✅ **Applies the correct calibration matrix** (`1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0`)  
✅ **Fixes vertical scaling issues** that get worse as you move down the screen  
✅ **Detects and resolves conflicting calibration files**  
✅ **Ensures consistency across all calibration configurations**  
✅ **Creates backups before making changes**  

### Manual Calibration Fix
If you need to fix calibration issues after deployment:

```bash
# Run the comprehensive calibration fix script
bash scripts/ensure-correct-calibration.sh

# Or run the specific conflict fix
python3 scripts/fix-calibration-conflict.py
```

### Calibration Matrix Details
- **Correct Matrix**: `1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0`
- **Purpose**: Fixes vertical scaling issues for 10.1" 1024x600 touchscreens
- **Effect**: Eliminates the problem where touch accuracy gets worse as you move down the screen

## Post-Deployment Configuration

### 1. Update Secrets
Edit `/opt/homeassistant/config/secrets.yaml` with your actual credentials:
- Email configuration
- Home Assistant token
- Camera passwords
- Zigbee channel

### 2. Access Home Assistant
- URL: `http://localhost:8123`
- Initial setup will guide you through configuration

### 3. Hardware Connection
Connect your hardware devices:
- TEMPerHUM sensor
- Camera
- Zigbee dongle
- Any other sensors

## Troubleshooting

### Touchscreen Issues
If touchscreen calibration problems persist:

1. **Run the comprehensive fix**:
   ```bash
   bash scripts/ensure-correct-calibration.sh
   ```

2. **Check calibration files**:
   ```bash
   sudo grep -r "CalibrationMatrix" /etc/X11/xorg.conf.d/
   ```

3. **Restart display server**:
   ```bash
   sudo systemctl restart lightdm
   ```

### Kiosk Issues
If the kiosk isn't displaying Home Assistant:

1. **Check Home Assistant status**:
   ```bash
   sudo docker ps | grep homeassistant
   ```

2. **Check kiosk service**:
   ```bash
   sudo systemctl status kiosk
   ```

3. **Restart kiosk**:
   ```bash
   sudo systemctl restart kiosk
   ```

### Manual Kiosk Start
If the service fails, try manual start:
```bash
bash scripts/start-kiosk.sh
```

## System Services

### Automatic Startup
The following services are configured to start automatically:
- `kiosk` - Touchscreen display
- `homeassistant` - Home Assistant container
- `auto-calibrate` - Touchscreen calibration service

### Manual Control
```bash
# Restart kiosk
sudo systemctl restart kiosk

# Restart Home Assistant
cd /opt/homeassistant && docker-compose restart

# Check logs
sudo journalctl -u kiosk -f
docker logs homeassistant
```

## Backup and Recovery

### Automatic Backups
- Daily backups are configured via cron
- Location: `/opt/backups/`
- Keeps 7 days of backups

### Manual Backup
```bash
/opt/homeassistant/backup.sh
```

## Maintenance

### Updates
```bash
# Pull latest changes
git pull origin master

# Re-run deployment for updates
bash scripts/deploy.sh
```

### Monitoring
```bash
# Check system status
/opt/homeassistant/monitor.sh

# View system logs
sudo journalctl -u kiosk -f
docker logs homeassistant
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review system logs
3. Ensure all hardware is properly connected
4. Verify network connectivity

---

**Note**: The deployment process now includes comprehensive touchscreen calibration that prevents the common vertical scaling issues. This ensures consistent touch accuracy across the entire screen surface. 