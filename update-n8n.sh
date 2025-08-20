#!/bin/bash

# Safe n8n Update Script
# This script safely updates n8n without touching PostgreSQL or volumes

set -e  # Exit on error

echo "========================================="
echo "Safe n8n Update Script"
echo "========================================="

# Change to the docker directory
cd /root/everyday-os/docker

# Step 1: Backup workflows
echo "Step 1: Backing up workflows..."
BACKUP_FILE="/root/everyday-os/n8n-backup-$(date +%Y%m%d-%H%M%S).json"
docker exec everydayos_n8n n8n export:workflow --all --output=/tmp/backup.json 2>/dev/null || echo "Note: Backup warnings can be ignored"
docker cp everydayos_n8n:/tmp/backup.json "$BACKUP_FILE"
echo "✅ Workflows backed up to: $BACKUP_FILE"

# Step 2: Check current version
echo ""
echo "Step 2: Checking current n8n version..."
CURRENT_VERSION=$(docker exec everydayos_n8n n8n --version 2>/dev/null || echo "unknown")
echo "Current version: $CURRENT_VERSION"

# Step 3: Pull latest n8n image
echo ""
echo "Step 3: Pulling latest n8n image..."
docker pull n8nio/n8n:latest

# Step 4: Stop n8n (NOT PostgreSQL!)
echo ""
echo "Step 4: Stopping n8n container..."
docker compose stop n8n

# Step 5: Start n8n with new image
echo ""
echo "Step 5: Starting n8n with new image..."
docker compose up -d n8n

# Step 6: Wait for n8n to be healthy
echo ""
echo "Step 6: Waiting for n8n to be healthy..."
for i in {1..30}; do
    if docker exec everydayos_n8n wget -q -O- http://localhost:5678/healthz 2>/dev/null | grep -q "ok"; then
        echo "✅ n8n is healthy!"
        break
    fi
    echo -n "."
    sleep 2
done

# Step 7: Verify new version
echo ""
echo "Step 7: Verifying update..."
NEW_VERSION=$(docker exec everydayos_n8n n8n --version 2>/dev/null || echo "unknown")
echo "New version: $NEW_VERSION"

# Step 8: Verify user data
echo ""
echo "Step 8: Verifying user data..."
USER_COUNT=$(docker exec everydayos_postgres psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM public.user;" 2>/dev/null | tr -d ' ')
WORKFLOW_COUNT=$(docker exec everydayos_postgres psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM public.workflow_entity;" 2>/dev/null | tr -d ' ')
echo "✅ Users in database: $USER_COUNT"
echo "✅ Workflows in database: $WORKFLOW_COUNT"

echo ""
echo "========================================="
echo "✅ n8n Update Complete!"
echo "========================================="
echo "Version: $CURRENT_VERSION → $NEW_VERSION"
echo "Backup saved to: $BACKUP_FILE"
echo ""
echo "You can now access n8n at: https://n8n.${BASE_DOMAIN:-yourdomain.com}"
echo ""
echo "If you encounter any issues, restore with:"
echo "docker exec everydayos_n8n n8n import:workflow --input=/tmp/backup.json"