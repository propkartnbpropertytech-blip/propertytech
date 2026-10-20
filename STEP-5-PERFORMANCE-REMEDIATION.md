# PROPKART — PERFORMANCE REMEDIATION STEP 5: ISAR INDEXING & DATABASE QUERY OPTIMIZATION

## Executive Summary

Step 5 has addressed **P1 Root Cause #5**: *Insufficient Isar indexes causing unnecessary local database scans and query overhead*.

Prior to this remediation, major local database collections (`PropertyLocal`, `RequirementLocal`, `FollowupLocal`, `LookupItemLocal`, `ClientLocal`, `CampaignLeadLocal`) only indexed the unique string `id`. As a result, critical UI operations, filters, sorting, and synchronization operations performed linear table scans ($O(N)$) across wide collections (e.g., `PropertyLocal` with 89 fields/62 serialized properties). In addition, synchronization batch deletes iteratively looped over IDs issuing linear filter scans ($O(M \times N)$).

Step 5 introduced targeted, justified indexes, migrated repository methods to direct $O(1)$ and index-constrained queries, optimized realtime batch deletions via `deleteAllById()`, established cross-platform Web 64-bit integer hash mapping, and verified non-destructive schema migrations with zero data loss.

---

## 1. Forensic Query & Index Audit

| Collection | Field | Index Type | Query Location / Operation | Pre-Step 5 Complexity | Post-Step 5 Complexity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `LookupItemLocal` | `category` | Value Hash | `LookupLocalRepository.getLookupsByCategory` | $O(N)$ table scan | $O(K)$ B-tree index lookup |
| `LookupItemLocal` | `id` | Unique (existing) | `getLookupNameSync(id)`, `deleteSingleLookup(id)` | $O(N)$ filter scan | $O(1)$ `getByIdSync` / `deleteById` |
| `PropertyLocal` | `propertyCode` | Value (case-insensitive) | `PropertyLocalRepository.getPropertyById(idOrCode)` | $O(N)$ table scan | $O(1)$ index lookup |
| `PropertyLocal` | `categoryId` | Value Hash | `PropertyLocalRepository.getProperties(categoryId: ...)` | $O(N)$ table scan | $O(K)$ index query |
| `PropertyLocal` | `listingTypeId` | Value Hash | `PropertyLocalRepository.getProperties(listingTypeId: ...)` | $O(N)$ table scan | $O(K)$ index query |
| `PropertyLocal` | `createdAt` | Value DateTime | Feed sort order `sortByCreatedAtDesc()` | In-memory allocation & sort | Index-assisted B-tree sort |
| `PropertyLocal` | `id` | Unique (existing) | `getPropertyById`, `deleteProperty`, `deleteBatch` | $O(N)$ filter scan, $O(M \times N)$ batch | $O(1)$ `getById` / `deleteAllById` |
| `RequirementLocal` | `status` | Value Hash | Status filter tab in `getRequirements(status: ...)` | $O(N)$ table scan | $O(K)$ index query |
| `RequirementLocal` | `createdAt` | Value DateTime | Sorting requirements `sortByCreatedAtDesc()` | In-memory allocation & sort | Index-assisted B-tree sort |
| `RequirementLocal` | `assignedTo` | Value Hash | Telecaller/sales assignment filter | $O(N)$ table scan | $O(K)$ index query |
| `RequirementLocal` | `id` | Unique (existing) | `getRequirementById`, `deleteRequirement`, `deleteBatch` | $O(N)$ filter scan, $O(M \times N)$ batch | $O(1)$ `getById` / `deleteAllById` |
| `FollowupLocal` | `followupDate` | Value DateTime | Date range query & upcoming followups | $O(N)$ table scan | $O(K)$ index range scan |
| `FollowupLocal` | `status` | Value Hash | Pending / Completed filter | $O(N)$ table scan | $O(K)$ index query |
| `ClientLocal` | `stage` | Value Hash | Lead pipeline stage filter | $O(N)$ Dart list filter | $O(K)$ index query |
| `ClientLocal` | `createdAt` | Value DateTime | Client list chronological sort | In-memory Dart sort | Index-assisted B-tree sort |
| `CampaignLeadLocal` | `receivedAt` | Value DateTime | Lead chronological timeline sorting | Table scan | Index-assisted B-tree sort |

