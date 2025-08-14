#!/bin/bash

# Ensure Correct Touchscreen Calibration
# Comprehensive script to fix touchscreen calibration issues and prevent conflicts

set -e

echo "🐢 Ensuring Correct Touchscreen Calibration"
echo "==========================================="

# Colors for output
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# The correct calibration matrix that fixes vertical scaling issues
CORRECT_MATRIX='Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"'
WRONG_MATRIX='Option "CalibrationMatrix" "1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0"'
EMPTY_MATRIX='Option "CalibrationMatrix" ""'

print_status "Starting comprehensive touchscreen calibration fix..."

# Backup all existing calibration files
print_status "Creating backups of existing calibration files..."
BACKUP_DIR="/etc/X11/xorg.conf.d/backup.$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p "$BACKUP_DIR"

for file in /etc/X11/xorg.conf.d/*.conf; do
    if [ -f "$file" ] && grep -q "CalibrationMatrix" "$file"; then
        sudo cp "$file" "$BACKUP_DIR/"
        print_status "Backed up: $(basename "$file")"
    fi
done

# Fix main touchscreen configuration
print_status "Fixing main touchscreen configuration..."
if [ -f /etc/X11/xorg.conf.d/10-touchscreen.conf ]; then
    # Replace empty or wrong calibration matrix with correct one
    sudo sed -i "s|$EMPTY_MATRIX|$CORRECT_MATRIX|g" /etc/X11/xorg.conf.d/10-touchscreen.conf
    sudo sed -i "s|$WRONG_MATRIX|$CORRECT_MATRIX|g" /etc/X11/xorg.conf.d/10-touchscreen.conf
    
    if grep -q "$CORRECT_MATRIX" /etc/X11/xorg.conf.d/10-touchscreen.conf; then
        print_success "✅ Main touchscreen configuration fixed"
    else
        print_warning "⚠️  Main touchscreen configuration may need manual review"
    fi
else
    print_warning "⚠️  Main touchscreen configuration file not found"
fi

# Fix 99-calibration.conf specifically (common conflict source)
print_status "Checking for 99-calibration.conf conflicts..."
if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
    # Replace wrong calibration matrix with correct one
    sudo sed -i "s|$WRONG_MATRIX|$CORRECT_MATRIX|g" /etc/X11/xorg.conf.d/99-calibration.conf
    
    if grep -q "$CORRECT_MATRIX" /etc/X11/xorg.conf.d/99-calibration.conf; then
        print_success "✅ 99-calibration.conf fixed"
    else
        print_warning "⚠️  99-calibration.conf may need manual review"
    fi
else
    print_status "No 99-calibration.conf found"
fi

# Check and fix all other calibration files
print_status "Checking all calibration files for consistency..."
CALIBRATION_FILES=$(find /etc/X11/xorg.conf.d/ -name "*.conf" -exec grep -l "CalibrationMatrix" {} \; 2>/dev/null || true)

if [ -n "$CALIBRATION_FILES" ]; then
    for file in $CALIBRATION_FILES; do
        if grep -q "$CORRECT_MATRIX" "$file"; then
            print_success "✅ $(basename "$file") has correct calibration matrix"
        else
            print_warning "⚠️  $(basename "$file") has incorrect calibration matrix - fixing..."
            # Replace any calibration matrix with the correct one
            sudo sed -i "s|Option \"CalibrationMatrix\" \"[^\"]*\"|$CORRECT_MATRIX|g" "$file"
            print_success "Fixed calibration matrix in $(basename "$file")"
        fi
    done
else
    print_warning "⚠️  No calibration files found"
fi

# Save working configuration for future use
print_status "Saving working configuration..."
sudo mkdir -p /opt/turtle-enclosure
sudo cp /etc/X11/xorg.conf.d/10-touchscreen.conf /opt/turtle-enclosure/saved_calibration.conf
sudo chmod 644 /opt/turtle-enclosure/saved_calibration.conf

# Final verification
print_status "Performing final verification..."
ALL_CORRECT=true

for file in $CALIBRATION_FILES; do
    if ! grep -q "$CORRECT_MATRIX" "$file"; then
        print_error "❌ $(basename "$file") still has incorrect calibration matrix"
        ALL_CORRECT=false
    fi
done

if [ "$ALL_CORRECT" = true ]; then
    print_success "🎯 All calibration files verified and corrected!"
    print_status "Calibration matrix: 1.0 0.0 0.0 0.0 0.8 0.0 0.0 0.0 1.0"
    print_status "This fixes vertical scaling issues that get worse as you move down the screen"
else
    print_warning "⚠️  Some calibration files may still need manual attention"
fi

echo ""
echo "📁 Backups saved in: $BACKUP_DIR"
echo "💾 Working configuration saved in: /opt/turtle-enclosure/saved_calibration.conf"
echo "🔄 Please restart the display server or reboot to apply changes"
echo ""
print_success "Touchscreen calibration fix completed! 🐢" 