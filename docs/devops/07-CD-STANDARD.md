# 07 — CONTINUOUS DEPLOYMENT (CD) & AUTOMATION STANDARD

## 1. Continuous Deployment Pipeline Architecture
PropKart implements automated deployment to Hostinger VPS via `.github/workflows/deploy.yml`.

```text
[ Git Push / Merge to main ]
            │
            ▼
[ Quality & Security Gates ]
   - npm ci
   - npm audit --omit=dev --audit-level=high
   - git secret scan
   - npm test (Full Test Suite)
            │ (Pass)
            ▼
[ SSH Action to Hostinger VPS ]
   - Capture PREV_COMMIT for rollback
   - git fetch & reset --hard origin/main
   - docker compose -f docker-compose.prod.yml up -d --build
            │
            ▼
[ Automated Post-Deployment Smoke Tests ]
   - Execute node scripts/smoke_test.js
   - Probes: /health/liveness, /health/readiness, /metrics, /api/v1
            │
     ┌──────┴──────┐
     ▼             ▼
   [PASS]        [FAIL]
 Deployment   Automatic Rollback
 Certified    to PREV_COMMIT
```

## 2. CD Invariants
1. **Pre-Deployment Test Gate:** Deploy job requires check job to pass completely. Unverified commits are never pushed to the server.
2. **Automated Verification:** The CD pipeline executes real HTTP probes against the updated instance.
3. **Automated Rollback:** If smoke tests fail or return non-200 responses, the runner automatically resets the repository to `PREV_COMMIT`, rebuilds the previous container image, and exits with error code 1.
