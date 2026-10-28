# 01 — Observability Architecture

## 1. System Vision & Architecture

The PropKart Observability Architecture establishes a unified, low-overhead, end-to-end telemetry system across the entire application stack:

```text
Flutter Mobile Client (Dart)
 ├── Logging Interceptor (Correlation ID Injection & Header Extraction)
 ├── Sentry Flutter Hub (PII/Secret Scrubbed Exception Capturing)
 ├── Sync Telemetry & Latency Instrumentation
 └── Performance Frame & Memory Watchdogs
        │
        │ HTTP / REST & Phoenix Channels (WebSocket)
        │ Headers: X-Request-Id, X-Correlation-Id
        ▼
Node.js / Express Backend (ESM)
 ├── Request Lifecycle Logger (Winston / Morgan Structured JSON)
 ├── Metrics Registry (In-Memory Histograms, P50/P90/P95/P99 Reservoirs, Prometheus /metrics)
 ├── Centralized Sentry & Error Monitoring (Token/Secret Redacted)
 ├── Canonical Health Probes (/health/liveness, /health/readiness, /health/metrics)
 └── Layered Services & Repositories
        │
        ├── PostgreSQL (Authoritative DB, Pool Stats, Slow Query Warnings)
        ├── Redis (Cache-Aside, Hit/Miss/HitRatio, In-Flight Single-Flight Tracking)
        └── Realtime (Phoenix Socket Connections, Topic Event Meters)
```

## 2. Core Pillars of Observability

1. **Structured Logging**: Standardized machine-readable JSON logging across backend (`src/config/logger.js`) and structured logging interceptor across Flutter client (`lib/core/api/logging_interceptor.dart`).
2. **Correlation & Distributed Traceability**: End-to-end propagation of `X-Request-Id` and `X-Correlation-Id` across mobile UI, network transport, Express routing, service domains, database transactions, and client responses.
3. **Application & Infrastructure Metrics**: High-performance, low-cardinality in-memory metrics registry exposing standard Prometheus format at `/metrics` and machine-readable JSON at `/health/metrics`.
4. **Error & Exception Tracking**: Centralized Sentry SDK integration on both client and server with pre-dispatch secret and PII scrubbers (`redactSensitive`).
5. **Health Probes**: Decoupled Kubernetes-ready `/health/liveness` (fast 200 OK process check) and `/health/readiness` (PostgreSQL query & Redis ping validation).

## 3. Guiding Principles & Invariants

- **Telemetry Failure Invariant**: Failure in telemetry instrumentation (e.g., metrics collection, Sentry dispatch, logging) must NEVER fail or interrupt the underlying business request (`telemetry failure != application failure`).
- **Zero Secret/PII Leakage**: Strict scrubbing of bearer tokens, passwords, refresh tokens, auth headers, and customer PII before writing to disk, stdout, or remote monitoring hubs.
- **Strict Cardinality Controls**: Metric tags and route dimensions are bounded. UUIDs, database IDs, and dynamic query strings are strictly normalized to template tokens (e.g., `:id`).
- **Performance Overhead Ceiling**: Observability instrumentation overhead must not exceed 2.0% of request latency or consume excessive heap memory.
