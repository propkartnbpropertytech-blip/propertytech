# PropKart Conflict Resolution Specification

## 1. Conflict Resolution Philosophy & Pipeline

In a distributed offline-first system, concurrent edits across multiple devices or between a disconnected client and the central server are inevitable.

PropKart implements a deterministic, multi-tiered conflict resolution pipeline:

```text
               Concurrent Mutation Detected
                            │
                            ▼
           Tier 1: Field-Level Merge Analysis
            (Are modified fields disjoint?)
                    ├── YES ──► Merge non-overlapping fields safely
                    │           (Both valid updates survive)
                    └── NO (Overlapping field collision)
                            │
                            ▼
           Tier 2: Version Counter Comparison
            (Are version numbers available?)
                    ├── YES ──► Higher version counter wins
                    └── NO / Tied
                            │
                            ▼
           Tier 3: Timestamp Fallback (LWW)
            (Compare authoritative updated_at)
                    ├── Distinct ──► Later timestamp wins
                    └── Tied (Exact ms match)
                            │
                            ▼
           Tier 4: Deterministic Tie-Break
            (Lexicographical entityId or UUID comparison)
```

---

## 2. Entity Conflict Resolution Profiles

### 2.1. Property Entity (`PropertyLocal` / `properties` table)
- **Conflict Key**: `id` (UUID v4)
- **Version Field**: `version` (INTEGER, default 1, incremented on every update)
- **Timestamp Field**: `updated_at` (TIMESTAMPTZ, UTC ISO-8601)
- **Field Merge Rules**:
  - Independent field groups can merge concurrently:
    - Group A (Financials): `price`, `deposit`, `maintenance`, `brokerage_type_id`.
    - Group B (Status): `property_status_id`, `listing_type_id`.
    - Group C (Content): `title`, `description`, `images`, `videos`, `amenities`.
    - Group D (Contact): `owner_name`, `owner_mobile`, `builder_id`.
  - If Device A updates `price` while Device B updates `property_status_id`, the merged record retains Device A's new price and Device B's new status.
- **Winner Rules for Overlapping Collisions**:
  1. Higher `version` wins.
  2. If versions are identical, the later `updated_at` wins.
  3. If timestamps match, smaller lexicographical `operationId` wins.
- **Loser Handling**:
  - If the client's outbox mutation loses, the outbox record is removed or marked as `RESOLVED_CONFLICT_SUPERSEDED`.
  - Local Isar state is updated with the winning merged state.
- **Audit Behavior**: Telemetry event logged with `conflictsDetected: 1, conflictsResolved: 1`.

### 2.2. Requirement Entity (`RequirementLocal` / `requirements` table)
- **Conflict Key**: `id` (UUID v4)
- **Version Field**: `version` (INTEGER)
- **Timestamp Field**: `updated_at` (TIMESTAMPTZ, UTC ISO-8601)
- **Field Merge Rules**:
  - Budget & Configuration group: `min_budget`, `max_budget`, `configuration_ids`.
  - Status group: `status` (e.g. 'Active', 'Deal Closed', 'Cold').
  - Location group: `city_id`, `area_ids`.
- **Winner Rules**:
  - Status transitions to terminal states (e.g., 'Deal Closed') take priority over intermediate modifications if versions collide.
  - Otherwise, version counter followed by `updated_at` timestamp.

### 2.3. Followup Entity (`FollowupLocal` / `followups` table)
- **Conflict Key**: `id` (UUID v4)
- **Timestamp Field**: `followup_date`, `created_at`
- **Field Merge Rules**:
  - Remarks appending: When remarks differ, new remarks are concatenated with timestamp and author metadata rather than silently overwritten.
  - Completed status: Marking a followup completed (`is_completed = true`) is an absorbing state.

### 2.4. Dashboard Metrics (`DashboardLocal`)
- **Conflict Key**: Singleton ID (`singleton`)
- **Strategy**: Dashboards are derived read-only snapshots computed authoritatively by PostgreSQL. Local state is unconditionally overwritten by the latest server calculation. No field-level merge is performed.

---

## 3. Concrete Conflict Scenarios & Verification

### Scenario A: Same record, disjoint fields
```text
Initial State:
  Property P1 (version: 1, price: 10,00,000, status: "Available")

Device A (offline):
  Sets price = 12,00,000 (modified fields: [price])

Device B (online / server):
  Sets status = "Rented" (modified fields: [status], version: 2)

Reconciliation Output:
  Property P1 merged state:
  - price: 12,00,000 (from Device A)
  - status: "Rented" (from Device B)
  - Result: BOTH valid changes survive. Zero data loss.
```

### Scenario B: Same record, overlapping field collision
```text
Initial State:
  Property P1 (version: 1, price: 10,00,000)

Device A (offline at 10:00:00):
  Sets price = 11,00,000 (local timestamp: 10:00:00)

Device B (online at 10:05:00):
  Sets price = 12,00,000 (server timestamp: 10:05:00, version: 2)

Reconciliation Output:
  - Tier 1: Overlapping collision on 'price'.
  - Tier 2: Server version (2) > Device A version (1).
  - Winner: Device B (price: 12,00,000).
  - Device A outbox item is purged; local Isar record updated to 12,00,000.
```

### Scenario C: Stale client version vs Newer server version
```text
Local Version = 3
Remote Version = 6

Resolution:
  Remote version strictly dominates. Local stale mutation is discarded to prevent resurrecting historical states.
```

### Scenario D: Identical timestamps (Exact Millisecond Collision)
```text
Device A: updated_at = 2026-10-21T10:00:00.000Z, operationId = "aaa-..."
Device B: updated_at = 2026-10-21T10:00:00.000Z, operationId = "bbb-..."

Resolution:
  Deterministic tie-break compares operationId strings: "aaa-..." < "bbb-...".
  Device A wins deterministically across all nodes.
```

---

## 4. Architectural Rules

1. **Deterministic Winner Guarantee**: For any given pair of mutations $(M_1, M_2)$, every node in the PropKart topology must independently compute the exact same winning state.
2. **Tombstone Protection**: A soft-deleted record (`deleted_at != null`) cannot be resurrected by an older update mutation whose timestamp is earlier than `deleted_at`.
3. **Audit Logging**: All conflict arbitrations must emit structured telemetry logging the entity type, ID, resolution tier, and winner reason.
