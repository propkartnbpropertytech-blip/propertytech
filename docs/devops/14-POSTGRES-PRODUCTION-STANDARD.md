# 14 — POSTGRESQL PRODUCTION ARCHITECTURE & TUNING SPECIFICATION

## 1. Authoritative Role & Architecture
PostgreSQL is the single authoritative source of truth for all business entities in the PropKart ecosystem:
- Enforces strict ACID compliance, relational integrity foreign keys, and multi-tenant Row Level Security.
- Partitioning and partial indexes applied to high-traffic tables (`leads`, `site_visits`, `audit_logs`).

## 2. Connection Pool Sizing & Management
The backend communicates with PostgreSQL via `node-pg` connection pool (`src/config/dbPool.js`):
- **Maximum Connections (`max`):** 20 connections per container instance.
- **Idle Timeout (`idleTimeoutMillis`):** 30,000ms.
- **Connection Timeout (`connectionTimeoutMillis`):** 5,000ms.
- **Statement Timeout (`statement_timeout`):** 15,000ms (prevents rogue runaway queries from starving connection pool).
- **Graceful Draining:** Handled during process shutdown via `dbPool.end()`.

## 3. Database Server Configuration Defaults
Recommended PostgreSQL parameter tuning for 4GB-8GB VPS hosts:
- `shared_buffers = 1GB`
- `effective_cache_size = 3GB`
- `maintenance_work_mem = 256MB`
- `checkpoint_completion_target = 0.9`
- `wal_buffers = 16MB`
- `default_statistics_target = 100`
- `random_page_cost = 1.1` (SSD storage)
- `effective_io_concurrency = 200`
- `work_mem = 16MB`
- `min_wal_size = 1GB`
- `max_wal_size = 4GB`
