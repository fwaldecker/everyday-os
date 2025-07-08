#!/usr/bin/env python3
"""
start_services.py

This script manages the Everyday-OS Docker Compose environment, including:
- Supabase backend services
- AI/ML services (N8N, Langfuse, etc.)
- Storage services (MinIO)
- Search and analytics services (SearXNG, Neo4j)
- Web interfaces and APIs

All services are managed under the same Docker Compose project ("everyday-os").
"""

import os
import subprocess
import shutil
import time
import argparse
import platform
import sys
import json
from pathlib import Path

# Project configuration
PROJECT_NAME = "everyday-os"
DEFAULT_ENV_FILE = ".env"
DOCKER_COMPOSE_FILE = "docker/docker-compose.yml"
DOCKER_COMPOSE_OVERRIDE = "docker/docker-compose.override.yml"
DOCKER_COMPOSE_PROD = "docker/docker-compose.prod.yml"

def run_command(cmd, cwd=None, check=True, capture_output=False):
    """Run a shell command and print it."""
    print("Running:", " ".join(cmd))
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            check=check,
            capture_output=capture_output,
            text=True
        )
        if result.returncode != 0 and check:
            print(f"Command failed with return code {result.returncode}")
            if result.stderr:
                print("Error:", result.stderr.strip())
            return None
        return result
    except subprocess.CalledProcessError as e:
        print(f"Command failed with error: {e}")
        if e.stderr:
            print("Error output:", e.stderr.strip())
        if e.stdout:
            print("Output:", e.stdout.strip())
        return None
    except Exception as e:
        print(f"Unexpected error running command: {e}")
        return None

def check_docker():
    """Check if Docker is running and accessible."""
    print("Checking Docker installation...")
    result = run_command(["docker", "--version"], check=False)
    if not result or result.returncode != 0:
        print("Error: Docker is not installed or not running. Please install Docker and start the Docker daemon.")
        sys.exit(1)
    
    print("Checking Docker Compose...")
    result = run_command(["docker", "compose", "version"], check=False)
    if not result or result.returncode != 0:
        print("Error: Docker Compose is not installed. Please install Docker Compose v2 or later.")
        sys.exit(1)

def check_requirements():
    """Check system requirements and dependencies."""
    print("Checking system requirements...")
    
    # Check Python version
    if sys.version_info < (3, 8):
        print("Error: Python 3.8 or higher is required.")
        sys.exit(1)
    
    # Check for required environment variables
    required_vars = ["BASE_DOMAIN", "PROTOCOL", "SERVER_IP"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"Error: The following required environment variables are not set: {', '.join(missing_vars)}")
        print("Please set these variables in your .env file or environment.")
        sys.exit(1)

def setup_environment():
    """Set up the environment for the application."""
    print("Setting up environment...")
    
    # Create necessary directories
    os.makedirs("docker/data/minio", exist_ok=True)
    os.makedirs("docker/data/neo4j", exist_ok=True)
    os.makedirs("docker/data/postgres", exist_ok=True)
    os.makedirs("docker/data/redis", exist_ok=True)
    os.makedirs("docker/data/clickhouse", exist_ok=True)
    os.makedirs("docker/logs/caddy", exist_ok=True)
    os.makedirs("docker/logs/n8n", exist_ok=True)
    
    # Set permissions (important for Linux/macOS)
    if platform.system() != "Windows":
        run_command(["chmod", "-R", "777", "docker/data"], check=False)
        run_command(["chmod", "-R", "777", "docker/logs"], check=False)

def clone_supabase_repo():
    """Clone the Supabase repository using sparse checkout if not already present."""
    if not os.path.exists("supabase"):
        print("Cloning the Supabase repository...")
        result = run_command([
            "git", "clone", "--filter=blob:none", "--no-checkout",
            "--depth=1", "--single-branch", "--branch=master",
            "https://github.com/supabase/supabase.git"
        ])
        if not result:
            print("Failed to clone Supabase repository.")
            sys.exit(1)
            
        os.chdir("supabase")
        run_command(["git", "sparse-checkout", "init", "--cone"])
        run_command(["git", "sparse-checkout", "set", "docker"])
        run_command(["git", "checkout", "master"])
        os.chdir("..")
    else:
        print("Supabase repository already exists, updating...")
        os.chdir("supabase")
        run_command(["git", "pull"])
        os.chdir("..")

