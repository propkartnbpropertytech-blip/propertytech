# PropKart End-to-End Synchronization Lifecycle

## 1. Lifecycle Overview

The PropKart synchronization engine guarantees data availability, offline autonomy, and eventual consistency across distributed devices and the PostgreSQL remote source of truth.

The lifecycle consists of 16 deterministic phases:

```text
1. App Start
   ↓
2. Local DB Open (Isar initialization / Web in-memory fallback)
   ↓
3. Session Check & Authentication Validation
   ↓
4. Connectivity Detection & Health Ping
   ↓
5. Sync Engine Initialization
   ↓
6. Initial Metadata Sync (Lookup tables & schema verification)
   ↓
7. Delta Sync (Incremental pull since last checkpoint)
   ↓
8. Realtime Subscription (WebSocket connection & channel join)
   ↓
9. Local Mutations (Optimistic UI updates)
   ↓
10. Outbox Queuing (Atomic local transaction)
   ↓
11. Remote Mutation (Replay through HTTP API with Idempotency Key)
   ↓
12. Realtime Echo Handling (Deduplication & verification)
   ↓
13. Conflict Resolution (Field Merge -> Version Counter -> Timestamp LWW)
   ↓
14. Disconnect Handling & Exponential Backoff
   ↓
15. Reconnect & Re-authentication
   ↓
16. Post-Reconnect Reconciliation (Catch-up Delta + Outbox Flush)
```

---

## 2. Phase-by-Phase Technical Analysis

### Phase 1: App Start
- **Owner**: `main.dart` / Flutter engine.
- **Data Flow**: System initialization, dependency injection, environment configuration.
- **State**: `SyncState.INITIALIZING`.
- **Error Handling**: Fatal errors prevent UI startup and display recovery dialog.

### Phase 2: Local DB Open
- **Owner**: `IsarService` (`lib/core/storage/isar_service.dart`).
- **Data Flow**:
  - Desktop/Mobile: Opens encrypted Isar instance with all 9 collections (`PropertyLocal`, `RequirementLocal`, `BuilderLocal`, `OwnerLocal`, `ClientLocal`, `FollowupLocal`, `DashboardLocal`, `LookupItemLocal`, `OutboxLocal`).
  - Web: Uses `WebStorage` IndexedDB driver with `inMemory` mirrors.
- **Persistence**: ACID compliant binary database.
- **Observability**: `PerformanceLogger().logMetric(operation: 'Isar Init', ...)`.

### Phase 3: Session Check & Auth Validation
- **Owner**: `AuthRepository` / `ApiClient`.
- **Data Flow**: Reads stored JWT from secure storage.
- **Validation**: Verifies token presence and non-expiration. If expired, initiates refresh token flow.
- **State Transition**: If unauthenticated, transition to `SyncState.STOPPED` (or waiting). If authenticated, proceed.

### Phase 4: Connectivity Detection
- **Owner**: `NetworkInfo` (`lib/core/network/network_info.dart`).
- **Mechanism**:
  - Sends GET request to `${ApiConstants.baseUrl}/health` with 3-second hard timeout.
  - Distinguishes between physical network interface connectivity and genuine API reachability.
- **State Transition**:
  - Reachable: Transition to `SyncState.CONNECTING`.
  - Unreachable: Transition to `SyncState.OFFLINE`.

### Phase 5: Sync Engine Initialization
- **Owner**: `SyncManager` (`lib/core/network/sync_manager.dart`).
- **Mechanism**: Attaches stream listeners, prepares buffers, ensures no duplicate workers exist.

### Phase 6: Initial Metadata Sync
- **Owner**: `SyncManager.performStartupSync()`.
- **Data Flow**:
  - Query `GET /api/v1/sync/status`.
  - Compares `schemaVersion` against cached `last_lookup_version` in `SharedPreferences`.
  - If empty or version mismatch, invokes `PropertiesRepository.fetchAndSaveMetadata()` to populate cities, areas, categories, configurations, and amenities.
  - Checkpoint update: `last_lookup_version` is written *only after* local metadata persistence succeeds.

### Phase 7: Delta Sync
- **Owner**: `SyncManager.triggerDeltaSync()`.
- **State**: `SyncState.SYNCING`.
- **Data Flow**:
  - Queries server endpoints (`/properties`, `/requirements`, `/builders`, `/owners`, etc.).
  - Extracts pending outbox IDs via `_getPendingOutboxTargetIds()`.
  - Passes server lists and local maps to `SyncEngine.computeDiff<T>()`.
  - Discards unchanged rows, preserves local `isarId`s, and schedules inserts/updates/deletions.
  - Executes `SyncEngine.applyBatchedWrites()` in chunks of 100 within an Isar `writeTxn`.
  - Dispatches debounced UI updates via `RepositoryCoordinator`.

