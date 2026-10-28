# 04 — Distributed Tracing Standard

## 1. Tracing Model

PropKart implements a lightweight, zero-dependency distributed tracing standard designed for high throughput and predictable memory overhead.

### Trace Representation:
```text
Trace Root (Client UI Interaction / Action)
 └── HTTP Network Span (Dio / LoggingInterceptor) [durationMs]
      └── Express Middleware Pipeline Span
           └── Controller Action Span
                └── Domain Service Span
                     ├── Redis Cache Operation Span (hit/miss/stampede)
                     ├── PostgreSQL Transaction Span (withTransaction)
                     │    ├── SQL Statement Execution Span
                     │    └── Row-Level Security Evaluation
                     └── Phoenix Realtime Broadcast Span
```

## 2. Distributed Context Propagation

- Trace context propagates across network boundaries using standard W3C Trace Context and HTTP headers (`X-Request-Id`, `X-Correlation-Id`).
- Within the Node.js runtime, asynchronous context propagation uses Node.js native `AsyncLocalStorage`, avoiding parameter pollution across service layers.
- In Flutter, asynchronous spans are tracked using `Sentry.startTransaction` or structured zone metadata.

## 3. Safe Tracing Attributes & Cardinality Limits

To prevent cardinality explosions and memory bloat:
- **Allowed Attributes**:
  - `http.method`: `GET`, `POST`, `PUT`, `DELETE`
  - `http.route`: Normalized route template (`/api/v1/leads/:id`)
  - `http.status_code`: `200`, `201`, `400`, `404`, `500`
  - `db.system`: `postgresql`
  - `cache.system`: `redis`
  - `cache.hit`: `true` / `false`
- **Forbidden Attributes**:
  - Raw SQL strings with unparameterized literal values
  - Raw customer phone numbers, emails, or names
  - Authorization tokens, passwords, or cookies
  - High-cardinality query parameters (e.g. `?search=term`)