def prepare_supabase_env():
    """Prepare the Supabase environment by copying .env and setting up necessary files."""
    # Create .env in supabase/docker if it doesn't exist
    env_path = os.path.join("supabase", "docker", ".env")
    env_example_path = os.path.join(".env")
    
    if not os.path.exists(env_path) and os.path.exists(env_example_path):
        print("Copying .env to supabase/docker/.env...")
        shutil.copyfile(env_example_path, env_path)
    
    # Ensure the .env file has the correct permissions
    if os.path.exists(env_path) and platform.system() != "Windows":
        os.chmod(env_path, 0o600)

def stop_existing_containers(project_name=PROJECT_NAME):
    """Stop and remove existing containers for the project."""
    print(f"Stopping and removing existing containers for project '{project_name}'...")
    run_command(["docker", "compose", "-p", project_name, "down", "--remove-orphans"], check=False)

def start_supabase(environment=None):
    """Start the Supabase services."""
    print("Starting Supabase services...")
    
    # Change to the supabase/docker directory
    supabase_dir = os.path.join("supabase", "docker")
    if not os.path.exists(supabase_dir):
        print(f"Error: Supabase directory not found at {supabase_dir}")
        sys.exit(1)
    
    # Build and start Supabase services
    cmd = ["docker", "compose", "-p", PROJECT_NAME, "up", "-d"]
    if environment and environment != "development":
        cmd.extend(["--profile", environment])
    
    result = run_command(cmd, cwd=supabase_dir)
    if not result or result.returncode != 0:
        print("Failed to start Supabase services.")
        return False
    
    print("Waiting for Supabase to initialize...")
    time.sleep(10)  # Give services time to start
    return True

def start_services(profile=None, environment=None):
    """Start all services for the Everyday-OS."""
    print("Starting Everyday-OS services...")
    
    # Build the Docker Compose command
    cmd = [
        "docker", "compose",
        "-f", DOCKER_COMPOSE_FILE,
        "--env-file", DEFAULT_ENV_FILE,
    ]
    
    # Add override files if they exist
    if os.path.exists(DOCKER_COMPOSE_OVERRIDE):
        cmd.extend(["-f", DOCKER_COMPOSE_OVERRIDE])
    
    # Add production override if in production mode
    if environment == "production" and os.path.exists(DOCKER_COMPOSE_PROD):
        cmd.extend(["-f", DOCKER_COMPOSE_PROD])
    
    # Add the project name and up command
    cmd.extend(["-p", PROJECT_NAME, "up", "-d"])
    
    # Add profile if specified
    if profile and profile != "none":
        cmd.extend(["--profile", profile])
    
    # Run the command
    result = run_command(cmd)
    if not result or result.returncode != 0:
        print("Failed to start services.")
        return False
    
    print("Waiting for services to initialize...")
    time.sleep(10)  # Give services time to start
    return True

def check_services_health():
    """Check the health of running services."""
    print("Checking service health...")
    
    # Get the list of services with health checks
    cmd = [
        "docker", "compose", "-p", PROJECT_NAME,
        "ps", "--format", "json"
    ]
    
    result = run_command(cmd, capture_output=True)
    if not result or not result.stdout.strip():
        print("No services running or failed to get service status.")
        return False
    
    try:
        services = json.loads(result.stdout)
        healthy = True
        
        for service in services:
            service_name = service.get("Service", "")
            status = service.get("Status", "")
            state = service.get("State", "")
            health = service.get("Health", "")
            
            print(f"\nService: {service_name}")
            print(f"Status: {status}")
            print(f"State: {state}")
            print(f"Health: {health}")
            
            if "unhealthy" in health.lower() or "exited" in state.lower():
                print(f"⚠️  Warning: {service_name} is not healthy")
                healthy = False
        
        return healthy
    except json.JSONDecodeError as e:
        print(f"Error parsing service status: {e}")
        return False

