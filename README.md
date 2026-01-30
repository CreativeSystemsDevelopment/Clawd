# Clawd - ClawdBot Deployment for Google VM

This repository contains setup scripts and configuration files for deploying ClawdBot on Google Cloud VM instances.

## What is ClawdBot?

ClawdBot is an open-source, self-hosted personal AI assistant that integrates Claude AI with messaging platforms like Telegram, WhatsApp, Discord, and more. It's designed for local execution, privacy, and full control of your assistant's capabilities.

## Prerequisites

- Google Cloud Platform account
- Google Cloud VM instance (Ubuntu 20.04 or later recommended)
- At least 2 GB RAM
- Node.js 22+ (will be installed by setup script)
- Anthropic API key or Claude CLI token

## Quick Start

### 1. Clone this repository on your Google VM

```bash
git clone https://github.com/CreativeSystemsDevelopment/Clawd.git
cd Clawd
```

### 2. Run the automated setup script

```bash
chmod +x setup-google-vm.sh
./setup-google-vm.sh
```

This script will:
- Install Node.js 22+
- Install ClawdBot globally
- Configure system dependencies
- Set up systemd service for automatic startup
- Configure firewall rules

### 3. Configure ClawdBot

After installation, run the onboarding wizard:

```bash
clawdbot onboard --install-daemon
```

You'll be prompted to:
- Add your Anthropic API key or Claude CLI token
- Select messaging channels (Telegram, WhatsApp, Discord, etc.)
- Configure the bot as a background service

## Manual Installation

If you prefer to install manually, follow these steps:

### 1. Install Node.js 22+

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2. Install ClawdBot

```bash
sudo npm install -g clawdbot@latest
```

### 3. Run Onboarding

```bash
clawdbot onboard --install-daemon
```

### 4. Set up systemd service (optional, for auto-start)

Copy the provided systemd service file:

```bash
sudo cp clawdbot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable clawdbot
sudo systemctl start clawdbot
```

## Configuration

### Environment Variables

Create a `.env` file or set environment variables:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export CLAWDBOT_PORT=18789
```

### Firewall Configuration

For Google VM, configure firewall rules to allow the ClawdBot port:

```bash
# Allow ClawdBot web dashboard
sudo ufw allow 18789/tcp

# Enable firewall if not already enabled
sudo ufw enable
```

Or use GCP firewall rules:

```bash
gcloud compute firewall-rules create allow-clawdbot \
  --allow tcp:18789 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow ClawdBot web dashboard"
```

## Docker Deployment

For containerized deployment, use the provided Docker configuration:

```bash
docker-compose up -d
```

This will:
- Build the ClawdBot container
- Set up persistent volumes
- Configure networking
- Enable automatic restart

## Managing ClawdBot

### Check Status

```bash
clawdbot gateway status
clawdbot status --all
```

### Start/Stop/Restart

```bash
# Using systemd
sudo systemctl start clawdbot
sudo systemctl stop clawdbot
sudo systemctl restart clawdbot

# Direct command
clawdbot gateway restart
```

### View Logs

```bash
# Systemd logs
sudo journalctl -u clawdbot -f

# Direct logs
clawdbot gateway --verbose
```

### Access Web Dashboard

Access the web dashboard at:
```
http://YOUR_VM_IP:18789
```

## Messaging Platform Setup

### Telegram

1. Create a bot using [@BotFather](https://core.telegram.org/bots#botfather)
2. Get your bot token
3. Add it during onboarding or via:
```bash
clawdbot channels add telegram --token YOUR_TOKEN
```

### WhatsApp

1. During onboarding, select WhatsApp
2. Scan the QR code displayed in your terminal
3. The bot will connect to your WhatsApp account

### Discord

1. Create a bot in the [Discord Developer Portal](https://discord.com/developers/applications)
2. Get your bot token
3. Add it during onboarding or via:
```bash
clawdbot channels add discord --token YOUR_TOKEN
```

## Security Best Practices

1. **Use SSH keys**: Disable password authentication for SSH
2. **Configure firewall**: Only open necessary ports
3. **Keep updated**: Regularly update ClawdBot and system packages
4. **Secure API keys**: Store keys in environment variables or secure vaults
5. **Limit bot permissions**: Don't give full disk access unless necessary
6. **Monitor logs**: Regularly check logs for suspicious activity

## Troubleshooting

### ClawdBot not starting

```bash
# Check logs
sudo journalctl -u clawdbot -n 50

# Verify installation
which clawdbot
clawdbot --version
```

### Port already in use

```bash
# Find process using port 18789
sudo lsof -i :18789

# Kill process if needed
sudo kill -9 PID
```

### Authentication errors

Re-run the onboarding:
```bash
clawdbot onboard --force
```

### Node.js version issues

Ensure Node.js 22+ is installed:
```bash
node --version
# Should show v22.x.x or higher
```

## Updating ClawdBot

```bash
# Update via npm
sudo npm update -g clawdbot

# Restart service
sudo systemctl restart clawdbot
```

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop clawdbot
sudo systemctl disable clawdbot

# Remove ClawdBot
sudo npm uninstall -g clawdbot

# Remove systemd service
sudo rm /etc/systemd/system/clawdbot.service
sudo systemctl daemon-reload
```

## Resources

- [Official ClawdBot Documentation](https://docs.clawd.bot/)
- [Anthropic Integration Guide](https://docs.clawd.bot/providers/anthropic)
- [Google Cloud VM Documentation](https://cloud.google.com/compute/docs)
- [ClawdBot GitHub Repository](https://github.com/clawdbot/clawdbot)

## Support

For issues specific to this deployment setup, please open an issue on this repository.

For ClawdBot-specific issues, refer to the [official documentation](https://docs.clawd.bot/) or the [ClawdBot repository](https://github.com/clawdbot/clawdbot).

## License

MIT License - see [LICENSE](LICENSE) file for details.