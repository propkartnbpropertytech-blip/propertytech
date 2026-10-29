# 12 — Final remediation report

Original score: 56/100. Status was not certified.

## Resolved in this pass

| ID | Result |
| :--- | :--- |
| P1-01 budget bands | One function. Node and Flutter vectors match |
| P1-02 report auth and placeholders | `reports.read`, organization check, sales and property screens load the API |
| P1-03 Broker | Tenant-admin permissions, no platform keys |
| P1-04 capacity race | Telecaller row is locked and workload is recounted. Second session blocked |
| P1-05 migrations 81 and 82 | Follow-up and Interested survived a lead sync. Rolled back |
| P1-06 regression | `npm test`: 272 passed, 1 runner crash that also happened at baseline |
| P1-07 local token | Rotated in `.env.local`. Not printed |

## Still open

- Production sheet token, CI, and the live Google Sheet were not rotated here. Restart the local API so it loads the new `.env.local` value.
- Match location and property-type scoring are still written in both Node and Dart. Budget is the shared contract.
- Phone deduplication is still check-then-insert.
- Requirement status has no database check constraint. The UI transition helper still accepts every move.
- The API has no websocket server. The Flutter sync client does not open one.
- Clients, owners, and builders routes now open their screens. Those screens were not clicked.
- No browser session ran the lead lifecycle. No latency percentiles were measured.

## Certification

PROPKART AUDIT — NOT CERTIFIED

The budget, report authorization, broker map, allocation lock, and migration interaction are fixed and tested. Production credential rotation and a full UI lifecycle are not proven, so the product is not certified.
