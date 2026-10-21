# PropKart Outbox Architecture & Idempotent Mutation Engine

## 1. Outbox Pattern Overview

The Outbox pattern guarantees **reliable, at-least-once mutation delivery** from offline client devices to the backend API without losing user actions during process crashes, network dropouts, or power loss.

---

## 2. Outbox Schema Specification

Each pending mutation is stored in `OutboxLocal`:

```dart
@collection
class OutboxLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id; // UUID v4 operation identifier

  late String endpoint; // e.g., '/properties' or '/requirements/uuid'
  late String method;   // 'POST', 'PUT', 'DELETE'
  late String payloadJson; // Sanitized JSON payload
  late DateTime createdAt; // Local enqueue timestamp
  String? deviceId; // Unique client installation ID

  // Step 9 Enterprise Hardening Attributes:
  String? operationId;   // Canonical idempotency UUID
  String? entityType;    // 'property', 'requirement', 'followup', etc.
  String? entityId;      // Target entity UUID
  String? operationType; // 'CREATE', 'UPDATE', 'DELETE'
  int attemptCount = 0;  // Number of replay attempts
  DateTime? nextAttemptAt; // Backoff schedule
  String status = 'PENDING'; // 'PENDING', 'PROCESSING', 'FAILED', 'COMPLETED'
  String? lastError;     // Diagnostic error string
  String? tenantId;      // Enforcing tenant boundary
}
```

### Prohibited Outbox Content
- **NEVER Store**:
  - API Keys, Bearer tokens, or passwords.
  - Credit card numbers or sensitive identity documents.
  - Plaintext authentication credentials.
- All requests draw the active session Bearer token dynamically at replay time from secure storage.

---

## 3. End-to-End Outbox Processing Flow

```text
                  User Action (Offline/Online)
                               │
                               ▼
               Local Atomic Database Transaction
              ┌─────────────────────────────────┐
              │ 1. Mutate Local Entity in Isar  │
              │ 2. Insert OutboxLocal Record    │
              └────────────────┬────────────────┘
                               │
                               ▼
                   Commit writeTxn Succeeded
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
     UI Updates Instantly                  Sync Engine Awakes
  (Shows "Pending Sync")                  (Checks Outbox Queue)
                                                  │
                                                  ▼
                                      Replay Outbox Item (FIFO)
                                      Add Header:
                                      X-Idempotency-Key: operationId
                                                  │
                                                  ▼
                                        Send HTTP to Backend
                                                  │
                               ┌──────────────────┴──────────────────┐
                               ▼                                     ▼
                         HTTP 200/201 Success                  HTTP Error / Timeout
                               │                                     │
                               ▼                                     ▼
                     Remove from Outbox                    Inspect Status Code
                               │                                     │
                               ▼                         ┌───────────┴───────────┐
                     UI shows "Synced"                   ▼                       ▼
                                                    4xx Client Error        5xx / Timeout
                                                    (Non-retryable)         (Retryable)
                                                         │                       │
                                                         ▼                       ▼
                                                    Mark FAILED             Increment attempt
                                                    Notify User             Schedule backoff
                                                                            Break queue loop
```

---

## 4. Idempotency Guarantees (Backend & Client)

### 4.1. The Client Retry Problem
In mobile networks, a POST/PUT request often reaches the server and commits in PostgreSQL, but the HTTP response socket closes before reaching the client (TCP reset, cell tower handoff).
If the client simply retries the mutation blindly, it risks:
- Creating duplicate properties.
- Creating duplicate requirements.
- Multiple duplicate charges or status history rows.

### 4.2. PropKart Idempotency Solution
1. Every client mutation generates a persistent `operationId = Uuid().v4()` at creation time before entering the outbox.
2. When transmitting the request, `SyncManager.processOutboxQueue()` attaches:
   ```http
   X-Idempotency-Key: <operationId>
   ```
3. Backend Idempotency Layer (certified in Step 4):
   - Caches operation outcomes in Redis keyed by `idempotency:<operationId>`.
   - If a duplicate `operationId` arrives: Returns the original cached response with `X-Cache-Lookup: HIT`.
   - Prevents duplicate database inserts while delivering HTTP 200/201 acknowledgement to the client.
4. Client receives 200/201 and safely deletes the item from `OutboxLocal`.

---

## 5. Retry Schedule & Exponential Backoff

When network requests fail due to transient timeouts or 5xx server errors:
- Head-of-line blocking prevention: The queue halts immediately on network failure to preserve order of operations.
- Backoff formula:
  $$\text{Delay} = \min(2^{\text{attemptCount}} \times 1.5, 60)\text{ seconds}$$
- Retry limit: After 5 failed attempts, the item is flagged with status `FAILED`, and the user is alerted with option to manually retry or cancel.
