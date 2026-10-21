# PropKart Synchronization Failure Injection & Recovery Matrix

## 1. Overview

Distributed offline architectures must endure brutal edge-case failures without data loss, deadlocks, infinite retry loops, or silent corruption.

This matrix documents the 16 core failure modes, the system's defensive mechanisms, and the verified recovery behavior.

---

## 2. Failure Injection Matrix

| # | Failure Mode | Injected Condition | Defensive Mechanism | Verified Recovery Outcome |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Network drops during sync** | Socket closed mid-download of delta records. | Checkpoint cursor is only advanced *after* `writeTxn` commits. Pending delta uncommitted. | On reconnect, client re-requests delta from previous checkpoint. No missing or partially committed records. |
| **2** | **Network drops during outbox upload** | POST request transmitted, network drops before HTTP response headers returned. | Client stores mutation with persistent `operationId`. Next replay resends with `X-Idempotency-Key: operationId`. | Backend idempotency detects duplicate key, returns cached response. Record created exactly once. |
| **3** | **App killed during local transaction** | OS process terminated while `writeTxn` is writing 50th of 100 records. | Isar ACID transaction rollbacks completely on uncommitted abort. | On restart, database state is pristine. Sync engine replays delta without inconsistency. |
| **4** | **App killed after remote mutation, before ack** | Server committed mutation in PostgreSQL, phone battery died before response parsed. | Outbox item remains on disk in `OutboxLocal`. | On reboot, outbox replays with identical `operationId`. Server recognizes idempotent duplicate, returns 200, outbox clears. |
| **5** | **WebSocket disconnects unexpectedly** | Server TCP connection reset or proxy timeout. | 30s heartbeat failure detected; `_handleDisconnect()` triggers exponential backoff (2s → 30s). | Client reconnects cleanly, verifies channel, triggers delta sync catch-up, transitions to `LIVE`. |
| **6** | **WebSocket sends duplicate event** | Network proxy duplicates CDC event frame. | Realtime pipeline deduplicates by entity `id` and compares `updated_at` against cached record. | Duplicate event is dropped as idempotent no-op. Zero redundant Isar writes or UI flashes. |
| **7** | **WebSocket sends malformed JSON** | Corrupted frame or syntax error received over socket. | `_handleIncomingMessage()` catches parse exceptions, drops bad frame, logs warning. | Socket remains alive; valid subsequent events processed normally. App isolate never crashes. |
| **8** | **Delta request times out (HTTP 504)** | Server under heavy load, HTTP gateway times out after 10s. | Dio request timeout triggers `catchError`; state transitions to `DEGRADED`. | Sync engine backs off and retries on next 9s ping tick without blocking UI navigation. |
| **9** | **API returns 500 Internal Error** | Temporary database connection exhaustion on backend. | Outbox processor recognizes 5xx as transient; increments `attemptCount`, calculates backoff, breaks loop. | Outbox retains operations; replayed automatically once backend service recovers. |
| **10** | **API returns 401 Unauthorized** | JWT expired while user was offline. | Auth interceptor intercepts 401; attempts refresh token. If refresh fails, sync pauses, transitions to `ERROR`. | Local Isar data is completely preserved. User prompted to re-authenticate; sync resumes immediately post-login. |
| **11** | **API returns 403 Forbidden** | User permissions altered or tenant boundary violated. | Outbox processor marks item as `FAILED` with `lastError = 'ACCESS_DENIED'`; avoids infinite retry loop. | Operation halts safely. User alerted with explanation. |
| **12** | **Redis cache unavailable** | Redis container restarted or crashed. | Backend falls back directly to PostgreSQL canonical repository; client idempotency bypasses cache to DB lock. | Mutations succeed with slightly higher latency. No data lost. |
| **13** | **PostgreSQL unavailable** | Database primary undergoing failover. | Backend returns HTTP 503 Service Unavailable. Client outbox retains operations. | Client remains functional offline; outbox flushes once PostgreSQL completes failover. |
| **14** | **Stale version mutation** | Client attempts to push update with version 2 when server is at version 5. | Optimistic concurrency check rejects mutation with 409 Conflict; triggers conflict resolver. | Conflict resolution merges non-overlapping fields or server wins; client adopts latest state. |
| **15** | **Conflicting concurrent updates** | Device A updates price; Device B updates status simultaneously. | Multi-tier conflict resolution (Tier 1 Field Merge). | Merged record contains both updates. Both users see unified correct state. |
| **16** | **Duplicate outbox operation queued** | Rapid multi-tap on UI button. | Repository coordinates local write with unique entity UUID and replaces existing pending item. | Exactly one outbox item exists for that mutation. Exactly one request dispatched. |
