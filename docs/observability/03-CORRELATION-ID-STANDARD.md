# 03 — Correlation ID Standard

## 1. Traceability Standard

To achieve complete forensic auditability and cross-tier request traceability, every transaction throughout the PropKart distributed ecosystem must carry a persistent correlation context.

### Headers:
- `X-Request-Id`: Unique identifier for the individual HTTP transaction (RFC 4122 UUIDv4).
- `X-Correlation-Id`: Distributed trace token linking related operations across UI events, background retries, offline sync transactions, and webhook ingestion.

## 2. Request Chain & Lifecycle

```text
[Flutter Client] (LoggingInterceptor)
      │ Generates UUIDv4 if absent
      │ Injects into outgoing Dio headers: X-Request-Id, X-Correlation-Id
      ▼
[Express Gateway / Middleware] (requestContext.js)
      │ Reads X-Request-Id & X-Correlation-Id
      │ If absent: generates crypto.randomUUID()
      │ Stores in AsyncLocalStorage context: { requestId, correlationId }
      ▼
[Controller & Domain Services]
      │ Passes correlationId down into database transaction tags
      │ Propagates correlationId into Redis cache keys and single-flight tags
      ▼
[HTTP Response Completion]
      │ Reflects X-Request-Id & X-Correlation-Id in response headers
      │ Attaches correlationId to standard API envelopes ({ success, data, meta: { requestId, correlationId } })
      ▼
[Flutter Client] (Response Handling)
      │ Extracts X-Request-Id & X-Correlation-Id from response headers
      │ Correlates local logs with server-side Winston log streams
```

## 3. Invariants & Preservation Rules

1. **Client-Preserved Correlation**: If a client provides an `X-Request-Id` or `X-Correlation-Id`, the backend MUST preserve the exact ID across the lifecycle.
2. **Deterministic UUID Format**: Generated IDs must conform strictly to RFC 4122 UUIDv4 (`^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`).
3. **Log Context Injection**: All Winston log outputs automatically include `requestId` and `correlationId` from the active context.
4. **Header Cleanliness**: Correlation IDs must never encode secrets, tenant tokens, user emails, or PII.
