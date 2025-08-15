#!/bin/bash

# Turtle Enclosure System - Recovery Fix Deployment Script
# This script deploys the recovery fix to the remote machine

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

REMOTE_HOST="shrimp@10.0.20.69"
REMOTE_DIR="/home/shrimp/turt3"

print_status "Deploying Recovery Fix to $REMOTE_HOST..."

# Step 1: Copy the recovery fix script
print_status "Step 1: Copying recovery fix script..."
scp -o StrictHostKeyChecking=no scripts/fix-recovery-mode.sh $REMOTE_HOST:$REMOTE_DIR/

# Step 2: Copy the fixed plugin and theme scripts
print_status "Step 2: Copying fixed scripts..."
scp -o StrictHostKeyChecking=no scripts/install-plugins-fixed.sh $REMOTE_HOST:$REMOTE_DIR/scripts/
scp -o StrictHostKeyChecking=no scripts/apply-turtle-theme-fixed.sh $REMOTE_HOST:$REMOTE_DIR/scripts/

# Step 3: Make scripts executable
print_status "Step 3: Making scripts executable..."
ssh -o StrictHostKeyChecking=no $REMOTE_HOST "chmod +x $REMOTE_DIR/fix-recovery-mode.sh"
ssh -o StrictHostKeyChecking=no $REMOTE_HOST "chmod +x $REMOTE_DIR/scripts/install-plugins-fixed.sh"
ssh -o StrictHostKeyChecking=no $REMOTE_HOST "chmod +x $REMOTE_DIR/scripts/apply-turtle-theme-fixed.sh"

# Step 4: Run the recovery fix script
print_status "Step 4: Running recovery fix script..."
print_warning "This will stop all containers and restart Home Assistant with proper configuration."
print_warning "The process will take several minutes."
echo ""

read -p "Do you want to proceed with the recovery fix? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting recovery fix..."
    ssh -o StrictHostKeyChecking=no $REMOTE_HOST "cd $REMOTE_DIR && ./fix-recovery-mode.sh"
    
    print_success "Recovery fix deployment completed!"
    echo ""
    print_status "The system should now be out of recovery mode."
    print_status "You can access Home Assistant at: http://10.0.20.69:8123"
else
    print_warning "Recovery fix cancelled."
    print_status "You can run the fix manually by connecting to the remote machine and running:"
    print_status "cd $REMOTE_DIR && ./fix-recovery-mode.sh"
fi 