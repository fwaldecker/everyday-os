#!/bin/bash

# Google Cloud Setup Script for Everyday-OS
# This script automates Google Cloud project setup for N8N clients

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if node is installed
check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed${NC}"
        echo "Please install Node.js version 14 or higher"
        exit 1
    fi
}

# Function to check if npm packages are installed
check_dependencies() {
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 Installing dependencies...${NC}"
        npm install
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to install dependencies${NC}"
            exit 1
        fi
    fi
}

# Function to check environment variables
check_env() {
    if [ ! -f "../.env" ]; then
        echo -e "${RED}❌ .env file not found${NC}"
        echo "Please copy .env.example to .env and configure it"
        exit 1
    fi

    # Source the .env file
    set -a
    source ../.env
    set +a

    # Check required variables
    if [ -z "$GOOGLE_SERVICE_ACCOUNT_KEY" ] || [ "$GOOGLE_SERVICE_ACCOUNT_KEY" == '{"type":"service_account"' ]; then
        echo -e "${RED}❌ GOOGLE_SERVICE_ACCOUNT_KEY not configured${NC}"
        echo "Please add your service account JSON to .env"
        exit 1
    fi

    if [ -z "$GOOGLE_BILLING_ACCOUNT_ID" ] || [ "$GOOGLE_BILLING_ACCOUNT_ID" == "your-billing-account-id" ]; then
        echo -e "${RED}❌ GOOGLE_BILLING_ACCOUNT_ID not configured${NC}"
        echo "Please add your billing account ID to .env"
        exit 1
    fi
}

# Main execution
echo -e "${GREEN}🚀 Google Cloud Setup Automation for Everyday-OS${NC}"
echo ""

# Change to script directory
cd "$(dirname "$0")"

# Run checks
check_node
check_dependencies
check_env

# Run the setup script
echo -e "${GREEN}Starting Google Cloud setup...${NC}"
echo ""
node setup-google-client.js

# Check exit status
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Setup completed successfully!${NC}"
else
    echo -e "${RED}❌ Setup failed. Please check the error messages above.${NC}"
    exit 1
fi