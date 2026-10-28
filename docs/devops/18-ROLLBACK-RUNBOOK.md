# 18 — AUTOMATED & MANUAL ROLLBACK RUNBOOK

## 1. Automated Rollback in CI/CD Pipeline
In `.github/workflows/deploy.yml`:
- Before pulling new code, the deployment script captures `PREV_COMMIT=$(git rev-parse HEAD)`.
- If post-deployment smoke tests (`scripts/smoke_test.js`) return a non-zero exit code or fail to reach `/health/liveness` or `/health/readiness`:
  ```bash
  echo "SMOKE TEST FAILED! INITIATING AUTOMATIC ROLLBACK..."
  git reset --hard "$PREV_COMMIT"
  docker compose -f docker-compose.prod.yml up -d --build
  exit 1
  ```
- The deployment aborts, the previous working container is restored, and an alert is raised to the engineering team.

## 2. Manual Emergency Rollback Procedure
If a production issue is detected post-deployment that escaped automated tests:
1. **Identify Previous Certified Commit:**
   ```bash
   git log --oneline -n 5
   ```
2. **Revert Working Tree to Last Certified Commit:**
   ```bash
   git reset --hard <LAST_CERTIFIED_COMMIT>
   ```
3. **Rebuild & Relaunch Container:**
   ```bash
   docker compose -f docker-compose.prod.yml up -d --build
   ```
4. **Flush Stale Redis Cache:**
   ```bash
   docker exec -it propkart-redis redis-cli FLUSHALL
   ```
5. **Verify Health:**
   ```bash
   node scripts/smoke_test.js
   ```
6. **Post-Mortem:** File incident report with root cause analysis (RCA).
