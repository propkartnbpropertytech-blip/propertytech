# 08 — KPI Observability

## 1. Canonical KPI Architecture Observability

The KPI subsystem delivers business-critical analytics across dashboards, reports, and mobile screens. Observability guarantees precision, freshness, and cache efficiency.

## 2. KPI Telemetry Pipeline

```text
HTTP GET /api/v1/dashboard/kpis
      │
      ▼
KpiController (Metrics: kpi_requests_total)
      │
      ▼
KpiService (Stampede Protection & Cache Invalidation)
      │
      ├── Cache Check: kpiCacheService.get(cacheKey)
      │    ├── Cache Hit -> return cached JSON immediately (latency < 2ms)
      │    └── Cache Miss -> execute CanonicalKpiRepository
      ▼
CanonicalKpiRepository (Authoritative SQL Queries)
      │
      ├── Single-Flight Mutex: collapses concurrent identical queries
      ├── Half-Open Date Windows: [from, to)
      ├── Fail-Safe Tenant Scoping: (organization_id = $1)
      └── Timed Query Execution: records duration & slow query alerts
```

## 3. Monitored KPI Invariants & Metrics

- `kpi_cache_hits` & `kpi_cache_misses`: Monitored to maintain > 80% hit ratio during business hours.
- `kpi_query_duration_ms`: Execution latency for canonical queries across site visits, won metrics, lead distribution, and inventory.
- `kpi_stampede_shields`: Count of redundant database roundtrips prevented by single-flight locks.
- **Data Integrity Verification**: Zero-divisor defense ($0/0 = 0.0\%$) and backward-compatible alias verification (`deal_won` ↔ `closed_deals`).
