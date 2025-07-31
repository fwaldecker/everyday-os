#!/bin/bash
# Script to import n8n workflows and initialize MinIO for first-time setup

echo "==============================================="
echo "Everyday-OS First-Time Setup Tool"
echo "==============================================="
echo ""

# Check if we're in the right directory
if [ ! -f "docker/docker-compose.yml" ]; then
    echo "Error: This script must be run from the everyday-os root directory."
    echo "Please cd to the everyday-os directory and try again."
    exit 1
fi

cd docker

# Initialize MinIO buckets
echo "Step 1: Initializing MinIO storage buckets..."
echo "-----------------------------------------------"
docker compose run --rm minio-init
echo ""

# Import n8n workflows
echo "Step 2: Importing n8n workflows..."
echo "-----------------------------------------------"
echo "This will import 18 pre-configured workflows into your n8n instance."
docker compose run --rm n8n-import

echo ""
echo "==============================================="
echo "Setup complete!"
echo "==============================================="
echo ""
echo "✅ MinIO buckets created"
echo "✅ n8n workflows imported"
echo ""
echo "You can now access n8n at your configured URL and see all imported workflows."
echo "Remember to configure credentials for each workflow before activating them."