def generate_searxng_secret_key():
    """Generate a secure secret key for SearXNG."""
    import secrets
    import string
    
    alphabet = string.ascii_letters + string.digits + "-_"
    return ''.join(secrets.choice(alphabet) for _ in range(64))

def check_and_fix_docker_compose_for_searxng():
    """Check and modify docker-compose.yml for SearXNG first run."""
    # Check if this is the first run by looking for the default secret key
    if not os.path.exists("docker/data/searxng"):
        os.makedirs("docker/data/searxng", exist_ok=True)
    
    settings_path = "docker/data/searxng/settings.yml"
    
    # Check if we need to generate a secret key
    if not os.path.exists(settings_path):
        print("Generating new SearXNG configuration...")
        secret_key = generate_searxng_secret_key()
        
        # Create a basic settings.yml
        settings_content = f"""# Base configuration for SearXNG
# See https://docs.searxng.org/admin/engines/settings.html for details

use_default_settings: true

server:
  secret_key: "{secret_key}"
  base_url: "https://search.${{BASE_DOMAIN}}/"
  limiter: false
  image_proxy: true
  http_protocol_version: "1.1"
  
ui:
  theme: simple
  theme_args:
    simple_style: auto
  infinite_scroll: true
  
search:
  safe_search: 0
  autocomplete: google
  default_lang: en
  languages_mapping:
    en: English
    de: Deutsch
    fr: Français
    es: Español

engines:
  - name: google
    engine: google
    shortcut: g
    disabled: false
    use_mobile_ui: true
    
  - name: bing
    engine: bing
    shortcut: b
    disabled: false
    
  - name: duckduckgo
    engine: duckduckgo
    shortcut: d
    disabled: false
"""
        
        with open(settings_path, 'w') as f:
            f.write(settings_content)
        
        # Set appropriate permissions
        if platform.system() != "Windows":
            os.chmod(settings_path, 0o600)
        
        print("SearXNG configuration has been generated.")
        return True
    
    return False

def main():
    parser = argparse.ArgumentParser(description='Start the Everyday-OS stack.')
    parser.add_argument('--stop', '-s', action='store_true', help='Stop the services instead of starting them')
    args = parser.parse_args()

    if args.stop:
        stop_existing_containers()
        return

    # Check if .env file exists
    if not os.path.exists(DEFAULT_ENV_FILE):
        print(f"Error: Environment file {DEFAULT_ENV_FILE} not found!")
        print("Please copy .env.example to .env and configure it first.")
        sys.exit(1)

    try:
        # Start Supabase first if it exists
        if os.path.exists("supabase"):
            print("Starting Supabase services...")
            start_supabase()
            
            # Wait for Supabase to initialize
            print("Waiting for Supabase to initialize...")
            time.sleep(10)
        else:
            print("Supabase directory not found, skipping Supabase services...")

        # Start the main stack
        print("Starting Everyday-OS services...")
        start_services()

        print("Services started successfully!")
        print("\nAccess the following services (ensure DNS is properly configured):")
        protocol = os.getenv('PROTOCOL', 'https')
        base_domain = os.getenv('BASE_DOMAIN', 'example.com')
        print(f"- n8n: {protocol}://n8n.{base_domain}")
        print(f"- MinIO Console: {protocol}://minio.{base_domain} (access key: {os.getenv('MINIO_ROOT_USER', 'minioadmin')}, secret: {os.getenv('MINIO_ROOT_PASSWORD', 'minioadmin')})")
        print(f"- Supabase Studio: {protocol}://supabase.{base_domain}")
        print(f"- Neo4j Browser: {protocol}://neo4j.{base_domain}")
        print(f"- Langfuse: {protocol}://langfuse.{base_domain}")
        print(f"- NCA Toolkit: {protocol}://nca.{base_domain}")
        print("\nNote: Make sure your DNS is properly configured to point these subdomains to your server's IP address.")

    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
