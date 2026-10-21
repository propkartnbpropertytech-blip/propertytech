# 08 — API SECURITY & GATEWAY HARDENING

## 1. Gateway & Middleware Architecture

Every incoming API request is processed through a deterministic security middleware pipeline:

```text
HTTP Request
     │
     ▼
[Correlation & Request ID] ── Sanitizes and ensures RFC 4122 UUID v4
     │
     ▼
[Helmet & Security Headers] ── HSTS, CSP, Frameguard, X-Content-Type-Options
     │
     ▼
[CORS Policy] ─────────────── Explicit origin allowlists; blocks wildcard credentials
     │
     ▼
[Rate Limiting] ───────────── Tiered IP and Account bounding
     │
     ▼
[Body Parser & Size Guards] ─ Rejects malformed JSON; limits payloads to 1MB / 10MB
     │
     ▼
[Auth Middleware] ─────────── Verifies HS256 JWT signature, iss, aud, exp, revocation
     │
     ▼
[Architectural Guard] ─────── Tenant context binding & Team boundary assertion
     │
     ▼
[Payload Validation] ──────── Zod schema parsing; PostgREST search sanitization
     │
     ▼
[Feature Controller & Service Layer]
```

---

## 2. Parameter & Input Validation

1. **Query & Path Parameters**:
   - Date formats strictly checked via regex/ISO-8601 parser. `startDate > endDate` produces immediate `400 VALIDATION_ERROR`.
   - Enumerations (e.g. `businessType`, `listingType`, `stage`) checked against allowed enums.
   - Pagination ceiling: Max limit bounded to 100 records (`paginationGuard.js`).
2. **Search Term Sanitization (`searchSanitize.js`)**:
   - Strips PostgREST special operators: `,`, `(`, `)`, `.`, `eq.`, `neq.`, `is.`, `null`.
   - Prevents SQL filter escaping and injection.
3. **Payload Whitelisting (Mass Assignment Protection)**:
   - Unknown and unauthorized fields (e.g. `organization_id`, `created_by`, `is_verified`, `role`) are stripped prior to SQL construction.

---

## 3. Standardized Error Envelope & Sanitization

PropKart adheres to the certified Step 8.4 API Error Envelope:
```json
{
  "success": false,
  "message": "Human-readable sanitized message",
  "errorCode": "MACHINE_READABLE_CODE",
  "details": {},
  "requestId": "123e4567-e89b-12d3-a456-426614174000"
}
```

- Production error handlers intercept all exceptions.
- Raw SQL syntax errors, database relation names, PostgreSQL error codes, file paths, and server stack traces are never exposed to the client.
- Sensitive errors are logged securely to server logs and Sentry/GlitchTip telemetry.
