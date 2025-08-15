# Mushroom Cards and Kiosk Mode Plugin Usage Guide

This guide explains how to use the Mushroom Cards and Kiosk Mode plugins in your Turtle Enclosure Home Assistant system.

## 🍄 Mushroom Cards Overview

Mushroom Cards provide a modern, clean interface for Home Assistant dashboards. They're perfect for touchscreen interfaces and provide excellent visual feedback.

### Available Mushroom Cards

1. **mushroom-template-card** - Customizable cards with templates
2. **mushroom-chips-card** - Compact toggle buttons
3. **mushroom-light-card** - Light controls with color picker
4. **mushroom-climate-card** - HVAC controls
5. **mushroom-cover-card** - Cover controls (blinds, garage doors)
6. **mushroom-media-player-card** - Media player controls
7. **mushroom-person-card** - Person presence
8. **mushroom-update-card** - System updates
9. **mushroom-vacuum-card** - Vacuum robot controls
10. **mushroom-weather-card** - Weather information

## 🎯 Kiosk Mode Features

The Kiosk Mode plugin provides:
- Full-screen mode for touchscreen displays
- Auto-refresh capabilities
- Screen saver functionality
- Touch-friendly interface optimizations

## 📱 Using Mushroom Cards in Your Dashboard

### Adding Mushroom Cards

1. **Access Dashboard Editor**:
   - Go to **Configuration** → **Lovelace Dashboards**
   - Click **Edit Dashboard**
   - Click **+ Add Card**

2. **Select Mushroom Card Type**:
   - In the card picker, look for cards starting with "Mushroom"
   - Choose the appropriate card type for your entity

### Common Mushroom Card Configurations

#### Temperature/Humidity Cards
```yaml
type: custom:mushroom-template-card
primary: Temperature
secondary: "{{ states('sensor.temperature_fallback') }}°F"
icon: mdi:thermometer
icon_color: |
  {% set temp = states('sensor.temperature_fallback') | float %}
  {% if temp < 70 %}
    red
  {% elif temp > 85 %}
    orange
  {% else %}
    green
  {% endif %}
layout: vertical
fill_container: true
```

#### Toggle Buttons (Chips)
```yaml
type: custom:mushroom-chips-card
alignment: start
chips:
  - type: template
    icon: mdi:weather-sunny
    icon_color: |
      {% if is_state('input_boolean.day_mode', 'on') %}
        yellow
      {% else %}
        grey
      {% endif %}
    tap_action:
      action: toggle
      entity: input_boolean.day_mode
```

#### System Status Card
```yaml
type: custom:mushroom-template-card
primary: System Status
secondary: |
  {% if is_state('input_boolean.maintenance_mode', 'on') %}
    Maintenance Mode
  {% elif is_state('input_boolean.health_check_running', 'on') %}
    Health Check Running
  {% else %}
    Normal Operation
  {% endif %}
icon: mdi:heart-pulse
icon_color: |
  {% if is_state('input_boolean.maintenance_mode', 'on') %}
    orange
  {% elif is_state('input_boolean.health_check_running', 'on') %}
    blue
  {% else %}
    green
  {% endif %}
layout: vertical
fill_container: true
```

## 🖥️ Kiosk Mode Configuration

### Enabling Kiosk Mode

1. **Access Kiosk Settings**:
   - In Home Assistant, go to **Configuration** → **Settings**
   - Look for **Kiosk Mode** in the sidebar

2. **Configure Kiosk Settings**:
   - **Full Screen**: Enable for touchscreen displays
   - **Auto Refresh**: Set refresh interval (recommended: 30 seconds)
   - **Screen Saver**: Configure if needed
   - **Touch Optimizations**: Enable for better touch response

### Kiosk Mode Features

- **Full Screen**: Removes browser UI elements
- **Auto Refresh**: Keeps data current
- **Touch Friendly**: Optimized for touchscreen interaction
- **Screen Saver**: Prevents screen burn-in

