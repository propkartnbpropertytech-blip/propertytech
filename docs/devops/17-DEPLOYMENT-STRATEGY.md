# 17 — DEPLOYMENT STRATEGY & ZERO-DOWNTIME ROLLOUT SPECIFICATION

## 1. Rolling Recreate Strategy
PropKart uses containerized rolling restarts via Docker Compose:
- **`docker-compose.prod.yml`** orchestrates the application containers.
- When new code is deployed, Docker stops the old container, replaces the container layer with the new image, and boots the new container.
- Nginx reverse proxy buffers incoming TCP connections during the restart window (typically 3–5 seconds), preventing connection drops.

## 2. Zero-Downtime Expand-Contract Database Schema Changes
To ensure seamless deployments when database changes occur:
1. **Expand Phase (Release N):**
   - New columns or tables are created with permissive defaults or NULL allowed (`ADD COLUMN IF NOT EXISTS`).
   - The old application version N continues functioning without knowledge of the new column.
2. **Deploy Phase (Release N+1):**
   - The new backend application code is deployed and writes to both old and new columns/tables.
3. **Contract Phase (Release N+2):**
   - After verification, old deprecated fields or legacy readers are safely decommissioned.

## 3. Deployment Health Verification
Every deployment executes an immediate automated smoke test:
```bash
TARGET_URL="http://127.0.0.1:5001" node scripts/smoke_test.js
```
The deployment is certified only after all 6 health probes return 200 OK.
