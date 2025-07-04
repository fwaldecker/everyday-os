#!/bin/bash
#
# Everyday-OS Deployment Verification Script
# This script checks that all services are running correctly after deployment
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    echo "Please ensure you're running this from the everyday-os directory"
    exit 1
fi

# Source the .env file to get configuration
export $(cat .env | grep -v '^#' | xargs)

echo "========================================"
echo "Everyday-OS Deployment Verification"
echo "========================================"
echo ""
print_info "Base Domain: $BASE_DOMAIN"
print_info "Protocol: $PROTOCOL"
echo ""

# Function to check if a service is healthy
check_service_health() {
    local service_name=$1
    local container_name=$2
    
    # Check if container exists and is running
    if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        # Get container status
        status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not found")
        
        if [ "$status" = "running" ]; then
            # Check if container has health check
            health=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no health check")
            
            if [ "$health" = "healthy" ]; then
                print_success "$service_name is healthy"
                return 0
            elif [ "$health" = "no health check" ]; then
                print_warning "$service_name is running (no health check configured)"
                return 0
            else
                print_error "$service_name is unhealthy (status: $health)"
                return 1
            fi
        else
            print_error "$service_name is not running (status: $status)"
            return 1
        fi
    else
        print_error "$service_name container not found"
        return 1
    fi
}

# Function to check URL accessibility
check_url() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}
    
    print_info "Checking $service_name at $url..."
    
    # Use curl to check the URL
    response=$(curl -k -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 10 || echo "000")
    
    if [ "$response" = "$expected_code" ] || [ "$response" = "200" ] || [ "$response" = "302" ] || [ "$response" = "301" ]; then
        print_success "$service_name is accessible (HTTP $response)"
        return 0
    elif [ "$response" = "000" ]; then
        print_error "$service_name is not accessible (connection failed)"
        return 1
    else
        print_warning "$service_name returned HTTP $response"
        return 1
    fi
}

echo "1. Checking Docker Services"
echo "============================"

# Check core services
services_ok=true

check_service_health "PostgreSQL" "postgres" || services_ok=false
check_service_health "N8N" "n8n" || services_ok=false
check_service_health "Open WebUI" "open-webui" || services_ok=false
check_service_health "MinIO" "minio" || services_ok=false
check_service_health "Neo4j" "neo4j" || services_ok=false
check_service_health "Langfuse Web" "langfuse-web" || services_ok=false
check_service_health "Langfuse Worker" "langfuse-worker" || services_ok=false
check_service_health "ClickHouse" "clickhouse" || services_ok=false
check_service_health "Redis" "redis" || services_ok=false
check_service_health "SearXNG" "searxng" || services_ok=false
check_service_health "NCA Toolkit" "nca-toolkit" || services_ok=false
check_service_health "Caddy" "caddy" || services_ok=false

echo ""
echo "2. Checking Service URLs"
echo "========================"

urls_ok=true

# Check if we can reach the services via their URLs
if [ "$PROTOCOL" = "https" ] && [ -n "$BASE_DOMAIN" ]; then
    check_url "N8N" "${PROTOCOL}://n8n.${BASE_DOMAIN}" || urls_ok=false
    check_url "Open WebUI" "${PROTOCOL}://chat.${BASE_DOMAIN}" || urls_ok=false
    check_url "Supabase" "${PROTOCOL}://supabase.${BASE_DOMAIN}" || urls_ok=false
    check_url "Langfuse" "${PROTOCOL}://langfuse.${BASE_DOMAIN}" || urls_ok=false
    check_url "Neo4j Browser" "${PROTOCOL}://neo4j.${BASE_DOMAIN}" || urls_ok=false
    check_url "NCA Toolkit" "${PROTOCOL}://nca.${BASE_DOMAIN}" || urls_ok=false
    check_url "MinIO Console" "${PROTOCOL}://minio-console.${BASE_DOMAIN}" || urls_ok=false
    check_url "SearXNG" "${PROTOCOL}://search.${BASE_DOMAIN}" || urls_ok=false
