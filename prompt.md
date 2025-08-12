# Eastern Box Turtle Enclosure Automation System

I am developing a turtle monitoring system that will be deployed on a remote machine. I'm using a **local development → GitHub → remote deployment** workflow.

## Development Workflow
- **Local Development**: I'm developing all configurations, automations, and code locally using Cursor AI
- **Version Control**: Push all changes to GitHub repository for version control
- **Remote Deployment**: Pull updates from GitHub to the remote turtle monitoring system
- **Target Machine**: Beelink Mini PC with Ubuntu Server + Docker + Home Assistant already running

## Remote Machine Current Status
- **✅ Ubuntu Server 22.04 LTS** - Installed and running on Beelink Mini PC
- **✅ Docker** - Installed and configured
- **✅ Home Assistant** - Running in Docker container
- **✅ GitHub Access** - Can pull repository updates
- **Ready to deploy**: All configurations I develop locally will be pulled to this machine

## Hardware Setup (Remote Machine)
- **Host**: Beelink Mini PC (running Ubuntu Server 22.04 LTS)
- **Display**: ROADOM 10.1" Touchscreen Monitor (1024×600 IPS) - Primary kiosk interface
- **Connectivity**: 3-foot Anker HDMI cable for display connection
- **Sensors**: TEMPerHUM PC USB sensor (temperature & humidity monitoring)
- **Camera**: Arducam 1080P Day & Night Vision USB Camera
- **Zigbee Hub**: Sonoff Zigbee USB Dongle Plus (ZBDongle-E 3.0)
- **Smart Control**: ZigBee Smart Plugs 4-pack with energy monitoring (15A outlets, Zigbee repeaters)
- **USB Expansion**: Anker 4-Port USB 3.0 Hub + AINOPE USB 3.0 extension cables
- **Primary Heat Control**: Vivarium Electronics VE-200 w/night drop (existing, reliable thermostat)

## Project Goals
1. **Touchscreen Kiosk Interface**: Create a simple, intuitive touchscreen dashboard for non-technical user operation
2. **Environmental Monitoring**: Track temperature and humidity with large, easy-to-read displays
3. **Smart Cooling Control**: Touch-controlled fans, misters, or cooling devices via Zigbee smart plugs
4. **Live Camera Feed**: Integrated video stream viewable on the touchscreen interface
5. **Energy Monitoring**: Display real-time power consumption from smart plugs
6. **Push Notifications**: Mobile app and email alerts for critical conditions and equipment failures
7. **Data Integration**: Monitor and log data while working alongside existing VE-200 heat controller
8. **Simple Device Control**: Large touch buttons for manual override of automated systems
9. **Visual Alerts**: Clear on-screen notifications for any issues or out-of-range conditions
10. **Beautiful Turtle Theming**: Create a visually stunning interface with turtle and nature-inspired design elements

## Specific Requirements
- Temperature range: 70-85°F (21-29°C) with basking spot up to 90°F (32°C)
- Humidity range: 60-80% for eastern box turtles
- Day/night lighting cycles
- **Critical Alert Scenarios**: Temperature outside safe range, humidity too low/high, equipment power failures, camera/sensor disconnection
- **Notification Preferences**: Tiered alerts (Critical/Warning/Info) with user-configurable settings
- **Delivery Methods**: Home Assistant mobile app (primary), email backup, on-screen kiosk alerts
- Historical data visualization and export capabilities
- **Equipment Failure Detection**: Monitor smart plug power consumption to detect device failures

## Technical Tasks I Need Help With

### Kiosk Display Setup
1. **Install Display Components**: Install X11, lightweight desktop environment, and Chromium for kiosk mode
2. **Touchscreen Configuration**: Set up touch input drivers and calibration for the 10.1" 1024×600 display
3. **Auto-boot Kiosk**: Create systemd services for automatic login and Chromium kiosk startup
4. **Kiosk Recovery**: Implement watchdog services to restart the kiosk if it crashes

### Hardware Integration
5. **USB Device Management**: Configure udev rules and permissions for TEMPerHUM sensor and Arducam camera
6. **Zigbee Integration**: Configure Sonoff dongle access in Home Assistant Docker container
7. **Camera Streaming**: Set up Arducam USB camera integration with Home Assistant
8. **USB Sensor Integration**: Configure TEMPerHUM PC USB sensor in Home Assistant
9. **Smart Plug Pairing**: Pair and configure the 4-pack Zigbee smart plugs with energy monitoring

### Home Assistant Configuration
10. **Device Integrations**: YAML configurations for all sensors, camera, and Zigbee devices
11. **Environmental Automations**: Create automations for temperature/humidity monitoring and cooling control
12. **Equipment Monitoring**: Set up automations to detect device failures via power consumption
13. **Smart Plug Control**: Configure smart plug automations that work alongside VE-200 thermostat
14. **Day/Night Cycles**: Automate lighting schedules and day/night temperature variations

