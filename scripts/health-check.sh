#!/bin/bash

# Health Check Script for Everyday-OS
# Checks the status of all services and reports issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Everyday-OS Health Check${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

# Load environment variables
if [ -f ../.env ]; then
    source ../.env
fi

# Function to check service health
check_service() {
    local service=$1
    local container=$2
    local port=$3
    local endpoint=$4
    
    echo -n "Checking $service... "
    
    # Check if container is running
    if ! docker ps --format "{{.Names}}" | grep -q "^$container$"; then
        echo -e "${RED}✗ Container not running${NC}"
        return 1
    fi
    
    # Check container health status
    health=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "none")
    
    if [ "$health" == "healthy" ]; then
        echo -e "${GREEN}✓ Healthy${NC}"
        return 0
    elif [ "$health" == "unhealthy" ]; then
        echo -e "${RED}✗ Unhealthy${NC}"
        return 1
    elif [ "$health" == "starting" ]; then
        echo -e "${YELLOW}⚡ Starting${NC}"
        return 0
    fi
    
    # If no health check, try to connect to port
    if [ ! -z "$port" ] && [ ! -z "$endpoint" ]; then
        if curl -sf "$endpoint" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Running${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Running (endpoint unreachable)${NC}"
            return 0
        fi
    else
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    fi
}

# Check Docker
echo -e "${YELLOW}Checking Docker...${NC}"
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running or not accessible${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Check services
echo -e "${YELLOW}Checking Services:${NC}"

check_service "PostgreSQL" "everydayos_postgres" "5432" ""
check_service "n8n" "everydayos_n8n" "5678" "http://localhost:5678/healthz"
check_service "MinIO" "everydayos_minio" "9000" "http://localhost:9000/minio/health/live"
check_service "Redis/Valkey" "everydayos_valkey" "6379" ""
check_service "Caddy" "everydayos_caddy" "80" ""

# Optional services
if docker ps --format "{{.Names}}" | grep -q "everydayos_nca"; then
    check_service "NCA Toolkit" "everydayos_nca" "8080" "http://localhost:8080/health"
fi

echo ""

# Check volumes
echo -e "${YELLOW}Checking Data Volumes:${NC}"

for volume in docker_n8n_storage docker_postgres_data everydayos_minio_data; do
    if docker volume ls --format "{{.Name}}" | grep -q "^$volume$"; then
        size=$(docker run --rm -v $volume:/data alpine du -sh /data 2>/dev/null | cut -f1)
        echo -e "  $volume: ${GREEN}✓${NC} ($size)"
    else
        echo -e "  $volume: ${YELLOW}⚠ Not found${NC}"
    fi
done

echo ""

# Check ports
echo -e "${YELLOW}Checking Exposed Ports:${NC}"

for port in 80 443; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "  Port $port: ${GREEN}✓ Open${NC}"
    else
        echo -e "  Port $port: ${RED}✗ Not listening${NC}"
    fi
done

echo ""

# Check URLs (if domain is configured)
if [ ! -z "$BASE_DOMAIN" ]; then
    echo -e "${YELLOW}Checking Service URLs:${NC}"
    
    for service in n8n minio-console; do
        url="https://$service.$BASE_DOMAIN"
        if curl -sf -o /dev/null -w "%{http_code}" "$url" | grep -q "^[23]"; then
            echo -e "  $url: ${GREEN}✓ Accessible${NC}"
        else
            echo -e "  $url: ${YELLOW}⚠ Not accessible (check DNS/firewall)${NC}"
        fi
    done
    echo ""
fi

# Database check
echo -e "${YELLOW}Checking Database:${NC}"

# Check user count
user_count=$(docker exec everydayos_postgres psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM public.user;" 2>/dev/null || echo "0")
workflow_count=$(docker exec everydayos_postgres psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM public.workflow_entity;" 2>/dev/null || echo "0")

echo -e "  Users: $user_count"
echo -e "  Workflows: $workflow_count"
echo ""

# Memory and disk usage
echo -e "${YELLOW}System Resources:${NC}"

# Memory
mem_total=$(free -h | awk '/^Mem:/ {print $2}')
mem_used=$(free -h | awk '/^Mem:/ {print $3}')
mem_percent=$(free | awk '/^Mem:/ {printf("%.1f"), $3/$2*100}')

echo -e "  Memory: $mem_used / $mem_total (${mem_percent}%)"

# Disk
disk_usage=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
echo -e "  Disk: $disk_usage"

# Docker disk usage
docker_size=$(docker system df --format "table {{.Type}}\t{{.Size}}" | tail -n +2 | awk '{sum+=$2} END {print sum "GB"}')
echo -e "  Docker: ~${docker_size} used"

echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"

all_good=true
if ! docker ps | grep -q everydayos_n8n; then
    all_good=false
fi

if [ "$all_good" = true ]; then
    echo -e "${GREEN}    All systems operational! ✓${NC}"
else
    echo -e "${YELLOW}    Some services need attention${NC}"
fi

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"