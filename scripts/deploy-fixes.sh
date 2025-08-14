#!/bin/bash

# Deploy Fixes to Kiosk System
# This script copies the fixed calibration script and diagnostic tools to the kiosk system

set -e

echo "🚀 Deploying Fixes to Kiosk System"
echo "=================================="

# Configuration
KIOSK_HOST="shrimpcenter"
KIOSK_USER="shrimp"
REMOTE_DIR="/home/shrimp/turt3"

echo "📋 Configuration:"
echo "  Host: $KIOSK_HOST"
echo "  User: $KIOSK_USER"
echo "  Remote Directory: $REMOTE_DIR"
echo ""

# Check if we can connect to the kiosk
echo "🔍 Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 "$KIOSK_USER@$KIOSK_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
    echo "❌ Cannot connect to $KIOSK_HOST"
    echo "💡 Please ensure:"
    echo "  1. The kiosk system is running"
    echo "  2. SSH is enabled on the kiosk"
    echo "  3. You have SSH access configured"
    exit 1
fi

echo "✅ SSH connection successful"
echo ""

# Create remote directory if it doesn't exist
echo "📁 Setting up remote directory..."
ssh "$KIOSK_USER@$KIOSK_HOST" "mkdir -p $REMOTE_DIR"

# Copy the fixed calibration script
echo "📋 Copying fixed calibration script..."
scp kiosk/apply-known-calibration-fixed.sh "$KIOSK_USER@$KIOSK_HOST:$REMOTE_DIR/"

# Copy the diagnostic script
echo "📋 Copying diagnostic script..."
scp scripts/ssh-diagnostic.sh "$KIOSK_USER@$KIOSK_HOST:$REMOTE_DIR/"

# Make scripts executable on remote system
echo "🔧 Making scripts executable..."
ssh "$KIOSK_USER@$KIOSK_HOST" "chmod +x $REMOTE_DIR/apply-known-calibration-fixed.sh $REMOTE_DIR/ssh-diagnostic.sh"

# Install the fixed calibration script
echo "🔧 Installing fixed calibration script..."
ssh "$KIOSK_USER@$KIOSK_HOST" "sudo cp $REMOTE_DIR/apply-known-calibration-fixed.sh /usr/local/bin/turtle-apply-known && sudo chmod +x /usr/local/bin/turtle-apply-known"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔍 Next steps:"
echo "1. SSH into the kiosk system:"
echo "   ssh $KIOSK_USER@$KIOSK_HOST"
echo ""
echo "2. Run the diagnostic script:"
echo "   cd $REMOTE_DIR && ./ssh-diagnostic.sh"
echo ""
echo "3. Try the fixed calibration script:"
echo "   turtle-apply-known"
echo ""
echo "4. If issues persist, check the diagnostic output for specific problems" 