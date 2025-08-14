# Eastern Box Turtle Enclosure Automation System

A comprehensive monitoring and automation system for Eastern Box Turtle habitats, featuring a touchscreen kiosk interface, environmental monitoring, and smart device control.

## 🐢 System Overview

This system provides:
- **Touchscreen Kiosk Interface** - Beautiful, intuitive dashboard for non-technical users
- **Environmental Monitoring** - Real-time temperature and humidity tracking
- **Smart Device Control** - Zigbee-powered cooling and lighting automation
- **Live Camera Feed** - Integrated video monitoring
- **Push Notifications** - Mobile app and email alerts for critical conditions
- **Energy Monitoring** - Real-time power consumption tracking
- **Turtle-Themed Design** - Nature-inspired interface with organic aesthetics

## 🏗️ Repository Structure

```
turtle-enclosure-system/
├── kiosk/                    # Display and touchscreen configuration
├── hardware/                 # USB device and sensor configurations
├── home-assistant/           # Home Assistant configurations
├── themes/                   # Custom CSS themes and styling
├── scripts/                  # Deployment and utility scripts
├── docker/                   # Docker configurations
└── docs/                     # Documentation and setup guides
```

## 🚀 Quick Deployment

### Prerequisites
- Ubuntu Server 22.04 LTS
- Docker installed and running
- Hardware connected (see hardware setup guide)

### ⚠️ Important: Configuration Required

**Before deployment, you must configure several values in the system files:**

1. **Email credentials** for notifications
2. **System passwords** for security
3. **Camera credentials** (if required)
4. **Home Assistant token** (after initial setup)

**📋 Use our configuration checklist**: [`docs/configuration-checklist.md`](docs/configuration-checklist.md)

**📖 Full deployment guide**: [`docs/deployment-guide.md`](docs/deployment-guide.md)

### Deployment Steps

1. **Clone Repository**
   ```bash
   git clone https://github.com/yourusername/turtle-enclosure-system.git
   cd turtle-enclosure-system
   ```

2. **Configure Required Values**
   ```bash
   # Edit secrets file
   nano home-assistant/secrets.yaml
   
   # Edit deployment script
   nano scripts/deploy.sh
   
   # Edit Docker passwords
   nano docker/docker-compose.yml
   ```

3. **Run Deployment Script**
   ```bash
   chmod +x scripts/deploy.sh
   sudo ./scripts/deploy.sh
   ```

4. **Configure Hardware**
   ```bash
   sudo ./scripts/setup-hardware.sh
   ```

5. **Generate Home Assistant Token**
   - Access Home Assistant at `http://your-server-ip:8123`
   - Complete initial setup
   - Generate long-lived access token
   - Update secrets file and restart

6. **Restart Services**
   ```bash
   sudo systemctl restart kiosk
   cd /opt/homeassistant && docker-compose restart
   ```

## 📋 Hardware Requirements

- **Display**: ROADOM 10.1" Touchscreen Monitor (1024×600 IPS)
- **Sensors**: TEMPerHUM PC USB sensor
- **Camera**: Arducam 1080P Day & Night Vision USB Camera
- **Zigbee Hub**: Sonoff Zigbee USB Dongle Plus (ZBDongle-E 3.0)
- **Smart Plugs**: ZigBee Smart Plugs 4-pack with energy monitoring
- **USB Hub**: Anker 4-Port USB 3.0 Hub

## 🎯 Target Specifications

- **Temperature Range**: 70-85°F (21-29°C) with basking spot up to 90°F (32°C)
- **Humidity Range**: 60-80%
- **Display Resolution**: 1024×600 (optimized for touch)
- **Alert Levels**: Critical/Warning/Info with tiered notifications

## 🔧 Development Workflow

1. **Local Development** - All configurations developed locally using Cursor AI
2. **Version Control** - Push changes to GitHub repository
3. **Remote Deployment** - Pull updates to Beelink Mini PC
4. **Auto-Configuration** - Scripts apply all settings automatically

## 📱 Features

- **Touch-Optimized Interface** - Large buttons, clear navigation
- **Real-Time Monitoring** - Live sensor data and camera feed
- **Smart Automation** - Environmental control with manual override
- **Mobile Notifications** - Home Assistant mobile app integration
- **Energy Tracking** - Power consumption monitoring
- **Beautiful Design** - Turtle-themed, nature-inspired aesthetics

## 🛠️ Maintenance

- **Auto-Recovery** - Services restart automatically after power loss
- **Easy Updates** - Pull from GitHub and run deployment script
- **Log Monitoring** - Comprehensive logging for troubleshooting
- **Backup System** - Configuration backups before updates

## 📞 Support

For issues or questions:
1. Check the troubleshooting guide in `docs/troubleshooting.md`
2. Review system logs: `sudo journalctl -u kiosk -f`
3. Verify hardware connections and permissions

---

**Built with ❤️ for happy, healthy turtles** 