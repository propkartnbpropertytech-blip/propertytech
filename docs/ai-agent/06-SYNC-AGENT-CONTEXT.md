# 06 — SYNC & REALTIME AGENT CONTEXT SPECIFICATION

## 1. Sync Architecture Overview
PropKart implements an enterprise offline-first synchronization architecture:
- **Authoritative Database:** PostgreSQL.
- **Local Client Store:** Isar Database v3 (on mobile, web, and desktop).
- **Change Notifications:** Supabase / Phoenix Realtime WebSockets.
- **Offline Mutations:** Crash-safe, durable transactional Outbox (`OutboxEntry`).

## 2. The 10-State Sync Finite State Machine (FSM)
The client synchronization engine (`lib/core/network/sync_engine.dart`) transitions deterministically across 10 discrete states:
1. `uninitialized`: Initial state prior to boot.
2. `idle`: System connected and awaiting scheduled interval or change event.
3. `initialSync`: First-time bulk hydration pulling snapshot from `/api/v1/sync/snapshot`.
4. `deltaSync`: Incremental sync fetching entity deltas since `last_checkpoint_timestamp`.
5. `processingOutbox`: Draining pending offline mutations via `/api/v1/sync/mutate`.
6. `syncingRealtime`: Establishing Phoenix WebSocket channel subscriptions.
7. `paused`: Temporarily halted due to UI lifecycle backgrounding.
8. `offline`: Network disconnected; reads served exclusively from Isar local store.
9. `reconnecting`: Backoff-retry timer attempting network restoration.
10. `error`: Unrecoverable exception state requiring diagnostic intervention.

## 3. Durable Outbox Invariants
- When offline or during network failures, user mutations (lead status updates, note additions, property edits) are written to local Isar collections AND committed to `OutboxEntry`.
- Each mutation is assigned an idempotency key (UUIDv4) to guarantee exactly-once processing on the backend.
- Once connectivity is restored, the outbox drains in strict FIFO sequence.
- Conflict resolution follows **Last-Write-Wins (LWW) with Server Authority** for business entities, and **Merge-Append** for lead timelines and audit logs.
