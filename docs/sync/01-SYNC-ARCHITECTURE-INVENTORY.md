# PropKart Sync Architecture Forensic Inventory

## 1. Executive Summary

This document establishes the comprehensive forensic audit of PropKart's offline, delta sync, realtime, and outbox architecture across both the Flutter client and the Node.js / PostgreSQL backend.

In accordance with Step 9 architectural rules:
- **PostgreSQL** remains the authoritative remote source of truth.
- **Isar DB** (and its high-speed in-memory web layer) remains the authoritative local read/write cache for instant UI rendering.
- **Realtime WebSocket connections** act strictly as change notification triggers and payload transports, never bypassing transaction boundaries or persistence layers.
- **Delta Sync** and **Outbox replay** guarantee eventual consistency with deterministic conflict resolution (Field-Level Merge -> Version Counter -> Timestamp Fallback / LWW).

---

## 2. Component Inventory Matrix

| Component | Layer / Repository | Primary File / Symbol | Key Responsibilities |
| :--- | :--- | :--- | :--- |
| **SyncManager** | Flutter Core Network | `lib/core/network/sync_manager.dart` (`SyncManager`) | Orchestrates startup sync, periodic 9s delta pings, Phoenix WebSocket lifecycle, heartbeat, outbox replay, and coordinator broadcasts. |
| **SyncEngine** | Flutter Core Network | `lib/core/network/sync_engine.dart` (`SyncEngine`) | Pure functional diff computation (`computeDiff`), batch write chunker (`applyBatchedWrites`), and field-level entity comparators. |
| **NetworkInfo** | Flutter Core Network | `lib/core/network/network_info.dart` (`NetworkInfo`) | 3-second timeout health reachability prober against `/api/v1/health`. |
| **RepositoryCoordinator** | Flutter Core Storage | `lib/core/storage/repository_coordinator.dart` (`RepositoryCoordinator`) | Debounces UI notification streams (400ms properties, 800ms dashboard) to prevent isolate lockups and watcher floods. |
| **Isar Collections** | Flutter Local Storage | `lib/core/storage/isar_collections.dart` (`OutboxLocal`, `PropertyLocal`, etc.) | Schema definitions for offline storage, indexed keys (`id`, `createdAt`), and embedded data structures. |
| **OutboxLocalRepository** | Flutter Local Storage | `lib/core/storage/local_repositories.dart` (`OutboxLocalRepository`) | Durable persistence for offline mutations with in-memory web and disk-backed Isar implementations. |
| **Sync API Routes** | Backend API | `src/modules/sync/sync.routes.js` | Exposes `/api/v1/sync/status`, `/api/v1/sync/google-sheet-feed`, `/api/v1/sync/users-list`, `/api/v1/sync/live-excel`. |
| **Sync Controller** | Backend Controller | `src/modules/sync/sync.controller.js` | Enforces sync token / JWT authorization, validates query parameters, and serves feed feeds. |
| **Sync Service** | Backend Service | `src/modules/sync/sync.service.js` | Compiles live database feeds, aggregates CRM entities, and streams Excel / JSON formats. |
| **Entity Services** | Backend Controllers/Services | `src/modules/properties/`, `src/modules/requirements/` | Remote CRUD operations supporting optimistic locking, `updated_at` timestamps, and soft deletes. |

---

## 3. Detailed Component Deep-Dive

### 3.1. Flutter Client Architecture

#### 3.1.1. `SyncManager` (`lib/core/network/sync_manager.dart`)
- **Singleton Pattern**: Managed via `SyncManager()` private constructor.
- **State Machine**: Historically tracked basic states (`disconnected`, `connecting`, `connected`, `reconnecting`, `syncing`, `offline`). Extended in Step 9 to the certified 10-state deterministic FSM (`INITIALIZING`, `OFFLINE`, `CONNECTING`, `SYNCING`, `LIVE`, `DEGRADED`, `RECONNECTING`, `CONFLICT_RESOLUTION`, `ERROR`, `STOPPED`).
- **Startup Sync (`performStartupSync`)**:
  - Checks if local lookup tables exist (`hasLocalCache()`).
  - Fetches server schema version via `GET /api/v1/sync/status`.
  - Downloads and caches metadata lookup tables if server version > client cached version (`last_lookup_version`).
  - Calls `triggerDeltaSync()`.
  - Asynchronously prewarms match criteria, upload limits, and campaign leads.
- **Periodic 9s Database Ping (`pingDatabase`)**:
  - Lightweight background loop preventing stale UI states.
  - Replays outbox items via `processOutboxQueue()`.
  - Simultaneously fetches delta candidates across properties, requirements, builders, owners, clients, and dashboard.
  - Computes entity diffs and commits mutations into Isar without full table clearing.
- **Phoenix / Supabase Realtime Subscription**:
  - Connects to WebSocket endpoint with channel `realtime:propkart`.
  - Sends join message: `{"topic": "realtime:propkart", "event": "phx_join", ...}`.
  - Subscribes to table-level events (`properties`, `requirements`, `notifications`, `followups`, `site_visits`, `integration_leads`, `leads`, `campaign_connections`).
  - 30-second heartbeat ping (`{"topic": "phoenix", "event": "heartbeat", ...}`).
  - Buffers incoming events (`_incomingBuffer`) with 100ms debouncing before applying batched database updates.
  - Exponential backoff reconnect logic: `(_reconnectAttempts * 2).clamp(2, 30)` seconds.

