#!/bin/bash

# Script to verify Mixpost custom package installation
echo "=== Mixpost Installation Verification ==="
echo "Running at: $(date)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if container is running
if ! docker ps | grep -q mixpost; then
    echo -e "${RED}✗ Mixpost container is not running${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Mixpost container is running${NC}"

# Function to check file in container
check_file() {
    local file_path=$1
    local search_pattern=$2
    local description=$3
    
    if docker exec mixpost test -f "$file_path"; then
        if [ -n "$search_pattern" ]; then
            if docker exec mixpost grep -q "$search_pattern" "$file_path"; then
                echo -e "${GREEN}✓ $description${NC}"
                return 0
            else
                echo -e "${RED}✗ $description - pattern not found${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}✓ $description exists${NC}"
            return 0
        fi
    else
        echo -e "${RED}✗ $description not found${NC}"
        return 1
    fi
}

# Check critical files
echo ""
echo "=== Checking Critical Files ==="

check_file "/var/www/html/vendor/inovector/mixpost-pro-team/src/WebhookManager.php" \
           "PostCommentCreated" \
           "WebhookManager.php with PostComment events"

check_file "/var/www/html/vendor/inovector/mixpost-pro-team/src/Concerns/Model/Post/ManagesComments.php" \
           "PostCommentCreated::dispatch" \
           "ManagesComments.php with webhook dispatch"

check_file "/var/www/html/vendor/inovector/mixpost-pro-team/src/Http/Api/Controllers/Workspace/Post/PostCommentsController.php" \
           "" \
           "PostCommentsController.php"

check_file "/var/www/html/vendor/inovector/mixpost-pro-team/src/Http/Base/Middleware/CheckWorkspaceUser.php" \
           'if (!$user)' \
           "CheckWorkspaceUser.php with null check"

check_file "/var/www/html/vendor/inovector/mixpost-pro-team/src/Events/Post/PostCommentCreated.php" \
           "workspace_uuid" \
           "PostCommentCreated.php with workspace_uuid"

# Check if setup flag exists
echo ""
echo "=== Checking Installation Status ==="
if docker exec mixpost test -f "/var/www/html/.mixpost-setup-complete"; then
    echo -e "${GREEN}✓ Mixpost setup is marked as complete${NC}"
    docker exec mixpost cat /var/www/html/.mixpost-setup-complete
else
    echo -e "${YELLOW}⚠ Mixpost setup flag not found (might be first run)${NC}"
fi

# Check API endpoint
echo ""
echo "=== Checking API Endpoint ==="
RESPONSE=$(docker exec mixpost curl -s -o /dev/null -w "%{http_code}" \
    -X GET "http://localhost:80/mixpost/api/dd7477ef-bcd2-45dd-8f2e-14e790fdd2e2/posts" \
    -H "Authorization: Bearer YwNO7dcJiIs7o0r9hwgqg8HoamYjIZoh0pLmpz8y67681cb9" \
    -H "Accept: application/json")

if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ API endpoint is accessible${NC}"
elif [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "403" ]; then
    echo -e "${YELLOW}⚠ API endpoint returned $RESPONSE (auth issue)${NC}"
elif [ "$RESPONSE" = "404" ]; then
    echo -e "${RED}✗ API endpoint not found (routes not loaded)${NC}"
else
    echo -e "${RED}✗ API endpoint returned unexpected status: $RESPONSE${NC}"
fi

# Check webhook events registration
echo ""
echo "=== Checking Webhook Events Registration ==="
EVENTS=$(docker exec mixpost php artisan tinker --execute="dump(count(\Inovector\Mixpost\WebhookManager::workspaceEvents()));" 2>&1 | grep -o '[0-9]\+')
if [ "$EVENTS" -ge "11" ]; then
    echo -e "${GREEN}✓ $EVENTS webhook events registered (including comment events)${NC}"
else
    echo -e "${RED}✗ Only $EVENTS webhook events registered (missing comment events)${NC}"
fi

# Check if Eve user exists
echo ""
echo "=== Checking Eve AI User ==="
EVE_EXISTS=$(docker exec mixpost php artisan tinker --execute="dump(\Inovector\Mixpost\Models\User::where('id', 2)->exists());" 2>&1 | grep -o 'true\|false')
if [ "$EVE_EXISTS" = "true" ]; then
    echo -e "${GREEN}✓ Eve AI user exists (ID: 2)${NC}"
else
    echo -e "${YELLOW}⚠ Eve AI user not found${NC}"
fi

echo ""
echo "=== Verification Complete ==="