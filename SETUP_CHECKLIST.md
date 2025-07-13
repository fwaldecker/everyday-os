# Everyday-OS Setup Checklist

This checklist ensures your Everyday-OS deployment is properly configured and ready for production use.

## 🔧 Pre-Setup Requirements

### System Requirements
- [ ] Ubuntu 20.04+ or compatible Linux distribution
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose v2.0+ installed
- [ ] Git installed
- [ ] Python 3.8+ installed (optional, for scripts)
- [ ] At least 8GB RAM (16GB recommended)
- [ ] At least 50GB free disk space
- [ ] Ports 80 and 443 available (not used by other services)

### Domain & DNS
- [ ] Domain name registered and configured
- [ ] DNS A records created for all services:
  - [ ] `n8n.yourdomain.com`
  - [ ] `chat.yourdomain.com`
  - [ ] `nca.yourdomain.com`
  - [ ] `neo4j.yourdomain.com`
  - [ ] `minio.yourdomain.com`
- [ ] DNS propagation completed (can take up to 48 hours)

## 📋 Configuration Steps

### 1. Environment Configuration
- [ ] Copy `.env.example` to `.env` in root directory
- [ ] Copy `.env` to `docker/.env`
- [ ] Set `BASE_DOMAIN` to your domain (e.g., example.com)
- [ ] Set `PROTOCOL` to `https` for production
- [ ] Set `SERVER_IP` to your server's public IP address
- [ ] Set `LETSENCRYPT_EMAIL` to your email for SSL certificates

### 2. Security Configuration
- [ ] Generate new `N8N_ENCRYPTION_KEY` using `openssl rand -hex 32`
- [ ] Generate new `N8N_USER_MANAGEMENT_JWT_SECRET` using `openssl rand -hex 32`
- [ ] Set strong `POSTGRES_PASSWORD` (no @ symbols!)
- [ ] Set strong `MINIO_ROOT_PASSWORD`
- [ ] Set `NEO4J_AUTH` with format `neo4j/your-password`
- [ ] Set `NEO4J_PASSWORD` to match the password in NEO4J_AUTH
- [ ] Generate `SEARXNG_SECRET_KEY` using `openssl rand -hex 32`
- [ ] Generate `WEBUI_SECRET_KEY` using `openssl rand -hex 32`
- [ ] Generate `JWT_SECRET_KEY` using `openssl rand -hex 32`
- [ ] Generate `SESSION_SECRET` using `openssl rand -hex 32`

### 3. Service Hostnames (Production Only)
Uncomment and configure in `.env`:
- [ ] `N8N_HOSTNAME=n8n.${BASE_DOMAIN}`
- [ ] `WEBUI_HOSTNAME=chat.${BASE_DOMAIN}`
- [ ] `NEO4J_HOSTNAME=neo4j.${BASE_DOMAIN}`
- [ ] `NCA_HOSTNAME=nca.${BASE_DOMAIN}`
- [ ] `MINIO_CONSOLE_HOSTNAME=minio.${BASE_DOMAIN}`
- [ ] `MINIO_API_HOSTNAME=minio-api.${BASE_DOMAIN}`

### 4. API Keys (Optional but Recommended)
- [ ] Set `OPENAI_API_KEY` if using OpenAI
- [ ] Set `ANTHROPIC_API_KEY` if using Claude
- [ ] Set `NCA_API_KEY` (or use default: `nca-toolkit-default-api-key`)

### 5. Google Cloud Setup (If Using)
- [ ] Configure `GOOGLE_SERVICE_ACCOUNT_KEY` with your service account JSON
- [ ] Set `GOOGLE_BILLING_ACCOUNT_ID`

## 🚀 Deployment Steps

### 1. Initial Setup
- [ ] Clone the repository: `git clone https://github.com/fwaldecker/everyday-os.git`
- [ ] Navigate to project directory: `cd everyday-os`
- [ ] Create `.env` file from template: `cp .env.example .env`
- [ ] Configure all required environment variables
- [ ] Copy .env to docker directory: `cp .env docker/.env`

