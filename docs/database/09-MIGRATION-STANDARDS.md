# PROPKART — DATABASE MIGRATION STANDARDS & EVOLUTION
**Version:** 1.0.0  
**Status:** CANONICAL DATABASE ENGINEERING SPECIFICATION (STEP 2)  
**Date:** October 20, 2026  
**Scope:** PostgreSQL Migration Protocols, Idempotency, Zero-Downtime DDL Rules  

---

## 1. Executive Summary & Migration Engine

PropKart utilizes a controlled, additive migration system managed via `src/config/ensureAdditiveSchema.js` and versioned SQL files located in `sql/migrations/`. 

As of Step 2, **59 migrations** have been created and validated against the production schema.

```
========================================================================================================================
                                MIGRATION PROTOCOL CORE REQUIREMENTS
========================================================================================================================
  Rule                           Standard                               Operational Requirement
------------------------------------------------------------------------------------------------------------------------
  1. Idempotency                 100% Mandatory                         Every statement must execute repeatedly without error
  2. Additive Schema Evolution   Strict Zero-Drop Policy                Columns and tables are NEVER dropped in single migrations
  3. Multi-Tenancy Defense       Tenant Constraint Mandatory            New tables must include `organization_id UUID`
  4. Timezone Uniformity         timestamptz Mandatory                  `TIMESTAMP WITH TIME ZONE` strictly enforced
  5. Safe Index Creation         IF NOT EXISTS Mandatory                Indexes created without failing on existing objects
  6. Migration Registration      ensureAdditiveSchema Entry             Every script must be registered in the additive array
========================================================================================================================
```

---

## 2. The Golden Rules of PropKart Migrations

### Rule 1: Absolute Idempotency
Migrations are executed automatically on server startup. If a migration is applied multiple times, it must never fail or corrupt existing data.

- **Tables:** `CREATE TABLE IF NOT EXISTS public.example (...);`
- **Columns:** `ALTER TABLE public.example ADD COLUMN IF NOT EXISTS remark TEXT;`
- **Functions:** `CREATE OR REPLACE FUNCTION public.fn_example() ...`
- **Triggers:** Drop trigger conditionally before recreation:
  ```sql
  DROP TRIGGER IF EXISTS trg_example ON public.example;
  CREATE TRIGGER trg_example AFTER INSERT ON public.example FOR EACH ROW EXECUTE FUNCTION fn_example();
  ```
- **Indexes:** `CREATE INDEX IF NOT EXISTS idx_example_col ON public.example (col);`

### Rule 2: Zero-Downtime Column & Table Deprecations
Dropping a column immediately breaks running backend processes that have cached query plans.

**The 3-Phase Deprecation Pattern:**
1. **Phase 1 (Additive):** Create the new column or table. Deploy backend code that writes to both old and new columns, reading from old.
2. **Phase 2 (Cutover):** Backfill historical data from old to new. Deploy backend code reading from the new column.
3. **Phase 3 (Cleanup):** Remove references in backend code. Only then mark the old column deprecated or drop it during a maintenance window.

### Rule 3: Safe Index Creation on Large Tables
On tables exceeding 50,000 rows (`notifications`, `lead_status_history`, `lead_assignment_history`):
- Standard `CREATE INDEX` takes an `SHARE` lock that permits reads but blocks all writes (`INSERT`, `UPDATE`, `DELETE`) until indexing completes.
- In high-throughput production environments, large indexes must be scheduled during low-traffic windows or created concurrently.

### Rule 4: Deterministic Data Backfills
When backfilling missing columns (such as the `organization_id` backfill in Migration 59):
- Always join against authoritative parent tables.
- Include explicit `WHERE target_col IS NULL` predicates to ensure rows are not repeatedly overwritten on subsequent server boots.
- Update `updated_at = NOW()` for auditing transparency.

---

## 3. Migration Creation Workflow for Developers

When introducing a database change:

1. **Assign Sequential Version Number:** Inspect `sql/migrations/` and take the next sequential number (e.g. `60_feature_name.sql`).
2. **Draft SQL adhering to Idempotency Rules:** Verify all statements contain `IF NOT EXISTS` or `CREATE OR REPLACE`.
3. **Register in `ensureAdditiveSchema.js`:**
   ```javascript
   const ADDITIVE_MIGRATIONS = [
     ...
     "sql/migrations/59_critical_performance_indexes.sql",
     "sql/migrations/60_feature_name.sql",
   ];
   ```
4. **Local Verification:**
   - Run `npm test` to verify test suite execution.
   - Run migration against local PostgreSQL on port 54329.
   - Run `EXPLAIN (ANALYZE, BUFFERS)` on impacted queries to verify execution plan changes.
5. **Commit:** Commit migration SQL and registration file atomically in git.
