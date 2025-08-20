# Running Mixpost Separately from Everyday-OS

Since Mixpost is a commercial Laravel application with custom modifications, you may want to run it separately from the main Everyday-OS stack. This guide shows you how.

## Option 1: Standalone Mixpost with Docker

Create a separate directory for Mixpost:

```bash
mkdir ~/mixpost-standalone
cd ~/mixpost-standalone
```

### Create docker-compose.yml for Mixpost

```yaml
version: '3.8'

volumes:
  mysql_data:
  mixpost_storage:
  redis_data:

services:
  mysql:
    image: mysql:8.0
    container_name: mixpost_mysql
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=YourSecureRootPassword
      - MYSQL_DATABASE=mixpost
      - MYSQL_USER=mixpost
      - MYSQL_PASSWORD=YourSecurePassword
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"  # Or use a different port if 3306 is taken

  redis:
    image: redis:alpine
    container_name: mixpost_redis
    restart: unless-stopped
    volumes:
      - redis_data:/data

  mixpost:
    image: inovector/mixpost-pro-team:latest
    container_name: mixpost
    restart: unless-stopped
    ports:
      - "8090:80"  # Access Mixpost on port 8090
    environment:
      # License
      - LICENSE_KEY=your-mixpost-license-key-here
      
      # Application
      - APP_NAME=Mixpost
      - APP_KEY=base64:generateYourOwnBase64KeyHere
      - APP_URL=https://social.yourdomain.com
      - APP_DOMAIN=social.yourdomain.com
      
      # Database
      - DB_CONNECTION=mysql
      - DB_HOST=mysql
      - DB_PORT=3306
      - DB_DATABASE=mixpost
      - DB_USERNAME=mixpost
      - DB_PASSWORD=YourSecurePassword
      
      # Redis
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    volumes:
      - mixpost_storage:/var/www/html/storage/app
    depends_on:
      - mysql
      - redis
```

### Add to your main Caddy configuration

Add this to your Everyday-OS Caddyfile to route traffic to standalone Mixpost:

```caddy
# Mixpost - Social Media Management (Standalone)
social.{$BASE_DOMAIN} {
    import security_headers
    
    # Proxy to standalone Mixpost on port 8090
    reverse_proxy localhost:8090 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

## Option 2: Mixpost with Custom AI Features

If you want to preserve your custom AI comment features, you'll need to build a custom image:

### Directory Structure
```
mixpost-custom/
├── docker-compose.yml
├── Dockerfile
└── customizations/
    ├── src/
    │   ├── AIManager.php
    │   ├── Services/
    │   │   └── OpenAIService.php
    │   └── AIProviders/
    │       └── OpenAI/
    │           └── OpenAIProvider.php
    └── routes/
        └── web/
            └── includes/
                └── workspace.php
```

### Custom Dockerfile
```dockerfile
FROM inovector/mixpost-pro-team:latest

# Copy your customizations
COPY customizations/ /tmp/custom/

# Apply customizations
RUN cp -rf /tmp/custom/src/* /var/www/html/vendor/inovector/mixpost/src/ && \
    cp -rf /tmp/custom/routes/* /var/www/html/vendor/inovector/mixpost/routes/ && \
    rm -rf /tmp/custom

# Set permissions
RUN chown -R www-data:www-data /var/www/html/vendor/inovector/mixpost && \
    php artisan config:clear && \
    php artisan route:clear

EXPOSE 80
```

## Option 3: Connect Mixpost via n8n

Instead of custom code, you can use n8n workflows to add AI features:

1. Run vanilla Mixpost separately
2. Use Mixpost's API/webhooks
3. Create n8n workflows for:
   - AI comment generation
   - Content suggestions
   - Automated responses

### Example n8n Workflow
```
Trigger: Mixpost Webhook (new post scheduled)
  ↓
Get Post Details via Mixpost API
  ↓
Generate AI Comment with OpenAI/Claude
  ↓
Post Comment via Mixpost API
```

## Connecting Mixpost to Everyday-OS

### Use n8n for Integration
1. In Mixpost, set up webhooks to notify n8n
2. In n8n, create workflows that:
   - Listen for Mixpost events
   - Process with AI (OpenAI/Claude nodes)
   - Send results back to Mixpost

### Shared MinIO Storage
If you need shared file storage:
1. Point Mixpost to Everyday-OS MinIO
2. Use S3 credentials from Everyday-OS
3. Create a bucket for Mixpost: `mixpost-media`

## Benefits of Separation

1. **Cleaner Architecture**
   - Everyday-OS remains focused on automation
   - Mixpost updates don't affect other services

2. **Easier Maintenance**
   - Update Mixpost independently
   - Test customizations separately

3. **Better for Clients**
   - They can choose to use Mixpost or not
   - No license key required for base Everyday-OS

4. **Simplified GitHub Distribution**
   - No commercial code in your repo
   - No complex build processes

## Migration from Integrated Setup

If you're moving from an integrated setup:

1. **Export Mixpost Data**
   ```bash
   docker exec mixpost_mysql mysqldump -u root -p mixpost > mixpost_backup.sql
   ```

2. **Copy Storage**
   ```bash
   docker cp mixpost:/var/www/html/storage/app ./mixpost_storage_backup
   ```

3. **Import to New Setup**
   ```bash
   docker exec -i mixpost_mysql mysql -u root -p mixpost < mixpost_backup.sql
   ```

## Your Custom Features

The customizations in `packages/mixpost-custom/` include:
- AI comment generation
- OpenAI/Anthropic integration
- Enhanced API endpoints

These can be:
1. Applied via custom Docker build (Option 2)
2. Replaced with n8n workflows (Option 3)
3. Maintained as a separate private repository