# 02 — Structured Logging Standard

## 1. Overview & JSON Schema

All server-side logs within the PropKart platform must be emitted in machine-readable JSON format. Ad-hoc string formatting, unformatted `console.log`, and raw object dumps are strictly forbidden.

### Canonical Log Schema:

```json
{
  "timestamp": "2026-10-21T10:00:00.123Z",
  "level": "INFO",
  "service": "propkart-backend",
  "environment": "production",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "tenantId": "c88ed9f1-5261-4e5f-8a34-e9fade752c70",
  "userId": "00000000-0000-0000-0000-000000000001",
  "operation": "HTTP_REQUEST",
  "method": "POST",
  "route": "/api/v1/leads/:id/qualify",
  "statusCode": 200,
  "durationMs": 42.5,
  "status": "SUCCESS",
  "errorCode": null,
  "message": "Lead qualified successfully"
}
```

## 2. Log Levels & Severity Guidelines

| Level | Usage Standard | Production Ingest Target |
|:---|:---|:---|
| **ERROR** | Unhandled system exceptions, 5xx responses, DB query aborts, network partitions. | Sentry + CloudWatch / Datadog alert |
| **WARN** | Deprecated API usage, rate limit saturation, soft fallbacks (Redis down, falling back to PG), 4xx client errors. | Telemetry dashboard |
| **INFO** | Request lifecycle completions, server lifecycle (startup/shutdown), batch worker status, key security audit events. | Elastic/Loki Log Aggregation |
| **DEBUG** | In-depth troubleshooting logs (disabled by default in production). | Local development / Staging |

## 3. Request Lifecycle Logging Middleware

The backend utilizes Winston combined with Morgan structured streams:
- Inbound requests assign/derive `X-Request-Id` and `X-Correlation-Id`.
- Response completion records the normalized route template, status code, latency in milliseconds, and content length.
- Outbound responses attach `X-Request-Id` and `X-Correlation-Id` to guarantee bidirectional traceability.

## 4. Mobile Client Logging Architecture

In the Flutter application:
- `AppLogger` (`lib/core/utils/app_logger.dart`) standardizes client logging.
- Development logs use ANSI color tagging while production builds enforce silent or remote-forwarded log streams.
- Raw `print()` is forbidden in production release builds.
- All network interactions log through `LoggingInterceptor` (`lib/core/api/logging_interceptor.dart`), attaching request and correlation tokens.
