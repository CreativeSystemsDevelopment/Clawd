# Google Cloud Platform Setup Guide

This guide provides step-by-step instructions for setting up ClawdBot on Google Cloud Platform.

## Creating a Google VM Instance

### Using Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **Compute Engine** > **VM instances**
3. Click **Create Instance**
4. Configure your instance:
   - **Name**: clawdbot-vm (or your preferred name)
   - **Region**: Choose a region close to your users
   - **Machine type**: e2-medium (2 vCPUs, 4 GB memory) - recommended
   - **Boot disk**: 
     - Operating System: Ubuntu
     - Version: Ubuntu 22.04 LTS
     - Disk size: 20 GB (minimum)
   - **Firewall**: 
     - ✓ Allow HTTP traffic
     - ✓ Allow HTTPS traffic
5. Click **Create**

### Using gcloud CLI

```bash
gcloud compute instances create clawdbot-vm \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-standard \
  --tags=http-server,https-server
```

## Configuring Firewall Rules

### Allow ClawdBot Port (18789)

#### Using Google Cloud Console

1. Go to **VPC Network** > **Firewall**
2. Click **Create Firewall Rule**
3. Configure the rule:
   - **Name**: allow-clawdbot
   - **Direction**: Ingress
   - **Targets**: All instances in the network (or specific tags)
   - **Source IP ranges**: 0.0.0.0/0 (or restrict to your IP for security)
   - **Protocols and ports**: tcp:18789
4. Click **Create**

#### Using gcloud CLI

```bash
gcloud compute firewall-rules create allow-clawdbot \
  --allow tcp:18789 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow ClawdBot web dashboard access"
```

For better security, restrict to your IP:

```bash
gcloud compute firewall-rules create allow-clawdbot \
  --allow tcp:18789 \
  --source-ranges YOUR_IP_ADDRESS/32 \
  --description "Allow ClawdBot web dashboard access from specific IP"
```

## SSH into Your VM

### Using Google Cloud Console

1. Go to **Compute Engine** > **VM instances**
2. Click **SSH** next to your instance

### Using gcloud CLI

```bash
gcloud compute ssh clawdbot-vm --zone=us-central1-a
```

### Using standard SSH

```bash
ssh -i ~/.ssh/google_compute_engine username@EXTERNAL_IP
```

## Installing ClawdBot

Once connected to your VM, clone this repository and run the setup script:

```bash
# Clone repository
git clone https://github.com/CreativeSystemsDevelopment/Clawd.git
cd Clawd

# Run setup script
chmod +x setup-google-vm.sh
./setup-google-vm.sh
```

## Running the Onboarding Wizard

After installation, configure ClawdBot:

```bash
clawdbot onboard --install-daemon
```

Follow the prompts to:
1. Add your Anthropic API key
2. Select messaging platforms (Telegram, WhatsApp, Discord)
3. Configure bot settings

## Starting ClawdBot Service

Enable and start the systemd service:

```bash
sudo systemctl enable clawdbot
sudo systemctl start clawdbot
sudo systemctl status clawdbot
```

## Accessing the Web Dashboard

1. Get your VM's external IP:
   ```bash
   gcloud compute instances describe clawdbot-vm \
     --zone=us-central1-a \
     --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
   ```

2. Access the dashboard:
   ```
   http://EXTERNAL_IP:18789
   ```

## Setting Up Static IP (Optional but Recommended)

To ensure your VM's IP doesn't change:

### Using gcloud CLI

```bash
# Reserve a static IP
gcloud compute addresses create clawdbot-static-ip --region=us-central1

# Get the reserved IP
gcloud compute addresses describe clawdbot-static-ip --region=us-central1

# Assign to your VM
gcloud compute instances delete-access-config clawdbot-vm \
  --zone=us-central1-a \
  --access-config-name="External NAT"

gcloud compute instances add-access-config clawdbot-vm \
  --zone=us-central1-a \
  --access-config-name="External NAT" \
  --address=RESERVED_IP
```

## Setting Up Custom Domain (Optional)

1. Reserve a static IP (see above)
2. In your domain registrar, create an A record:
   - **Name**: bot (or your subdomain)
   - **Type**: A
   - **Value**: YOUR_STATIC_IP
