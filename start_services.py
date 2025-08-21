#!/usr/bin/env python3
"""
Everyday-OS Service Manager
Starts all services using docker-compose
"""

import subprocess
import sys
import os
import time
from pathlib import Path

def print_banner():
    """Print welcome banner"""
    print("=" * 60)
    print("         Everyday-OS Service Manager")
    print("=" * 60)

def check_docker():
    """Check if Docker is installed and running"""
    print("\nChecking Docker installation...")
    
    # Check Docker
    try:
        result = subprocess.run(["docker", "--version"], 
                              check=True, 
                              capture_output=True, 
                              text=True)
        print(f"✓ {result.stdout.strip()}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("✗ Error: Docker is not installed or not in PATH")
        print("  Please install Docker from https://www.docker.com/")
        sys.exit(1)
    
    # Check Docker Compose
    try:
        result = subprocess.run(["docker", "compose", "version"], 
                              check=True, 
                              capture_output=True, 
                              text=True)
        print(f"✓ Docker Compose {result.stdout.strip()}")
    except subprocess.CalledProcessError:
        # Try legacy docker-compose command
        try:
            result = subprocess.run(["docker-compose", "--version"], 
                                  check=True, 
                                  capture_output=True, 
                                  text=True)
            print(f"✓ {result.stdout.strip()}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("✗ Error: Docker Compose is not installed")
            print("  Docker Compose should be included with Docker Desktop")
            sys.exit(1)
    
    # Check if Docker daemon is running
    try:
        subprocess.run(["docker", "ps"], 
                      check=True, 
                      capture_output=True, 
                      stderr=subprocess.DEVNULL)
        print("✓ Docker daemon is running")
    except subprocess.CalledProcessError:
        print("✗ Error: Docker daemon is not running")
        print("  Please start Docker Desktop")
        sys.exit(1)

def check_env():
    """Check if .env file exists and has required variables"""
    print("\nChecking environment configuration...")
    
    env_path = Path(".env")
    if not env_path.exists():
        print("✗ Error: .env file not found")
        print("\nTo set up your environment:")
        print("  1. Copy .env.example to .env")
        print("  2. Edit .env with your configuration:")
        print("     - Set BASE_DOMAIN to your domain")
        print("     - Set secure passwords for all services")
        print("     - Add API keys if needed")
        sys.exit(1)
    
    print("✓ .env file found")
    
    # Check for required variables
    required_vars = [
        "BASE_DOMAIN",
        "LETSENCRYPT_EMAIL",
        "POSTGRES_PASSWORD",
        "N8N_ENCRYPTION_KEY",
        "N8N_USER_MANAGEMENT_JWT_SECRET",
        "MINIO_ROOT_USER",
        "MINIO_ROOT_PASSWORD",
        "NCA_API_KEY"
    ]
    
    missing_vars = []
    with open(env_path, "r") as f:
        env_content = f.read()
        for var in required_vars:
            if f"{var}=" not in env_content:
                missing_vars.append(var)
    
    if missing_vars:
        print(f"✗ Error: Missing required environment variables:")
        for var in missing_vars:
            print(f"    - {var}")
        print("\nPlease add these to your .env file")
        sys.exit(1)
    
    print("✓ All required environment variables found")

def start_services():
    """Start all services using docker-compose"""
    print("\nStarting Everyday-OS services...")
    print("This may take a few minutes on first run...\n")
    
    try:
        # Try docker compose (v2) first
        compose_cmd = ["docker", "compose"]
        subprocess.run(compose_cmd + ["--version"], 
                      check=True, 
                      capture_output=True, 
                      stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        # Fall back to docker-compose (v1)
        compose_cmd = ["docker-compose"]
    
    try:
        # Pull latest images
        print("Pulling latest images...")
        subprocess.run(compose_cmd + ["pull"], check=True)
        
        # Start services
        print("\nStarting services...")
        subprocess.run(compose_cmd + ["up", "-d"], check=True)
        
        print("\n✓ Services started successfully!")
        
    except subprocess.CalledProcessError as e:
        print(f"\n✗ Error starting services: {e}")
        print("\nTroubleshooting tips:")
        print("  - Check if ports 80 and 443 are available")
        print("  - Ensure Docker has enough resources allocated")
        print("  - Run 'docker compose logs' to see detailed errors")
        sys.exit(1)

def show_service_urls():
    """Display service URLs based on .env configuration"""
    print("\n" + "=" * 60)
    print("Service URLs")
    print("=" * 60)
    
    # Read domain from .env
    domain = None
    with open(".env", "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("BASE_DOMAIN="):
                domain = line.split("=", 1)[1].strip()
                # Remove quotes if present
                domain = domain.strip('"').strip("'")
                break
    
    if domain:
        print(f"\nYour services are available at:\n")
        print(f"  n8n Automation:    https://n8n.{domain}")
        print(f"  MinIO Console:     https://minio-console.{domain}")
        print(f"  NCA Toolkit:       https://nca.{domain}")
        print(f"\nNote: It may take a minute for services to be fully ready.")
        print("      n8n will import your workflows on first startup.")
    else:
        print("\nWarning: Could not read BASE_DOMAIN from .env")
        print("Services should be running, check docker compose ps")

def check_service_health():
    """Optional: Check if services are healthy"""
    print("\nChecking service health...")
    
    try:
        # Try docker compose (v2) first
        compose_cmd = ["docker", "compose"]
        subprocess.run(compose_cmd + ["--version"], 
                      check=True, 
                      capture_output=True, 
                      stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        # Fall back to docker-compose (v1)
        compose_cmd = ["docker-compose"]
    
    result = subprocess.run(compose_cmd + ["ps", "--format=json"], 
                          capture_output=True, 
                          text=True)
    
    if result.returncode == 0:
        print("\nRun 'docker compose ps' to see detailed service status")
    
    print("\n" + "=" * 60)
    print("Setup Complete!")
    print("=" * 60)

def main():
    """Main entry point"""
    print_banner()
    
    # Change to script directory
    script_dir = Path(__file__).parent.absolute()
    os.chdir(script_dir)
    
    # Run checks and start services
    check_docker()
    check_env()
    start_services()
    show_service_urls()
    check_service_health()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)