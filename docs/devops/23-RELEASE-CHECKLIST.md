# 23 — PRODUCTION RELEASE CHECKLIST & SIGN-OFF GATE

## 1. Pre-Deployment Stage
- [ ] Pull request reviewed and approved by at least one Principal/Senior Engineer.
- [ ] CI Pipeline (`backend-ci.yml`) passed:
  - [ ] `npm ci` clean install.
  - [ ] `npm audit --omit=dev --audit-level=high` reports 0 high/critical issues.
  - [ ] Accidental secret scanner reports 0 findings.
  - [ ] Backend test suite (239 tests) reports 100% PASS.
  - [ ] Multi-stage Docker image builds cleanly.
- [ ] Frontend CI Pipeline (`flutter-ci.yml`) passed:
  - [ ] `flutter analyze --no-fatal-infos` reports 0 errors.
  - [ ] `flutter test` reports 952/952 PASS.
- [ ] Database migrations:
  - [ ] Migration is purely additive (`CREATE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`).
  - [ ] Migration registered in `ADDITIVE_MIGRATIONS` in `src/config/ensureAdditiveSchema.js`.
  - [ ] Migration verified against local PostgreSQL container.
- [ ] Configuration & Secrets:
  - [ ] Required new environment variables added to `.env.production` on VPS.
  - [ ] No secrets or tokens committed to git.

## 2. Deployment Execution Stage
- [ ] Capture previous release commit hash (`PREV_COMMIT`).
- [ ] Ensure database backup snapshot completed within last 24 hours.
- [ ] Deploy container via `docker compose -f docker-compose.prod.yml up -d --build`.
- [ ] Monitor container logs during startup: `docker compose logs -f --tail=100 backend`.
- [ ] Verify `ensureAdditiveSchema` logs `Additive schema ensured` for all migrations.

## 3. Post-Deployment Verification Stage
- [ ] Execute production smoke test suite: `node scripts/smoke_test.js`.
  - [ ] Probe 1: Liveness 200 OK.
  - [ ] Probe 2: Readiness 200 OK (Database & Redis UP).
  - [ ] Probe 3: Prometheus metrics exposition 200 OK.
  - [ ] Probe 4: API v1 gateway root 200 OK.
  - [ ] Probe 5: Sync status schemaVersion contract 200 OK.
  - [ ] Probe 6: Correlation ID header propagation 200 OK.
- [ ] Check Sentry / errorMonitoring dashboard for anomalous error spikes.
- [ ] Formal sign-off and deployment tag pushed (`git tag -a vX.Y.Z`).
