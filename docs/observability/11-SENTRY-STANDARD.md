# 11 — Sentry Standard

## 1. Error Monitoring & Exception Tracking

PropKart integrates Sentry for real-time error detection, crash reporting, and exception lifecycle monitoring across both backend Node.js services and Flutter mobile clients.

## 2. Backend Sentry Architecture (`errorMonitoring.js`)

The backend error monitoring subsystem initializes via `initErrorMonitoring()`:
- Supports Sentry and GlitchTip DSN configurations.
- Falls back gracefully to local Winston structured error logging if no DSN is configured.
- Implements `captureException(err, context)` and `captureMessage(msg, level, context)`.
- **Pre-Dispatch Sanitization**: Centralized `redactSensitive(data)` deep-traverses error parameters, headers, and metadata to scrub sensitive keys (`password`, `token`, `secret`, `cookie`, `authorization`).

## 3. Flutter Sentry Integration (`main.dart`)

- Initialized in `main()` with custom environment tagging (`production`, `staging`, `development`) and release tags (`propkart@2.1.0+35`).
- Configures `options.beforeSend`:
  - Iterates over all exception values and deep-scrubs messages matching token or password patterns using `SentryException.copyWith(value: scrubbed)`.
  - Discards unauthorized request bodies and raw network payloads.
  - Attaches non-sensitive diagnostic breadcrumbs (BLoC events, route names, sync states).

## 4. Exception Triage & Severity Classification

- **Critical (P0)**: System crashes, unhandled database pool exhaustions, encryption key failures (immediate alert via PagerDuty/Slack).
- **High (P1)**: 5xx API errors, failed sync cycles, payment gateway timeouts.
- **Medium (P2)**: 4xx client errors exceeding baseline error rate, transient network drops.
- **Low (P3)**: Deprecated API usages, soft validation rejections.
