# Everyday‑OS • Tasks

## ✅ Done
- [x] 2025‑07‑02 | Custom n8n workflows and tools are present in the repo.
- [x] 2025‑07‑02 | Created Dockerfile for NCA Toolkit in docker/nca-toolkit/
- [x] 2025‑07‑02 | Updated docker-compose.yml with pinned versions, healthchecks, and new services
- [x] 2025‑07‑02 | Created credentials template and updated .gitignore for security
- [x] 2025‑07‑02 | Added credentials documentation to README.md

## 🔜 Next

### 1. Repository House-Keeping
- [x] De-initialized the current `supabase` submodule with `git submodule deinit -f supabase`.
- [x] Removed the cached `supabase` submodule with `git rm --cached supabase`.
- [x] Added the correct submodule: `git submodule add https://github.com/fwaldecker/everyday-supabase supabase`.
- [x] Removed unused service directories: `rm -rf ollama`.
- [x] Tidied the directory structure: `mkdir docker` and `mv docker-compose*.yml docker/`.
- [x] Created a new directory `docker/nca-toolkit`.
- [x] Created `Dockerfile` that clones `https://github.com/stephengpope/no-code-architects-toolkit`, installs dependencies, and starts on port 8010.
- [x] 2025-07-02 | Added and configured the `nca-toolkit` service with proper environment variables and health checks.
- [ ] Ensure all running services have `restart: unless-stopped`.
- [ ] Update the `n8n-import` service command to use the correct credentials path: `n8n import:credentials --separate --input=/backup/credentials.json`.
- [ ] Verify volume mounts for persistent data.
- [ ] Add proper logging configuration to all services.

### 2. Dockerfile Creation
- [x] Created a new directory `docker/nca-toolkit`.
- [x] Created `Dockerfile` that clones `https://github.com/stephengpope/no-code-architects-toolkit`, installs dependencies, and starts on port 8010.

### 3. Docker Compose Configuration (`docker/docker-compose.yml`)
- [x] 2025-07-02 | Removed the `ollama-*` service blocks from the `docker-compose.yml` file.
- [x] 2025-07-02 | Pinned n8n images to version 1.49.1
- [x] 2025-07-02 | Pinned caddy image to 2.8.4-alpine and added healthcheck
- [x] 2025-07-02 | Commented out flowise service
- [x] 2025-07-02 | Added health checks to core services (n8n, MinIO, NCA Toolkit, Langfuse, Neo4j)
- [x] 2025-07-02 | Configured MinIO with proper volume mounts and lifecycle policies
- [x] 2025-07-02 | Updated n8n-import command to use credentials.json
- [x] 2025-07-02 | Added restart: unless-stopped to services
- [x] 2025-07-02 | Enhanced Neo4j configuration with proper security, performance, and health checks
- [x] 2025-07-02 | Added resource limits to critical services
- [x] 2025-07-02 | Added health checks to Supabase services (analytics, kong, supavisor, rest, auth, storage)
- [x] 2025-07-02 | Added resource limits to Supabase services
- [x] 2025-07-02 | Configured GoTrue (authentication service) with proper environment variables
- [x] 2025-07-02 | Configured proper volume mounts for all persistent data
- [x] 2025-07-02 | **Verified and enhanced configurations for `open-webui` and `searxng`**
  - Added health checks, resource limits, and security settings
  - Configured persistent storage and logging
  - Set up environment variables and performance tuning
- [x] 2025-07-02 | Verified sensitive data management in `.env.example`
  - All sensitive values are properly documented and managed via environment variables
  - Added secure defaults and instructions for generating secure values
  - Included all necessary configuration options for all services
- [x] 2025-07-02 | Added `minio:latest` service with proper configuration and healthcheck
- [x] 2025-07-02 | Added `nca-toolkit` service with build context
- [x] 2025-07-02 | Ensured all running services have `restart: unless-stopped`
- [x] 2025-07-02 | Updated `n8n-import` service command to use credentials.json
- [x] 2025-07-02 | **Enhanced Caddyfile configuration**
  - Added security headers and SSL/TLS settings for all services
  - Configured reverse proxies for all services with proper headers
  - Added support for MinIO Console and API endpoints
  - Enabled compression and caching where appropriate
  - Added detailed logging configuration

- [x] 2025-07-02 | **Updated service management scripts**
  - Completely rewrote `start_services.py` for better reliability and maintainability
  - Added proper error handling and logging
  - Implemented service health checks
  - Added support for different environments (development/production)
  - Improved SearXNG configuration management
  - Added proper cleanup and reset functionality
  - Enhanced security with proper file permissions
  - Added comprehensive status reporting

### 4. Environment & Initialization
- [x] Created `n8n/backup/credentials.template.json` with placeholders for all required services
- [x] Added `n8n/backup/credentials.json` to .gitignore
- [x] Created `minio-init.sh` script in the `docker` directory to apply a 7-day expiry policy to all buckets
- [x] Updated `start_services.py` to remove ollama profiles and start the updated stack
- [x] Updated `.env.example` with all required environment variables for all services
- [x] Made `minio-init.sh` executable
- [x] Added MinIO bucket initialization to service startup

### 5. Testing & Validation
- [ ] Test the full stack startup with `./start_services.py`
- [ ] Verify all services are accessible and healthy
- [ ] Test MinIO bucket creation and lifecycle policies
- [ ] Verify NCA Toolkit is accessible and functional
- [ ] Test n8n workflows that depend on the updated services

### 6. Domain & DNS Configuration
- [x] Updated Caddy configuration to handle subdomains with SSL
- [x] Created Caddyfile for routing subdomains
- [x] Updated docker-compose.yml with domain configuration
- [x] Added DNS setup instructions to README.md
- [x] Removed all localhost references from configurations
- [x] Updated service URLs to use domain-based addressing
- [ ] Test DNS resolution and SSL certificate generation
- [ ] Document any required firewall configurations
- [ ] Verify all services are accessible via their domain names

### 7. Documentation
- [x] Updated README.md with domain and DNS setup instructions
- [x] Documented service endpoints and access URLs
- [x] Added DNS record requirements
- [ ] Add troubleshooting section for common DNS/SSL issues
- [ ] Document backup and restore procedures

### 8. VPS Deployment
- [ ] Set up VPS on Hostinger
- [ ] Configure DNS records (A records for all subdomains)
- [ ] Set up firewall (UFW or similar)
- [ ] Configure automatic SSL certificate renewal
- [ ] Set up monitoring and alerts
- [ ] Configure automated backups

### 9. Testing
- [ ] Test all service endpoints after deployment
- [ ] Verify SSL certificates are working correctly
- [ ] Test inter-service communication
- [ ] Verify health checks are working

### 7. CI/CD Pipeline (Optional)
- [ ] Create GitHub Actions workflow for linting and testing
- [ ] Add automated Docker image builds
- [ ] Set up deployment to staging/production environments

## 🧩 Discovered During Work
- [ ] Create a CI pipeline for linting and building Docker images.