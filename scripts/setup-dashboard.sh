#!/bin/bash

# Setup Home Assistant Dashboard with Turtle Theme
# This script configures the dashboard and applies the turtle theme

set -e

echo "🐢 Setting up Turtle Enclosure Dashboard..."

# Function to wait for Home Assistant to be ready
wait_for_ha() {
    echo "Waiting for Home Assistant to be ready..."
    while ! curl -s http://localhost:8123/api/ > /dev/null 2>&1; do
        sleep 5
    done
    echo "Home Assistant is ready!"
}

# Function to create the dashboard configuration
setup_dashboard() {
    echo "Setting up dashboard configuration..."
    
    # Create the dashboard configuration directory if it doesn't exist
    mkdir -p /config/.storage
    
    # Create the lovelace configuration
    cat > /config/.storage/lovelace << 'EOF'
{
    "data": {
        "dashboards": {
            "dashboard": {
                "icon": "mdi:view-dashboard",
                "id": "dashboard",
                "mode": "storage",
                "require_admin": false,
                "show_in_sidebar": true,
                "title": "Turtle Enclosure",
                "url_path": "dashboard"
            }
        },
        "mode": "storage"
    },
    "key": "lovelace",
    "version": 1
}
EOF

    # Create the dashboard view configuration
    cat > /config/.storage/lovelace_dashboards.yaml << 'EOF'
dashboard:
  mode: storage
  title: Turtle Enclosure
  icon: mdi:view-dashboard
  show_in_sidebar: true
  require_admin: false
  views:
    - title: Dashboard
      path: dashboard
      type: custom:grid-layout
      layout:
        grid-template-columns: repeat(4, 1fr)
        grid-template-rows: repeat(3, 1fr)
        grid-gap: 20px
        padding: 20px
      badges: []
      theme: turtle-theme
      cards:
        # Temperature Card (Mushroom) - Top Left
        - type: custom:mushroom-template-card
          primary: Temperature
          secondary: "{{ states('sensor.temperature_fallback') }}°F"
          icon: mdi:thermometer
          icon_color: |
            {% set temp = states('sensor.temperature_fallback') | float %}
            {% if temp < 70 %}
              #4682b4
            {% elif temp > 85 %}
              #dc143c
            {% elif temp > 80 %}
              #ff8c00
            {% else %}
              #228b22
            {% endif %}
          layout: vertical
          fill_container: true
          grid_position:
            x: 0
            y: 0
            w: 1
            h: 1
          card_mod:
            class: temperature-card

        # Humidity Card (Mushroom) - Top Right
        - type: custom:mushroom-template-card
          primary: Humidity
          secondary: "{{ states('sensor.humidity_fallback') }}%"
          icon: mdi:water-percent
          icon_color: |
            {% set humidity = states('sensor.humidity_fallback') | float %}
            {% if humidity < 60 %}
              #ff8c00
            {% elif humidity > 80 %}
              #4682b4
            {% else %}
              #228b22
            {% endif %}
          layout: vertical
          fill_container: true
          grid_position:
            x: 1
            y: 0
            w: 1
            h: 1
          card_mod:
            class: humidity-card

        # Camera Card - Large Center
        - type: picture-entity
          entity: camera.turtle_camera
          name: Turtle Camera
          camera_view: live
          aspect_ratio: 16:9
          grid_position:
            x: 2
            y: 0
            w: 2
            h: 2
          card_mod:
            class: camera-card

        # Day Mode Toggle (Mushroom Chips) - Bottom Left
        - type: custom:mushroom-chips-card
          alignment: start
          chips:
            - type: template
              icon: mdi:weather-sunny
              icon_color: |
                {% if is_state('input_boolean.day_mode', 'on') %}
                  #ffd700
                {% else %}
                  #8b7355
                {% endif %}
              tap_action:
                action: toggle
                entity: input_boolean.day_mode
              hold_action:
                action: call-service
                service: script.day_mode_toggle
          grid_position:
            x: 0
            y: 1
            w: 2
            h: 1
          card_mod:
            class: control-card

        # Auto Cooling Toggle (Mushroom Chips) - Bottom Right
        - type: custom:mushroom-chips-card
          alignment: start
          chips:
            - type: template
              icon: mdi:snowflake
              icon_color: |
                {% if is_state('input_boolean.auto_cooling', 'on') %}
                  #4682b4
                {% else %}
                  #8b7355
                {% endif %}
              tap_action:
                action: toggle
                entity: input_boolean.auto_cooling
              hold_action:
                action: call-service
                service: script.emergency_cooling
          grid_position:
            x: 2
            y: 1
            w: 2
            h: 1
          card_mod:
            class: control-card

        # System Status (Mushroom) - Bottom Center
        - type: custom:mushroom-template-card
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
              #ff8c00
            {% elif is_state('input_boolean.health_check_running', 'on') %}
              #4682b4
            {% else %}
              #228b22
            {% endif %}
          layout: vertical
          fill_container: true
          grid_position:
            x: 0
            y: 2
            w: 2
            h: 1
          card_mod:
            class: status-card

        # Quick Actions (Mushroom Chips) - Bottom Right
        - type: custom:mushroom-chips-card
          alignment: start
          chips:
            - type: template
              icon: mdi:refresh
              icon_color: "#228b22"
              tap_action:
                action: call-service
                service: script.health_check
            - type: template
              icon: mdi:backup-restore
              icon_color: "#8b4513"
              tap_action:
                action: call-service
                service: script.backup_system
            - type: template
              icon: mdi:settings
              icon_color: "#708090"
              tap_action:
                action: navigate
                navigation_path: /config
          grid_position:
            x: 2
            y: 2
            w: 2
            h: 1
          card_mod:
            class: control-card
EOF

    echo "Dashboard configuration created!"
}

