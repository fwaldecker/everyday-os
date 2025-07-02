# Everyday‑OS • Planning

## Vision
Ship a turnkey, self‑hosted content‑automation stack managed by a single `.env`.

## Architecture Overview
Caddy serves as the reverse proxy for all user-facing services. n8n orchestrates workflows, interacting with the NCA Toolkit for content tasks, Qdrant for vector search, MinIO for object storage, and Supabase for core data and authentication.

## Constraints
- Hostinger VPS (Ubuntu 22.04)
- Developer follows **GLOBAL_RULES.md**
- Object files in MinIO auto‑purge after 7 days.

## Tech Stack & Versions
| Component | Version | Notes |
|-----------|---------|-------|
| Docker | Compose v2 | From `docker-compose-plugin` |
| Caddy | 2.8.4-alpine | Reverse Proxy |
| n8n | 1.49.1 | Automations |
| Qdrant | latest | Vector Database |
| Supabase | Postgres 15 | DB & Auth via submodule |
| MinIO | latest | Object Storage |
| NCA Toolkit | latest | Content Agent, built from source |
| Flowise | latest | *Available but disabled by default* |