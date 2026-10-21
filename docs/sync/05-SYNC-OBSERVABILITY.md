# PropKart Synchronization Observability & Telemetry

## 1. Observability Principles & Privacy Guardrails

PropKart implements structured, low-overhead sync telemetry to diagnose distributed replication issues, detect network degradation, monitor outbox throughput, and ensure data integrity.

### Strict Privacy & Security Invariants
- **NEVER Log**:
  - Passwords, OTPs, or API secrets.
  - JWT tokens or session cookies.
  - Plaintext Customer PII (customer names, phone numbers, email addresses).
  - Unsanitized mutation payloads containing financial or personal details.
- **ALWAYS Sanitize**:
  - Outbox requests log endpoint and entity ID, masking any payload contents.
  - Errors log machine-readable error codes and sanitized exception names, stripping raw SQL queries and internal database schema names.

---

## 2. Telemetry Schema: `SyncTelemetryRecord`

Every delta sync, startup sync, or outbox replay emits a structured telemetry payload:

```json
{
  "syncId": "c57a911e-7b3b-486d-9273-fae4e5cf428b",
  "tenantId": "c88ed9f1-5261-4e5f-8a34-e9fade752c70",
  "syncType": "DELTA", 
  "stateFrom": "CONNECTING",
  "stateTo": "LIVE",
  "startedAt": "2026-10-21T10:00:00.120Z",
  "completedAt": "2026-10-21T10:00:00.345Z",
  "durationMs": 225,
  "recordsReceived": 45,
  "recordsApplied": 12,
  "recordsSkipped": 33,
  "recordsFailed": 0,
  "outboxProcessed": 3,
  "outboxFailed": 0,
  "conflictsDetected": 1,
  "conflictsResolved": 1,
  "reconnectCount": 0,
  "lastCheckpoint": "2026-10-21T09:59:00.000Z",
  "success": true,
  "failureReason": null
}
```

---

## 3. Metrics Definitions & Thresholds

| Metric | Description | Target / SLA | Alert Threshold |
| :--- | :--- | :--- | :--- |
| **`durationMs`** | End-to-end sync execution time including diffing and Isar write. | < 250ms | > 1000ms |
| **`isarWriteMs`** | Time spent inside Isar `writeTxn`. | < 50ms | > 200ms |
| **`recordsSkipped`** | Unchanged records filtered out by pure diff comparators. | High ratio expected | N/A |
| **`outboxThroughput`** | Rate of replaying offline queued mutations. | > 20 items/sec | Stalled (> 15s) |
| **`reconnectCount`** | Number of consecutive WebSocket reconnect attempts. | 0 (steady state) | > 5 attempts |
| **`conflictsDetected`** | Number of concurrent mutations requiring arbitration. | Low (< 1%) | > 5% of records |

---

## 4. Integration with Logging Systems

1. **Local Performance Logging (`PerformanceLogger`)**:
   - High-precision timestamp metrics logged via `PerformanceLogger().logMetric()`.
   - Captured in local diagnostic ring buffer for debugging field reports.
2. **Crash & Error Reporting (`Sentry` / `GlitchTip`)**:
   - Fatal sync errors (such as local database disk full, or 401 token expiry) capture `syncId` and breadcrumbs showing the preceding state machine transitions.
   - PII is automatically scrubbed by Sentry client before dispatch.
3. **Backend Audit Trail (`/api/v1/audit/logs`)**:
   - Remote outbox submissions write audit entries with client `operationId` and user identity for traceability.
