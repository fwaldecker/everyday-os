# Everyday-OS: Self-hosted AI and Automation Platform

Everyday-OS is a comprehensive, self-hosted platform that combines powerful AI tools with automation capabilities. Built with Docker Compose, it provides a complete ecosystem for AI development, data processing, and workflow automation.

## 🚀 Key Features

- **AI & Automation**
  - n8n for visual workflow automation with 400+ integrations
  - Open WebUI for interacting with OpenAI and Anthropic APIs
  - NCA Toolkit for document processing and AI operations
  - Integration-ready for OpenAI and Anthropic APIs

- **Data & Storage**
  - PostgreSQL for relational database needs
  - MinIO for S3-compatible object storage
  - Neo4j for graph database and knowledge graphs
  - Qdrant for high-performance vector search
  - Redis for caching and session management

- **Security & Operations**
  - Caddy reverse proxy with automatic HTTPS/SSL
  - Secure credential management
  - Service health monitoring
  - Production-ready configuration

## 📦 Included Services

| Service | Purpose | Access URL |
|---------|---------|------------|
| [n8n](https://n8n.io/) | Workflow automation platform | `https://n8n.yourdomain.com` |
| [Open WebUI](https://openwebui.com/) | AI chat interface | `https://chat.yourdomain.com` |
| [NCA Toolkit](https://github.com/coleam00/nca-toolkit) | Document processing | `https://nca.yourdomain.com` |
| [MinIO](https://min.io/) | S3-compatible storage | `https://minio.yourdomain.com` |
| [Neo4j](https://neo4j.com/) | Graph database | `https://neo4j.yourdomain.com` |
| [PostgreSQL](https://www.postgresql.org/) | Relational database | Internal only |
| [Qdrant](https://qdrant.tech/) | Vector database | Internal only |
| [Redis](https://redis.io/) | Cache/session store | Internal only |
| [Caddy](https://caddyserver.com/) | Reverse proxy & SSL | Handles all HTTPS |

## 🚀 Quick Start

### Prerequisites

- **Server Requirements**:
  - Ubuntu 20.04+ or compatible Linux distribution
  - 8GB RAM minimum (16GB recommended)
  - 50GB+ free disk space
  - Docker 20.10+ and Docker Compose v2.0+
  - Python 3.8+
  - Git

- **Domain Requirements**:
  - A domain name with DNS control
  - Ability to create A records

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/fwaldecker/everyday-os.git
   cd everyday-os
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and configure:
   - `BASE_DOMAIN` - Your domain (e.g., `example.com`)
   - `PROTOCOL` - Set to `https` for production
   - `SERVER_IP` - Your server's public IP address
   - `LETSENCRYPT_EMAIL` - Your email for SSL certificates
   - All passwords and secrets (use `openssl rand -hex 32` to generate)

3. **Copy .env to docker directory**:
   ```bash
   cp .env docker/.env
   ```

4. **Set up DNS records** pointing to your server's IP:
   - `n8n.yourdomain.com`
   - `chat.yourdomain.com`
   - `nca.yourdomain.com`
   - `neo4j.yourdomain.com`
   - `minio.yourdomain.com`

5. **Configure firewall**:
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

6. **Start services**:
   ```bash
   cd docker
   docker compose up -d
   ```

7. **Verify deployment**:
   ```bash
   docker compose ps
   ```
   All services should show as "running" or "healthy".

## 🔧 Configuration

### Required Environment Variables

Configure these in your `.env` file:

```bash
# Core Configuration
BASE_DOMAIN=yourdomain.com
PROTOCOL=https
SERVER_IP=your.server.ip
LETSENCRYPT_EMAIL=your-email@example.com

# n8n Configuration
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 32)

# Database Passwords
POSTGRES_PASSWORD=your-secure-password  # No @ symbols!
NEO4J_AUTH=neo4j/your-neo4j-password
NEO4J_PASSWORD=your-neo4j-password

# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=your-minio-password

# Security Keys
SEARXNG_SECRET_KEY=$(openssl rand -hex 32)
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)

# API Keys (Optional)
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
```

### Service URLs Configuration

Uncomment and configure these in `.env` for production:

```bash
N8N_HOSTNAME=n8n.${BASE_DOMAIN}
WEBUI_HOSTNAME=chat.${BASE_DOMAIN}
NEO4J_HOSTNAME=neo4j.${BASE_DOMAIN}
NCA_HOSTNAME=nca.${BASE_DOMAIN}
MINIO_CONSOLE_HOSTNAME=minio.${BASE_DOMAIN}
```

## 📋 Post-Installation Setup

### 1. n8n Setup
1. Visit `https://n8n.yourdomain.com`
2. Create your admin account
3. Configure workspace settings
4. Set up credentials for external services

### 2. Open WebUI Setup
1. Visit `https://chat.yourdomain.com`
2. Create your account
3. Configure API keys:
   - Settings → Connections → Add OpenAI/Anthropic API keys

### 3. MinIO Setup
1. Visit `https://minio.yourdomain.com`
2. Login with credentials from `.env`
3. Create buckets as needed for your workflows

### 4. Neo4j Setup
1. Visit `https://neo4j.yourdomain.com`
2. Login with username `neo4j` and password from `.env`
3. Browser will prompt to change password on first login

### 5. NCA Toolkit
- Access via API at `https://nca.yourdomain.com`
- Default API key: `nca-toolkit-default-api-key`
- Configure custom API key in `.env` as `NCA_API_KEY`

## 🔒 Security Best Practices

1. **Change all default passwords** immediately
2. **Generate strong secrets** using `openssl rand -hex 32`
3. **Enable 2FA** where available (especially n8n)
4. **Use HTTPS only** - never disable SSL in production
5. **Regular updates**: 
   ```bash
   cd everyday-os
   git pull
   cd docker
   docker compose pull
   docker compose up -d
   ```
6. **Monitor logs**:
   ```bash
   docker compose logs -f [service-name]
   ```

## 🛠️ Maintenance

### Service Management

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]

# Stop all services
docker compose down

# Stop and remove all data (WARNING!)
docker compose down -v
```

### Backup

Important data locations:
- PostgreSQL: Automated backups in volumes
- MinIO: `/var/lib/docker/volumes/docker_minio_data`
- n8n workflows: Export via UI or API
- Neo4j: `/var/lib/docker/volumes/docker_neo4j_data`

### Troubleshooting

**Services not starting:**
- Check logs: `docker compose logs [service-name]`
- Verify `.env` file exists in docker directory
- Ensure all required variables are set

**SSL certificate issues:**
- Verify DNS records point to correct IP
- Check Caddy logs: `docker compose logs caddy`
- Ensure ports 80/443 are open

**Connection issues:**
- Verify firewall rules
- Check service health: `docker compose ps`
- Test internal connectivity

## 🌐 Optional: Google Cloud Integration

For automated Google Cloud setup during client onboarding:

1. Create a service account in Google Cloud
2. Download the JSON key file
3. Add to `.env`:
   ```bash
   GOOGLE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
   GOOGLE_BILLING_ACCOUNT_ID=XXXXXX-XXXXXX-XXXXXX
   ```

This enables automated:
- Project creation
- API enablement (Gmail, Drive, Docs, etc.)
- OAuth credential generation
- Direct n8n integration

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [MinIO Documentation](https://min.io/docs/)
- [Caddy Documentation](https://caddyserver.com/docs/)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [n8n](https://n8n.io/) for the workflow automation platform
- [Open WebUI](https://openwebui.com/) for the AI chat interface
- [MinIO](https://min.io/) for S3-compatible storage
- [Neo4j](https://neo4j.com/) for graph database capabilities
- All other open-source projects that make this possible