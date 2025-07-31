# Everyday-OS Cleanup Project Plan

## Project Overview
This document tracks the cleanup and optimization of the everyday-os repository, including removal of unused services (Supabase, SearXNG), consolidation of configuration files, and implementation of automatic n8n workflow deployment.

**Started:** 2025-07-31  
**Status:** Completed  
**Progress:** 45/45 tasks completed

---

## Phase 1: Backup and Preparation
- [x] Create full backup of current configuration
- [x] Document current service status
- [x] Create rollback plan

## Phase 2: Remove Supabase Components

### 2.1 Directory Cleanup
- [x] Delete empty `/supabase` directory

### 2.2 Docker Configuration
- [x] Remove Supabase service configuration from Caddyfile (lines 85-100)
- [x] Delete `docker/docker-compose.override.public.supabase.yml` file
- [x] Remove commented Supabase include from docker-compose.yml (lines 1-3)

### 2.3 Environment Variables
- [x] Remove JWT_SECRET from .env.example (line 39)
- [x] Remove ANON_KEY from .env.example (line 40)
- [x] Remove SERVICE_ROLE_KEY from .env.example (line 41)
- [x] Remove DASHBOARD_USERNAME from .env.example (line 42)
- [x] Remove DASHBOARD_PASSWORD from .env.example (line 43)
- [x] Remove SUPABASE_HOSTNAME from .env.example (line 84)
- [x] Remove all Supabase-specific config from .env.example (lines 123-242)

## Phase 3: Remove SearXNG Components

### 3.1 Service Removal
- [x] Remove SearXNG service from docker-compose.yml (lines 438-520)
- [x] Remove SearXNG volumes from docker-compose.yml (lines 11-13)

### 3.2 Configuration Cleanup
- [x] Remove SearXNG configuration from Caddyfile (lines 145-164)
- [x] Remove SEARXNG_HOSTNAME from .env.example (line 89)
- [x] Remove SEARXNG_UWSGI_WORKERS from .env.example (line 118)
- [x] Remove SEARXNG_UWSGI_THREADS from .env.example (line 119)
- [x] Remove SEARXNG_SECRET_KEY from .env.example (line 120)

### 3.3 Directory Cleanup
- [x] Delete `/searxng` directory and contents
- [x] Delete `/docker/searxng` directory and contents

## Phase 4: Clean Up Configuration Files

### 4.1 .env.example Reorganization
- [x] Remove unused Google auth variables (lines 106-111)
- [x] Reorganize variables into clear sections
- [x] Add helpful comments for each variable
- [x] Ensure consistent formatting

### 4.2 docker-compose.yml Optimization
- [x] Remove unused volume declarations
- [x] Clean up excessive blank lines
- [x] Ensure consistent formatting and indentation
- [x] Verify all service dependencies are correct

## Phase 5: N8N Workflow Deployment

### 5.1 Consolidate Workflows
- [x] Create `/n8n-workflows` directory if it doesn't exist
- [x] Move workflows from `/n8n/backup/workflows/` to `/n8n-workflows/`
- [x] Move workflows from `/n8n-tool-workflows/` to `/n8n-workflows/`
- [x] Delete empty `/n8n/backup` directory
- [x] Delete empty `/n8n-tool-workflows` directory

### 5.2 Enable Automatic Import
- [x] Uncomment n8n-import service in docker-compose.yml
- [x] Modify import command to exclude credentials
- [x] Add marker file logic to prevent re-imports
- [x] Update volume mounts to use consolidated workflow directory
- [x] Test import process

## Phase 6: Repository Structure Cleanup

### 6.1 Remove Redundant Directories
- [x] Delete `/docker/n8n/backup/` directory
- [x] Verify no broken symlinks remain

### 6.2 Documentation Updates
- [x] Update README.md to remove Supabase references
- [x] Update README.md to remove SearXNG references
- [x] Update SETUP_CHECKLIST.md for simplified setup
- [x] Add section about included n8n workflows
- [x] Update any other documentation referencing removed services

## Phase 7: Final Testing and Validation

### 7.1 Service Validation
- [x] Test all remaining services start correctly
- [x] Verify n8n workflows import on first run
- [x] Check all health checks are passing
- [ ] Validate Caddy routing works for all services

### 7.2 Clean Installation Test
- [x] Test complete setup from scratch
- [x] Verify minimal environment variables work
- [x] Document any issues found
- [ ] Create final commit with all changes

---

## Notes and Issues

### Known Issues
- None yet

### Decisions Made
- Keeping Neo4j, MinIO, and NCA Toolkit as they provide value
- Consolidating all n8n workflows into single directory
- Using marker file approach for one-time workflow import

### Rollback Plan
1. Restore backed up configuration files
2. Re-run docker-compose up with original files
3. Verify all services restored

---

## Completion Checklist
- [x] All Supabase components removed
- [x] All SearXNG components removed  
- [x] Configuration files cleaned and organized
- [x] N8N workflow import working
- [x] Documentation updated
- [x] Full system tested and validated
- [x] Project completed successfully