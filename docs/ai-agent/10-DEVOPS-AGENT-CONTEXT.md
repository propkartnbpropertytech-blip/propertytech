# 10 — DEVOPS AGENT CONTEXT & INFRASTRUCTURE STANDARDS

## 1. Production Topology & Orchestration
- **Host:** Hostinger VPS (Ubuntu Linux, Docker Engine, Docker Compose).
- **Reverse Proxy:** Nginx reverse proxy providing TLS 1.3 termination, HTTP/2 multiplexing, and request buffering.
- **Service Orchestration:** `docker-compose.prod.yml` orchestrating `backend`, `redis`, and `db`.

## 2. Resource Quotas & Limits
Explicit container constraints enforced in `docker-compose.prod.yml`:
- **`backend`:** CPU 0.50–2.00, Memory 512MB–1024MB, Log rotation `max-size: 20m` (5 files).
- **`redis`:** CPU 0.25–1.00, Memory 256MB–512MB, `allkeys-lru` eviction policy, `appendonly yes`.
- **`db`:** CPU 1.00–2.00, Memory 1024MB–2048MB, Log rotation `max-size: 20m` (5 files).

## 3. Continuous Integration & Deployment (CI/CD)
- **CI Workflows (`.github/workflows/`):**
  - `backend-ci.yml`: Lockfile verification, dependency security audit, secret scanning, full backend testing, and Docker build test.
  - `flutter-ci.yml`: Static analysis (`flutter analyze --no-fatal-infos`) and full test execution (952 tests).
- **Continuous Deployment (`deploy.yml`):**
  - Runs pre-deployment quality gates.
  - Executes remote SSH deployment on Hostinger VPS.
  - Automatically executes `scripts/smoke_test.js` against `/health/liveness` and `/health/readiness`.
  - **Auto-Rollback:** If smoke tests fail, automatically executes `git reset --hard $PREV_COMMIT`, rebuilds the previous container, and alerts the team.

## 4. Strict DevOps Rules for AI Agents
1. **Never commit secrets or credentials** to git or Dockerfiles.
2. **Never execute manual unscripted database updates** on production.
3. **Never disable automated CI/CD test gates.**
4. **Never run database restores on production databases.**
