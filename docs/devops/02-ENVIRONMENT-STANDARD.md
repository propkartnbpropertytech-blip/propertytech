# 02 — ENVIRONMENT SEGREGATION & STANDARD SPECIFICATION

## 1. Environment Topology Matrix
PropKart strictly enforces 3 distinct, non-overlapping environments with zero configuration bleed.

| Dimension | Local (`local`) | Staging (`staging`) | Production (`production`) |
| :--- | :--- | :--- | :--- |
| **`APP_ENV`** | `local` | `staging` | `production` |
| **Host Domain** | `localhost`, `127.0.0.1` | `staging-api.nbpropertytech.com` | `api-propkart.nbpropertytech.com` |
| **Database** | Local Docker PostgreSQL (`:54329`) | Dedicated Staging Database | Dedicated Production VPS PostgreSQL (`:5432`) |
| **Redis** | Local Docker Redis (`:6379`) | Staging In-Memory Redis | Production Redis (`appendonly yes`) |
| **TLS / SSL** | Disabled / Plaintext | Strict TLS 1.3 | Strict TLS 1.3 + HSTS Preload |
| **Log Level** | `debug` | `info` | `info` / `warn` (Structured JSON) |
| **Metrics** | `/metrics` local inspection | Prometheus Scraped | Prometheus / Alertmanager Scraped |
| **Database Restore** | Permitted (Snapshot sync) | Permitted (Controlled test) | **STRICTLY FORBIDDEN (HTTP 403 / Panic)** |

## 2. Environment Isolation Guardrails (`assertEnvIsolation`)
The backend service boots with strict, programmatic environment guardrails in `src/config/env.js`:
1. **Production Guard:**
   - If `APP_ENV === "production"`, `DATABASE_URL` and `SUPABASE_URL` must NEVER contain `localhost` or `127.0.0.1`. Attempting to boot production on localhost triggers immediate process exit.
2. **Local Guard:**
   - If `APP_ENV === "local"`, `SUPABASE_URL` and `DATABASE_URL` must NEVER reference production domains (`nbpropertytech.com` or `200.234.36.120`). Attempting to boot local on production triggers immediate process abort.
3. **Database Restore Guard:**
   - `SnapshotService.restoreSnapshotToLocal` verifies `APP_ENV !== "production"`. Any execution in production throws a fatal security exception.

## 3. Configuration Precedence Order
1. Process Environment Variables (`process.env`)
2. Pinned Environment File (`.env.production` in production, `.env.local` in local)
3. Default fallbacks in `src/config/env.js` (fail-safe defaults)
