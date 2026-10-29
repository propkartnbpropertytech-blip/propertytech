# 02 — Feature Inventory

Status here means "present in code and how far this audit proved it." It is not a certification.

| Domain | Code entry | Proven this audit | Status |
| :--- | :--- | :--- | :--- |
| Login, refresh, logout, password reset | auth module, Flutter auth screens | Code path only | PARTIAL |
| Users, roles, activation | users module | Code path only | PARTIAL |
| Organizations and subscriptions | subscriptions module | Org delete cascade is in `3f4dd27`. Not re-run | PARTIAL |
| Properties CRUD, photos, share | properties module, property screens | Controller rejects a loaded property when the organization does not match. Not click-tested | PARTIAL |
| Requirements and lead status | requirements module and screen | Local SQL proof after migration 81. Flutter keeps a non-assigned salesperson status over Assigned | PARTIAL |
| Lead ingestion and campaigns | leads and campaign modules | Code path only | PARTIAL |
| Allocation | `allocate_waiting_leads` | Code path only. SQL transaction with `SKIP LOCKED` | PARTIAL |
| Matching | `MatchingService` and `PropertyRequirementMatcher` | Two scoring implementations found. Not executed | PARTIAL |
| KPI | `CanonicalKpiRepository`, Redis cache | Code path only. No live count reconciliation | NOT TESTABLE |
| Reports and Excel | reports routes, sheet sync | Sheet sync auth and org scope fixed and unit-tested. Report screens include placeholders | PARTIAL |
| Notifications | notifications module | Code path only | NOT TESTABLE |
| Files | upload and share modules | Code path only | NOT TESTABLE |
| Offline outbox | Flutter sync engine | Code path only. WebSocket channel is not connected | PARTIAL |
| Audit log | audit module | Code path only | NOT TESTABLE |

## Interactive surfaces traced only to a handler

Buttons, dialogs, filters, and exports were inventoried from widgets and routes. A handler existing is not proof of the database write. The coverage matrix marks those as `PARTIAL` or `NOT TESTABLE`.
