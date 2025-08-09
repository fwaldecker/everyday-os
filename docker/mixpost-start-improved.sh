#!/bin/bash

echo "=== Mixpost Improved Start Script ==="
echo "Starting at: $(date)"

# Environment variables
: "${LICENSE_KEY:=''}"
: "${DB_HOST:=mysql}"
: "${DB_PORT:=3306}"

# Paths
VENDOR_DIR="/var/www/html/vendor"
CUSTOM_PACKAGE_SOURCE="/var/www/html/packages/mixpost-custom"
VENDOR_PACKAGE_DIR="$VENDOR_DIR/inovector/mixpost-pro-team"
STORAGE_DIR="/var/www/html/storage/app"

# Function to apply custom package
apply_custom_package() {
    echo "=== Applying custom package ==="
    
    if [ ! -d "$CUSTOM_PACKAGE_SOURCE" ]; then
        echo "WARNING: Custom package source not found at $CUSTOM_PACKAGE_SOURCE"
        return 1
    fi
    
    # Only copy the custom package files, don't remove vendor first
    echo "Overlaying custom package files..."
    cp -rf "$CUSTOM_PACKAGE_SOURCE"/* "$VENDOR_PACKAGE_DIR/" 2>/dev/null || {
        echo "Creating vendor directory structure..."
        mkdir -p "$VENDOR_PACKAGE_DIR"
        cp -rf "$CUSTOM_PACKAGE_SOURCE"/* "$VENDOR_PACKAGE_DIR/"
    }
    
    # Set permissions
    chown -R www-data:www-data "$VENDOR_PACKAGE_DIR"
    
    # Verify critical files
    if grep -q 'PostCommentCreated' "$VENDOR_PACKAGE_DIR/src/WebhookManager.php" 2>/dev/null; then
        echo "✓ Custom package applied successfully"
        return 0
    else
        echo "✗ Custom package verification failed"
        return 1
    fi
}

# Function to clear Laravel caches
clear_caches() {
    echo "=== Clearing Laravel caches ==="
    php artisan cache:clear 2>/dev/null || true
    php artisan config:clear 2>/dev/null || true
    php artisan route:clear 2>/dev/null || true
    php artisan view:clear 2>/dev/null || true
    php artisan event:clear 2>/dev/null || true
}

# Function to rebuild caches
rebuild_caches() {
    echo "=== Rebuilding caches ==="
    php artisan config:cache 2>/dev/null || true
    php artisan route:cache 2>/dev/null || true
    php artisan event:cache 2>/dev/null || true
}

# Check if vendor directory exists and has content
if [ -d "$VENDOR_DIR" ] && [ "$(ls -A $VENDOR_DIR 2>/dev/null)" ]; then
    echo "=== Found existing vendor directory, applying custom package only ==="
    
    # Apply custom package
    apply_custom_package
    
    # Clear and rebuild caches
    clear_caches
    rebuild_caches
    
else
    echo "=== First time setup - downloading Mixpost ==="
    
    # Setup composer auth
    mkdir -p /root/.config/composer
    echo '{
      "http-basic": {
        "packages.inovector.com": {
          "username": "username",
          "password": "'$LICENSE_KEY'"
        }
      }
    }' > /root/.config/composer/auth.json
    
    # Download Mixpost
    echo "Running composer create-project..."
    rm -rf standalone-app
    composer create-project inovector/mixpost-pro-team-app:^4.0 standalone-app --no-interaction --prefer-dist
    
    if [ -d "standalone-app/vendor/inovector/mixpost-pro-team" ]; then
        echo "Download successful, setting up application..."
        
        # Copy application files
        cp -r standalone-app/* .
        rm -rf standalone-app
        
        # Setup database structure
        rm -rf database/migrations
        cp -r /var/www/app/migrations database/migrations
        cp -r /var/www/app/commands/* app/Console/Commands
        
        # Create .env file
        /var/www/startup/create_env.sh
        
        # Apply custom package
        apply_custom_package
        
        # Clear and rebuild caches
        clear_caches
        rebuild_caches
    else
        echo "ERROR: Composer download failed!"
        exit 1
    fi
fi

# Ensure storage permissions
echo "=== Setting storage permissions ==="
mkdir -p "$STORAGE_DIR"
chown -R www-data:www-data "$STORAGE_DIR"
chmod -R 775 "$STORAGE_DIR"

# Create storage link
php artisan storage:link 2>/dev/null || true

# Wait for database
echo "=== Waiting for database ==="
/usr/local/bin/wait-for-it.sh $DB_HOST:$DB_PORT -t 30

# Run migrations
echo "=== Running migrations ==="
php artisan mixpost:update-migration-timestamps 2>/dev/null || true
php artisan migrate --force

# Seed database if needed
php artisan mixpost:seed 2>/dev/null || true

# Start supervisor
echo "=== Starting supervisor ==="
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf &

echo "
      __  ___ _                          __ 
    /  |/  /(_)_  __ ____   ____   _____ / /_
    / /|_/ // /| |/_// __ \\ / __ \\ / ___// __/
  / /  / // /_>  < / /_/ // /_/ /(__  )/ /_  
  /_/  /_//_//_/|_|/ .___/ \\____//____/ \\__/  
                  /_/                         
  ";

echo "=== Mixpost Start Complete ==="
echo "Started successfully at: $(date)"

# Keep container running
tail -f /dev/null