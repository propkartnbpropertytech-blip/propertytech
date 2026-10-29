# 01 — System Discovery

Discovery date: 29 October 2026. Source of truth is the code in `C:\NB\propkart` and `C:\NB\PropKart-Backend`. Documentation was used only as a pointer.

## What was executed

- Route, screen, permission, lead, allocation, match, and KPI inventory from the current source.
- Spot check of `sync.controller.js`, `sync.service.js`, property get-by-id, and migrations 81 and 82.
- `node --import ./test/setup-env.js --test test/sync.auth.scope.test.js`: 5 passed, 0 failed.
- Earlier in this product cycle, backend `npm test` and `npm run test:all` passed, and a rolled-back local SQL proof showed requirement statuses Interested and Follow-up surviving a lead update after migration 81. Those runs are supporting evidence. They are not a new click-through of every screen.

## What was not executed

No role-by-role UI session, no tenant IDOR attempt against a live API, no Redis-down or database-down drill, no latency percentiles, and no reconciliation of every KPI number from PostgreSQL to the Flutter screen. Those items are `NOT TESTABLE` in this audit, not `PASS`.

## Runtime shape

| Piece | Location | Authority |
| :--- | :--- | :--- |
| Flutter client | `C:\NB\propkart` | UI, BLoC, local Isar, outbox |
| API | `C:\NB\PropKart-Backend`, local `http://127.0.0.1:5001/api/v1` | Services and SQL |
| PostgreSQL 16 | local `127.0.0.1:54329`, database `propkart` | Business data |
| Redis | port 6379 | Transient cache, fail-open |
| Realtime | PostgREST gateway plus a Flutter WebSocket client | The sync WebSocket channel is constructed and not assigned |

Debug builds must call the local API. Release builds must not call localhost. `AppEnv` enforces that split.

## Git at discovery

- Backend `local_setup` and `main`: `3f4dd27` before this audit. This audit adds the sheet-sync scope fix and is not committed.
- Frontend `local_setup` and `main`: `1aad93e`.

## Domain map found in code

Authentication and sessions, users and roles, organizations, properties, requirements, leads, campaigns and ingestion, allocation, matching, site visits and follow-ups, KPI, reports and exports, notifications, files, subscriptions, audit logs, sync and outbox, Google Sheet live feed.

Broker, client, owner, and builder screens exist. The router sends `/clients`, `/owners`, and `/builders` to the dashboard, so those screens are not reachable from navigation.
