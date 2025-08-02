# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Everyday-OS is a self-hosted AI and automation platform built with Docker Compose that combines:
- **n8n** for workflow automation with 400+ integrations
- **Open WebUI** for AI chat interfaces (OpenAI/Anthropic)
- **NCA Toolkit** for document processing and media operations
- **MinIO** for S3-compatible object storage
- **PostgreSQL**, **Neo4j**, **Qdrant**, and **Redis** for data storage
- **Caddy** for reverse proxy with automatic HTTPS

## Key Commands

### Service Management
```bash
# Start all services
cd docker && docker compose up -d

# Stop all services
cd docker && docker compose down

# View service status
cd docker && docker compose ps

# View logs (all services or specific)
cd docker && docker compose logs -f [service-name]

# Restart a specific service
cd docker && docker compose restart [service-name]

# Update services
cd docker && docker compose pull && docker compose up -d
```

### First-Time Setup
```bash
# Run after initial deployment to initialize storage and import workflows
./first-time-setup.sh
```

### Service-Specific Operations
```bash
# Import n8n workflows manually
cd docker && docker compose run --rm n8n-import

# Initialize MinIO buckets
cd docker && docker compose run --rm minio-init

# Enter a container for debugging
cd docker && docker compose exec [service-name] bash
```

### Health Checks
```bash
# Check all service health
cd docker && docker compose ps

# Check specific service logs for errors
cd docker && docker compose logs [service-name] | grep -i error
```

## Architecture Overview

### Service Dependencies
```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Caddy     │────▶│  Services    │────▶│  Databases   │
│  (Proxy)    │     │              │     │              │
└─────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │
       ▼                    ▼                     ▼
  - Port 80/443      - n8n:5678           - PostgreSQL:5432
  - Auto HTTPS       - Open WebUI:8080     - Neo4j:7474/7687
  - Domain routing   - NCA:8080            - Qdrant:6333
                     - MinIO:9000/9001     - Redis:6379
```

### Data Flow
1. **Caddy** receives HTTPS requests and routes to services based on subdomain
2. **Services** authenticate requests and process data
3. **Databases** store persistent data in Docker volumes
4. **MinIO** handles file/media storage with S3-compatible API

### Key Configuration Files
- `.env` - Main environment configuration (must be copied to `docker/.env`)
- `docker/docker-compose.yml` - Service definitions and orchestration
- `Caddyfile` - Reverse proxy routing and SSL configuration
- `docker/nca-toolkit/` - NCA Toolkit application (built as Docker image)

## Service Access URLs

When deployed, services are available at:
- n8n: `https://n8n.{BASE_DOMAIN}`
- Open WebUI: `https://chat.{BASE_DOMAIN}`
- Neo4j Browser: `https://neo4j.{BASE_DOMAIN}`
- MinIO Console: `https://minio-console.{BASE_DOMAIN}`
- NCA Toolkit API: `https://nca.{BASE_DOMAIN}`

## Critical Environment Variables

### Required for All Deployments
- `BASE_DOMAIN` - Your domain name (e.g., example.com)
- `PROTOCOL` - Should be "https" for production
- `SERVER_IP` - Your server's public IP address
- `POSTGRES_PASSWORD` - Database password (no @ symbols)
- `N8N_ENCRYPTION_KEY` - 32-byte hex string for n8n data encryption
- `N8N_USER_MANAGEMENT_JWT_SECRET` - 32-byte hex string for n8n auth
- `NEO4J_AUTH` - Format: `neo4j/your-password`
- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` - MinIO credentials
- `WEBUI_SECRET_KEY`, `JWT_SECRET_KEY`, `SESSION_SECRET` - Security keys

### API Keys (Optional but Recommended)
- `OPENAI_API_KEY` - For OpenAI integration
- `ANTHROPIC_API_KEY` - For Claude integration
- `NCA_API_KEY` - For NCA Toolkit authentication

## Common Development Tasks

### Adding a New Service
1. Define service in `docker/docker-compose.yml`
2. Add necessary environment variables to `.env.example`
3. Update Caddyfile if external access needed
4. Document service in README.md
5. Add health check configuration
6. Update backup scripts if data persistence needed

### Debugging Service Issues
1. Check service logs: `docker compose logs -f [service-name]`
2. Verify environment variables are set correctly
3. Check service health status in docker compose ps
4. Ensure required ports are not already in use
5. Verify DNS records for production deployments
6. Check Caddy logs for SSL/routing issues

### Working with NCA Toolkit
- API endpoint: `https://nca.{BASE_DOMAIN}/v1/`
- Requires `X-API-Key` header for authentication
- Extensive documentation in `docker/nca-toolkit/docs/`
- Media processing workflows use MinIO for storage
- Test endpoint: `/v1/toolkit/authenticate`

### n8n Workflow Management
- 18 pre-built workflows imported on first setup
- Workflows stored in `n8n-workflows/` directory
- Each workflow requires credential configuration
- Access workflow editor at n8n subdomain
- Webhook URLs follow pattern: `https://n8n.{BASE_DOMAIN}/webhook/...`

## Security Considerations

- Never commit `.env` files or expose secrets
- All inter-service communication happens on Docker network
- Only ports 80/443 should be exposed publicly
- Use strong, unique passwords for all services
- Rotate API keys and secrets periodically
- Enable 2FA where available (especially n8n)
- Monitor service logs for suspicious activity

## Performance Optimization

- Services have resource limits defined in docker-compose.yml
- Adjust memory/CPU limits based on workload
- PostgreSQL is shared between n8n and Open WebUI
- MinIO uses lifecycle policies for automatic cleanup
- Redis handles caching and session storage
- Monitor disk usage for Docker volumes