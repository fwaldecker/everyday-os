#!/bin/bash

# Backup Script for Everyday-OS
# Creates timestamped backups of all data

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="../backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="everyday-os-backup-${TIMESTAMP}"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Everyday-OS Backup${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
mkdir -p "$BACKUP_PATH"

echo -e "${YELLOW}Starting backup to: $BACKUP_PATH${NC}"
echo ""

# Function to backup a volume
backup_volume() {
    local volume=$1
    local name=$2
    
    echo -n "Backing up $name... "
    
    if docker volume ls --format "{{.Name}}" | grep -q "^$volume$"; then
        docker run --rm \
            -v $volume:/data:ro \
            -v "$PWD/$BACKUP_PATH":/backup \
            alpine tar czf /backup/${name}.tar.gz -C /data . 2>/dev/null
        
        if [ $? -eq 0 ]; then
            size=$(du -h "$BACKUP_PATH/${name}.tar.gz" | cut -f1)
            echo -e "${GREEN}✓${NC} ($size)"
        else
            echo -e "${RED}✗ Failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Volume not found${NC}"
    fi
}

# Backup n8n workflows via API
echo -n "Exporting n8n workflows... "
if docker exec everydayos_n8n n8n export:workflow --all --output=/tmp/workflows.json 2>/dev/null; then
    docker cp everydayos_n8n:/tmp/workflows.json "$BACKUP_PATH/n8n-workflows.json" 2>/dev/null
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ Could not export workflows${NC}"
fi

# Backup PostgreSQL database
echo -n "Backing up PostgreSQL database... "
if docker exec everydayos_postgres pg_dumpall -U postgres > "$BACKUP_PATH/postgres-dump.sql" 2>/dev/null; then
    gzip "$BACKUP_PATH/postgres-dump.sql"
    size=$(du -h "$BACKUP_PATH/postgres-dump.sql.gz" | cut -f1)
    echo -e "${GREEN}✓${NC} ($size)"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Backup Docker volumes
echo -e "${YELLOW}Backing up Docker volumes:${NC}"

backup_volume "docker_n8n_storage" "n8n-data"
backup_volume "docker_postgres_data" "postgres-data"
backup_volume "everydayos_minio_data" "minio-data"
backup_volume "everydayos_caddy_data" "caddy-data"
backup_volume "everydayos_valkey_data" "redis-data"

# Backup configuration files
echo -n "Backing up configuration files... "
cp ../.env "$BACKUP_PATH/.env" 2>/dev/null || true
cp ../docker-compose.yml "$BACKUP_PATH/docker-compose.yml" 2>/dev/null || true
cp ../Caddyfile "$BACKUP_PATH/Caddyfile" 2>/dev/null || true
echo -e "${GREEN}✓${NC}"

# Create backup manifest
echo -n "Creating backup manifest... "
cat > "$BACKUP_PATH/manifest.json" << EOF
{
    "timestamp": "$TIMESTAMP",
    "date": "$(date)",
    "version": "1.0",
    "services": {
        "n8n": "$(docker exec everydayos_n8n n8n --version 2>/dev/null || echo 'unknown')",
        "postgres": "17-alpine",
        "minio": "latest"
    },
    "volumes": [
        "n8n-data.tar.gz",
        "postgres-data.tar.gz",
        "minio-data.tar.gz",
        "caddy-data.tar.gz",
        "redis-data.tar.gz"
    ]
}
EOF
echo -e "${GREEN}✓${NC}"

# Create compressed archive
echo -n "Creating compressed archive... "
cd "$BACKUP_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
cd - >/dev/null

archive_size=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}✓${NC} ($archive_size)"

# Clean up uncompressed backup
rm -rf "$BACKUP_PATH"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    Backup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Backup saved to: ${BLUE}$BACKUP_DIR/${BACKUP_NAME}.tar.gz${NC}"
echo -e "Size: ${archive_size}"
echo ""
echo -e "${YELLOW}To restore from this backup:${NC}"
echo -e "  ./restore.sh $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo ""
echo -e "${YELLOW}Tip:${NC} Copy this backup to a safe location!"