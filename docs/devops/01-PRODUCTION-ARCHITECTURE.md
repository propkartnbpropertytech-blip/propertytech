# 01 — PROPKART PRODUCTION TOPOLOGY & ARCHITECTURE SPECIFICATION

## 1. System Topology Overview
The PropKart production environment is designed as a resilient, multi-tiered enterprise architecture providing authoritative transactional persistence, high-throughput caching, offline-first client synchronization, and sub-second telemetry.

```text
               [ Cloudflare / CDN Edge & DDoS Shield ]
                                  │
                                  ▼
               [ Hostinger VPS Nginx Reverse Proxy / TLS ]
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
       [ Express App Engine ]          [ Express App Engine ]
       Container Instance 1            Container Instance 2
       (Node 22 Bookworm Slim)         (Node 22 Bookworm Slim)
                  │                               │
                  ├───────────────────────────────┤
                  ▼                               ▼
       [ Redis Caching Tier ]          [ PostgreSQL Tier ]
       (Cache, Mutex, Locks)           (Authoritative DB)
       Fail-Open In-Memory             ACID / RLS / Multi-Tenant
```

## 2. Tier Responsibilities & Boundaries
1. **Edge & Reverse Proxy Tier:**
   - Nginx handles TLS 1.3 termination, HTTP/2 multiplexing, gzip/brotli compression, and path routing.
   - Enforces strict security headers: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy`.
   - Reverse proxies to application port 5001 with header forwarding (`X-Forwarded-For`, `X-Forwarded-Proto`, `X-Request-Id`).

2. **Application Tier (Node.js / Express):**
   - Stateless containerized microservices running pinned Node.js 22 LTS under non-root user `node`.
   - Pure business logic layer: controllers, services, repositories, validators, telemetry wrappers.
   - Graceful shutdown lifecycle intercepting `SIGTERM` and `SIGINT` with a 10s drain window.

3. **Authoritative Persistence Tier (PostgreSQL):**
   - Single source of truth for all business data (properties, leads, requirements, audit trails, user RBAC).
   - Multi-tenant data isolation via `organization_id` foreign keys and Row-Level Security (RLS).
   - 60 additive, backward-compatible, idempotent database migrations guaranteed at boot.

4. **Cache & Coordination Tier (Redis):**
   - High-performance, fail-open cache-aside layer for canonical KPI aggregations and dashboard queries.
   - Distributed locking mutexes preventing cache stampedes.
   - Ephemeral only: Redis data loss never impacts transactional business data integrity.

## 3. Communication Protocols & Ports
- **Client to Edge:** HTTPS (Port 443) / WSS (WebSocket Secure Port 443)
- **Nginx to Node.js Backend:** HTTP (Port 5001 over Docker internal bridge network)
- **Node.js to PostgreSQL:** PostgreSQL Wire Protocol (Port 5432, SSL enabled in production)
- **Node.js to Redis:** Redis Protocol (Port 6379, password protected)
