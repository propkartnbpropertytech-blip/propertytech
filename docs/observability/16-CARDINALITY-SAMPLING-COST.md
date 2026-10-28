# 16 — Cardinality, Sampling & Cost Control Standard

## 1. High-Cardinality Prevention Policy

Unbounded cardinality is the primary cause of memory exhaustion in metrics registries and runaway observability costs. PropKart enforces strict compile-time and runtime guardrails to constrain dimension cardinality.

## 2. Cardinality Bounding Rules

1. **Route Normalization**:
   - Express paths are mapped to static route templates:
     `/api/v1/leads/3fa85f64-5717-4562-b3fc-2c963f66afa6` → `/api/v1/leads/:id`
     `/api/v1/properties/42` → `/api/v1/properties/:id`
   - All UUIDs (`[0-9a-f]{8}-[0-9a-f]{4}-...`) and numeric IDs (`[0-9]+`) are replaced with `:id`.
2. **Hard Route Limit**:
   - The in-memory metrics registry caps the number of unique routes at 50 (`MAX_ROUTES = 50`).
   - If an unexpected path is queried (e.g. fuzzing or bot scan), it is assigned to the catch-all dimension `OTHER`.
3. **Forbidden Dimension Tags**:
   - Never tag metrics with: `userId`, `tenantId`, `propertyId`, `leadId`, `ipAddress`, `queryString`, or `userAgent`.

## 3. Sampling & Ingest Cost Controls

| Telemetry Pillar | Production Sampling Rate | Retention Window | Cost Control Mechanism |
|:---|:---:|:---:|:---|
| **Metrics** | 100% Aggregated In-Memory | 30 days (Prometheus TSDB) | Fixed cardinality ceiling (O(1) memory complexity). |
| **HTTP Access Logs** | 100% on Errors / 10% on 2xx | 14 days | Sampled logging for high-volume read endpoints (`/health/liveness`). |
| **Distributed Traces** | 100% on Errors / 5% on 2xx | 7 days | Head-based trace sampling on mobile and backend. |
| **Sentry Exceptions** | 100% of unhandled errors | 90 days | Deduplicated via issue fingerprinting. |
| **Database Slow Logs**| 100% of queries > 500ms | 30 days | Filtered at runtime (`SLOW_QUERY_THRESHOLD_MS`). |
