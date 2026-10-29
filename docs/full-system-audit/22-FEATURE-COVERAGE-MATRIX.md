# 22 — Feature Coverage Matrix

`UNKNOWN` is not used. Rows that were not run are `NOT TESTABLE`.

| Feature | Screen | API | Database | Auth | Happy path | Failure path | Status | Evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Login and session | Login | `/auth` | users, sessions | JWT | NOT TESTABLE | NOT TESTABLE | PARTIAL | Code and earlier suite |
| Property CRUD | Property screens | `/properties` | properties | Org check after load | NOT TESTABLE | NOT TESTABLE | PARTIAL | Controller read |
| Requirement status | Requirements | `/requirements` | requirements, leads | Sales path | PARTIAL | Rethrow on failed update | PARTIAL | Migration 81 proof, earlier persistence tests |
| Lead allocation | Campaign leads | allocation RPC | leads | Role checks | NOT TESTABLE | NOT TESTABLE | PARTIAL | SQL inspection |
| Match | Match UI | `/requirements/:id/matches` | properties, requirements | Config permission | NOT TESTABLE | Divergent formulas | FAIL | Two implementations |
| KPI | Dashboard | `/kpi` | canonical SQL | Role scope in repository | NOT TESTABLE | Redis not stopped | NOT TESTABLE | Authority located, numbers not reconciled |
| Sales report | Sales report | reports | n/a | UI guard only | Placeholder | n/a | FAIL | Screen is a placeholder |
| Property report | Property report | reports | n/a | UI guard only | Coming soon | n/a | FAIL | Screen is coming soon |
| Live Excel | n/a | `/sync/live-excel` | leads and related | Token or JWT plus organization | Unit tests | Missing org and bad token | PARTIAL | 5 unit tests. File not downloaded |
| Clients, owners, builders | Screens exist | modules exist | tables exist | Router redirects | Unreachable | n/a | FAIL | `app_router.dart` |
| Offline outbox | Requirements | PUT requirements | server on reconnect | Session | Local save exists | Rethrow | PARTIAL | Code. No offline drill |
| Realtime socket | n/a | gateway | n/a | n/a | Channel not connected | n/a | FAIL | Assignment missing |
| Notifications | Notification screen | notifications | notifications | Authenticate | NOT TESTABLE | NOT TESTABLE | NOT TESTABLE | Not sent |
| Audit log | Admin | `/audit` | audit_logs | Admin | NOT TESTABLE | NOT TESTABLE | NOT TESTABLE | Not queried |
| Organization delete | Admin | subscriptions | cascade | Admin | In `3f4dd27` | Not re-run | PARTIAL | Code review of the cascade |

Interactive controls that only have an `onPressed` and were not followed into SQL are covered by the PARTIAL rows above. They are not listed again as PASS.
