# Everyday-OS Server Deployment Guide

This guide provides step-by-step instructions for deploying Everyday-OS on your server.

## Quick Start

If you're ready to deploy and have your DNS and .env configured:

```bash
# On your server
curl -O https://raw.githubusercontent.com/yourusername/everyday-os/main/scripts/deploy-to-server.sh
chmod +x deploy-to-server.sh
./deploy-to-server.sh
```

## Prerequisites

### 1. Server Requirements
- **OS**: Ubuntu 20.04+ (recommended) or compatible Linux distribution
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB+ free disk space
- **CPU**: 2+ cores (4+ recommended)
- **Network**: Static IP address

### 2. Domain & DNS Setup
You need a domain with these A records pointing to your server's IP:
- `n8n.yourdomain.com`
- `chat.yourdomain.com`
- `supabase.yourdomain.com`
- `neo4j.yourdomain.com`
- `nca.yourdomain.com`
- `minio-console.yourdomain.com`
- `minio-api.yourdomain.com`
- `search.yourdomain.com` (optional)

**Note**: Do NOT include port numbers in DNS records. Caddy handles routing.

## Manual Deployment Steps

### 1. Connect to Your Server
```bash
ssh user@your-server-ip
```

### 2. Install Required Software
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Log out and back in for group changes
exit
ssh user@your-server-ip

# Install Docker Compose v2
sudo apt install docker-compose-plugin

# Install other tools
sudo apt install -y git python3 python3-pip openssl
```

### 3. Configure Firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 4. Clone Repository
```bash
git clone https://github.com/yourusername/everyday-os.git
cd everyday-os
```

### 5. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

Key variables to configure:
- `BASE_DOMAIN` - Your domain (e.g., example.com)
- `PROTOCOL` - Set to `https`
- `SERVER_IP` - Your server's public IP
- All passwords and secrets (generate with `openssl rand -hex 32`)
- Service hostnames (uncomment and set for production)
- `LETSENCRYPT_EMAIL` - Your email for SSL certificates

### 6. Deploy Services
```bash
python3 start_services.py --environment public
```

This will:
- Start all services in production mode
- Configure Caddy for automatic SSL
- Set up secure networking
- Initialize databases

### 7. Verify Deployment
```bash
# Check service health
./scripts/verify-deployment.sh

# View service logs
docker compose -p everyday-os logs -f
```

## Post-Deployment Setup

### 1. Initial Service Configuration

#### N8N
1. Visit `https://n8n.yourdomain.com`
2. Create your admin account
3. Configure workspace settings

#### Open WebUI
1. Visit `https://chat.yourdomain.com`
2. Create your account
3. Configure API keys for OpenAI/Anthropic

#### MinIO
1. Visit `https://minio-console.yourdomain.com`
2. Login with credentials from .env
3. Create buckets as needed

#### Neo4j
1. Visit `https://neo4j.yourdomain.com`
2. Login with neo4j/your-password
3. Change default password if needed

### 2. Google Cloud Integration

See [GOOGLE_CLOUD_SETUP.md](./GOOGLE_CLOUD_SETUP.md) for detailed instructions on:
- Creating Google Cloud project
- Enabling APIs
- Setting up OAuth credentials
- Configuring N8N integration

### 3. Security Hardening

1. **Change all default passwords**
2. **Enable 2FA** where available (N8N, etc.)
3. **Review access logs** regularly
4. **Set up backups**:
   ```bash
   # Create backup script
   ./scripts/backup.sh
   ```

## Troubleshooting

### Services Not Starting
```bash
# Check logs
docker compose -p everyday-os logs [service-name]

# Restart specific service
docker compose -p everyday-os restart [service-name]

# Check system resources
df -h
free -m
```

### SSL Certificate Issues
- Ensure DNS is properly configured
- Check Caddy logs: `docker logs caddy`
- Verify ports 80/443 are open
- Wait for DNS propagation (can take up to 48 hours)

### Connection Refused
- Check firewall settings
- Verify service is running: `docker ps`
- Check service health: `docker inspect [container-name]`

### Database Connection Issues
- Ensure passwords don't contain @ symbol
- Check PostgreSQL logs
- Verify network connectivity between services

## Maintenance

### Updates
```bash
cd everyday-os
git pull
python3 start_services.py --environment public
```

### Backups
```bash
# Backup all data
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh [backup-date]
```

### Monitoring
```bash
# Check resource usage
docker stats

# View all logs
docker compose -p everyday-os logs -f

# Check disk space
df -h
```

## Support

For issues:
1. Check service logs
2. Run verification script
3. Review [SETUP_CHECKLIST.md](../SETUP_CHECKLIST.md)
4. Check GitHub issues
5. Contact support

## Quick Reference

### Common Commands
```bash
# Start services
python3 start_services.py --environment public

# Stop services
docker compose -p everyday-os down

# Restart all services
docker compose -p everyday-os restart

# View logs
docker compose -p everyday-os logs -f [service]

# Check status
docker compose -p everyday-os ps

# Run verification
./scripts/verify-deployment.sh
```

### Service URLs
After deployment, access services at:
- N8N: `https://n8n.yourdomain.com`
- Open WebUI: `https://chat.yourdomain.com`
- MinIO: `https://minio-console.yourdomain.com`
- Neo4j: `https://neo4j.yourdomain.com`
- NCA: `https://nca.yourdomain.com`
- SearXNG: `https://search.yourdomain.com`