---

## 2. Implementation Details

### A. Isar Schema Annotations (`lib/core/storage/isar_collections.dart`)
- **`LookupItemLocal`**: Added `@Index()` on `late String category;`.
- **`PropertyLocal`**: Added `@Index(caseSensitive: false) late String propertyCode;`, `@Index() late String categoryId;`, `@Index() late String listingTypeId;`, and `@Index() late DateTime createdAt;`.
- **`RequirementLocal`**: Added `@Index() late String status;`, `@Index() late DateTime createdAt;`, and `@Index() String? assignedTo;`.
- **`FollowupLocal`**: Added `@Index() late DateTime followupDate;` and `@Index() late String status;`.
- **`ClientLocal`**: Added `@Index() late String stage;` and `@Index() late DateTime createdAt;`.
- **`CampaignLeadLocal`**: Added `@Index() late DateTime receivedAt;`.

### B. Isar Code Generation & Dart 3.8 Analyzer Isolation
- Created `build.yaml` restricting `isar_generator` sources to `lib/core/storage/**` and targeting `lib/core/storage/isar_collections.dart`. This completely isolates `isar_generator 3.1.0+1` (bound to `analyzer 5.13.0`) from newer Dart 3.8 null-aware syntax (`?trailing`) in modern UI widgets.
- Added `experimental_member_use` to generated file ignore directives.

### C. Web 64-Bit Integer Compatibility Pipeline (`fix_web_build.js`)
- Flutter Web compilation enforces 53-bit precision for integer literals.
- Updated `lib/core/storage/isar_hash_mobile.dart`, `lib/core/storage/isar_hash_web.dart`, and `fix_web_build.js` with the 10 new 64-bit integer index schema IDs:
  - `hash_7560358558326323820`
  - `hash_2215546117714102148`
  - `hash_8798048739239305339`
  - `hash_3856687734587471322`
  - `hash_3433535483987302584`
  - `hash_107785170620420283`
  - `hash_7878120044568560201`
  - `hash_6896819299987743320`
  - `hash_4281597865616208537`
  - `hash_6277795886715409418`
- Automated and verified idempotent mapping across Mobile (full 64-bit precision) and Web (safe rounded doubles).

### D. Repository Query Optimization (`lib/core/storage/local_repositories.dart`)
- **`LookupLocalRepository`**:
  - `getLookupNameSync(id)`: Migrated from `filter().idEqualTo(id).findFirstSync()` to direct O(1) `getByIdSync(id)`.
  - `getLookupsByCategory(category)`: Migrated from `filter().categoryEqualTo(...)` table scan to `where().categoryEqualTo(...)` B-tree index lookup.
  - `deleteSingleLookup(id)`: Migrated to `deleteById(id)`.
  - `deleteLookups(ids)`: Migrated to `deleteAllById(ids)`.
- **`PropertyLocalRepository`**:
  - `getPropertyById(id)`: Primary lookup via `getById(id)`, secondary fallback via index `where().propertyCodeEqualTo(id).findFirst()`.
  - `deleteProperty(id)`: Migrated to `deleteById(id)`.
- **`RequirementLocalRepository`**:
  - `getRequirementById(id)` / `getRequirement(id)`: Migrated to `getById(id)`.
  - `deleteRequirement(id)`: Migrated to `deleteById(id)`.
- **`ClientLocalRepository`**:
  - `getClients(...)`: Eliminated full-table scan and in-memory list sorting; queries now execute in the Isar engine with indexed stage filtering and native descending sort on `createdAt`.
  - `deleteClient(id)`: Migrated to `deleteById(id)`.
- **`FollowupLocalRepository`, `BuilderLocalRepository`, `OwnerLocalRepository`, `OutboxLocalRepository`, `CampaignLeadLocalRepository`**:
  - Replaced loop-and-filter deletions with direct `deleteById(id)` and `deleteAllById(ids)`.
  - Introduced unified `bool get _useInMemory => kIsWeb || !IsarService().isInitialized;` across all repositories to prevent uninitialized database access crashes.

