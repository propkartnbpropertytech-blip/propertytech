# 06-BACKEND-CLEANUP-PLAN.md — PropKart Backend Cleanup Execution Plan

## 1. Scope & Governance
- **Repository**: `C:/NB/PropKart-Backend`
- **Guiding Law**: Zero-Behavior-Change.
- **Invariants**:
  - PostgreSQL 16 remains authoritative.
  - Redis remains transient fail-open cache tier.
  - All 62 migrations in `sql/migrations/` remain frozen.
  - Canonical KPI repository SQL queries remain immutable.
  - Auth, RBAC, tenant boundaries (`organization_id`), and rate limits remain intact.
  - All 239 verified backend tests must remain 100% PASS.

---

## 2. Planned Operations

### Batch B1: Removal of Provably Dead Root Scratch Files
The following files have been verified to have 0 internal or external references and zero production utility:
1. `C:/NB/PropKart-Backend/scratch_check_ids.py` (Delete - Confidence 4)
2. `C:/NB/PropKart-Backend/scratch_fetch_health.py` (Delete - Confidence 4)
3. `C:/NB/PropKart-Backend/scratch_health.html` (Delete - Confidence 4)

### Batch B2: Preserved Components (Explicit Non-Deletions)
1. `scratch_vps_exec.py`: **Retained**. Imported dynamically by `scripts/backup/deploy_to_vps.py`.
2. `vps.txt`: **Retained**. Connection configuration artifact.
3. `src/middleware/notFound.middleware.js`: **Retained**. Legacy non-interfering fallback.
4. `src/middleware/validate.middleware.js`: **Retained**. Legacy non-interfering fallback.
5. All 62 `.sql` files in `sql/migrations/`: **Strictly Preserved**.
6. `package.json` dependencies: **Preserved**.

---

## 3. Post-Cleanup Verification Sequence
1. Run AI-Agent Guardrail Tests:
   `node --import ./test/setup-env.js --test test/ai_agent.guardrails.test.js`
2. Run Full Backend Test Suite:
   `npm test` (Expect 239/239 PASS)
3. Run Security & Environment Regression Checks:
   `node --import ./test/setup-env.js --test test/security.hardening.test.js`
