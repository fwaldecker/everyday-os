#!/bin/bash
#
# Everyday-OS Server Deployment Script
# This script automates the deployment of Everyday-OS on a new server
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   echo "Please run as a regular user with sudo privileges."
   exit 1
fi

echo "======================================"
echo "Everyday-OS Server Deployment Script"
echo "======================================"
echo ""

# Step 1: Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    print_warning "Docker installed. You may need to log out and back in for group changes to take effect."
else
    print_status "Docker is already installed"
fi

# Step 3: Install Docker Compose v2
if ! docker compose version &> /dev/null; then
    print_status "Installing Docker Compose v2..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
else
    print_status "Docker Compose v2 is already installed"
fi

# Step 4: Install Python3 and pip if not installed
if ! command -v python3 &> /dev/null; then
    print_status "Installing Python3..."
    sudo apt install -y python3 python3-pip
else
    print_status "Python3 is already installed"
fi

# Step 5: Install Git if not installed
if ! command -v git &> /dev/null; then
    print_status "Installing Git..."
    sudo apt install -y git
else
    print_status "Git is already installed"
fi

# Step 6: Install other required tools
print_status "Installing additional required tools..."
sudo apt install -y openssl curl wget nano

# Step 7: Configure firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
print_status "Firewall configured (ports 22, 80, 443 open)"

# Step 8: Create application directory
APP_DIR="$HOME/everyday-os"
if [ ! -d "$APP_DIR" ]; then
    print_status "Creating application directory..."
    mkdir -p "$APP_DIR"
else
    print_warning "Application directory already exists at $APP_DIR"
fi

cd "$APP_DIR"

# Step 9: Clone or update repository
if [ ! -d ".git" ]; then
    print_status "Cloning Everyday-OS repository..."
    # Remove directory contents if it exists but is not a git repo
    if [ "$(ls -A)" ]; then
        print_warning "Directory is not empty. Backing up existing files..."
        mkdir -p "$HOME/everyday-os-backup"
        mv * "$HOME/everyday-os-backup/" 2>/dev/null || true
    fi
    git clone https://github.com/franciswaldecker/everyday-os.git .
else
    print_status "Updating existing repository..."
    git pull
fi

# Step 10: Check for .env file
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        print_warning ".env file not found. Creating from .env.example..."
        cp .env.example .env
        print_error "IMPORTANT: You must edit the .env file before starting services!"
        echo "Please edit: $APP_DIR/.env"
        echo "Run 'nano .env' to edit the configuration"
    else
        print_error ".env.example file not found!"
        exit 1
    fi
else
    print_status ".env file found"
fi

# Step 11: Create required directories
print_status "Creating required directories..."
mkdir -p docker/data/{minio,neo4j,postgres,redis,clickhouse}
mkdir -p docker/logs/{caddy,n8n}
mkdir -p n8n/backup
mkdir -p shared

# Set permissions
chmod -R 755 docker/data docker/logs

# Step 12: System optimizations
print_status "Applying system optimizations..."
# Increase max file descriptors
echo "fs.file-max = 65535" | sudo tee -a /etc/sysctl.conf
# Increase inotify watchers
echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Step 13: Docker daemon configuration
print_status "Configuring Docker daemon..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65535,
      "Soft": 65535
    }
  }
}
EOF

sudo systemctl restart docker

echo ""
echo "======================================"
echo "Deployment preparation complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Edit the .env file: cd $APP_DIR && nano .env"
echo "2. Configure all required environment variables"
echo "3. Run: python3 start_services.py --environment public"
echo ""
print_warning "Make sure your DNS A records are properly configured before starting services!"
echo ""

# Offer to edit .env file now
read -p "Would you like to edit the .env file now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nano .env
fi

# Offer to start services
echo ""
read -p "Would you like to start the services now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting Everyday-OS services..."
    python3 start_services.py --environment public
else
    echo "To start services later, run:"
    echo "cd $APP_DIR && python3 start_services.py --environment public"
fi