# 13 — Health, Readiness & Liveness Standard

## 1. Kubernetes-Ready Probe Architecture

PropKart decouples liveness, readiness, and metrics endpoints into dedicated HTTP probes to ensure zero cascading failures during rolling deployments, container restarts, and infrastructure maintenance.

## 2. Probe Specifications

### A. Liveness Probe (`GET /health/liveness` / `GET /api/v1/health/liveness`)
- **Purpose**: Verifies that the Node.js event loop and process are alive and responsive.
- **Dependency Isolation**: Performs ZERO network or external I/O (no PostgreSQL, no Redis, no Supabase).
- **Execution Target**: < 1 millisecond.
- **Response Contract (HTTP 200 OK)**:
  ```json
  {
    "status": "UP",
    "timestamp": "2026-10-21T10:00:00.000Z",
    "uptime": 124.5,
    "service": "propkart-backend",
    "version": "1.1.2"
  }
  ```

### B. Readiness Probe (`GET /health/readiness` / `GET /api/v1/health/readiness`)
- **Purpose**: Verifies whether the instance is healthy and ready to receive live user traffic.
- **Dependency Checks**:
  1. **PostgreSQL**: Executes fast `SELECT 1` probe with connection timeout (2,000ms).
  2. **Redis**: Validates `cacheService.isReady()` or pings active cache connection.
- **Response Contract**:
  - `status`: `"UP"` (200 OK) when all dependencies are green.
  - `status`: `"DEGRADED"` (200 OK) if Redis is down (since Redis is fail-open and PostgreSQL serves traffic).
  - `status`: `"DOWN"` (503 Service Unavailable) if PostgreSQL is unreachable.

### C. Health Metrics Probe (`GET /health/metrics` / `GET /metrics`)
- **Purpose**: Exposes comprehensive operational telemetry for Prometheus scraping and administrative dashboards.
- **Payload**: Full latency distributions, pool statistics, cache hit ratios, and process resource utilization.
