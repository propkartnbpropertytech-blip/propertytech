# 09 — DATABASE SECURITY & POSTGRESQL HARDENING

## 1. Database Architecture & Roles

PropKart uses PostgreSQL hosted with secure connection pooling via `dbPool` (`node-pg`).
- **Connection Transport**: TLS/SSL enabled in production.
- **Connection Secrets**: Passwords and connection URLs loaded exclusively from environment variables (`DATABASE_URL`, `SUPABASE_DB_URL`).
- **Zero Raw Query Concatenation**: All database operations use prepared parameterized statements (`$1, $2, ...`) or safe query builder methods (`.eq()`, `.ilike()`). User input is NEVER concatenated into raw SQL strings.

---

## 2. In-Code Architectural Guard & Schema Rules

Enforced via `src/security/architecturalGuard.js` and verified by `test/architecture.contract.test.js`:
1. **Banned Shadow Tables**:
   - Creating clone tables such as `deleted_properties` or `deleted_property_images` is forbidden.
   - Deletions MUST use native soft delete with the standard `deleted_at` timestamp.
2. **Dropped Bloat Tables**:
   - Re-introducing abandoned experiment tables (`form_fields`, `form_submissions`, `submission_media`, etc.) is blocked.
3. **Mandatory Standard Columns**:
   - Every primary business table (`leads`, `requirements`, `properties`, `users`, `followups`, `site_visits`, `clients`, `owners`) must possess `organization_id`, `created_at`, and `updated_at`.

---

## 3. SQL Injection Defense Verification

1. **Prepared Parameterization**:
   - `SELECT * FROM properties WHERE organization_id = $1 AND id = $2`
   - Even if an attacker supplies `id = "1' OR '1'='1"`, PostgreSQL treats it strictly as a literal text parameter.
2. **PostgREST Sanitization (`searchSanitize.js`)**:
   - The query filter helper strips punctuation and syntax tokens before passing to PostgREST/Supabase clients.
   - Tested in `test/security.hardening.test.js` and `test/security/backend_security_matrix.test.js`.

---

## 4. Transactional Integrity

- Multi-table mutations (e.g. creating a lead and associated requirement, or reassigning team pipelines) are wrapped in `BEGIN ... COMMIT` transactional boundaries.
- On error, `ROLLBACK` is executed immediately, leaving the database in a clean, consistent state.
