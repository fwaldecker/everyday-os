# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains two integrated platforms:
1. **Everyday-OS**: Self-hosted AI and automation platform with 10+ containerized services
2. **Mixpost**: Social media management platform built with Laravel and Vue.js

## Essential Commands

### Docker Services Management
```bash
# Start all services
cd /root/everyday-os/docker && docker compose up -d

# Check service status
docker compose ps

# View logs for specific service
docker compose logs -f [service-name]  # Services: n8n, open-webui, neo4j, minio, etc.

# Restart a service
docker compose restart [service-name]

# First-time setup (run from everyday-os directory)
./first-time-setup.sh
```

### Mixpost Development
```bash
cd /root/mixpost

# Frontend development
npm run dev        # Start Vite dev server with hot reload
npm run build      # Production build

# Testing & Quality
composer test      # Run PHPUnit/Pest test suite
composer analyse   # Run PHPStan static analysis
composer format    # Format code with Laravel Pint

# Laravel commands
php artisan migrate
php artisan queue:work
```

### NCA Toolkit Development
```bash
cd /root/everyday-os/docker/nca-toolkit
./local.sh  # Start local development server
```

## Architecture & Service Communication

### Service Topology
- **Reverse Proxy**: Caddy handles all HTTPS traffic and SSL certificates
- **Internal Network**: Services communicate via `everyday-os_default` Docker network
- **Databases**: PostgreSQL (n8n, Open WebUI), Neo4j (graph), MySQL (Mixpost), Redis/Valkey (cache)
- **Storage**: MinIO provides S3-compatible object storage

### Service URLs (configured in Caddyfile)
- n8n automation: `https://n8n.{domain}`
- Open WebUI: `https://chat.{domain}`
- Neo4j Browser: `https://neo4j.{domain}`
- MinIO Console: `https://minio-console.{domain}`
- Mixpost: `https://social.{domain}`

### Key Integration Points
1. **n8n Workflows**: Located in `/root/everyday-os/n8n-workflows/`, 18 pre-built workflows integrate with various services
2. **Environment Configuration**: Each service has `.env` files in `/root/everyday-os/docker/`
3. **Caddy Configuration**: `/root/everyday-os/Caddyfile` manages all routing and SSL
4. **Docker Compose**: `/root/everyday-os/docker/docker-compose.yml` orchestrates all services

## Mixpost Structure

### Backend (Laravel)
- **Package Source**: `/root/mixpost/src/` - Core Laravel package code
- **Database**: `/root/mixpost/database/` - Migrations and factories
- **API Routes**: `/root/mixpost/routes/` - RESTful API endpoints
- **Service Providers**: `/root/mixpost/src/Providers/` - Laravel service registration

### Frontend (Vue.js/Inertia)
- **Components**: `/root/mixpost/resources/js/Components/` - Reusable Vue components
- **Pages**: `/root/mixpost/resources/js/Pages/` - Inertia page components
- **Composables**: `/root/mixpost/resources/js/Composables/` - Vue composition API utilities
- **Build Config**: `/root/mixpost/vite.config.js` - Vite bundler configuration

## Testing Approach

### Mixpost Tests
```bash
# Run all tests
composer test

# Run specific test file
./vendor/bin/pest tests/Feature/SomeTest.php

# Run with coverage
composer test -- --coverage
```

### Service Health Checks
```bash
# Check all services are running
docker compose ps

# Test service connectivity
curl -I https://n8n.{domain}
curl -I https://chat.{domain}
```

## Common Development Tasks

### Adding New n8n Workflow
1. Export workflow from n8n UI as JSON
2. Place in `/root/everyday-os/n8n-workflows/`
3. Import via n8n UI or API

### Modifying Caddy Routes
1. Edit `/root/everyday-os/Caddyfile`
2. Restart Caddy: `docker compose restart caddy`

### Updating Service Configuration
1. Edit relevant `.env` file in `/root/everyday-os/docker/`
2. Restart service: `docker compose restart [service-name]`

### Database Access
```bash
# PostgreSQL (n8n database)
docker exec -it postgres psql -U everydayos -d n8n

# MySQL (Mixpost database)
docker exec -it mysql mysql -u root -p mixpost

# Neo4j
# Access via browser at https://neo4j.{domain}
```

## Security Considerations

- All services run behind Caddy reverse proxy with automatic SSL
- Internal services not exposed directly to internet
- Credentials stored in `.env` files (not committed to git)
- Security headers configured in Caddyfile (CSP, HSTS, etc.)
- Docker network isolation between services