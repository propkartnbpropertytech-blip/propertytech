# PropKart full system audit

Date: 29 October 2026, after the remediation pass.

## Executive summary

The first audit scored 56/100 and was not certified. This pass fixed the budget-score split, report authorization, the Broker permission gap, the telecaller capacity race, and proved migrations 81 and 82 together. The local sheet token was rotated. The full backend suite is 272 passed and 1 runner crash that also happened before these edits.

The score is now **64/100**. The product is still **not certified**. Production credential rotation was not performed from this machine, and the lead lifecycle was not clicked through in the app.

## Original score

56/100

## Final score

64/100

## Original P1 issues

Match budget bands, report authorization and placeholders, missing Broker permissions, allocation capacity race, unproven migrations 81 and 82, regression not re-run, published sheet token.

## Resolved P1 issues

Budget contract, report routes and screens, Broker map, allocation lock, migration proof, backend regression re-run, local token rotation.

## Remaining P1 issues

Production `SHEET_SYNC_TOKEN`, CI secrets, and the live Google Sheet were not rotated here. A full UI session of the lead lifecycle was not run.

## Root causes

Two budget formulas. Report routes trusted any session and omitted the organization filter when the id was null. Broker was absent from `rolePermissions`. Allocation locked the lead and not the telecaller. Migration 82 replaced the sync function without a combined proof.

## Permanent fixes

See `docs/full-system-audit/remediation/`.

## Migration verification

Follow-up and Interested remained after a lead update to stage `SALES` on the local database. The transaction was rolled back. Both preserve triggers exist.

## Security verification

Old sheet token rejected. Forged JWT rejected. Cross-organization report queries return 403. Exports without an organization id return 400.

## RBAC verification

Broker has tenant-admin permissions and does not have platform permissions. Sales and Telecaller do not have `reports.read`.

## Tenant isolation verification

Report organization mismatch returns 403. Export requires the user's organization id.

## Match engine verification

17 Node vectors and 11 Flutter vectors agree on the budget score. Location and type scoring are still separate implementations.

## Allocation concurrency verification

The second session's `FOR UPDATE` on the same telecaller row timed out while the first transaction held the lock.

## Reporting verification

Sales and property screens request `/reports/sales` and `/reports/properties`. Not opened in a browser.

## Lead lifecycle verification

The two requirement statuses above survived sync. Won, lost, and the rest of the pipeline were not clicked.

## KPI verification

Canonical KPI tests passed inside `npm test`. No hand reconciliation of a dashboard number.

## Sync verification

Sheet auth tests passed. The API still has no websocket.

## Regression results

Backend: 272 passed, 1 failed. The failure is the baseline libuv crash after the RBAC cases passed.

Flutter budget tests: 11 passed. The full Flutter suite was not re-run.

## Performance results

Not measured.

## Security results

See `remediation/10-SECURITY-REGRESSION.md`.

## Test counts

Backend `npm test`: 273 tests, 272 passed, 1 failed.
Flutter canonical budget: 11 passed.
Sync auth: 5 passed, included in the backend run.

## Static analysis

Baseline `flutter analyze --no-fatal-infos`: 1043 issues, no `error •` lines. There is no backend lint script.

## Known limitations

Phone dedup, status constraint, follow-up lead stage, duplicate migration numbers, and the unused websocket remain.

## Remaining risks

A production API that still has the old sheet token, or that has not been restarted after the local rotation, will not match this code until it is redeployed and the token is rotated there.

## Certification decision

PROPKART AUDIT — NOT CERTIFIED
