# 09 — DATABASE MIGRATION & SCHEMA DISCIPLINE STANDARD

## 1. Migration Architectural Rules
All database modifications in PropKart must adhere to strict additive rules:
1. **Additive Only:**
   - Never execute destructive statements (`DROP TABLE`, `DROP COLUMN`, `ALTER TABLE ... DROP CONSTRAINT`) on active production tables.
   - New columns must either allow `NULL` or provide an explicit default value.
2. **Backward Compatibility:**
   - Database schema changes must remain compatible with previous backend releases to support zero-downtime rolling deployments (expand-contract pattern).
3. **Idempotence:**
   - Every migration script must use `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, or `DO $$ ... $$` blocks.
   - Migrations can be safely re-run multiple times without failing or creating duplicate objects.

## 2. Boot-Time Migration Assurance (`ensureAdditiveSchema`)
The PropKart backend automatically ensures schema synchronization on every startup via `src/config/ensureAdditiveSchema.js`.
- An authoritative array of 60 migrations (`ADDITIVE_MIGRATIONS`) is registered and executed in transactional blocks against `dbPool`.
- Migrations 25 through 60 (including recent 59 performance indexes and 60 telecaller qualification boundary) are validated on boot.
- If an individual migration encounters an error, a transaction rollback is issued, the error is logged, and execution continues to preserve existing live database uptime.

## 3. Migration Verification Protocol
Before submitting a migration PR:
1. Verify the migration SQL file is placed in `sql/migrations/`.
2. Register the file path in `ADDITIVE_MIGRATIONS` in `src/config/ensureAdditiveSchema.js`.
3. Run `npm test` to verify `test/devops.infrastructure.test.js` passes disk and non-empty checks.
