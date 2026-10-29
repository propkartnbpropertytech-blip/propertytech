# 04 — API Coverage

Base path: `/api/v1`.

## Groups found

Auth, users, organizations, properties, requirements, leads, campaigns, allocation, matches, KPI, reports, exports, notifications, files, sync, subscriptions, audit, config.

## Authorization pattern

Most business routes use `authenticate` and then a permission or role check. Exceptions found:

- Google Sheet feed, user list, and live Excel used a shared token. This audit removed the hardcoded token and now requires `organization_id`. See `test/sync.auth.scope.test.js`.
- Several report and export routes are `authenticate` only. The Flutter UI hides reports with `RoleGuard.canViewReports`. That is not a backend authorization check.
- Builder routes were found without a permission middleware.

## Tests this audit ran

`test/sync.auth.scope.test.js`: 5 passed.

The full backend suite was not re-run in this audit. The last full run in this product cycle passed before the organization-delete commit. That does not cover the sheet-sync change beyond the new file.