## 🎨 Customizing Your Dashboard

### Color Schemes

Mushroom Cards support dynamic colors based on entity states:

```yaml
icon_color: |
  {% if is_state('sensor.temperature_fallback', 'on') %}
    green
  {% else %}
    red
  {% endif %}
```

### Layout Options

- **vertical**: Stack primary and secondary text vertically
- **horizontal**: Arrange text side by side
- **fill_container**: Make card fill available space

### Grid Layout

Use the grid layout for organized dashboards:

```yaml
type: custom:grid-layout
layout:
  grid-template-columns: repeat(4, 1fr)
  grid-template-rows: repeat(3, 1fr)
  grid-gap: 16px
```

## 🔧 Troubleshooting

### Mushroom Cards Not Appearing

1. **Check Installation**:
   ```bash
   ls -la /opt/homeassistant/config/custom_components/mushroom/
   ```

2. **Verify Configuration**:
   ```bash
   grep -r "mushroom" /opt/homeassistant/config/configuration.yaml
   ```

3. **Restart Home Assistant**:
   ```bash
   cd /opt/homeassistant && docker-compose restart
   ```

### Kiosk Mode Not Working

1. **Check Plugin Installation**:
   ```bash
   ls -la /opt/homeassistant/config/www/kiosk-mode/
   ```

2. **Verify Frontend Configuration**:
   ```bash
   grep -r "kiosk-mode" /opt/homeassistant/config/configuration.yaml
   ```

3. **Clear Browser Cache**: Refresh the page with Ctrl+F5

### Common Issues

#### Cards Not Loading
- Ensure Home Assistant is fully started
- Check browser console for JavaScript errors
- Verify entity names are correct

#### Touchscreen Not Responsive
- Enable touch optimizations in Kiosk Mode
- Check touchscreen calibration
- Ensure proper permissions

## 📋 Best Practices

### Dashboard Design
1. **Use Consistent Colors**: Green for good, orange for warning, red for critical
2. **Group Related Cards**: Temperature and humidity together
3. **Use Appropriate Icons**: Make cards easily identifiable
4. **Keep It Simple**: Don't overcrowd the dashboard

### Touchscreen Optimization
1. **Large Touch Targets**: Make buttons at least 44px
2. **Clear Visual Feedback**: Use color changes for state
3. **Minimize Scrolling**: Fit everything on one screen
4. **Test Touch Response**: Ensure all elements are tappable

### Performance
1. **Limit Auto-refresh**: Don't refresh too frequently
2. **Use Efficient Templates**: Avoid complex calculations
3. **Monitor Resource Usage**: Check Home Assistant logs

## 🔄 Updating Plugins

### Update Mushroom Cards
```bash
cd /opt/homeassistant/config/custom_components/mushroom
git pull origin main
cd /opt/homeassistant
docker-compose restart
```

### Update Kiosk Mode
```bash
cd /opt/homeassistant/config/www/kiosk-mode
wget -O kiosk-mode.js https://github.com/NemesisRE/kiosk-mode/releases/latest/download/kiosk-mode.js
cd /opt/homeassistant
docker-compose restart
```

## 📚 Additional Resources

- **Mushroom Cards Documentation**: https://github.com/piitaya/lovelace-mushroom
- **Kiosk Mode Documentation**: https://github.com/NemesisRE/kiosk-mode
- **Home Assistant Community**: https://community.home-assistant.io
- **Lovelace UI Documentation**: https://www.home-assistant.io/lovelace/

## 🆘 Getting Help

If you encounter issues:

1. **Check Logs**: `docker logs homeassistant`
2. **Verify Configuration**: Use Home Assistant's configuration validation
3. **Community Support**: Post on Home Assistant community forums
4. **Plugin Issues**: Check the respective GitHub repositories

---

**🐢 Your turtle enclosure system is now equipped with modern, touch-friendly controls!** 