# 04 — API AGENT CONTEXT & CONTRACT SPECIFICATION

## 1. Unified Response Envelope
Every HTTP endpoint exposed by the PropKart backend must strictly adhere to the unified JSON envelope:

### Success Response Contract (HTTP 200 / 201)
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": {
    "page": 1,
    "limit": 25,
    "total": 100,
    "totalPages": 4,
    "hasNextPage": true,
    "hasPrevPage": false,
    "serverTime": "2026-10-22T10:30:00.000Z"
  }
}
```

### Error Response Contract (HTTP 4xx / 5xx)
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "User-facing sanitized description",
    "details": [],
    "requestId": "123e4567-e89b-12d3-a456-426614174000"
  }
}
```

## 2. Request Correlation ID Tracking
- Every request is tagged with an RFC 4122 UUIDv4 correlation ID via `src/middleware/correlationId.middleware.js`.
- If the incoming client supplies `X-Request-Id` or `X-Correlation-Id`, the ID is validated (regex alphanumeric, length $\le 128$) and preserved.
- The ID is echoed in the response headers (`X-Request-Id` and `X-Correlation-Id`).

## 3. Pagination Guards & Bounding
- Standard query parameters: `?page=1&limit=25`.
- `page` is clamped to $\ge 1$.
- `limit` is clamped to a strict maximum ceiling of 100 (`maxLimit = 100`) to prevent memory exhaustion and database pool starvation.

## 4. Tenant Authority Extraction
- Tenant context (`organization_id`) must NEVER be accepted from unverified query string or body parameters for regular tenant users.
- Tenant context is extracted exclusively from the cryptographically verified JWT payload (`req.user.organization_id`).
- For Super Admins, multi-tenant switching is permitted only through explicitly authorized administrative endpoints.