### 2. Network Security
- [ ] Enable firewall: `sudo ufw enable`
- [ ] Allow SSH: `sudo ufw allow 22/tcp`
- [ ] Allow HTTP: `sudo ufw allow 80/tcp`
- [ ] Allow HTTPS: `sudo ufw allow 443/tcp`
- [ ] Reload firewall: `sudo ufw reload`

### 3. Start Services
- [ ] Navigate to docker directory: `cd docker`
- [ ] Start services: `docker compose up -d`
- [ ] Wait for all services to become healthy (2-5 minutes)
- [ ] Check service status: `docker compose ps`

## ✅ Post-Deployment Verification

### Service Health Checks
Run `docker compose ps` and verify all services are running:
- [ ] n8n
- [ ] open-webui
- [ ] neo4j
- [ ] postgres (docker-postgres-1)
- [ ] minio
- [ ] nca-toolkit
- [ ] qdrant
- [ ] redis
- [ ] caddy (docker-caddy-1)

### Web Access Verification
Test each service URL in your browser:
- [ ] n8n: `https://n8n.yourdomain.com`
- [ ] Open WebUI: `https://chat.yourdomain.com`
- [ ] MinIO Console: `https://minio.yourdomain.com`
- [ ] Neo4j Browser: `https://neo4j.yourdomain.com`
- [ ] NCA API: `https://nca.yourdomain.com/v1/toolkit/authenticate` (with API key header)

### SSL Certificate Verification
- [ ] All HTTPS URLs show valid SSL certificates
- [ ] No browser security warnings
- [ ] Certificates issued by Let's Encrypt (or ZeroSSL)

### Initial Service Configuration

#### n8n
- [ ] Create admin account on first access
- [ ] Set up workspace
- [ ] Configure any needed credentials

#### Open WebUI
- [ ] Create your account
- [ ] Add OpenAI/Anthropic API keys in Settings → Connections

#### MinIO
- [ ] Login with MINIO_ROOT_USER and MINIO_ROOT_PASSWORD
- [ ] Create necessary buckets

#### Neo4j
- [ ] Login with neo4j username and password from .env
- [ ] Change password if prompted

## 🔒 Security Hardening

### Access Control
- [ ] Change all default passwords
- [ ] Enable 2FA where available (especially n8n)
- [ ] Use strong, unique passwords for all services
- [ ] Document passwords securely (password manager)

### Monitoring
- [ ] Set up log monitoring: `docker compose logs -f`
- [ ] Monitor disk usage: `df -h`
- [ ] Check Docker resource usage: `docker stats`

### Regular Maintenance
- [ ] Schedule regular updates
- [ ] Set up backup procedures for important data
- [ ] Monitor service logs for errors
- [ ] Keep Docker images updated

## 🚨 Troubleshooting

### Common Issues

**Services won't start:**
- Check logs: `docker compose logs [service-name]`
- Verify .env exists in docker directory
- Ensure all required variables are set

**Port already in use:**
- Check what's using the port: `sudo lsof -i :[port-number]`
- Stop conflicting service or change port

**SSL certificates fail:**
- Verify DNS is properly configured
- Check Caddy logs: `docker compose logs caddy`
- Ensure firewall allows ports 80/443

**Database connection issues:**
- Check password doesn't contain @ symbol
- Verify network connectivity between services
- Check service logs for specific errors

### Useful Commands

```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]

# Stop all services
docker compose down

# Stop and remove all data (WARNING!)
docker compose down -v

# Check resource usage
docker stats

# Enter a container
docker compose exec [service-name] bash
```

## 📞 Support

If you encounter issues:
1. Check service logs for error messages
2. Verify all environment variables are set correctly
3. Ensure all ports are available
4. Check firewall rules
5. Verify DNS configuration
6. Review GitHub issues or create a new one

Remember: Never commit your `.env` file or share your secrets!