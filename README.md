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
| [Neo4j](https://neo4j.com/) | Graph database (optional) | `https://neo4j.yourdomain.com` |
| [PostgreSQL](https://www.postgresql.org/) | Relational database | Internal only |
| [Qdrant](https://qdrant.tech/) | Vector database | Internal only |
| [Redis](https://redis.io/) | Cache/session store | Internal only |
| [Caddy](https://caddyserver.com/) | Reverse proxy & SSL | Handles all HTTPS |

## 🎯 Pre-configured n8n Workflows

Everyday-OS includes 18 pre-built n8n workflows that are automatically imported on first setup:

- **AI Agent Workflows**: Local Agentic RAG AI Agent
- **Integration Tools**: Create Google Doc, Summarize Slack Conversation, Post to Slack
- **Database Tools**: Get Postgres Tables
- **Various automation templates** for common use cases

These workflows provide immediate value and serve as examples for building your own automations. When you first access n8n, you'll see all workflows ready to configure with your credentials.

## 🚀 Complete Setup Guide

### Prerequisites

- **Server Requirements**:
  - Ubuntu 20.04+ or compatible Linux distribution
  - 8GB RAM minimum (16GB recommended)
  - 30GB minimum disk space (50GB+ recommended)
    - Docker images: ~22GB (NCA Toolkit: 8.5GB, Open WebUI: 4.9GB, others: ~8GB)
    - Data storage: Grows with usage (databases, uploads, logs)
    - Tip: Use pre-built images to save ~10GB of build cache space
  - Docker 20.10+ and Docker Compose v2.0+
  - Python 3.8+
  - A domain name with DNS access (for HTTPS setup)

### Step 1: Server Preparation

1. **Update your system**:
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Install Docker** (if not already installed):
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

3. **Install Docker Compose v2**:
```bash
# Docker Compose is included with Docker Desktop, but for servers:
sudo apt install docker-compose-plugin
```

4. **Verify installations**:
```bash
docker --version
docker compose version
```

### Step 2: Clone the Repository

```bash
git clone https://github.com/yourusername/everyday-os.git
cd everyday-os
```

### Step 3: Configure Environment Variables

1. **Copy the example environment file**:
```bash
cp .env.example .env
```

2. **Generate secure keys automatically**:
```bash
# This command will generate all required keys and show them
cat << 'EOF'
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 32)
NEXTAUTH_SECRET=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)
EOF

# Copy the output and save it for the next step
```

3. **Edit the `.env` file** with your favorite editor:
```bash
nano .env  # or vim .env
```

4. **Configure the required variables** (replace placeholder values):

```bash
# Here's a template you can copy and modify:
# 1. Replace yourdomain.com with your actual domain
# 2. Replace your.server.ip with your server's IP
# 3. Replace the generated keys from step 2
# 4. Create secure passwords for services

# === REQUIRED: Server Configuration ===
PROTOCOL=https
BASE_DOMAIN=yourdomain.com
SERVER_IP=your.server.ip

# === REQUIRED: n8n Credentials ===
N8N_ENCRYPTION_KEY=paste-generated-key-here
N8N_USER_MANAGEMENT_JWT_SECRET=paste-generated-key-here

# === REQUIRED: Database Password ===
POSTGRES_PASSWORD=create-a-strong-password-no-at-symbol

# === REQUIRED: Neo4j Authentication ===
NEO4J_AUTH=neo4j/create-a-strong-password
NEO4J_PASSWORD=same-password-as-above

# === REQUIRED: MinIO Object Storage ===
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minimum-8-characters

# === REQUIRED: Security Keys ===
NEXTAUTH_SECRET=paste-generated-key-here
ENCRYPTION_KEY=paste-generated-key-here
WEBUI_SECRET_KEY=paste-generated-key-here
JWT_SECRET_KEY=paste-generated-key-here
SESSION_SECRET=paste-generated-key-here

# === REQUIRED: Service Hostnames (auto-configured) ===
N8N_HOSTNAME=n8n.${BASE_DOMAIN}
WEBUI_HOSTNAME=chat.${BASE_DOMAIN}
NEO4J_HOSTNAME=neo4j.${BASE_DOMAIN}
NCA_HOSTNAME=nca.${BASE_DOMAIN}
MINIO_CONSOLE_HOSTNAME=minio-console.${BASE_DOMAIN}
MINIO_API_HOSTNAME=minio-api.${BASE_DOMAIN}
LETSENCRYPT_EMAIL=admin@${BASE_DOMAIN}

# === OPTIONAL: AI API Keys ===
# Uncomment and add keys to enable AI features
# OPENAI_API_KEY=your-openai-api-key-here
# ANTHROPIC_API_KEY=your-anthropic-api-key-here
```

**Pro tip**: Use `nano .env` or `vim .env` to edit. In nano, use Ctrl+O to save and Ctrl+X to exit.

### Step 4: Configure DNS

Before starting the services, configure your domain's DNS records:

1. **Create A records** for each service pointing to your server's IP:
   - `n8n.yourdomain.com` → Your Server IP
   - `chat.yourdomain.com` → Your Server IP
   - `neo4j.yourdomain.com` → Your Server IP
   - `nca.yourdomain.com` → Your Server IP
   - `minio-console.yourdomain.com` → Your Server IP
   - `minio-api.yourdomain.com` → Your Server IP

2. **Wait for DNS propagation** (usually 5-30 minutes)

### Step 5: Start the Services

1. **Navigate to the docker directory**:
```bash
cd docker
```

2. **Start all services**:
```bash
docker compose up -d
```

3. **Check service status**:
```bash
docker compose ps
```

All services should show as "running" or "healthy".

### Step 6: Run First-Time Setup

Initialize storage and import workflows:

```bash
# From the everyday-os root directory
./first-time-setup.sh
```

This script will:
- Create MinIO storage buckets for NCA Toolkit
- Import 18 pre-configured n8n workflows

Note: This only needs to be run once during initial setup.

### Step 7: Initial Service Access

1. **Wait for SSL certificates** (2-3 minutes after first start)
   - Caddy automatically obtains Let's Encrypt certificates

2. **Access your services**:
   - n8n: `https://n8n.yourdomain.com`
   - Open WebUI: `https://chat.yourdomain.com`
   - Neo4j Browser: `https://neo4j.yourdomain.com`
   - MinIO Console: `https://minio-console.yourdomain.com`

3. **First-time setup for each service**:
   - **n8n**: Create your admin account on first visit
   - **Open WebUI**: Create admin account (first user becomes admin)
   - **Neo4j**: Login with username `neo4j` and your configured password
   - **MinIO**: Login with `minioadmin` and your configured password

## 🔧 Post-Installation Configuration

### Configure n8n Workflows

1. Log in to n8n at `https://n8n.yourdomain.com`
2. You'll see 18 pre-imported workflows
3. For each workflow you want to use:
   - Click on the workflow to open it
   - Add required credentials (API keys, database connections, etc.)
   - Activate the workflow when ready

### Set Up Open WebUI

1. Access Open WebUI at `https://chat.yourdomain.com`
2. Create your admin account (first user)
3. Configure AI providers:
   - Go to Settings → Connections
   - Add your OpenAI/Anthropic API keys
   - Test the connections

### Configure Email (Optional but Recommended)

To enable password reset and email notifications in n8n:

1. Edit your `.env` file and uncomment the SMTP settings:
```bash
# Example for Gmail (requires app password)
N8N_SMTP_HOST=smtp.gmail.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=your-email@gmail.com
N8N_SMTP_PASS=your-app-password  # NOT your regular password!
N8N_SMTP_SENDER=your-email@gmail.com
N8N_SMTP_SSL=false
```

2. For Gmail users:
   - Enable 2-factor authentication
   - Generate an app password: https://support.google.com/accounts/answer/185833
   - Use the app password in N8N_SMTP_PASS

3. Restart n8n to apply changes:
```bash
cd docker && docker compose restart n8n
```

## 🛠️ Common Operations

### View logs
```bash
cd docker
docker compose logs -f [service-name]
```

### Restart a service
```bash
cd docker
docker compose restart [service-name]
```

### Stop all services
```bash
cd docker
docker compose down
```

### Update services
```bash
cd docker
docker compose pull
docker compose up -d
```

### Backup data
The data for all services is stored in Docker volumes. To backup:
```bash
# Backup all volumes
docker run --rm -v everyday-os_n8n_storage:/data -v $(pwd):/backup alpine tar czf /backup/n8n_backup.tar.gz -C /data .
```

## 🔒 Security Considerations

1. **Firewall Configuration**:
   - Only open ports 80 and 443
   - All other services communicate internally

2. **Regular Updates**:
   - Keep Docker and all images updated
   - Monitor service security announcements

3. **Backup Strategy**:
   - Regular backups of all Docker volumes
   - Test restore procedures

4. **API Key Security**:
   - Never commit `.env` file to git
   - Rotate keys periodically
   - Use strong, unique passwords

## 🚨 Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs [service-name]

# Verify environment variables
docker compose config
```

### SSL certificate issues
- Ensure DNS is properly configured
- Check Caddy logs: `docker compose logs caddy`
- Verify ports 80/443 are accessible

### n8n workflow import issues
- Run import manually: `cd docker && docker compose run --rm n8n-import`
- Check if workflows already exist in n8n

### Database connection issues
- Verify PostgreSQL is healthy: `docker compose ps postgres`
- Check credentials in `.env` match service configs

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Open WebUI Docs](https://docs.openwebui.com/)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [MinIO Documentation](https://docs.min.io/)
- [Caddy Documentation](https://caddyserver.com/docs/)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

[Your License Here]

## 🙏 Acknowledgments

- The n8n team for the amazing automation platform
- Open WebUI for the excellent AI interface
- All the open-source projects that make this possible