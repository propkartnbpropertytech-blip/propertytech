# 06 — Database Testing Standard & Data Integrity Verification

## 1. Scope & Core Objectives

The PropKart database testing standard defines the automated verification requirements for PostgreSQL relational persistence and Isar local embedded database storage. Data integrity, strict relational consistency, tenant isolation, and transaction durability form the foundation of PropKart's enterprise architecture.

---

## 2. PostgreSQL Testing Architecture

### 2.1 Test Harness & Lifecycle Management
- **Dedicated Test Database:** All tests execute against an isolated database instance (`propkart_test`).
- **Migration Verification:** Test suites execute pending migrations prior to test execution to verify schema parity with production:
  ```bash
  npm run db:migrate:test
  ```
- **Transaction Rollback Pattern:** Wherever possible, individual tests execute within an explicit database transaction:
  ```javascript
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await testFn(client);
  } finally {
    await client.query('ROLLBACK');
    client.release();
  }
  ```
- **Deterministic Cleaners:** For tests asserting commit-dependent behaviors (e.g. outbox dispatchers or concurrent workers), tables are cleaned up using truncated cascades on test-scoped IDs.

---

## 3. Mandatory Database Verification Areas

### 3.1 Tenant Isolation & Row-Level Security (RLS)
- Every query, join, and mutation must be scoped by `tenant_id`.
- Automated test suites must explicitly create:
  1. Record $R_A$ belonging to Tenant A.
  2. Record $R_B$ belonging to Tenant B.
- Assert that an authenticated query with `tenant_id = A` strictly returns $\{R_A\}$ and zero records from Tenant B.
- Assert that an attempted `UPDATE` or `DELETE` targeting $R_B$ with `tenant_id = A` updates 0 rows and returns a `404 Not Found` or `403 Forbidden` error.

### 3.2 Foreign Keys & Cascading Rules
- Foreign keys must enforce referential integrity across all relationships:
  - `leads.campaign_id -> campaigns.id`
  - `requirements.client_id -> users.id`
  - `properties.owner_id -> users.id`
  - `kpi_snapshots.tenant_id -> tenants.id`
- Cascade deletes are strictly forbidden on primary business entities (Leads, Deals, Payments, Requirements). Foreign keys must use `ON DELETE RESTRICT` or `ON DELETE NO ACTION`.
- Soft-delete cascades (updating `deleted_at`) must be handled by application transactions and verified by integration tests.

### 3.3 Soft-Delete Verification Standard
- Soft-deleted entities (`deleted_at IS NOT NULL`) must:
  1. Be completely omitted from all standard list, search, and aggregation endpoints.
  2. Retain all historical audit logs and foreign key relationships.
  3. Be restorable only by privileged `TenantAdmin` or `SuperAdmin` roles via explicit audit-logged endpoints.

### 3.4 Concurrency & Concurrency Control
- **Lead Assignment Race Conditions:** Multiple agents attempting to claim the same lead simultaneously must be tested with concurrent promises. The query must use `SELECT ... FOR UPDATE SKIP LOCKED` or an atomic `UPDATE ... WHERE assigned_to IS NULL RETURNING id`.
- **Duplicate Prevention:** Unique constraints (e.g., `(tenant_id, email)`, `(tenant_id, phone)`, `(tenant_id, lead_id, call_session_id)`) must be tested to ensure concurrent inserts reject duplicates with a unique violation error code (`23505`).

---

## 4. Durable Outbox Pattern Testing

The PropKart transactional outbox pattern guarantees reliable event publishing even during broker downtime:

1. **Atomic Write:** The business entity mutation and outbox event insert must occur in the exact same database transaction.
2. **Outbox State Machine:**
   - `status = 'PENDING'` upon insertion.
   - Transitions to `status = 'PROCESSING'` when picked up by the poller (using `FOR UPDATE SKIP LOCKED`).
   - Transitions to `status = 'PROCESSED'` upon successful acknowledgment from Phoenix/Kafka/RabbitMQ.
   - Increments `retry_count` and updates `next_retry_at` (exponential backoff) on failure.
   - Moves to `status = 'FAILED'` after 5 failed attempts (dead-letter queue).
3. **Automated Test Scenarios:**
   - Verify outbox record created within transaction rollback is never committed.
   - Verify poller picks up pending items without duplicate deliveries.
   - Verify failed worker updates retry count and backoff timestamp.

---

## 5. Isar Local Database Testing (Flutter)

1. **Schema Integrity:**
   - Isar collections (`LocalLead`, `LocalProperty`, `LocalRequirement`, `SyncQueueItem`) are tested with in-memory or temporary directory instances (`Isar.open(..., directory: tempDir)`).
2. **Offline CRUD:**
   - Verify offline writes generate a corresponding `SyncQueueItem` with monotonically increasing timestamp and payload checksum.
3. **Clean Teardown:**
   - All tests must close and delete the Isar instance in `tearDown()` to prevent file lock leaks on Windows/macOS/Linux runners.
