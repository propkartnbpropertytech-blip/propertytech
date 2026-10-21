# 07 — PROPKART API SECURITY CONTRACT (STEP 8.4)

## 1. Primary Objective

Defines the multi-tenant isolation guarantees, authentication barriers, role-based authorization constraints, and input sanitization boundaries across all API endpoints.

---

## 2. Server-Derived Tenant Isolation Guarantee

1. **Client Tenant Parameter Non-Trust**: Query string parameters (e.g. `?organization_id=...`) or JSON body attributes attempting to declare `organization_id` are strictly ignored for all non-Super-Admin roles.
2. **Server-Side Derivation**: The operating tenant identity is derived solely from the authenticated session context (`req.user.organization_id`).
3. **Fail-Safe Zero Row Matching**: If an authenticated non-super-admin user has a null or missing `organization_id`, SQL queries execute an impenetrable `1=0` guardrail, returning 0 rows without crashing or leaking cross-tenant data.
4. **Super Admin Scope**: Only authenticated users with role `'Super Admin'` are authorized to pass explicit `organization_id` filters to query or manage specific tenants.

---

## 3. Request Correlation & Header Injection Defense

Every incoming HTTP request is evaluated by `correlationIdMiddleware`:
```text
Client Header (X-Request-Id / X-Correlation-Id)
             ↓
Whitelist Validation: /^[a-zA-Z0-9_\-\.]{1,128}$/
             ↓
    [Match: Keep Clean Token]
    [Fail/CRLF/Special Chars: Discard & Generate RFC 4122 UUIDv4]
             ↓
Attached to req.id, req.correlationId, res.setHeader("X-Request-Id")
```

This prevents CRLF header injection, HTTP response splitting, and log injection attacks.

---

## 4. Authentication & JWT Invariants

1. **Bearer Authentication**: Required on all `/api/v1/*` routes except public auth endpoints (`/auth/login`, `/auth/refresh`, `/auth/health`).
2. **Clock Tolerance**: 30 seconds maximum allowable drift between client and server clocks.
3. **Revocation Checks**: Every authenticated call checks `isAccessTokenDenied(jti)` against Redis to ensure logged-out or administratively revoked sessions cannot access data.
4. **Session Version**: Validates token session version against current user state.

---

## 5. Input Sanitization & Monotonic Constraints

- All query parameters are parsed and type-checked via Zod schemas.
- Date inputs enforce `startDate <= endDate` to protect against query inversion.
- Text inputs and search strings enforce length caps (`max(100)`).
- SQL queries utilize parameterized statements (`$1, $2, ...`) without raw dynamic string concatenations.
