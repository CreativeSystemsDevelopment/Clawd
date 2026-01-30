#!/bin/bash

# ClawdBot Setup Script for Google VM
# This script automates the installation and configuration of ClawdBot on Google Cloud VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[i]${NC} $1"
}

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then 
    print_error "This script requires sudo privileges. Please run with sudo or as root."
    exit 1
fi

print_info "Starting ClawdBot installation for Google VM..."
echo ""

# Update system packages
print_status "Updating system packages..."
sudo apt-get update -qq

# Install required dependencies
print_status "Installing system dependencies..."
sudo apt-get install -y curl wget git build-essential

# Check if Node.js 22+ is installed
print_status "Checking Node.js installation..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_VERSION" -ge 22 ]; then
        print_status "Node.js $(node --version) is already installed"
    else
        print_warning "Node.js version is too old. Installing Node.js 22..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    print_status "Installing Node.js 22..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Verify Node.js installation
NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION"

# Install ClawdBot
print_status "Installing ClawdBot..."
if command -v clawdbot &> /dev/null; then
    print_warning "ClawdBot is already installed. Updating..."
    sudo npm update -g clawdbot
else
    sudo npm install -g clawdbot@latest
fi

# Verify ClawdBot installation
if command -v clawdbot &> /dev/null; then
    CLAWDBOT_VERSION=$(clawdbot --version 2>/dev/null || echo "unknown")
    print_status "ClawdBot installed successfully (version: $CLAWDBOT_VERSION)"
else
    print_error "ClawdBot installation failed!"
    exit 1
fi

# Configure firewall (UFW)
print_status "Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 18789/tcp comment "ClawdBot web dashboard" 2>/dev/null || true
    print_status "Firewall rule added for port 18789"
else
    print_warning "UFW not installed. You may need to manually configure firewall rules."
    print_info "To allow ClawdBot port in GCP, run:"
    print_info "  gcloud compute firewall-rules create allow-clawdbot --allow tcp:18789"
fi

# Create systemd service file
print_status "Creating systemd service..."
cat > /tmp/clawdbot.service << 'EOF'
[Unit]
Description=ClawdBot AI Assistant
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=/usr/bin/clawdbot gateway --port 18789
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=clawdbot

[Install]
WantedBy=multi-user.target
EOF

# Replace placeholders
sed -i "s/\$USER/$SUDO_USER/" /tmp/clawdbot.service
sed -i "s|\$HOME|/home/$SUDO_USER|" /tmp/clawdbot.service

sudo mv /tmp/clawdbot.service /etc/systemd/system/clawdbot.service
sudo systemctl daemon-reload
print_status "Systemd service created"

echo ""
print_status "ClawdBot installation completed successfully!"
echo ""
print_info "Next steps:"
print_info "1. Run the onboarding wizard:"
print_info "   clawdbot onboard --install-daemon"
print_info ""
print_info "2. Start the ClawdBot service:"
print_info "   sudo systemctl enable clawdbot"
print_info "   sudo systemctl start clawdbot"
print_info ""
print_info "3. Check service status:"
print_info "   sudo systemctl status clawdbot"
print_info ""
print_info "4. Access web dashboard at:"
print_info "   http://$(curl -s ifconfig.me):18789"
print_info ""
print_info "For more information, see README.md"
echo ""
