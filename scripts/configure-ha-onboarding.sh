#!/bin/bash
# Turtle Enclosure System - Home Assistant Onboarding Configuration
# This script configures Home Assistant to skip onboarding and go directly to dashboard

set -e

# Color functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Configuring Home Assistant to skip onboarding..."

# Check if Home Assistant container is running
if ! docker compose -f /opt/homeassistant/docker-compose.yml ps | grep -q homeassistant; then
    print_error "Home Assistant container is not running. Please start it first."
    exit 1
fi

# Create onboarding configuration
ONBOARDING_CONFIG='onboarding:
  skip: true'

# Define the path to configuration.yaml on the host
HA_CONFIG_PATH="/home/shrimp/homeassistant/config/configuration.yaml"

# Check if configuration.yaml exists on the host
if [ -f "$HA_CONFIG_PATH" ]; then
    print_status "Backing up existing configuration.yaml..."
    echo "shrimp" | sudo -S cp "$HA_CONFIG_PATH" "$HA_CONFIG_PATH.backup"
    
    # Check if onboarding is already configured
    if grep -q "onboarding:" "$HA_CONFIG_PATH"; then
        print_status "Onboarding configuration already exists, updating..."
        # Remove existing onboarding section and any lines indented below it
        echo "shrimp" | sudo -S sed -i '/^onboarding:/,/^[^ ].*/d' "$HA_CONFIG_PATH"
    fi
    
    # Ensure a newline at the end of the file before appending, if it's not empty
    if [ -s "$HA_CONFIG_PATH" ]; then
        if [ -z "$(tail -c 1 "$HA_CONFIG_PATH")" ]; then
            # File already ends with a newline, do nothing
            :
        else
            # File does not end with a newline, add one
            echo "shrimp" | sudo -S sh -c 'echo "" >> "$HA_CONFIG_PATH"'
        fi
    fi
    
    # Add onboarding configuration
    print_status "Adding onboarding skip configuration..."
    echo "shrimp" | sudo -S sh -c "echo '$ONBOARDING_CONFIG' >> "$HA_CONFIG_PATH""
else
    print_status "Creating new configuration.yaml..."
    echo "shrimp" | sudo -S sh -c "echo '$ONBOARDING_CONFIG' > "$HA_CONFIG_PATH""
fi

# Create .storage/onboarding file to mark onboarding as complete
print_status "Creating onboarding completion marker..."
echo "shrimp" | sudo -S mkdir -p /home/shrimp/homeassistant/config/.storage
echo "shrimp" | sudo -S sh -c 'cat > /home/shrimp/homeassistant/config/.storage/onboarding << EOF
{
  "data": {
    "done": [
      "user",
      "core_config",
      "integration",
      "person",
      "area_registry",
      "device_registry"
    ],
    "skipped": [
      "user",
      "core_config", 
      "integration",
      "person",
      "area_registry",
      "device_registry"
    ]
  },
  "key": "onboarding",
  "version": 1
}
EOF'

# Create .storage/auth file to skip authentication if needed
print_status "Creating authentication configuration..."
echo "shrimp" | sudo -S sh -c 'cat > /home/shrimp/homeassistant/config/.storage/auth << EOF
{
  "data": {
    "users": [
      {
        "id": "admin",
        "is_active": true,
        "is_owner": true,
        "name": "Admin",
        "system_generated": false
      }
    ]
  },
  "key": "auth",
  "version": 1
}
EOF'

# Create .storage/auth_providers file
echo "shrimp" | sudo -S sh -c 'cat > /home/shrimp/homeassistant/config/.storage/auth_providers << EOF
{
  "data": {
    "auth_providers": [
      {
        "id": null,
        "name": "Home Assistant Local",
        "type": "homeassistant"
      }
    ]
  },
  "key": "auth_providers",
  "version": 1
}
EOF'

print_status "Restarting Home Assistant to apply changes..."
docker restart homeassistant

print_success "Home Assistant configured to skip onboarding!"
print_status "The system will now go directly to the dashboard without showing the Welcome screen."
print_status "Waiting for Home Assistant to restart..."

# Wait for Home Assistant to be ready
sleep 30

print_success "Configuration complete! Home Assistant should now skip the onboarding process." 