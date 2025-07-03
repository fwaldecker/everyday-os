# Everyday-OS Setup Verification Checklist

This checklist ensures your Everyday-OS deployment is properly configured and ready for production use.

## 🔧 Pre-Setup Requirements

### System Requirements
- [ ] Ubuntu 20.04+ or compatible Linux distribution
- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose v2.0+ installed
- [ ] Git installed
- [ ] Python 3.8+ installed
- [ ] At least 8GB RAM (16GB recommended)
- [ ] At least 50GB free disk space
- [ ] Ports 80 and 443 available (not used by other services)

### Domain & DNS
- [ ] Domain name registered and configured
- [ ] DNS A records created for all services you plan to expose
- [ ] DNS propagation completed (can take up to 48 hours)

## 📋 Configuration Steps

### 1. Environment Configuration
- [ ] Copy `.env.example` to `.env`
- [ ] Set `BASE_DOMAIN` to your domain (e.g., example.com)
- [ ] Set `PROTOCOL` to `https` for production
- [ ] Set `SERVER_IP` to your server's public IP address
- [ ] Set `TZ` to your timezone (e.g., America/New_York)

### 2. Security Configuration
- [ ] Generate new `N8N_ENCRYPTION_KEY` using `openssl rand -hex 32`
- [ ] Generate new `N8N_USER_MANAGEMENT_JWT_SECRET` using `openssl rand -hex 32`
- [ ] Generate new `JWT_SECRET` for Supabase using `openssl rand -base64 32`
- [ ] Set strong `POSTGRES_PASSWORD` (no @ symbols!)
- [ ] Set strong `MINIO_ROOT_PASSWORD`
- [ ] Generate new `LANGFUSE_SECRET_KEY` using `openssl rand -hex 32`
- [ ] Generate new `NEXTAUTH_SECRET` using `openssl rand -hex 32`
- [ ] Generate new `ENCRYPTION_KEY` using `openssl rand -hex 32`
- [ ] Set unique `NEO4J_PASSWORD` in `NEO4J_AUTH`
- [ ] Change `REDIS_AUTH` from default value
- [ ] Update all other default passwords and secrets

### 3. Service Hostnames (Production Only)
Uncomment and configure in `.env` for services you want to expose:
- [ ] `N8N_HOSTNAME=n8n.yourdomain.com`
- [ ] `WEBUI_HOSTNAME=chat.yourdomain.com`
- [ ] `SUPABASE_HOSTNAME=supabase.yourdomain.com`
- [ ] `LANGFUSE_HOSTNAME=langfuse.yourdomain.com`
- [ ] `NEO4J_HOSTNAME=neo4j.yourdomain.com`
- [ ] `NCA_HOSTNAME=nca.yourdomain.com`
- [ ] `MINIO_CONSOLE_HOSTNAME=minio-console.yourdomain.com`
- [ ] `MINIO_API_HOSTNAME=minio-api.yourdomain.com`
- [ ] `SEARXNG_HOSTNAME=search.yourdomain.com` (optional, consider security)
- [ ] `LETSENCRYPT_EMAIL=your-email@example.com` (required for SSL certificates)

### 4. API Keys (Optional but Recommended)
- [ ] Set `OPENAI_API_KEY` if using OpenAI
- [ ] Set `ANTHROPIC_API_KEY` if using Claude
- [ ] Set `LANGFUSE_PUBLIC_KEY` for Langfuse worker

### 5. Google Cloud Setup (If Using)
- [ ] Configure `GOOGLE_SERVICE_ACCOUNT_KEY` with your service account JSON
- [ ] Set `GOOGLE_BILLING_ACCOUNT_ID`
- [ ] Set `N8N_API_KEY` if using automated credential injection

## 🚀 Deployment Steps

### 1. Initial Setup
- [ ] Clone the repository: `git clone <repo-url>`
- [ ] Navigate to project directory: `cd everyday-os`
- [ ] Create `.env` file from template: `cp .env.example .env`
- [ ] Configure all required environment variables

### 2. Network Security
- [ ] Enable firewall: `sudo ufw enable`
- [ ] Allow SSH: `sudo ufw allow 22/tcp`
- [ ] Allow HTTP: `sudo ufw allow 80/tcp`
- [ ] Allow HTTPS: `sudo ufw allow 443/tcp`
- [ ] Reload firewall: `sudo ufw reload`

### 3. Start Services
- [ ] Run setup script: `python start_services.py --environment public`
- [ ] Wait for all services to become healthy (5-10 minutes)
- [ ] Check service status: `docker compose -p everyday-os ps`

## ✅ Post-Deployment Verification

### Service Health Checks
Run `docker compose -p everyday-os ps` and verify all services show "healthy":
- [ ] n8n
- [ ] n8n-postgres
- [ ] open-webui
- [ ] neo4j
- [ ] postgres
- [ ] minio
- [ ] nca-toolkit
- [ ] langfuse-web
- [ ] langfuse-worker
- [ ] clickhouse
- [ ] redis
- [ ] searxng
- [ ] caddy

### Web Access Verification
Test each service URL in your browser:
- [ ] N8N: `https://n8n.yourdomain.com`
- [ ] Open WebUI: `https://chat.yourdomain.com`
- [ ] Supabase: `https://supabase.yourdomain.com`
- [ ] Langfuse: `https://langfuse.yourdomain.com`
- [ ] MinIO Console: `https://minio-console.yourdomain.com`
- [ ] Neo4j Browser: `https://neo4j.yourdomain.com`

### SSL Certificate Verification
- [ ] All HTTPS URLs show valid SSL certificates
- [ ] No browser security warnings
- [ ] Certificates issued by Let's Encrypt

### Initial Configuration
- [ ] Create N8N admin account on first access
- [ ] Configure Open WebUI with API keys
- [ ] Access MinIO console with configured credentials
- [ ] Verify Neo4j connection with configured password

## 🔒 Security Hardening

### Access Control
- [ ] Change all default passwords
- [ ] Enable 2FA where available (N8N, etc.)
- [ ] Restrict access to sensitive services if needed
- [ ] Review and adjust CORS policies

### Monitoring
- [ ] Set up log rotation for all services
- [ ] Configure monitoring alerts (optional)
- [ ] Enable backup procedures
- [ ] Document recovery procedures

### Regular Maintenance
- [ ] Schedule regular updates: `git pull && python start_services.py --reset`
- [ ] Monitor disk usage: `df -h`
- [ ] Check service logs: `docker compose -p everyday-os logs -f [service-name]`
- [ ] Backup databases regularly

## 🚨 Troubleshooting

### Common Issues
- [ ] If services won't start, check logs: `docker compose -p everyday-os logs [service-name]`
- [ ] If "port already in use", check: `sudo lsof -i :[port-number]`
- [ ] If SSL certificates fail, verify DNS is properly configured
- [ ] If database connections fail, check password doesn't contain @ symbol

### Recovery Commands
```bash
# Stop all services
python start_services.py --reset

# Remove all volumes (WARNING: deletes all data)
docker compose -p everyday-os down -v

# Restart a specific service
docker compose -p everyday-os restart [service-name]

# View service logs
docker compose -p everyday-os logs -f [service-name]
```

## 📞 Support

If you encounter issues:
1. Check service logs for error messages
2. Verify all environment variables are set correctly
3. Ensure all ports are available
4. Check firewall rules
5. Verify DNS configuration

Remember to never commit your `.env` file or share your secrets!