# PropKart Offline Data Consistency & Transaction Integrity

## 1. Local-First Consistency Philosophy

PropKart is designed as an **offline-first enterprise CRM**. Users frequently operate in basements, rural sites, high-rise buildings with zero cellular connectivity, or transit.

The fundamental guarantee is:
> **Any operation performed offline is persisted immediately to disk, updates the UI instantaneously without artificial blocking spinners, and is guaranteed to be delivered reliably upon connectivity restoration.**

---

## 2. Invariants & Transaction Boundaries

### Invariant 1: Atomic Entity Mutation + Outbox Queuing
When an offline mutation occurs (e.g., user adds a property or updates client notes):
```text
Begin Local Isar writeTxn
  ├── 1. Put updated entity into PropertyLocal collection.
  └── 2. Put corresponding OutboxLocal request into OutboxLocal collection.
Commit writeTxn
```
**Under no circumstances can step 1 succeed and step 2 fail (or vice versa).**
If the app process is terminated or battery dies at any microsecond:
- If uncommitted: Neither the entity edit nor the outbox entry is saved; UI reverts to previous state cleanly upon relaunch.
- If committed: Both are on disk; upon restart, the outbox processor detects the queued request and syncs it.

### Invariant 2: Checkpoint Safety & Crash Invariance
When applying remote deltas to local storage:
```text
Correct Order:
  1. Receive Delta from Server
  2. Parse & Validate Schema
  3. Begin Local Isar writeTxn
  4. Write Delta Records to Collections
  5. Commit Local writeTxn
  6. Write New Checkpoint / Cursor to SharedPreferences

Incorrect Order (FORBIDDEN):
  1. Receive Delta from Server
  2. Write New Checkpoint to SharedPreferences (FATAL: Crash here loses data forever!)
  3. Begin Local Isar writeTxn
  4. Commit Local writeTxn
```
If a crash occurs before Step 5 commits, the checkpoint has NOT advanced. Upon restart, the sync engine re-requests the same delta. Because sync diffing and upserts are **strictly idempotent**, re-applying the same delta produces the identical correct state without duplicate rows.

### Invariant 3: Zero UI Lockups & Batching Limits
- Large deltas are processed in batches of 100 items (`SyncEngine.defaultBatchSize`).
- Stream notifications through `RepositoryCoordinator` are debounced:
  - Properties watcher: 400ms debounce.
  - Dashboard watcher: 800ms debounce.
- Prevents isolate stutter or 60fps frame drops when downloading 2,000+ properties during initial synchronization.

---

## 3. Delete, Restore, and Tombstone Semantics

### Deletion Tombstones
- Remote deletions do not immediately purge rows into non-existence.
- Server maintains `deleted_at` timestamp.
- When client receives a delete event or delta with `deleted_at != null`:
  - If entity exists locally in Isar, it is removed from active queries or purged from local cache.
  - If a pending local outbox mutation exists for that entity:
    - If outbox mutation is older than `deleted_at`: Outbox mutation is discarded (cannot modify a deleted entity).
    - If outbox mutation is newer than `deleted_at` (e.g. an offline restore/reactivate): Outbox mutation proceeds with a restore payload.

### Resurrected Entity Prevention
A common distributed flaw is when a stale sync delta or out-of-order realtime event resurrects a record that was already deleted.
PropKart prevents this by:
1. Maintaining deleted entity ID tombstones in memory and checking `pendingOutboxIds`.
2. Validating event timestamps against local record creation/deletion timestamps before write.
3. Rejecting any server update event whose `updated_at` is prior to a known deletion.

---

## 4. UI Representation of Offline State

The Flutter UI never misleads the user regarding synchronization reality:
- **Saved Locally**: Entity has been committed to Isar DB, outbox item queued.
- **Pending Sync**: Outbox item is awaiting network connection.
- **Syncing**: Outbox item is actively in transit.
- **Synced**: Server acknowledged HTTP 200/201, outbox item cleared.
- **Conflict**: Server had concurrent edit; resolved state displayed with notification.
- **Offline Banner**: Sticky non-intrusive indicator displayed when `SyncState == OFFLINE`.
