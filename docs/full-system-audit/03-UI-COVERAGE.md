# 03 — UI Coverage

Router source: `lib/core/router/app_router.dart`.

## Reachable areas

Login, dashboard, properties list and detail, add and edit property, requirements (the leads page), lead detail actions, settings, notifications, KPI dashboard, match results, recycle bin, and role-gated drawers.

## Present but not reachable from the router

`/clients`, `/owners`, and `/builders` redirect to `/dashboard`. The screens exist. A user cannot open them through those routes.

`/telecaller/leads` opens `CampaignLeadsScreen`, not `TelecallerLeadsScreen`.

The sales report screen is a placeholder. The property report screen is a coming-soon state.

## States not exercised

Initial load, empty, error, retry, offline, slow network, permission denied, and expired session were not clicked through on every screen. No screen is marked `PASS` for those states.

## Requirement status UI

`resolveStoredRequirementStatus` keeps a salesperson's non-assigned choice when the loaded row still says Assigned, unless the server status is terminal (won, closed, reject, not interested). `updateLeadStatus` rethrows after queueing the outbox, so a failed write is not shown as success. This was proven by code inspection and by the earlier local SQL proof, not by a fresh Chrome session in this audit.
