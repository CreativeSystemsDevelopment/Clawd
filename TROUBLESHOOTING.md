# Troubleshooting Guide

This guide helps you diagnose and fix common issues when running ClawdBot on Google VM.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Service Issues](#service-issues)
- [Connection Issues](#connection-issues)
- [Authentication Issues](#authentication-issues)
- [Performance Issues](#performance-issues)
- [Messaging Platform Issues](#messaging-platform-issues)

## Installation Issues

### Node.js Version Too Old

**Symptom**: Error messages about Node.js version requirements

**Solution**:
```bash
# Remove old Node.js
sudo apt-get remove nodejs

# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version  # Should show v22.x.x or higher
```

### npm Install Fails

**Symptom**: Errors during `npm install -g clawdbot`

**Solution 1**: Clear npm cache
```bash
sudo npm cache clean --force
sudo npm install -g clawdbot@latest
```

**Solution 2**: Install with different registry
```bash
sudo npm install -g clawdbot@latest --registry=https://registry.npmjs.org/
```

**Solution 3**: Check for permission issues
```bash
# Fix npm permissions
sudo chown -R $USER:$(id -gn $USER) ~/.npm
sudo chown -R $USER:$(id -gn $USER) /usr/lib/node_modules
```

### Setup Script Fails

**Symptom**: `setup-google-vm.sh` exits with errors

**Solution**:
```bash
# Run with verbose output
bash -x setup-google-vm.sh

# Check system logs
sudo journalctl -xe

# Ensure script is executable
chmod +x setup-google-vm.sh

# Run with sudo if needed
sudo ./setup-google-vm.sh
```

## Service Issues

### ClawdBot Service Won't Start

**Symptom**: `systemctl status clawdbot` shows failed or inactive

**Diagnosis**:
```bash
# Check service status
sudo systemctl status clawdbot

# View detailed logs
sudo journalctl -u clawdbot -n 100 --no-pager

# Check if clawdbot binary exists
which clawdbot

# Test manual start
clawdbot gateway --port 18789
```

**Solutions**:

1. **Fix service file user**:
   ```bash
   sudo nano /etc/systemd/system/clawdbot.service
   # Change User= to your username
   sudo systemctl daemon-reload
   sudo systemctl restart clawdbot
   ```

2. **Fix permissions**:
   ```bash
   sudo chown -R $USER:$USER ~/.clawdbot
   chmod -R 755 ~/.clawdbot
   ```

3. **Recreate service**:
   ```bash
   sudo systemctl stop clawdbot
   sudo systemctl disable clawdbot
   sudo rm /etc/systemd/system/clawdbot.service
   sudo cp clawdbot.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable clawdbot
   sudo systemctl start clawdbot
   ```

### Service Keeps Restarting

**Symptom**: Service status shows constant restarts

**Diagnosis**:
```bash
# Check restart count
sudo systemctl status clawdbot | grep "Active:"

# View recent crashes
sudo journalctl -u clawdbot --since "10 minutes ago"
```

**Common Causes**:
1. Port already in use
2. Missing configuration
3. Invalid API keys
4. Memory issues

**Solutions**:

1. **Check port conflicts**:
   ```bash
   sudo lsof -i :18789
   # Kill conflicting process
   sudo kill -9 PID
   ```

2. **Check configuration**:
   ```bash
   clawdbot config show
   ```

3. **Increase restart delay**:
   ```bash
   sudo nano /etc/systemd/system/clawdbot.service
   # Change RestartSec=10 to RestartSec=30
   sudo systemctl daemon-reload
   sudo systemctl restart clawdbot
   ```

### Service Crashes After Some Time

**Symptom**: Service runs initially but crashes after hours/days

**Diagnosis**:
```bash
# Check memory usage
free -h
top -b -n 1 | grep clawdbot

# Check disk space
df -h

# View crash logs
sudo journalctl -u clawdbot --since "yesterday"
```

**Solutions**:

1. **Increase VM memory**: Upgrade to a larger machine type
2. **Add swap space**:
   ```bash
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   # Make permanent
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

3. **Set memory limits in service**:
   ```bash
   sudo nano /etc/systemd/system/clawdbot.service
   # Add under [Service]
   # MemoryMax=1G
   sudo systemctl daemon-reload
   sudo systemctl restart clawdbot
   ```

## Connection Issues

### Can't Access Web Dashboard

**Symptom**: Browser can't connect to `http://VM_IP:18789`

**Diagnosis**:
```bash
# 1. Check if service is running
sudo systemctl status clawdbot

# 2. Check if port is open
sudo netstat -tlnp | grep 18789
# OR
sudo ss -tlnp | grep 18789

# 3. Check firewall rules
sudo ufw status
gcloud compute firewall-rules list --filter="name:allow-clawdbot"

# 4. Test local connection
curl http://localhost:18789
```

**Solutions**:

1. **Add firewall rule**:
   ```bash
   # UFW
   sudo ufw allow 18789/tcp
   sudo ufw reload
   
   # GCP
   gcloud compute firewall-rules create allow-clawdbot \
     --allow tcp:18789 \
     --source-ranges 0.0.0.0/0
   ```

2. **Verify VM external IP**:
   ```bash
   curl ifconfig.me
   # Use this IP to access dashboard
   ```

3. **Check if binding to correct interface**:
   ```bash
   # Service should bind to 0.0.0.0, not 127.0.0.1
   clawdbot gateway --port 18789 --host 0.0.0.0
   ```

### Connection Times Out

**Symptom**: Browser shows "Connection timed out" or "Can't reach this page"

**Solutions**:

1. **Check GCP firewall**:
   ```bash
   gcloud compute firewall-rules list
   ```

2. **Add VM network tag**:
   ```bash
   gcloud compute instances add-tags clawdbot-vm \
     --tags clawdbot \
     --zone us-central1-a
   ```

3. **Update firewall rule to use tag**:
   ```bash
   gcloud compute firewall-rules update allow-clawdbot \
     --target-tags clawdbot
   ```

### SSL/HTTPS Not Working

**Symptom**: HTTPS connection fails or shows certificate errors

**Solutions**:

1. **Verify Nginx is running**:
   ```bash
   sudo systemctl status nginx
   ```

2. **Check Nginx configuration**:
   ```bash
   sudo nginx -t
   ```

3. **Renew SSL certificate**:
   ```bash
   sudo certbot renew
   ```

4. **Check certificate status**:
   ```bash
   sudo certbot certificates
   ```

## Authentication Issues

### Invalid API Key

**Symptom**: Errors about invalid or expired API key

**Solutions**:

1. **Verify API key**:
   - Go to [Anthropic Console](https://console.anthropic.com/)
   - Regenerate API key if needed

2. **Update API key**:
   ```bash
   # Re-run onboarding
   clawdbot onboard --force
   
   # OR update environment variable
   export ANTHROPIC_API_KEY="sk-ant-your-new-key"
   sudo systemctl restart clawdbot
   ```

3. **Check configuration file**:
   ```bash
   cat ~/.clawdbot/config.json
   # Verify API key is present and correct
   ```

### Claude CLI Token Expired

**Symptom**: Token authentication fails

**Solution**:
```bash
# Reinstall Claude CLI
npm install -g @anthropic-ai/claude-cli

# Get new token
claude setup-token

# Update ClawdBot
clawdbot models auth setup-token --provider anthropic
```

## Performance Issues

### Slow Response Times

**Diagnosis**:
```bash
# Check CPU usage
top -b -n 1

# Check memory
free -h

# Check disk I/O
iostat -x 1 5

# Check network
ping -c 10 8.8.8.8
```

**Solutions**:

1. **Upgrade VM**:
   ```bash
   gcloud compute instances stop clawdbot-vm --zone us-central1-a
   gcloud compute instances set-machine-type clawdbot-vm \
     --machine-type e2-standard-2 \
     --zone us-central1-a
   gcloud compute instances start clawdbot-vm --zone us-central1-a
   ```

2. **Optimize Node.js**:
   ```bash
   # Add to service file
   sudo nano /etc/systemd/system/clawdbot.service
   # Add under [Service]:
   # Environment="NODE_OPTIONS=--max-old-space-size=1024"
   sudo systemctl daemon-reload
   sudo systemctl restart clawdbot
   ```

### High Memory Usage

**Symptom**: Memory usage constantly near 100%

**Solutions**:

1. **Add monitoring**:
   ```bash
   watch -n 5 free -h
   ```

2. **Restart service regularly** (temporary fix):
   ```bash
   # Add cron job to restart daily
   crontab -e
   # Add: 0 2 * * * systemctl restart clawdbot
   ```

3. **Upgrade RAM**: Use larger machine type

## Messaging Platform Issues

### Telegram Bot Not Responding

**Diagnosis**:
```bash
# Check bot status
clawdbot status --all

# View logs for Telegram errors
sudo journalctl -u clawdbot | grep -i telegram
```

**Solutions**:

1. **Verify bot token**:
   - Message @BotFather on Telegram
   - Use `/mybots` to verify bot exists

2. **Re-add bot**:
   ```bash
   clawdbot channels remove telegram
   clawdbot channels add telegram --token YOUR_TOKEN
   sudo systemctl restart clawdbot
   ```

### WhatsApp Connection Lost

**Symptom**: QR code scanning fails or connection drops

**Solutions**:

1. **Regenerate QR code**:
   ```bash
   clawdbot channels remove whatsapp
   clawdbot channels add whatsapp
   # Scan new QR code
   ```

2. **Check WhatsApp Web status**:
   - Open WhatsApp on phone
   - Go to Settings > Linked Devices
   - Remove old sessions
   - Re-scan QR code

### Discord Bot Offline

**Solutions**:

1. **Verify bot token**:
   - Check [Discord Developer Portal](https://discord.com/developers/applications)
   - Regenerate token if needed

2. **Check bot permissions**:
   - Bot needs "Send Messages", "Read Messages", "Read Message History"

3. **Re-add bot**:
   ```bash
   clawdbot channels remove discord
   clawdbot channels add discord --token YOUR_TOKEN
   sudo systemctl restart clawdbot
   ```

## Getting Help

If you're still experiencing issues:

1. **Check logs**:
   ```bash
   sudo journalctl -u clawdbot -n 200 --no-pager > clawdbot-logs.txt
   ```

2. **Gather system info**:
   ```bash
   uname -a
   node --version
   npm --version
   clawdbot --version
   free -h
   df -h
   ```

3. **Open an issue** on GitHub with:
   - Description of the problem
   - Steps to reproduce
   - Logs (sanitize any sensitive information)
   - System information

## Additional Resources

- [ClawdBot Documentation](https://docs.clawd.bot/)
- [Google Cloud Support](https://cloud.google.com/support)
- [Node.js Documentation](https://nodejs.org/docs/)
- [systemd Documentation](https://www.freedesktop.org/software/systemd/man/)