#### 3.1.2. `SyncEngine` (`lib/core/network/sync_engine.dart`)
- **Pure Diff Computation (`computeDiff`)**:
  - Accepts `serverItems` list and `localItems` map.
  - Distinguishes items to insert, items to update, items to delete, and unchanged items.
  - Enforces `preserveLocalMetadata` to retain auto-incrementing `isarId`s for O(1) in-place row replacements.
  - Respects `pendingOutboxIds` to prevent local offline creations from being prematurely deleted by server reconciliation.
- **Batched Write Executor (`applyBatchedWrites`)**:
  - Chunks writes into configurable batches (default 100 records) to avoid holding long write transactions or starving UI thread event loops.
- **Field-Level Entity Comparators**:
  - `arePropertiesEqual`: Validates 28 distinct attributes (price, deposit, status, bedrooms, photos, amenities, etc.).
  - `areRequirementsEqual`: Compares budgets, categories, status, areas, and configurations.
  - `areBuildersEqual`, `areOwnersEqual`, `areClientsEqual`, `areFollowupsEqual`, `areDashboardsEqual`.

#### 3.1.3. Local Persistence (`lib/core/storage/isar_collections.dart` & `local_repositories.dart`)
- **Isar Database**:
  - Thread-safe binary storage with reactive query watchers.
  - Collections: `PropertyLocal`, `RequirementLocal`, `BuilderLocal`, `OwnerLocal`, `ClientLocal`, `FollowupLocal`, `DashboardLocal`, `LookupItemLocal`, `OutboxLocal`.
- **Outbox Store (`OutboxLocal`)**:
  - Tracks client-side offline mutations awaiting transmission.
  - Fields: `id` (UUID), `endpoint`, `method`, `payloadJson`, `createdAt`, `deviceId`.
  - Extended in Step 9 with: `operationId`, `entityType`, `entityId`, `operationType`, `attemptCount`, `nextAttemptAt`, `status`, `lastError`, `tenantId`.

#### 3.1.4. Network Reachability (`lib/core/network/network_info.dart`)
- Uses Dio client with 3-second hard timeout against `/health`.
- Differentiates between physical link establishment (e.g., connected to a router with no internet) and genuine application backend reachability.

---

## 4. Backend Synchronization Architecture

### 4.1. Sync Endpoints (`src/modules/sync/`)
- `GET /api/v1/sync/status`:
  - Returns `serverTime`, `schemaVersion` (currently 4), `minimumClientVersion` (18), `maintenance` (false).
  - Used by client to verify schema compatibility and determine if lookup metadata must be refreshed.
- `GET /api/v1/sync/google-sheet-feed`:
  - Authenticated via sync token (`x-sync-token` or query param) or JWT Bearer.
  - Delivers live feed of properties, requirements, and telemetry metrics.
- `GET /api/v1/sync/users-list`:
  - Returns active team members grouped by role (`Admin`, `Telecaller`, `Sales`).
- `GET /api/v1/sync/live-excel`:
  - Generates binary `.xlsx` stream with real-time database snapshot.

### 4.2. Database & Data Model Integrity
- **Timestamps**: All core tables (`properties`, `requirements`, etc.) feature `created_at` and `updated_at` columns managed via PostgreSQL triggers.
- **Soft Deletes**: Managed via `deleted_at` timestamp column, ensuring deletions are synchronized as tombstone updates rather than hard row disappearances.
- **Idempotency**: API endpoints accept `X-Idempotency-Key` or `operationId` headers to prevent duplicate records upon network retry.

---

## 5. Architectural Findings & Gaps Addressed in Step 9

1. **State Machine Completeness**:
   - Previous state machine had 6 states (`disconnected`, `connecting`, `connected`, `reconnecting`, `syncing`, `offline`).
   - Hardened to the mandatory 10 states with deterministic transition guards and reentrancy protection.
2. **Outbox Metadata Rigor**:
   - Augmented `OutboxLocal` to capture `operationId`, `entityType`, `entityId`, `operationType`, `attemptCount`, `nextAttemptAt`, `status`, `lastError`, and `tenantId`.
3. **Conflict Resolution Strategy**:
   - Replaced simplistic timestamp-only discard policy with a 3-tier deterministic conflict resolution pipeline:
     1. Field-Level Merge (non-overlapping property modifications merge cleanly).
     2. Version Counter Comparison (higher monotonically increasing version wins).
     3. Timestamp Fallback (LWW) with deterministic tie-break (lexicographical UUID comparison).
4. **Checkpoint Crash-Safety**:
   - Strict invariant enforced: Checkpoints are saved to local persistent storage *only after* the corresponding Isar `writeTxn` has committed.

---

## 6. Conclusion

The existing PropKart synchronization foundation is robust, featuring functional diffing, batching, and reactive stream throttling. The Step 9 hardening completes the distributed consistency guarantees required for high-volume offline enterprise operation.
