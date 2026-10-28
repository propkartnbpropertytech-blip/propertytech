# 13 — REDIS PRODUCTION CONFIGURATION & FAIL-OPEN SPECIFICATION

## 1. Role of Redis in PropKart
Redis serves strictly as a **transient, cache-aside, and temporary coordination layer**.
- **PostgreSQL remains the sole authoritative store.**
- Redis stores:
  - Canonical KPI aggregations and dashboard summaries (TTL: 300s).
  - Distributed single-flight mutexes (preventing stampedes).
  - Rate limiting buckets and session nonces.

## 2. Production Configuration Parameters
In production (`docker-compose.prod.yml`):
- **Command:** `redis-server --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru --requirepass "${REDIS_PASSWORD}"`
- **Memory Limit:** Capped at 512MB RAM with strict `allkeys-lru` eviction policy.
- **Persistence:** Append-Only File (AOF) enabled for durability across restarts.
- **Protected Mode:** Bound strictly to internal Docker bridge network.

## 3. Fail-Open Architecture Guarantees
- The `CacheService` (`src/services/cache.service.js`) and `KpiCacheService` wrap all Redis commands in try-catch handlers.
- If Redis is unavailable, disconnected, or timeouts exceed 500ms, the operation logs a warning and transparently delegates to the authoritative PostgreSQL database.
- Zero client requests fail due to Redis downtime.
