# 05 — Metrics Standard

## 1. Metrics Architecture

PropKart features a zero-external-dependency, in-memory `MetricsRegistry` implemented in `C:\NB\PropKart-Backend\src\config\metrics.js`.

### Exposition Formats:
1. **JSON Format**: Exposed via `GET /metrics` and `GET /health/metrics` with `Accept: application/json`.
2. **Prometheus Exposition**: Exposed via `GET /metrics` with `Accept: text/plain` conforming strictly to Prometheus exposition format specifications.

## 2. Core Metric Categories & Taxonomy

| Metric Category | Metric Name | Type | Description |
|:---|:---|:---:|:---|
| **HTTP Requests** | `http_requests_total` | Counter | Total HTTP requests partitioned by method, normalized route, and status code. |
| **HTTP Errors** | `http_errors_total` | Counter | Total HTTP 4xx and 5xx errors. |
| **HTTP Latency** | `http_request_duration_ms` | Histogram | Latency histogram with buckets: 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1000ms, 2500ms, 5000ms, 10000ms. |
| **Percentiles** | Reservoir P50, P90, P95, P99 | Gauge | Latency percentiles computed via bounded reservoir sampling (1,024 samples). |
| **Process CPU** | `process_cpu_user_seconds_total`, `process_cpu_system_seconds_total` | Gauge | Node.js process CPU user and system utilization. |
| **Process Memory** | `process_resident_memory_bytes`, `nodejs_heap_size_used_bytes` | Gauge | RSS, heap total, and heap used memory in bytes. |
| **PostgreSQL Pool** | `pg_pool_total`, `pg_pool_idle`, `pg_pool_waiting` | Gauge | Active connections, idle connections, and queued query counts. |
| **Redis Cache** | `redis_hits_total`, `redis_misses_total`, `redis_hit_ratio` | Gauge / Counter | Cache efficiency, single-flight stampede shields, and memory bytes stored. |
| **KPI Metrics** | `kpi_cache_hits`, `kpi_cache_misses`, `kpi_cache_hit_ratio` | Gauge / Counter | KPI cache performance and query delegation counters. |
| **Phoenix Realtime** | `realtime_events_total`, `realtime_events_dropped` | Counter | Active connections, joined topics, and delivered realtime events. |

## 3. Cardinality Control Guarantees

- **Route Normalization**: High-cardinality route fragments (UUIDs, integer IDs, hashes) are collapsed into `:id` before recording into the metrics map.
- **Maximum Route Entries**: The metrics map caps tracked unique routes at 50 patterns. Any anomalous path beyond the ceiling collapses into `OTHER`.
- **Query Parameter Exclusion**: URL query parameters (`?page=1&filter=foo`) are stripped from metric keys.
