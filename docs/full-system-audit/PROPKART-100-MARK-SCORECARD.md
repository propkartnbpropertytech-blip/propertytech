# PropKart 100-mark scorecard

Date: 29 October 2026, after the P1 remediation pass. The original audit score was 56/100.

| # | Dimension | Score | Evidence | Still open |
| :--- | :--- | ---: | :--- | :--- |
| 1 | Authentication and session | 4/5 | Sheet token has no built-in fallback. Local token rotated. Sync auth tests passed | Production token not rotated from here |
| 2 | RBAC and authorization | 4/5 | Broker has the tenant-admin set and not the platform keys. Reports require `reports.read` | No live login as each role |
| 3 | Tenant isolation | 4/5 | Report cross-organization requests return 403. Exports require an organization id | Service role still bypasses RLS |
| 4 | Property management | 3/5 | Inventory report query added. Not clicked | Browser pass |
| 5 | Requirement management | 4/5 | Follow-up and Interested survived lead sync on a database with migrations 81 and 82 | No status check constraint |
| 6 | Lead management | 3/5 | Stage and allocation constraints unchanged | Three vocabularies remain |
| 7 | Lead ingestion | 3/5 | Enqueue failure now throws | Phone dedup is still check-then-insert |
| 8 | Lead allocation | 4/5 | Telecaller row locked, then recounted. Second session hit statement timeout | N+X live assignments were not run |
| 9 | Lead lifecycle | 3/5 | Two pipeline statuses proven under the sync trigger | Invalid transitions are still accepted |
| 10 | Match engine | 4/5 | Budget bands share one contract. 17 Node tests and 11 Flutter tests passed | Location and type scoring are still duplicated |
| 11 | KPI accuracy | 3/5 | Canonical KPI tests passed inside `npm test` | Dashboard numbers were not reconciled by hand |
| 12 | Reporting and export | 3/5 | Sales and property screens call authorized APIs | Screens were not opened in a browser |
| 13 | Database integrity | 4/5 | Preserve triggers exist. Status proof rolled back | Duplicate migration numbers 80 and 81 remain |
| 14 | API reliability | 4/5 | 272 passed, 1 runner crash whose cases had passed | Same crash as the baseline |
| 15 | Redis and cache | 3/5 | Redis suite passed inside `npm test` | Redis was not stopped |
| 16 | Offline, sync, realtime | 2/5 | Outbox unchanged. No API websocket | Channel is still unused |
| 17 | UI completeness | 3/5 | Clients, owners, and builders routes open their screens | Not clicked |
| 18 | Loading, error, empty | 2/5 | The two new report screens have those states | Other screens were not rechecked |
| 19 | Performance | 1/5 | Not measured | No percentiles |
| 20 | Observability and audit | 3/5 | Audit tests passed inside `npm test` | The status proof was not checked in `audit_logs` |
| | **Total** | **64/100** | | |

## Interpretation

64 is high risk. It is not production ready.

## Certification

PROPKART AUDIT — NOT CERTIFIED
