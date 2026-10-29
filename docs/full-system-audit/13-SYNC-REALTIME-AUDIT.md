# 13 — Sync, Realtime, and Offline Audit

## Offline

The Flutter client writes locally and queues an outbox item. `updateLeadStatus` saves locally, queues `PUT /requirements/:id`, then rethrows so the UI does not claim success when the server call failed.

## Realtime

The sync WebSocket channel is created in code and never assigned or listened to. Live refresh depends on refetch and the outbox, not on that socket.

## Sheet sync

`GET /api/v1/sync/google-sheet-feed`, `/sync/users-list`, and `/sync/live-excel` are the live export. Before this audit, a missing `SHEET_SYNC_TOKEN` fell back to a token published in the setup guide, and a missing organization returned every tenant because the SQL adds the organization predicate only when the id is present. JWT verification also fell back to a short static secret.

After this audit, access requires the configured token or a JWT signed with `env.jwtSecret`, and the feed refuses a missing organization. A JWT organization that disagrees with the query is rejected. Five unit tests pass. The old token is still in git history and must be rotated on the server.

## Not executed

Offline create, conflict, duplicate replay, reconnect, and socket failure. Status: `NOT TESTABLE`.
