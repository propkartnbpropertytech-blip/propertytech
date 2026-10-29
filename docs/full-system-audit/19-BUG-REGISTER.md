# 19 — Bug Register

| ID | Severity | Feature | Status after this audit |
| :--- | :--- | :--- | :--- |
| BUG-001 | P0 | Sheet sync token and cross-tenant export | Fixed in source. Local token rotated. Production token still must be rotated |
| BUG-002 | P1 | Server and Flutter budget bands differed | Fixed. One budget function. Other match categories are still duplicated |
| BUG-003 | P1 | Report and export routes are authenticate-only | Fixed. `reports.read` and an organization id are required |
| BUG-004 | P1 | Sales report is a placeholder. Property report is coming soon | Fixed in the UI. Screens load the report API. Not clicked in a browser |
| BUG-005 | P1 | Broker has no `rolePermissions` entry | Fixed. Tenant-admin set, no platform keys |
| BUG-006 | P2 | Allocation capacity race. Telecaller row is not locked | Fixed in both allocation functions. Live N+X assignment was not run |
| BUG-007 | P2 | Phone dedup is check-then-insert | Open |
| BUG-008 | P2 | Requirement status has no constraint and no invalid-transition check | Open |
| BUG-009 | P2 | Follow-up maps to lead stage INTERESTED | Open. The stage check has no follow-up value. Requirement status Follow-up is preserved |
| BUG-010 | P2 | Duplicate migration numbers 80 and 81. Migration 82 replaces the forward sync function | Interaction proven for Follow-up and Interested. Duplicate file numbers remain |
| BUG-011 | P2 | Clients, owners, and builders routes redirect to the dashboard | Fixed. Routes open the existing screens. Not clicked |
| BUG-012 | P2 | Sync WebSocket channel is never connected | Open. The API has no websocket server |
| BUG-013 | P2 | Enqueue failure can surface as an empty allocated list | Fixed. The method throws. Callers already log the error |
| BUG-014 | P3 | Service role bypasses RLS | Open |
| BUG-015 | P3 | 500 responses include driver messages on the sheet feed | Fixed for the sheet feed and the executive export |

## BUG-001 detail

User impact: anyone with the published token could download the live workbook for every organization when the query omitted `organization_id`.

Reproduction: call `/api/v1/sync/live-excel` with the token from the setup guide and no organization id, against an API that had not set `SHEET_SYNC_TOKEN`.

Root cause: the controller fell back to a constant, and the SQL omitted the organization predicate when the id was null.

Layer: sync controller and sync service query construction. The permanent change is in the controller, which now refuses to call the service without an organization id.
