# Everyday-OS: Self-hosted AI and Automation Platform

Everyday-OS is a comprehensive, self-hosted platform that combines powerful AI tools with automation capabilities. Built with Docker Compose, it provides a complete ecosystem for workflow automation, data processing, and AI operations.

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/everyday-os.git
cd everyday-os

# 2. Configure your environment
cp .env.example .env
# Edit .env with your domain and secure passwords

# 3. Start all services
python start_services.py
```

That's it! Your n8n workflows will be automatically imported on first run.

## 🎯 Key Features

- **n8n Workflow Automation** - Visual workflow builder with 400+ integrations
- **NCA Toolkit** - Advanced document and video processing
- **MinIO Storage** - S3-compatible object storage
- **Automatic Workflow Import** - 18+ pre-built n8n workflows
- **Domain-based Access** - Professional URLs with automatic SSL
- **Production Ready** - Secure, scalable configuration

## 📦 Included Services

| Service | Purpose | Access URL |
|---------|---------|------------|
| [n8n](https://n8n.io/) | Workflow automation | `https://n8n.yourdomain.com` |
| [NCA Toolkit](https://github.com/coleam00/nca-toolkit) | Document processing | `https://nca.yourdomain.com` |
| [MinIO](https://min.io/) | Object storage | `https://minio-console.yourdomain.com` |
| [PostgreSQL](https://www.postgresql.org/) | Database | Internal only |
| [Valkey/Redis](https://valkey.io/) | Cache | Internal only |
| [Caddy](https://caddyserver.com/) | Reverse proxy & SSL | Handles all HTTPS |

## 🔧 Pre-configured n8n Workflows

Your Everyday-OS comes with 18+ professional n8n workflows that are **automatically imported** on first startup:

- **Everyday Creator** - Content creation automation
- **Everyday Copywriter** - AI-powered copywriting
- **Everyday Brain Live** - Knowledge management
- **Crop & Caption Production** - Media processing
- **RAG Ingestion** - Document processing for AI
- Plus many more automation templates!

All workflows are imported automatically when you first start the services.

## 📋 Prerequisites

- Docker 20.10+ and Docker Compose v2.0+
- Python 3.8+
- A domain name with DNS configured
- 4GB RAM minimum (8GB recommended)
- 20GB disk space

## 🔧 Installation

### 1. Install Docker (if needed)

```bash
# Quick Docker install
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Log out and back in for group changes
```

### 2. Clone and Configure

```bash
# Clone the repository
git clone https://github.com/yourusername/everyday-os.git
cd everyday-os

# Set up environment
cp .env.example .env
```

### 3. Edit .env file

Open `.env` and configure:
- `BASE_DOMAIN` - Your domain (e.g., example.com)
- `LETSENCRYPT_EMAIL` - Your email for SSL certificates
- Generate secure passwords for all services (use commands in .env.example)

### 4. Start Services

```bash
python start_services.py
```

That's it! Services will start and n8n workflows will be imported automatically.

## 🌐 Accessing Your Services

After startup, your services will be available at:
- n8n: `https://n8n.yourdomain.com`
- MinIO Console: `https://minio-console.yourdomain.com`
- NCA Toolkit: `https://nca.yourdomain.com`

## 🔄 Managing Services

```bash
# View service status
docker compose ps

# View logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]

# Stop all services
docker compose down

# Update and restart
docker compose pull
docker compose up -d
```

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
- Workflows are imported automatically on first run
- Check if workflows already exist in n8n UI
- View import logs: `docker compose logs n8n-import`

### Database connection issues
- Verify PostgreSQL is healthy: `docker compose ps postgres`
- Check credentials in `.env` match service configs

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [MinIO Documentation](https://docs.min.io/)
- [NCA Toolkit](https://github.com/coleam00/nca-toolkit)
- [Caddy Documentation](https://caddyserver.com/docs/)

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details