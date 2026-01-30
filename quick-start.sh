#!/bin/bash

# ClawdBot Quick Start Script
# This script provides a guided setup for ClawdBot on Google VM

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
   ____ _                     _ ____        _   
  / ___| | __ ___      ____| | __ )  ___ | |_ 
 | |   | |/ _` \ \ /\ / / _` |  _ \ / _ \| __|
 | |___| | (_| |\ V  V / (_| | |_) | (_) | |_ 
  \____|_|\__,_| \_/\_/ \__,_|____/ \___/ \__|
                                                
  Quick Start Setup for Google VM
EOF
echo -e "${NC}"

# Check if running on Google Cloud VM
if [ -f "/sys/class/dmi/id/product_name" ]; then
    PRODUCT=$(cat /sys/class/dmi/id/product_name)
    if [[ $PRODUCT == *"Google"* ]]; then
        echo -e "${GREEN}✓ Running on Google Cloud VM${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}This script will:${NC}"
echo "1. Install Node.js and dependencies"
echo "2. Install ClawdBot"
echo "3. Configure systemd service"
echo "4. Set up firewall rules"
echo "5. Run the onboarding wizard"
echo ""

read -p "Continue with installation? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}[1/5] Running setup script...${NC}"
if [ -f "./setup-google-vm.sh" ]; then
    chmod +x setup-google-vm.sh
    ./setup-google-vm.sh
else
    echo -e "${RED}Error: setup-google-vm.sh not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[2/5] Checking API key...${NC}"
read -p "Do you have an Anthropic API key? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your Anthropic API key: " API_KEY
    export ANTHROPIC_API_KEY="$API_KEY"
    
    # Create .env file
    if [ ! -f ".env" ]; then
        cp .env.example .env
        sed -i "s/sk-ant-your-api-key-here/$API_KEY/" .env
        echo -e "${GREEN}✓ Created .env file with your API key${NC}"
    fi
else
    echo -e "${YELLOW}You'll need to get an API key from: https://console.anthropic.com/${NC}"
    echo "Press Enter to continue..."
    read
fi

echo ""
echo -e "${BLUE}[3/5] Running ClawdBot onboarding...${NC}"
clawdbot onboard --install-daemon

echo ""
echo -e "${BLUE}[4/5] Starting ClawdBot service...${NC}"
sudo systemctl enable clawdbot
sudo systemctl start clawdbot
sleep 3

echo ""
echo -e "${BLUE}[5/5] Checking service status...${NC}"
if sudo systemctl is-active --quiet clawdbot; then
    echo -e "${GREEN}✓ ClawdBot is running!${NC}"
else
    echo -e "${YELLOW}⚠ ClawdBot service may need attention${NC}"
    echo "Check status with: sudo systemctl status clawdbot"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ClawdBot Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Get external IP
EXTERNAL_IP=$(curl -s ifconfig.me || echo "YOUR_VM_IP")

echo -e "${BLUE}Access your ClawdBot:${NC}"
echo "  🌐 Web Dashboard: http://$EXTERNAL_IP:18789"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo "  • Check status:  clawdbot status --all"
echo "  • View logs:     sudo journalctl -u clawdbot -f"
echo "  • Restart:       sudo systemctl restart clawdbot"
echo "  • Stop:          sudo systemctl stop clawdbot"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Access the web dashboard"
echo "2. Connect your messaging platforms (Telegram, WhatsApp, Discord)"
echo "3. Start chatting with your AI assistant!"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo "  • README.md - General information"
echo "  • GOOGLE_CLOUD_SETUP.md - Detailed GCP setup"
echo "  • TROUBLESHOOTING.md - Common issues and solutions"
echo ""
echo -e "${GREEN}Happy chatting! 🤖${NC}"