3. Access ClawdBot at: `http://bot.yourdomain.com:18789`

## Setting Up SSL/HTTPS (Optional)

For secure access, set up a reverse proxy with SSL:

### Install Nginx

```bash
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

### Configure Nginx

Create `/etc/nginx/sites-available/clawdbot`:

```nginx
server {
    listen 80;
    server_name bot.yourdomain.com;

    location / {
        proxy_pass http://localhost:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/clawdbot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Get SSL Certificate

```bash
sudo certbot --nginx -d bot.yourdomain.com
```

Access at: `https://bot.yourdomain.com`

## Cost Optimization

### Use Preemptible VMs (Spot Instances)

Save up to 80% on VM costs with preemptible instances:

```bash
gcloud compute instances create clawdbot-vm \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --preemptible \
  --maintenance-policy=TERMINATE
```

**Note**: Preemptible VMs can be terminated by Google Cloud with 30 seconds notice. Ensure your ClawdBot service is configured to auto-restart.

### Use Auto-scaling (For High Availability)

For production deployments, consider using:
- Instance groups with auto-scaling
- Cloud Load Balancing
- Cloud SQL for persistent data

## Backup and Recovery

### Backup ClawdBot Configuration

```bash
# Create backup directory
mkdir -p ~/backups

# Backup ClawdBot data
tar -czf ~/backups/clawdbot-backup-$(date +%Y%m%d).tar.gz ~/.clawdbot

# Upload to Cloud Storage (optional)
gsutil cp ~/backups/clawdbot-backup-*.tar.gz gs://your-bucket/backups/
```

### Restore from Backup

```bash
# Download from Cloud Storage (if using)
gsutil cp gs://your-bucket/backups/clawdbot-backup-YYYYMMDD.tar.gz ~/

# Extract backup
tar -xzf ~/clawdbot-backup-YYYYMMDD.tar.gz -C ~/

# Restart service
sudo systemctl restart clawdbot
```

## Monitoring

### View Logs

```bash
# Systemd logs
sudo journalctl -u clawdbot -f

# Last 100 lines
sudo journalctl -u clawdbot -n 100

# Logs from specific time
sudo journalctl -u clawdbot --since "1 hour ago"
```

### Set Up Cloud Monitoring (Optional)

1. Enable Cloud Monitoring in your GCP project
2. Install monitoring agent:
   ```bash
   curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
   sudo bash add-google-cloud-ops-agent-repo.sh --also-install
   ```

3. Configure alerts for:
   - High CPU usage
   - High memory usage
   - Service downtime

## Troubleshooting

### VM Won't Start

```bash
# Check instance status
gcloud compute instances describe clawdbot-vm --zone=us-central1-a

# View serial port output (for boot errors)
gcloud compute instances get-serial-port-output clawdbot-vm --zone=us-central1-a
```

### Can't Access Web Dashboard

1. Verify firewall rules:
   ```bash
   gcloud compute firewall-rules list --filter="name:allow-clawdbot"
   ```

2. Check if service is running:
   ```bash
   sudo systemctl status clawdbot
   ```

3. Check if port is open:
   ```bash
   sudo netstat -tlnp | grep 18789
   ```

### High Costs

1. Check your VM usage:
   ```bash
   gcloud compute instances list
   ```

2. Stop VM when not in use:
   ```bash
   gcloud compute instances stop clawdbot-vm --zone=us-central1-a
   ```

3. Start VM when needed:
   ```bash
   gcloud compute instances start clawdbot-vm --zone=us-central1-a
   ```

## Additional Resources

- [Google Cloud Compute Engine Documentation](https://cloud.google.com/compute/docs)
- [GCP Free Tier](https://cloud.google.com/free)
- [GCP Pricing Calculator](https://cloud.google.com/products/calculator)
- [ClawdBot Documentation](https://docs.clawd.bot/)

## Support

For GCP-specific issues, consult the [Google Cloud documentation](https://cloud.google.com/docs) or support.

For ClawdBot issues, see the main [README.md](README.md) or [ClawdBot documentation](https://docs.clawd.bot/).
