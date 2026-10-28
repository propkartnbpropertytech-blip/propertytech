# 06 — Database Observability

## 1. PostgreSQL Authoritative Database Telemetry

PostgreSQL serves as the sole authoritative transactional database for PropKart. Telemetry is collected at the connection pool, query execution, and transaction lifecycle boundaries.

## 2. Connection Pool Metrics (`dbPool.js`)

The `dbPool` module exports `getPoolStats()` which provides real-time connection telemetry:
```json
{
  "total": 10,
  "idle": 8,
  "waiting": 0
}
```
- **Total Connections**: Current connection count allocated in the pg pool.
- **Idle Connections**: Available connections ready for immediate checkout.
- **Waiting Clients**: Number of queued asynchronous queries blocked waiting for a database socket.

## 3. Query Latency & Slow Query Warning Guardrails

- `timedQuery(sql, params)` wraps PostgreSQL query execution:
  - Records execution duration in milliseconds.
  - Queries exceeding `SLOW_QUERY_THRESHOLD_MS` (default 500ms) emit a structured `WARN` log.
  - Emitted log includes normalized SQL operation, execution duration, and caller context.
  - **SQL Parameter Scrubbing**: Parameter values (`$1, $2, ...`) are never written in raw form to prevent PII and secret disclosure.

## 4. Transaction Integrity & Rollback Telemetry

- `withTransaction(callback)` instruments transactional lifecycles:
  - Logs transaction start, savepoint creations, and successful commits.
  - On error or constraint violation, an automatic rollback is executed, and an `ERROR` log records the PostgreSQL error code (e.g., `23505` Unique Violation, `23503` Foreign Key Violation) with sanitized details.