# Function to apply the turtle theme
apply_theme() {
    echo "Applying turtle theme..."
    
    # Copy the theme file to the themes directory
    cp /config/themes/turtle-theme.yaml /config/themes/ 2>/dev/null || true
    
    # Create a theme configuration file
    cat > /config/.storage/frontend.themes << 'EOF'
{
    "data": {
        "themes": {
            "turtle-theme": {
                "primary-color": "#2d5016",
                "primary-background-color": "#f4f1e8",
                "secondary-background-color": "#e8dcc0",
                "text-primary-color": "#2d5016",
                "text-secondary-color": "#5a4a3f",
                "accent-color": "#8b4513",
                "divider-color": "#d2b48c",
                "state-icon-active-color": "#2d5016",
                "state-icon-inactive-color": "#8b7355",
                "state-icon-unavailable-color": "#a0522d",
                "card-background-color": "#faf8f3",
                "card-rgb-color": "250, 248, 243",
                "card-background-opacity": 0.95,
                "app-header-background-color": "#2d5016",
                "app-header-text-color": "#f4f1e8",
                "sidebar-icon-color": "#f4f1e8",
                "sidebar-text-color": "#f4f1e8",
                "sidebar-selected-icon-color": "#8b4513",
                "sidebar-selected-text-color": "#8b4513",
                "button-primary-color": "#2d5016",
                "button-primary-text-color": "#f4f1e8",
                "button-secondary-color": "#8b4513",
                "button-secondary-text-color": "#f4f1e8",
                "input-fill-color": "#faf8f3",
                "input-disabled-color": "#e8dcc0",
                "input-border-color": "#d2b48c",
                "switch-checked-color": "#2d5016",
                "switch-unchecked-color": "#8b7355",
                "temperature-color": "#d2691e",
                "humidity-color": "#4682b4",
                "pressure-color": "#708090",
                "error-color": "#dc143c",
                "warning-color": "#ff8c00",
                "info-color": "#4682b4",
                "success-color": "#228b22",
                "ha-card-border-radius": "16px",
                "ha-card-box-shadow": "0 6px 16px rgba(45, 80, 22, 0.12)"
            }
        }
    },
    "key": "frontend.themes",
    "version": 1
}
EOF

    echo "Turtle theme applied!"
}

# Function to restart Home Assistant
restart_ha() {
    echo "Restarting Home Assistant to apply changes..."
    systemctl restart home-assistant@turtle || true
    sleep 10
}

# Main execution
main() {
    echo "🐢 Starting Turtle Enclosure Dashboard Setup..."
    
    # Wait for Home Assistant to be ready
    wait_for_ha
    
    # Setup dashboard
    setup_dashboard
    
    # Apply theme
    apply_theme
    
    # Restart Home Assistant
    restart_ha
    
    echo "✅ Dashboard setup complete!"
    echo "🌐 Access your dashboard at: http://localhost:8123/lovelace/dashboard"
    echo "🎨 Turtle theme has been applied!"
}

# Run the main function
main "$@" 