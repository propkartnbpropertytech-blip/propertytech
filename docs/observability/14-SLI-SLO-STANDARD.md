# 14 — Service Level Indicators (SLI) & Objectives (SLO) Standard

## 1. Executive Reliability Objectives

PropKart defines clear, measurable Service Level Objectives across API availability, request latencies, data synchronization, and mobile UI rendering performance.

## 2. Production SLI / SLO Matrix

| Domain | Service Level Indicator (SLI) | Target Objective (SLO) | Measurement Method |
|:---|:---|:---:|:---|
| **API Availability** | Ratio of non-5xx HTTP responses to total requests. | **≥ 99.9%** (Monthly) | Prometheus counter: `(total - 5xx) / total` |
| **API P95 Latency** | P95 latency of standard REST endpoints (`/api/v1/*`). | **< 200 ms** | Reservoir histogram: `http_request_duration_ms` |
| **API P99 Latency** | P99 latency across all read and write endpoints. | **< 500 ms** | Reservoir histogram: `http_request_duration_ms` |
| **KPI Query P95 Latency**| P95 execution time of canonical dashboard KPI requests. | **< 150 ms** | KPI Metrics timer & cache hit ratio |
| **Redis Cache Efficiency**| Overall cache hit ratio on repeated analytical requests. | **≥ 80.0%** | `cacheService.getMetrics().hitRatio` |
| **Database Pool Queuing** | Proportion of queries with zero wait time in pool queue. | **≥ 99.5%** | `dbPool.getPoolStats().waiting === 0` |
| **Mobile App Cold Start**| Time from process launch to first interactive frame. | **< 1,200 ms** | Sentry app start transaction measurement |
| **Mobile UI Frame Time** | Proportion of frames rendered in < 16.6ms (60 fps). | **≥ 95.0%** | Flutter frame timing callback watchdog |
| **Offline Sync Cycle** | Time to pull deltas and reconcile local Isar storage. | **< 1,000 ms** | `sync_cycle_duration_ms` |
| **Zero Data Loss Invariant**| Outbox mutations queued offline successfully replayed. | **100.0%** | Outbox audit reconciliation |

## 3. Error Budget & Burn Rate Policy

- **Monthly Error Budget (at 99.9% Availability)**: 43.8 minutes of downtime/5xx error allowance per 30-day rolling window.
- **Burn Rate 14.4x (2% budget consumed in 1 hour)**: P0 Emergency PagerDuty page triggered; automated rollback initiated if recent deployment occurred.
- **Burn Rate 6x (5% budget consumed in 6 hours)**: P1 On-Call engineer alerted; non-essential background jobs paused.
- **Burn Rate 1x (100% budget consumed in 30 days)**: Architectural freeze; reliability hardening prioritized over new features.
