#!/bin/bash

# Everyday-OS Setup Script
# This script sets up the complete Everyday-OS platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ASCII Banner
echo -e "${BLUE}"
cat << "EOF"
 _____                        _               ___  ____  
| ____|_   _____ _ __ _   _  | |_ __ _ _   _ / _ \/ ___| 
|  _| \ \ / / _ \ '__| | | | | __/ _` | | | | | | \___ \ 
| |___ \ V /  __/ |  | |_| | | || (_| | |_| | |_| |___) |
|_____| \_/ \___|_|   \__, |  \__\__,_|\__, |\___/|____/ 
                      |___/             |___/             
EOF
echo -e "${NC}"
echo -e "${GREEN}Welcome to Everyday-OS Setup!${NC}"
echo -e "This script will set up n8n, NCA Toolkit, and MinIO with automatic HTTPS."
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command_exists docker compose && ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose are installed${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file...${NC}"
    
    # Prompt for required values
    read -p "Enter your domain name (e.g., example.com): " BASE_DOMAIN
    read -p "Enter your email for SSL certificates: " LETSENCRYPT_EMAIL
    
    # Generate secure passwords
    POSTGRES_PASSWORD=$(generate_password)
    N8N_ENCRYPTION_KEY=$(generate_password)
    N8N_JWT_SECRET=$(generate_password)
    MINIO_ROOT_PASSWORD=$(generate_password)
    NCA_API_KEY=$(generate_password)
    
    # Create .env file
    cat > .env << EOL
# Domain Configuration
BASE_DOMAIN=${BASE_DOMAIN}
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}

# Database
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# n8n Configuration
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_JWT_SECRET}

# MinIO Configuration
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

# NCA Toolkit
NCA_API_KEY=${NCA_API_KEY}

# Optional: AI API Keys (add your own)
# OPENAI_API_KEY=your-openai-key
# ANTHROPIC_API_KEY=your-anthropic-key
EOL
    
    echo -e "${GREEN}✓ Created .env file with secure passwords${NC}"
    echo -e "${YELLOW}Important: Save these credentials in a password manager!${NC}"
    echo ""
    echo "MinIO Password: ${MINIO_ROOT_PASSWORD}"
    echo "NCA API Key: ${NCA_API_KEY}"
    echo ""
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
    source .env
fi

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p docker/nca-toolkit/data
mkdir -p n8n-workflows
mkdir -p backups

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo -e "${RED}Error: docker-compose.yml not found!${NC}"
    exit 1
fi

# Validate environment variables
echo -e "${YELLOW}Validating configuration...${NC}"

if [ -z "$BASE_DOMAIN" ]; then
    echo -e "${RED}Error: BASE_DOMAIN not set in .env${NC}"
    exit 1
fi

if [ -z "$LETSENCRYPT_EMAIL" ]; then
    echo -e "${RED}Error: LETSENCRYPT_EMAIL not set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration validated${NC}"

# Check ports
echo -e "${YELLOW}Checking port availability...${NC}"

for port in 80 443; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}Error: Port $port is already in use${NC}"
        echo "Please stop the service using port $port or use a different port"
        exit 1
    fi
done

echo -e "${GREEN}✓ Ports 80 and 443 are available${NC}"

# Fix Docker Compose volumes (mark as external if they exist)
echo -e "${YELLOW}Checking Docker volumes...${NC}"

if docker volume ls | grep -q "docker_n8n_storage"; then
    echo -e "${YELLOW}Found existing n8n data volume${NC}"
    # Update docker-compose to use external volumes
    sed -i 's/name: docker_n8n_storage$/name: docker_n8n_storage\n    external: true/' docker-compose.yml 2>/dev/null || true
fi

if docker volume ls | grep -q "docker_postgres_data"; then
    echo -e "${YELLOW}Found existing PostgreSQL data volume${NC}"
    sed -i 's/name: docker_postgres_data$/name: docker_postgres_data\n    external: true/' docker-compose.yml 2>/dev/null || true
fi

# Start services
echo -e "${YELLOW}Starting services...${NC}"
echo "This may take a few minutes on first run..."

# Start core services first
docker compose up -d postgres
echo -e "${GREEN}✓ PostgreSQL started${NC}"

sleep 5

docker compose up -d n8n minio valkey
echo -e "${GREEN}✓ n8n, MinIO, and Redis started${NC}"

sleep 5

docker compose up -d caddy
echo -e "${GREEN}✓ Caddy reverse proxy started${NC}"

# Optional: Start NCA Toolkit if not building
if [ "$SKIP_NCA" != "true" ]; then
    echo -e "${YELLOW}Building NCA Toolkit (this may take 5-10 minutes)...${NC}"
    docker compose up -d nca-toolkit || echo -e "${YELLOW}NCA Toolkit build failed (optional service)${NC}"
fi

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be healthy...${NC}"

for i in {1..30}; do
    if curl -sf http://localhost:5678/healthz >/dev/null 2>&1; then
        echo -e "${GREEN}✓ n8n is healthy${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Final status check
echo ""
echo -e "${YELLOW}Checking service status...${NC}"
docker compose ps

# Success message
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    Everyday-OS Setup Complete! 🎉${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Access your services at:${NC}"
echo -e "  n8n:           ${GREEN}https://n8n.${BASE_DOMAIN}${NC}"
echo -e "  MinIO Console: ${GREEN}https://minio-console.${BASE_DOMAIN}${NC}"
echo -e "  NCA Toolkit:   ${GREEN}https://nca.${BASE_DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Visit https://n8n.${BASE_DOMAIN} to set up your n8n account"
echo -e "  2. MinIO login: admin / (check .env for password)"
echo -e "  3. Import workflows from n8n-workflows/ folder"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  View logs:       docker compose logs -f"
echo -e "  Stop services:   docker compose down"
echo -e "  Update n8n:      ./update-n8n.sh"
echo -e "  Backup data:     ./scripts/backup.sh"
echo ""
echo -e "${GREEN}Documentation: https://github.com/yourusername/everyday-os${NC}"