#!/bin/bash

echo "=== Mixpost Custom Start Script ==="
echo "Starting at: $(date)"

# Environment variables from original script
: "${LICENSE_KEY:=''}"
: "${DB_HOST:=mysql}"
: "${DB_PORT:=3306}"

# Flag file to check if initial setup is done
SETUP_COMPLETE_FLAG="/var/www/html/.mixpost-setup-complete"
CUSTOM_PACKAGE_DIR="/var/www/html/packages/mixpost-custom"
VENDOR_PACKAGE_DIR="/var/www/html/vendor/inovector/mixpost-pro-team"

# Function to copy and verify custom package
install_custom_package() {
    echo "=== Installing custom package ==="
    
    if [ ! -d "$CUSTOM_PACKAGE_DIR" ]; then
        echo "ERROR: Custom package not found at $CUSTOM_PACKAGE_DIR"
        return 1
    fi
    
    # Remove existing vendor package
    echo "Removing existing vendor package..."
    rm -rf "$VENDOR_PACKAGE_DIR"
    
    # Copy custom package
    echo "Copying custom package..."
    cp -rf "$CUSTOM_PACKAGE_DIR" "$VENDOR_PACKAGE_DIR"
    
    # Set proper permissions
    echo "Setting permissions..."
    chown -R www-data:www-data "$VENDOR_PACKAGE_DIR"
    
    # Verify critical files
    echo "=== Verifying critical files ==="
    
    # Check WebhookManager
    if [ -f "$VENDOR_PACKAGE_DIR/src/WebhookManager.php" ]; then
        if grep -q 'PostCommentCreated' "$VENDOR_PACKAGE_DIR/src/WebhookManager.php"; then
            echo "✓ WebhookManager.php verified with PostCommentCreated"
        else
            echo "✗ ERROR: WebhookManager.php missing PostCommentCreated!"
            return 1
        fi
    else
        echo "✗ ERROR: WebhookManager.php not found!"
        return 1
    fi
    
    # Check ManagesComments
    if [ -f "$VENDOR_PACKAGE_DIR/src/Concerns/Model/Post/ManagesComments.php" ]; then
        if grep -q 'PostCommentCreated::dispatch' "$VENDOR_PACKAGE_DIR/src/Concerns/Model/Post/ManagesComments.php"; then
            echo "✓ ManagesComments.php verified with webhook dispatch"
        else
            echo "✗ WARNING: ManagesComments.php missing webhook dispatch"
        fi
    fi
    
    # Check API Controllers
    if [ -f "$VENDOR_PACKAGE_DIR/src/Http/Api/Controllers/Workspace/Post/PostCommentsController.php" ]; then
        echo "✓ PostCommentsController.php exists"
    else
        echo "✗ WARNING: PostCommentsController.php not found"
    fi
    
    # Check middleware
    if [ -f "$VENDOR_PACKAGE_DIR/src/Http/Base/Middleware/CheckWorkspaceUser.php" ]; then
        if grep -q 'if (!$user)' "$VENDOR_PACKAGE_DIR/src/Http/Base/Middleware/CheckWorkspaceUser.php"; then
            echo "✓ CheckWorkspaceUser.php has null check fix"
        else
            echo "✗ WARNING: CheckWorkspaceUser.php missing null check fix"
        fi
    fi
    
    echo "Custom package installation complete!"
    return 0
}

# Function to clear all Laravel caches
clear_laravel_caches() {
    echo "=== Clearing Laravel caches ==="
    php artisan cache:clear 2>/dev/null || true
    php artisan config:clear 2>/dev/null || true
    php artisan route:clear 2>/dev/null || true
    php artisan view:clear 2>/dev/null || true
    php artisan event:clear 2>/dev/null || true
    php artisan clear-compiled 2>/dev/null || true
    
    # Rebuild caches
    echo "=== Rebuilding caches ==="
    php artisan config:cache 2>/dev/null || true
    php artisan route:cache 2>/dev/null || true
    php artisan event:cache 2>/dev/null || true
    
    # Restart Horizon
    echo "=== Restarting Horizon ==="
    php artisan horizon:terminate 2>/dev/null || true
}

# Check if this is first run or restart
if [ -f "$SETUP_COMPLETE_FLAG" ]; then
    echo "=== Mixpost already installed, skipping composer setup ==="
    
    # Just ensure our custom package is in place
    install_custom_package
    
    # Clear and rebuild caches
    clear_laravel_caches
    
else
    echo "=== First time setup - running full installation ==="
    
    # Create composer auth file
    echo '{
      "http-basic": {
        "packages.inovector.com": {
          "username": "username",
          "password": "'$LICENSE_KEY'"
        }
      }
    }' > /root/.config/composer/auth.json
    
    # Check if vendor directory already has Mixpost (from volume mount)
    if [ -d "$VENDOR_PACKAGE_DIR" ] && [ -f "/var/www/html/composer.json" ]; then
        echo "Found existing installation in vendor directory"
    else
        echo "Running composer create-project..."
        # Remove any existing standalone-app
        rm -rf standalone-app
        
        # Create standalone app
        composer create-project inovector/mixpost-pro-team-app:^4.0 standalone-app --no-interaction --prefer-dist
        
        # Check if download was successful
        if [ -d "/var/www/html/standalone-app/vendor/inovector/mixpost-pro-team" ]; then
            echo "Composer download successful"
            
            # Copy app files to root (from original script)
            cp -r standalone-app/* .
            rm -rf standalone-app
            
            # Setup database and migrations
            rm -rf database/migrations
            cp -r /var/www/app/migrations database/migrations
            cp -r /var/www/app/commands/* app/Console/Commands
            
            # Create .env file
            /var/www/startup/create_env.sh
        else
            echo "ERROR: Composer download failed"
            # Try to restore from backup if exists
            if [ -f "/var/www/html/storage/app/backup-standalone-app.tar.gz" ]; then
                echo "Restoring from backup..."
                tar xzf storage/app/backup-standalone-app.tar.gz -C .
                cp -r standalone-app/* .
                rm -rf standalone-app
            fi
        fi
    fi
    
    # Now install our custom package over the downloaded one
    install_custom_package
    
    # Mark setup as complete
    touch "$SETUP_COMPLETE_FLAG"
    echo "First time setup completed at: $(date)" >> "$SETUP_COMPLETE_FLAG"
fi

# Run Laravel setup tasks
echo "=== Running Laravel setup tasks ==="
php artisan storage:link 2>/dev/null || true

# Wait for MySQL
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
      __  ___ _                            __ 
    /  |/  /(_)_  __ ____   ____   _____ / /_
    / /|_/ // /| |/_// __ \ / __ \ / ___// __/
  / /  / // /_>  < / /_/ // /_/ /(__  )/ /_  
  /_/  /_//_//_/|_|/ .___/ \____//____/ \__/  
                  /_/                         
  ";

echo "=== Mixpost Custom Start Complete ==="
echo "Started successfully at: $(date)"

# Keep container running
tail -f /dev/null