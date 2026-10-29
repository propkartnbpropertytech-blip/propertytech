# 00 — Baseline

Recorded before the remediation edits, on 29 October 2026.

## Backend `npm test`

239 passed, 1 failed, 0 skipped. Duration about 47 seconds.

The failure is `test/rbac.team.isolation.test.js`. Every case inside that file passed. The process then hit a Windows libuv assertion (`UV_HANDLE_CLOSING`) while the test runner was closing handles. That is a runner crash, not a failed business assertion.

`npm run test:coverage` and `npm run lint` are not scripts in this repository. ESLint is installed and there is no eslint config file.

## Flutter

`flutter analyze --no-fatal-infos` finished with 1043 issues and no `error •` lines. The command exited 1 because warnings are still reported. `flutter test` for the whole client was not part of this baseline run; it was not started before the edits.

## Remediation map (not fixed at baseline)

| ID | Problem | Severity | Root cause | Layer | Planned fix |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P1-01 | Budget bands differ | P1 | Two formulas | Match module and Flutter matcher | One `scoreBudget` used by both |
| P1-02 | Reports are placeholders and only check login | P1 | UI placeholder plus `authenticate` only | Report routes, service, screens | `reports.read`, org scope, real screens |
| P1-03 | Broker missing from API permissions | P1 | `rolePermissions` has no Broker key | `permissions.js` | Tenant-admin set, no platform keys |
| P1-04 | Capacity race | P1 | Lead lock without telecaller lock | Allocation SQL | Lock the availability row, then recount |
| P1-05 | Migrations 81 and 82 unproven together | P1 | 82 replaces the sync function | Database | Rolled-back status proof on the live schema |
| P1-06 | Full suite not re-run after the sync fix | P1 | QA gap | Tests | Re-run `npm test` |
| P1-07 | Published sheet token | P1 | Value was in git history | Local env | Rotate `.env.local`. Production is an operator step |
