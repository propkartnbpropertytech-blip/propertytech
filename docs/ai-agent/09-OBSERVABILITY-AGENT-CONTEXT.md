# 09 — OBSERVABILITY AGENT CONTEXT & TELEMETRY STANDARDS

## 1. Unified Telemetry Architecture
PropKart integrates logs, metrics, distributed traces, error reporting, and health signals:

```text
[ Flutter Telemetry Interceptor ] ──(Headers: X-Request-Id, X-Correlation-Id)──> [ Express Gateway ]
                                                                                         │
          ┌──────────────────────────────────┬───────────────────────────────────────────┤
          ▼                                  ▼                                           ▼
[ In-Memory MetricsRegistry ]      [ Structured Winston / Pino ]                [ Sentry / ErrorMonitoring ]
11 Bounded Latency Buckets         Correlation ID, Duration, Status             Scrubbed Exception Traces
Prometheus Exposition (/metrics)   Redacted PII / Passwords                     beforeSend Filters
```

## 2. In-Memory Metrics Registry (`MetricsRegistry`)
Located in `src/config/metrics.js`:
- Records request throughput, status codes (`2xx`, `3xx`, `4xx`, `5xx`), and duration histograms.
- Computes exact latency percentiles (P50, P90, P95, P99) using a rolling sample reservoir.
- Normalizes dynamic URL paths (e.g. `/api/v1/properties/123e4567...` becomes `/api/v1/properties/:id`) with a strict ceiling of 50 routes to prevent metric cardinality explosion.
- Exposes Prometheus-compatible text format at `GET /metrics` (`Accept: text/plain`).

## 3. Kubernetes / Container Health Probes
- **Liveness Probe (`GET /health/liveness`):** Ultra-fast, zero-I/O process viability check returning HTTP 200 `UP`. Verifies the Node.js event loop is unblocked.
- **Readiness Probe (`GET /health/readiness`):** Verifies downstream external dependencies (PostgreSQL `SELECT 1` ping and Redis cache status).

## 4. Telemetry Non-Blocking Invariant
Telemetry operations must **NEVER** disrupt core business processing:
$$\text{Telemetry Failure} \ne \text{Application Failure}$$
Any metric emission, log writing, or Sentry dispatch error is caught locally, logged to stderr, and discarded without impacting client HTTP status codes or throwing unhandled promise rejections.
