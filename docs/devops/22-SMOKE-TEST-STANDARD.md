# 22 — PRODUCTION SMOKE TEST SPECIFICATION & RUNBOOK

## 1. Overview & Objectives
The PropKart Smoke Test Suite (`scripts/smoke_test.js`) is an automated, zero-side-effect probe suite executed immediately following every deployment to verify critical operational contracts before releasing traffic.

```text
[ Deploy Container ] ──> [ Execute smoke_test.js ] ──> [ All 6 Probes Pass ] ──> [ Certify Deployment ]
                                     │ (Any Failure)
                                     └──> [ Auto-Rollback to PREV_COMMIT ]
```

## 2. Probe Catalog & Acceptance Criteria

| Probe # | Target Endpoint | Method | Success Criteria | Failure Action |
| :--- | :--- | :--- | :--- | :--- |
| **1. Liveness** | `/health/liveness` | `GET` | HTTP 200, `status: "UP"`, zero external I/O dependency | Abort & Rollback |
| **2. Readiness** | `/health/readiness` | `GET` | HTTP 200, `status: "UP"` (or `"DEGRADED"`), `checks.database.status: "UP"` | Abort & Rollback |
| **3. Prometheus Metrics** | `/metrics` | `GET` (Accept: text/plain) | HTTP 200, contains `http_requests_total` and memory metrics | Abort & Rollback |
| **4. API Gateway Root** | `/api/v1` | `GET` | HTTP 200, valid JSON envelope | Abort & Rollback |
| **5. Sync Status** | `/api/v1/sync/status` | `GET` | HTTP 200, contains `schemaVersion` and `serverTime` | Abort & Rollback |
| **6. Correlation Tracking** | `/api/v1` | `GET` (with `x-request-id`) | HTTP 200, response headers echo `x-request-id` and `x-correlation-id` | Abort & Rollback |

## 3. Running the Smoke Test Suite
```bash
# Against local instance
TARGET_URL="http://127.0.0.1:5001" node scripts/smoke_test.js

# Against production instance
TARGET_URL="https://api-propkart.nbpropertytech.com" node scripts/smoke_test.js
```