### Push Notifications & Alerts
15. **Mobile App Setup**: Configure Home Assistant mobile app notifications
16. **Email Alerts**: Set up email notifications as backup alerting method
17. **Alert Automations**: Create tiered alert system (Critical/Warning/Info) for various conditions
18. **Notification Management**: Build touch-friendly notification history in the interface

### Turtle-Themed Interface Design
19. **Custom CSS Theme**: Create turtle-inspired colors, fonts, and styling optimized for 1024×600 touchscreen
20. **Custom Icons**: Implement turtle, leaf, water drop, and nature-themed icons throughout interface
21. **Touch-Optimized Layout**: Design large buttons and controls perfect for finger navigation
22. **Dashboard Cards**: Create beautiful cards for temperature, humidity, camera feed, and device status
23. **Animations**: Add subtle nature-themed animations (water ripples, gentle movements)
24. **Seasonal Themes**: Dynamic color schemes that change with day/night cycles

## Development Environment
**Local Development Setup**: I'm developing locally and need all files organized for GitHub deployment
**Remote Target**: Ubuntu Server + Docker + Home Assistant container running on Beelink Mini PC
**Deployment Method**: Git pull from repository to remote machine

### Repository Structure Needed:
- **Home Assistant configs**: YAML files for automations, integrations, dashboard configurations
- **Kiosk setup scripts**: Systemd services, display configuration, auto-start scripts
- **Custom themes**: CSS files for turtle-themed interface
- **Hardware configs**: Udev rules, USB device configurations
- **Docker configs**: Any additional container configurations needed
- **Documentation**: Setup instructions for deploying to the remote machine

### Development Goals:
- Create all configuration files that can be version controlled
- Organize files in a clear repository structure for easy deployment
- Include deployment scripts/instructions for the remote machine
- Ensure configurations work with the specific hardware on the remote system

## System Architecture Priorities
- **Container Isolation**: Home Assistant and related services in Docker containers
- **Hardware Access**: Proper USB device mapping for sensors and camera
- **Auto-recovery**: System should restart all services after power loss
- **Kiosk Reliability**: Browser should restart if it crashes, always return to HA dashboard
- **Touch Optimization**: All UI elements sized and styled for finger navigation
- **Resource Efficiency**: Lightweight desktop environment to preserve resources for HA
- **Update Management**: Easy container updates without affecting system configuration

## Design Aesthetic Goals
- **Color Scheme**: Natural earth tones (forest green, warm browns, shell amber, water blue)
- **Visual Elements**: Turtle shell patterns, leaf shapes, water ripples, organic curves
- **Icons**: Custom turtle-themed icons for temperature (turtle with thermometer), humidity (turtle with water drops), power (turtle with leaf), camera (turtle eye), etc.
- **Animations**: Subtle nature-inspired movements (gentle leaf sway, water ripples, soft shell patterns)
- **Typography**: Friendly, readable fonts that complement the natural theme
- **Layout**: Organic, flowing layouts that avoid harsh geometric shapes
- **Status Indicators**: Shell-pattern progress bars, leaf-shaped buttons, water-drop humidity indicators

## User Experience Priority
This system is being built for a non-technical user who will primarily interact through the touchscreen. The interface must be:
- **Intuitive**: Large buttons, clear labels, obvious functionality
- **Reliable**: Auto-recovery from errors, graceful failure handling
- **Visual**: Prominent displays of critical information (temperature, humidity, camera)
- **Simple**: Minimal complexity, essential functions only
- **Responsive**: Fast touch response, immediate visual feedback
- **Connected**: Easy mobile app setup with clear notification management
- **Informative**: Notification history accessible via touchscreen with simple alert acknowledgment
- **Delightful**: Beautiful turtle-themed design that creates emotional connection and joy
- **Natural**: Interface that feels organic and connects the user to their pet's natural habitat needs

I need help developing all the configuration files and scripts locally that I can then push to GitHub and deploy on the remote machine. Please provide:

1. **Repository Structure** - How to organize all files for easy deployment
2. **Configuration Files** - All YAML, CSS, and config files needed
3. **Deployment Scripts** - Scripts the remote machine can run after pulling from GitHub
4. **Clear Instructions** - Step-by-step deployment guide for the remote machine

**Development Priority:**
1. **Kiosk Mode Configs** - Systemd services, display setup scripts for the remote machine
2. **Hardware Integration Files** - Udev rules, device configurations for USB sensors/camera/Zigbee
3. **Home Assistant Configs** - Complete YAML configurations for automations and integrations
4. **Turtle-Themed Interface** - CSS theme files and custom dashboard configurations
5. **Deployment Automation** - Scripts to apply all configurations on the remote machine

**Important**: All files should be designed to work when deployed to the remote Ubuntu Server machine via git pull. Focus on creating a complete, deployable repository structure.

What repository structure and configuration files should I create first to get the remote machine's kiosk display working?