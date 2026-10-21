# 01 — SECURITY ARCHITECTURE

## 1. Executive Summary & Vision

PropKart enforces a strict **Defense-in-Depth Security Architecture** spanning the entire client-server continuum:
1. Flutter Client (UI, BLoC, Isar DB, Secure Storage, Outbox)
2. Network Boundary (TLS, Strict Security Headers, Token Authentication, Correlation Tracking)
3. API Gateway & Express Middleware (Authentication, Tenant Verification, Role-Based Access Control, Payload Validation, PostgREST Sanitization, Rate Limiting)
4. Application Service Layer (Effective Permissions, Team Boundary Guards, Transactional Integrity)
5. Caching Layer (Redis with strict tenant prefixing and isolation)
6. Data Tier (PostgreSQL with schema contracts, foreign keys, mandatory organization isolation columns, and prepared statements)
7. Asynchronous Channels (Phoenix WebSocket realtime replication and offline delta synchronization)

---

## 2. Fundamental Security Invariants

### Invariant 1: Server Is the Sole Security Boundary
The client (Flutter, web browser, external API caller) is completely untrusted. All security controls, authorization decisions, ownership determinations, and tenant bindings are evaluated and enforced strictly on the server:
- Never trust `organization_id`, `admin_id`, or `user_id` provided in request query strings, route parameters, or request bodies.
- Always derive security context exclusively from the verified JWT / session context: `authenticatedUser.organization_id`.
- Every incoming mutation or retrieval automatically applies server-stamped tenant filters.

### Invariant 2: Multi-Tenant Zero-Trust Isolation
PropKart operates as a multi-tenant enterprise real estate platform. Data belonging to Tenant A must NEVER be accessible, visible, modifiable, or enumerable by Tenant B under any condition:
- Tenant A queries automatically attach `WHERE organization_id = $1` on the server.
- Super Admin possesses global administrative capability across tenants, but standard Admins, Sales agents, and Telecallers are strictly confined to their organization.
- Cache keys in Redis are prefixed by tenant (`tenant:{org_id}:...`).
- Realtime channels only replicate authorized, tenant-scoped events.

### Invariant 3: Principle of Least Privilege (RBAC & Team Boundaries)
Every user identity has a defined role (`Super Admin`, `Admin`, `Sales`, `Telecaller`):
- Roles are verified on every single authenticated request.
- Sales agents can only view or manage their assigned leads and properties within their organization.
- Telecallers operate within inbound qualification pipelines and cannot access admin configurations, audit logs, or manage team rosters.
- Super Admin accounts cannot be managed, created, or deleted by standard Admins.

---

## 3. Defense-in-Depth Layered Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                       Flutter Client                        │
│  - SecureStorage (Encrypted SharedPreferences / Keychain)   │
│  - RoleGuard (UI route protection & link sanitization)      │
│  - SessionCleanup (Complete local wipe on logout / 401)     │
│  - Outbox Isolation (Purged on user switch)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / TLS + WSS
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Network & API Gateway Layer                 │
│  - Helmet (HSTS, CSP, Frameguard, X-Content-Type-Options)   │
│  - Strict CORS Policy (No wildcards on credentialed routes) │
│  - Rate Limiting & Account Lockout Guard                    │
│  - Request ID Correlation & Header Sanitization             │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Express Security Middleware                 │
│  - authMiddleware (JWT signature, iss, aud, exp validation) │
│  - architecturalGuard (Tenant context, Team boundary checks)│
│  - validateRequest / Zod Schema Validation (Input bounds)   │
│  - searchSanitize (PostgREST injection character stripping) │
│  - fileMagic (Magic-byte verification, MIME allowlisting)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Domain & Service Layer                    │
│  - Mass Assignment Allowlisting (pickAllowedFields)         │
│  - Effective Permissions Matrix Evaluation                  │
│  - KpiService (Authoritative calculation & verification)    │
│  - Telemetry & Security Audit Logging (events.js)           │
└──────────────────────────────┬──────────────────────────────┘
                               │
                ┌──────────────┴──────────────┐
                ▼                             ▼
┌──────────────────────────────┐ ┌───────────────────────────┐
│     PostgreSQL Database      │ │      Redis Cache Tier     │
│  - Mandatory org_id columns  │ │  - Tenant-prefixed keys   │
│  - Prepared parameterization │ │  - Non-authoritative cache│
│  - Foreign key constraints   │ │  - TTL bounds on sessions │
│  - Zero raw SQL concatenation│ │  - Token deny list & JTIs │
└──────────────────────────────┘ └───────────────────────────┘
```

---

## 4. Security Verification & Certification Framework

Security correctness is verified via automated regression suites:
- **Flutter Security Suite**: 77 verified unit & contract tests across 21 test files in `test/security/`.
- **Backend Security Suite**: 114 verified integration & architectural tests across modules in `test/` and `test/security/`.
- **Static Code Analysis**: Enforcing layer decoupling, banning deprecated tables, and blocking direct database connections from controllers.
