# 15 — Security Leak Audit

## Fixed in this audit

| Issue | Evidence | Fix |
| :--- | :--- | :--- |
| Sheet sync accepted a built-in token when `SHEET_SYNC_TOKEN` was unset | `sync.controller.js` before the edit. The same value was in the Google Sheet guide | Token comes only from the environment. The guide and connector now use placeholders |
| Unscoped live feed | `getLiveFeed` adds `organization_id` only when the query has one. Token auth set organization to null | Feed, user list, and Excel require one organization. A JWT org that conflicts with the query returns 403 |
| JWT verify fallback secret | `jwt.verify(..., process.env.JWT_SECRET \|\| "default_jwt_secret")` | Verify uses `env.jwtSecret` only |

Regression: `test/sync.auth.scope.test.js`, 5 passed.

## Still true

- The old token remains in git history. Rotate `SHEET_SYNC_TOKEN` on every deployed API and in the Google Sheet script.
- Service-role database access bypasses RLS. Isolation is application code.
- Sheet and some API 500 responses include `err.message`.
- Report and export routes that are only `authenticate` are an authorization gap. Not called live.
- Property get-by-id loads by id, then the controller compares `organization_id`. The check exists. It was not bypass-tested.

## Not found in this pass

No new hardcoded database password in the sync path. `.env.local` was not printed.
