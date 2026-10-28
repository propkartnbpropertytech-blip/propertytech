# 10 — Flutter Observability

## 1. Mobile Client Telemetry Architecture

The Flutter application architecture integrates telemetry into BLoC state transitions, Dio HTTP networking, Isar database transactions, and UI frame rendering.

## 2. Core Flutter Observability Components

1. **LoggingInterceptor (`lib/core/api/logging_interceptor.dart`)**:
   - Generates and injects `X-Request-Id` and `X-Correlation-Id` into outgoing HTTP requests.
   - Extracts server-returned request IDs and latency headers.
   - Scrubs passwords, bearer tokens, and refresh tokens from URL logs and payload dumps.
2. **AppLogger (`lib/core/utils/app_logger.dart`)**:
   - Centralizes console and remote logging with categorized logging channels (`AppLogger.network`, `AppLogger.sync`, `AppLogger.database`).
   - Applies regex-based redaction patterns for Authorization headers, JWT tokens, and PII.
3. **SyncTelemetry (`lib/core/network/sync_telemetry.dart`)**:
   - Tracks sync execution metrics, outbox replay durations, and conflict frequencies.
   - Redacts embedded bearer tokens and SQL statements from error traces before remote dispatch.
4. **Sentry Flutter Hub (`lib/main.dart`)**:
   - Captures unhandled UI exceptions, Flutter framework errors (`FlutterError.onError`), and platform dispatcher errors (`PlatformDispatcher.instance.onError`).
   - Uses `beforeSend` to scrub passwords, tokens, and PII from exception values and breadcrumbs before transmission.

## 3. UI Performance & Frame Budget Monitoring

- Frame build/render timings are observed to detect jank (frames exceeding 16.6ms at 60fps).
- Route navigation tracking records screen transition latencies (`onGenerateRoute` / Navigator observer).
- Memory monitoring tracks image cache sizes to prevent mobile OOM events.