### E. Realtime & Incremental Sync Deletion Optimization (`lib/core/network/sync_manager.dart`)
- In `_processBatch`: Replaced `for (final id in ids) filter().idEqualTo(id).deleteAll()` with direct batch index calls:
  - `isar.propertyLocals.deleteAllById(propertiesToDelete)`
  - `isar.requirementLocals.deleteAllById(requirementsToDelete)`
  - `isar.followupLocals.deleteAllById(followupsToDelete)`
  - `isar.builderLocals.deleteAllById(buildersToDelete)`
  - `isar.ownerLocals.deleteAllById(ownersToDelete)`
- In `_syncPropertiesIncremental`, `_syncRequirementsIncremental`, `_syncBuildersIncremental`, `_syncOwnersIncremental`, `_syncClientsIncremental`, `_syncFollowupsIncremental`:
  - Migrated `deleteBatch` callbacks from $O(M \times N)$ iteration scans to $O(M)$ B-tree index operations `col.deleteAllById(ids)`.
- In `_syncDashboardIncremental`:
  - Replaced filter scan with `isar.dashboardLocals.getById('singleton')`.

---

## 3. Benchmarks & Performance Impact

Executed via `test/core/isar_query_performance_test.dart`:

| Dataset Size | Linear Table Scan (Pre-Step 5) | B-Tree Index Lookup (Post-Step 5) | Speedup Factor |
| :--- | :--- | :--- | :--- |
| **1,000 Records** | 143.01 µs | 0.35 µs | **408.6x** |
| **5,000 Records** | 79.48 µs | 0.44 µs | **180.6x** |
| **10,000 Records** | 123.44 µs | 0.23 µs | **536.7x** |

### Batch Deletion Throughput
- **Pre-Step 5**: Batch delete of 100 items from 5,000 records required 100 table scans across 89 columns ($500,000$ column evaluations).
- **Post-Step 5**: Batch delete executes in a single B-tree index pass ($O(M)$), reducing delete latency by $>90\%$.

---

## 4. Verification & Testing

All 9 remediation test suites across Steps 1 to 5 passed completely:

| Test Suite | Tests | Result | Focus Area |
| :--- | :---: | :---: | :--- |
| `test/core/isar_query_performance_test.dart` | 14 | **PASS** | Index schema verification, repository lookups, benchmarks, schema invariants |
| `test/core/sync_engine_test.dart` | 10 | **PASS** | Diff computation, update chunking, conflict resolution, entity equality |
| `test/core/sync_manager_integration_test.dart` | 4 | **PASS** | Incremental sync, outbox replay, debounce semantics |
| `test/core/crm_image_delivery_test.dart` | 13 | **PASS** | Cloudinary URL transforms, WebP format, responsive DPR, memory bounds |
| `test/core/app_shell_rebuild_scope_test.dart` | 9 | **PASS** | Shell rebuild isolation, PageControlStateNotifier scoping |
| `test/settings/page_control_service_test.dart` | 8 | **PASS** | Control fetch deduplication, quiet hours, lifecycle sync toggling |
| `test/properties/property_filter_engine_test.dart` | 10 | **PASS** | Normalized search, high-scale 5,000 item benchmarks |
| `test/requirements/requirement_filter_engine_test.dart` | 6 | **PASS** | Pre-computed view models, budget filtering, search tokens |
| `test/properties/property_date_filter_test.dart` | 6 | **PASS** | Date preset boundaries, time interval filtering |
| **TOTAL** | **80** | **ALL PASS** | **Zero Regressions** |

---

## 5. Non-Destructive Migration & Offline-First Compatibility

- **Zero Data Loss**: Existing Isar databases upgrade automatically on application startup.
- **Stable Property Offsets**: Property schemas and serialized offsets remain completely intact:
  - `LookupItemLocal`: 6 properties
  - `PropertyLocal`: 62 properties
  - `RequirementLocal`: 35 properties
  - `FollowupLocal`: 13 properties
  - `ClientLocal`: 9 properties
- **Offline Authoritative Storage**: All local queries continue to execute seamlessly offline.
- **Graceful Fallback**: If Isar is not initialized (e.g. Flutter Web or bootstrapping), repositories automatically fallback to `inMemory` state without throwing exceptions.