### Phase 8: Realtime Subscription
- **Owner**: `SyncManager.connect()`.
- **State**: `SyncState.LIVE`.
- **Data Flow**:
  - Opens WebSocket to Phoenix channel `realtime:propkart`.
  - Sends `phx_join` with explicit watched tables (`properties`, `requirements`, `followups`, etc.).
  - Starts 30-second periodic heartbeat timer.
  - Starts 9-second periodic database ping loop as a backup heartbeat and delta verifier.

### Phase 9: Local Mutations (Optimistic UI)
- **Owner**: Feature Repositories (e.g., `PropertiesRepository`).
- **Data Flow**:
  - User creates, updates, or deletes an entity in the UI.
  - Local repository writes immediately to Isar with temporary local ID and updated timestamp.
  - UI updates instantaneously with zero network latency.

### Phase 10: Outbox Queuing (Atomic Local Transaction)
- **Owner**: `OutboxLocalRepository` (`lib/core/storage/local_repositories.dart`).
- **Atomicity Invariant**:
  - The local entity write and the `OutboxLocal` entry creation MUST occur within the same transaction.
  - Outbox payload includes `operationId` (UUID v4), `entityType`, `entityId`, `operationType` (CREATE/UPDATE/DELETE), `payloadJson`, `createdAt`, `attemptCount` (0), `status` (PENDING), and `tenantId`.

### Phase 11: Remote Mutation (Outbox Replay)
- **Owner**: `SyncManager.processOutboxQueue()`.
- **Data Flow**:
  - Retrieves pending outbox items ordered by `createdAt` ascending.
  - Injects `X-Idempotency-Key: operationId` header into the HTTP request.
  - Replays operation via `ApiClient` (`POST`, `PUT`, `DELETE`).
  - Upon receiving HTTP 200/201: Removes item from `OutboxLocalRepository`.
  - On non-retryable 4xx (e.g., 400 validation error, 403 access denied): Marks status as FAILED with `lastError`, logs to telemetry, and alerts user.
  - On network/5xx error: Increments `attemptCount`, computes next exponential backoff timestamp, and breaks loop to prevent head-of-line hammering.

### Phase 12: Realtime Echo Handling
- **Owner**: `SyncManager._handleIncomingMessage()`.
- **Mechanism**:
  - The server broadcasts Postgres change events to all connected clients, including the originating client.
  - When the originating client receives its own echo, it checks if an active outbox item exists for that record or if the local version/timestamp is already identical.
  - If identical, the echo is recognized as an idempotent no-op and discarded without triggering UI re-render.

### Phase 13: Conflict Resolution
- **Owner**: `SyncEngine` & `SyncManager`.
- **State**: `SyncState.CONFLICT_RESOLUTION` (if complex arbitration needed) or inline resolver.
- **Resolution Pipeline**:
  1. **Field-Level Merge**: Non-conflicting attributes (e.g., Device A updated `price`, Server updated `status`) are cleanly combined.
  2. **Version Counter Comparison**: If both updated the same field, the higher monotonically increasing `version` wins.
  3. **Timestamp Fallback (LWW)**: If versions are identical, the later `updated_at` timestamp wins.
  4. **Deterministic Tie-Break**: If timestamps are identical to the millisecond, the record with the lower lexicographical UUID wins.

### Phase 14: Disconnect Handling & Exponential Backoff
- **Owner**: `SyncManager._handleDisconnect()`.
- **State**: `SyncState.RECONNECTING`.
- **Mechanism**:
  - Tears down socket, cancels heartbeat timer.
  - Increments `_reconnectAttempts`.
  - Calculates backoff delay: `delay = clamp(_reconnectAttempts * 2, 2, 30)` seconds.
  - Schedules reconnection timer.

### Phase 15: Reconnect & Re-authentication
- **Owner**: `SyncManager.connect()`.
- **Mechanism**:
  - Verifies token validity before opening socket.
  - Re-establishes WebSocket channel.
  - Transitions to `SyncState.CONNECTING`.

### Phase 16: Post-Reconnect Reconciliation
- **Owner**: `SyncManager.triggerDeltaSync()` & `processOutboxQueue()`.
- **Execution Order**:
  1. Pull remote deltas to capture server changes that occurred during disconnect.
  2. Detect conflicts between remote deltas and local pending outbox items.
  3. Resolve conflicts according to policy.
  4. Replay remaining valid outbox mutations.
  5. Apply verified delta to local Isar DB.
  6. Transition to `SyncState.LIVE`.

---

## 3. Component Ownership & Invariants Summary

| Invariant | Enforcement Mechanism |
| :--- | :--- |
| **No UI Blocking** | All diffs and Isar writes are batched (100 items/chunk) and stream-debounced (400ms-800ms). |
| **Durable Outbox** | Stored in persistent Isar database before any HTTP call is attempted. |
| **Crash Safety** | Checkpoints advance strictly after `writeTxn` commits. |
| **Zero Duplicate Mutations** | Enforced by client-generated `operationId` used as server `X-Idempotency-Key`. |
| **Tenant Isolation** | Every outbox record and realtime subscription filters by authoritative `tenantId`. |
