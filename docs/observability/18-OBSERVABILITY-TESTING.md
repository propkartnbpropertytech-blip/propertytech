# 18 — Observability Testing & Verification Standard

## 1. Automated Telemetry Verification

Observability components are treated as first-class production code and tested continuously through automated unit, contract, and failure-injection tests.

## 2. Test Coverage & Verification Suites

1. **Backend Observability Suite (`test/observability.telemetry.test.js`)**:
   - **Structured Logging & PII Redaction**: Validates that objects with `password`, `token`, `secret`, `cookie`, and `authorization` are masked as `[REDACTED]`.
   - **JWT & Bearer Scrubbing**: Validates that inline JWT tokens and Bearer strings embedded in error messages are scrubbed.
   - **Correlation ID Tracking**: Confirms that incoming client `X-Request-Id` and `X-Correlation-Id` are preserved, and new UUIDv4 IDs are generated when omitted.
   - **Health Probes**: Confirms `/health/liveness` returns 200 OK without I/O and `/health/readiness` performs database/Redis checks.
   - **Metrics Registry**: Confirms latency histograms, P50/P90/P95/P99 reservoirs, Prometheus exposition format, and route normalization (`:id`).
   - **Non-Blocking Telemetry Invariant**: Verifies that logging or telemetry dispatch failures never crash or fail incoming HTTP requests.
2. **Flutter Observability Suite (`test/core/observability_telemetry_test.dart`)**:
   - **LoggingInterceptor**: Validates header injection and extraction.
   - **AppLogger PII Redaction**: Validates regex masking for sensitive credentials.
   - **SyncTelemetry**: Validates SQL query stripping and token masking.
   - **Sentry BeforeSend**: Validates `SentryException.copyWith` scrubbing.

## 3. Failure Injection & Chaos Testing

- **Redis Network Failure**: Simulated connection drops verify that `CacheService` gracefully fails open, routes queries to PostgreSQL, and transitions readiness status to `DEGRADED` (200 OK) without user-facing 500 errors.
- **Malformed Header Injection**: Fuzzing request headers with CRLF (`\r\n`) and invalid characters confirms automatic sanitization to clean RFC 4122 UUIDv4 tokens.