else
    print_warning "HTTPS not configured or BASE_DOMAIN not set, skipping URL checks"
fi

echo ""
echo "3. Checking SSL Certificates"
echo "============================"

if [ "$PROTOCOL" = "https" ] && [ -n "$BASE_DOMAIN" ]; then
    # Check if Caddy has obtained certificates
    if docker exec caddy ls /data/caddy/certificates 2>/dev/null | grep -q "$BASE_DOMAIN"; then
        print_success "SSL certificates found for $BASE_DOMAIN"
    else
        print_warning "SSL certificates not found yet (Caddy may still be obtaining them)"
    fi
else
    print_info "SSL checks skipped (not using HTTPS)"
fi

echo ""
echo "4. Checking Storage Volumes"
echo "==========================="

# Check if volumes exist
volumes=(
    "everyday-os_n8n_storage"
    "everyday-os_qdrant_storage"
    "everyday-os_open-webui"
    "everyday-os_minio_data"
    "everyday-os_neo4j_data"
    "everyday-os_langfuse_postgres_data"
    "everyday-os_langfuse_clickhouse_data"
)

volumes_ok=true
for volume in "${volumes[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        print_success "Volume $volume exists"
    else
        print_error "Volume $volume not found"
        volumes_ok=false
    fi
done

echo ""
echo "5. Service Logs Check"
echo "===================="

# Check for critical errors in logs
print_info "Checking for critical errors in service logs..."

error_count=0
for service in n8n open-webui postgres minio neo4j langfuse-web caddy; do
    errors=$(docker logs "$service" 2>&1 | grep -i "error\|fatal\|critical" | tail -5 || true)
    if [ -n "$errors" ]; then
        print_warning "Found errors in $service logs (showing last 5):"
        echo "$errors" | sed 's/^/  /'
        ((error_count++))
    fi
done

if [ $error_count -eq 0 ]; then
    print_success "No critical errors found in service logs"
fi

echo ""
echo "6. System Resource Check"
echo "======================="

# Check disk space
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -lt 80 ]; then
    print_success "Disk usage is at ${disk_usage}%"
else
    print_warning "Disk usage is high: ${disk_usage}%"
fi

# Check memory
if command -v free &> /dev/null; then
    mem_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    if [ "$mem_usage" -lt 80 ]; then
        print_success "Memory usage is at ${mem_usage}%"
    else
        print_warning "Memory usage is high: ${mem_usage}%"
    fi
fi

echo ""
echo "========================================"
echo "Deployment Verification Summary"
echo "========================================"
echo ""

if $services_ok && $urls_ok && $volumes_ok; then
    print_success "All checks passed! Your Everyday-OS deployment appears to be healthy."
    echo ""
    echo "Access your services at:"
    echo "  N8N:           ${PROTOCOL}://n8n.${BASE_DOMAIN}"
    echo "  Open WebUI:    ${PROTOCOL}://chat.${BASE_DOMAIN}"
    echo "  Langfuse:      ${PROTOCOL}://langfuse.${BASE_DOMAIN}"
    echo "  MinIO Console: ${PROTOCOL}://minio-console.${BASE_DOMAIN}"
    echo "  Neo4j Browser: ${PROTOCOL}://neo4j.${BASE_DOMAIN}"
    echo "  NCA Toolkit:   ${PROTOCOL}://nca.${BASE_DOMAIN}"
    echo "  SearXNG:       ${PROTOCOL}://search.${BASE_DOMAIN}"
else
    print_error "Some checks failed. Please review the errors above."
    echo ""
    echo "Troubleshooting tips:"
    echo "  - Check service logs: docker logs <service-name>"
    echo "  - Restart services: docker compose -p everyday-os restart"
    echo "  - Check DNS records are pointing to: $SERVER_IP"
    echo "  - Ensure firewall allows ports 80 and 443"
fi

echo ""
echo "For detailed logs, run:"
echo "  docker compose -p everyday-os logs -f [service-name]"