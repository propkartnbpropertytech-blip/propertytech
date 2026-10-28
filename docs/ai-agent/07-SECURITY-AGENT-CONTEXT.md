# 07 — SECURITY AGENT CONTEXT & DEFENSE-IN-DEPTH SPECIFICATION

## 1. Multi-Tenant Isolation
PropKart enforces strict logical and cryptographic multi-tenancy:
- **Tenant Context (`organization_id`):** Extracted exclusively from verified JWT tokens via `src/middleware/auth.middleware.js`.
- **Database RLS:** PostgreSQL Row-Level Security policies prevent cross-tenant reads or writes.
- **Fail-Safe Tenant Guardrail:** If a non-superadmin request lacks an `organization_id`, queries default to an empty condition (`WHERE 1=0`) rather than leaking global data.

## 2. Role-Based Access Control (RBAC) Hierarchy
Four distinct roles with explicit permission boundaries:
1. **Super Admin:** Global platform administration, tenant provisioning, cross-organization analytics.
2. **Admin:** Full administrative authority within their own organization.
3. **Telecaller:** Restricted workspace: allocated leads queue, call attempts logging, qualification handover to sales. Strictly forbidden from accessing user management, system configs, or unallocated leads.
4. **Sales Executive:** Handed leads workspace, site visit scheduling, negotiation, closing deals. Scoped strictly to leads assigned to them or their team.

## 3. Input Sanitization & Anti-Injection
- Parameterized SQL queries (`$1, $2, ...`) throughout all repositories in `src/modules/**/*.repository.js`. Raw string interpolation into SQL clauses is strictly forbidden.
- PostgREST metacharacters (`.`, `,`, `(`, `)`, `:`, `%`) are sanitized in text search filters.
- File upload magic bytes inspection verifies true MIME types (JPEG, PNG, PDF) and rejects SVG/HTML script payloads.

## 4. Telemetry & Log Sanitization (Zero PII/Secret Leak)
The structured logger (`src/config/logger.js`) and error monitoring wrapper (`src/config/errorMonitoring.js`) scrub:
- Passwords (`password`, `password_hash`, `new_password`)
- Tokens (`accessToken`, `refreshToken`, `token`, `Bearer ...`)
- Secrets (`apiKey`, `client_secret`, `encryptionKey`, `jwtSecret`)
- Session cookies and sensitive PII
- Sentry exceptions are scrubbed via `beforeSend` hooks before transmission.
