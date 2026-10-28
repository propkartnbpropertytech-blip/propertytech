# 12 — DISASTER RECOVERY & BUSINESS CONTINUITY PLAN

## 1. Recovery Objectives
- **Recovery Point Objective (RPO):** < 15 minutes (via continuous WAL archiving and daily cryptographic snapshots).
- **Recovery Time Objective (RTO):** < 30 minutes (via automated container redeployment and scriptable restore procedures).

## 2. Failure Scenarios & Recovery Procedures

### Scenario A: Complete Application Server / Host Crash
1. Provision replacement VPS or cloud instance.
2. Clone repository: `git clone https://github.com/propkart/propkart-backend.git`.
3. Decrypt and copy `.env.production` to host.
4. Execute `docker compose -f docker-compose.prod.yml up -d --build`.
5. Run smoke tests: `node scripts/smoke_test.js`.
6. Update DNS A record in Cloudflare to new host IP.

### Scenario B: Database Volume Corruption or Loss
1. Stop backend container to prevent partial writes: `docker compose stop backend`.
2. Retrieve latest verified daily snapshot from off-site storage.
3. Validate SHA-256 checksum against snapshot registry.
4. Restore snapshot using `pg_restore --clean`.
5. Run schema migration check: `ensureAdditiveSchema()`.
6. Clear Redis cache: `redis-cli FLUSHALL` (ensures no stale cache).
7. Start backend container: `docker compose start backend`.
8. Execute smoke test suite and verify `/health/readiness` returns status `UP`.

### Scenario C: Redis Failure / Crash
1. PropKart's caching architecture is strictly fail-open.
2. If Redis crashes, backend services continue serving HTTP traffic directly from authoritative PostgreSQL.
3. Redis restart: `docker compose restart redis`. Backend re-establishes connection automatically without downtime.
