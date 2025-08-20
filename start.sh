#!/bin/bash
# Simple startup script for Everyday-OS

echo "Starting Everyday-OS services..."

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Start all services
docker-compose up -d

# Wait a moment for services to start
sleep 10

# Show service status
docker-compose ps

echo ""
echo "Services are starting up!"
echo "Access your services at:"
echo "  - n8n: https://n8n.${BASE_DOMAIN}"
echo "  - MinIO Console: https://minio-console.${BASE_DOMAIN}"
echo "  - NCA Toolkit: https://nca.${BASE_DOMAIN}"