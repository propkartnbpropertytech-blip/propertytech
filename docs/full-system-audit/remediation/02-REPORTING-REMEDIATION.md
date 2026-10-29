# 02 — Reporting remediation

## Cause

`/api/v1/reports/*` and the executive export used `authenticate` only. The sales screen was a placeholder. The property screen was a coming-soon page. Export queries added the organization predicate only when an organization id was present, so a missing id exported every tenant.

## Fix

- Every report route requires `reports.read`. Admin, Broker, and Super Admin have it. Sales and Telecaller do not.
- `ReportsService.resolveReportOrganization` rejects a non-super-admin organization id that does not match the signed-in user, and rejects a missing organization for those roles.
- `GET /api/v1/reports/properties` returns status counts and a page of listings from `properties`. It does not invent days-on-market or absorption rates.
- `GET /api/v1/reports/sales` was already a real query. The Flutter sales screen now loads it. The property screen loads the new inventory route. Both show loading, empty, and error states.
- CSV and Excel exports require the matching read permission and an organization id on the user. A missing organization returns 400 instead of an unscoped file. Driver text is not returned to the client.

## Tests

`test/reports.organization.test.js`: admin and broker cross-organization requests return 403. A user with no organization returns 400. A super admin may name one organization. Permission membership passed.

The screens were not clicked in a browser.
