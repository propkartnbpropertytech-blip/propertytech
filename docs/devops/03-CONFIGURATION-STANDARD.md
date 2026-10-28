# 03 — CONFIGURATION & PARAMETER MANAGEMENT STANDARD

## 1. Principles of Configuration
1. **Twelve-Factor App Compliance:** All runtime parameters must be injected via environment variables.
2. **Deterministic Defaults:** Every non-secret configuration parameter must have a safe, production-viable default in `src/config/env.js`.
3. **Strict Validation at Startup:** The system uses `envalid` and custom assertions to validate types, ranges, and URL formats before starting HTTP listeners.

## 2. Configuration Inventory & Reference

| Parameter Key | Type | Production Requirement | Default / Fallback |
| :--- | :--- | :--- | :--- |
| `NODE_ENV` | String | `production` | `development` |
| `APP_ENV` | String | `production` | `local` |
| `PORT` | Number | `5001` | `5001` |
| `DATABASE_URL` | String | Valid PostgreSQL connection string | Required |
| `SUPABASE_URL` | String | HTTPS URL pointing to cloud/VPS instance | Required |
| `SUPABASE_SERVICE_ROLE_KEY` | String | Production secret key | Required |
| `REDIS_HOST` | String | Redis server hostname / container name | `redis` |
| `REDIS_PORT` | Number | Port number | `6379` |
| `REDIS_PASSWORD` | String | Strong alphanumeric password | Empty |
| `JWT_SECRET` | String | At least 32 high-entropy characters | Required |
| `LOG_LEVEL` | String | `info` or `warn` | `info` |
| `TRUST_PROXY` | Boolean | `true` (behind Nginx reverse proxy) | `false` |
| `BODY_LIMIT` | String | Bounded JSON body size (`100kb`) | `100kb` |
| `CORS_ORIGINS` | CSV | Explicit allowlist of frontend domains | Restricted |

## 3. Immutability
Runtime configuration objects (`env`) are treated as immutable singletons across the application lifecycle. Mutation during runtime is forbidden except in designated test harnesses.
