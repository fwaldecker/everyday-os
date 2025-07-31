# Rollback Plan for Everyday-OS Cleanup

## Quick Rollback Steps

If any issues occur during the cleanup process, follow these steps to restore the system:

### 1. Stop all services
```bash
docker compose -f docker/docker-compose.yml down
```

### 2. Restore configuration files
```bash
# From the everyday-os root directory
cp backup_20250731_031929/docker-compose.yml docker/
cp backup_20250731_031929/docker-compose.override.public.supabase.yml docker/
cp backup_20250731_031929/.env.example .
cp backup_20250731_031929/Caddyfile .
cp -r backup_20250731_031929/searxng .
cp -r backup_20250731_031929/docker/searxng docker/
```

### 3. Restart services
```bash
docker compose -f docker/docker-compose.yml up -d
```

### 4. Verify services
```bash
docker compose -f docker/docker-compose.yml ps
```

## Backed Up Files
- docker/docker-compose.yml
- docker/docker-compose.override.public.supabase.yml
- .env.example
- Caddyfile
- searxng/ directory
- docker/searxng/ directory

## Service Status at Backup Time
See service_status.txt for the state of all services when backup was created.