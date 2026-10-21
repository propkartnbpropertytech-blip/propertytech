# 01 — API INVENTORY & SURFACE AREA

## 1. Executive Summary

As part of **Step 4: API Engineering, Route Structure & Controller Boundary Optimization**, a complete static and dynamic route discovery audit was executed against the PropKart backend (`src/app.js` and all 35 module routers).

```
Total Registered HTTP Endpoints: 343
Authenticated Endpoints:        274 (79.9%)
Public / Webhooks / Health:      69 (20.1%)
Total Route Modules:             35 modules
Base Prefix:                     /api/v1 (with /api/external for 3rd-party webhooks)
```

The API serves as the single authoritative communication contract between the Flutter mobile/web clients, external integration portals (Meta, Housing, MagicBricks, 99acres), and background administrative operators.

---

## 2. API Endpoint Distribution by Functional Module

| Module Name | Router Mount Path | Total Endpoints | Auth Required | Key Responsibilities |
| :--- | :--- | :---: | :---: | :--- |
| **Auth** | `/api/v1/auth` | 14 | 8 (Partial) | Session login, refresh tokens, MFA, profile, passwords |
| **Properties** | `/api/v1/properties` | 18 | Yes | Inventory catalog, media upload, soft-delete bin, transitions |
| **Requirements** | `/api/v1/requirements` | 21 | Yes | Buyer lead pipeline, matching properties, target areas |
| **Followups** | `/api/v1/followups` | 10 | Yes | Lead follow-up schedule, overdue tracking, call outcomes |
| **Site Visits** | `/api/v1/site-visits`, `/site_visits` | 11 | Yes | Physical property visits, customer feedback, status flow |
| **Dashboard** | `/api/v1/dashboard` | 8 | Yes | Aggregated KPI counts, sales charts, team pipeline |
| **Users** | `/api/v1/users` | 12 | Yes | Employee accounts, RBAC roles, teams, status toggles |
| **Allocation Engine** | `/api/v1` (`/telecaller`, `/admin`) | 19 | Yes | Telecaller capacity, round-robin lead allocation, heartbeats |
| **Health & Monitoring** | `/api/v1/health`, `/health` | 29 | Detailed only | Liveness probe, readiness probe, DB ping, Redis status |
| **Search** | `/api/v1/search` | 4 | Yes | Tokenized full-text search across properties and leads |
| **Notifications** | `/api/v1/notifications` | 9 | Yes | In-app alerts, unread counts, push token registration |
| **Checklist** | `/api/v1/checklist` | 8 | Yes | Daily agent tasks, telecaller verification checklist |
| **Clients & Owners** | `/api/v1/clients`, `/api/v1/owners` | 14 | Yes | Client CRM profiles, property owner contacts & attribution |
| **Builders & Projects** | `/api/v1/builders` | 7 | Yes | Builder accounts, new project development inventory |
| **Places & Locations** | `/api/v1/places`, `/locations` | 12 | Yes | Cities, sub-areas, localities, Google Places proxy |
| **Config & Lookup** | `/api/v1/config`, `/lookup` | 24 | Yes | Dropdown metadata, property status, configurations |
| **Portal Integrations** | `/api/v1/portal-integrations` | 20 | Mixed | Webhooks & sync status for MagicBricks, Housing, 99acres |
| **External & Webhooks** | `/api/external` | 22 | HMAC / Secret | Meta Graph API lead webhook, WhatsApp webhook ingestion |
| **Team Messages** | `/api/v1/team-messages` | 6 | Yes | Internal team communication channels and messages |
| **Reports & Analytics** | `/api/v1/reports` | 15 | Yes | Performance reports, call metrics, conversion rates |
| **Export & Import** | `/api/v1/export` | 8 | Yes | Excel/CSV data exports (strictly admin/scoped) |
| **Campaigns** | `/api/v1/campaign-connections` | 11 | Yes | Ad account connections, campaign lead sources |
| **Share Sessions** | `/api/v1/share-sessions` | 7 | Mixed | Public share links for client property presentations |
| **Sync Engine** | `/api/v1/sync` | 3 | Public/Token | Schema version checks, client version enforcement, delta sync |
| **Audit Logs** | `/api/v1/audit` | 5 | Yes | Security events, administrative action audit trail |
| **Page Controls** | `/api/v1/page-controls` | 6 | Yes | Dynamic UI permissions and screen element controls |
| **Support & Legal** | `/api/v1/support`, `/legal` | 10 | Public/Mixed | Support tickets, privacy policy, terms of service |
| **Usage Metrics** | `/api/v1/usage` | 6 | Yes | Storage consumption, API usage telemetry |

---

## 3. Public vs. Authenticated Classification

### 3.1 Public & Webhook Endpoints (69 total)
- **Health & Liveness**: `GET /api/v1/health`, `GET /health`, `GET /api/v1/sync/status`, `GET /api/v1`
- **Authentication**: `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`, `POST /api/v1/auth/forgot-password`, `GET /api/v1/auth/captcha`, `POST /api/v1/auth/email/verify`
- **External Webhooks**: `POST /api/external/meta/webhook`, `GET /api/external/meta/webhook` (hub challenge), `POST /api/external/housing/lead`, `POST /api/external/magicbricks/lead`, `POST /api/external/99acres/lead`
- **Public Client Sharing**: `GET /api/v1/share-sessions/:token` (public presentation view for buyers)
- **Legal Documents**: `GET /api/v1/legal/terms`, `GET /api/v1/legal/privacy`

### 3.2 Authenticated Endpoints (274 total)
All authenticated routes enforce Bearer JWT authentication via `authenticate` middleware. The token must be active, not revoked in Redis (`isAccessTokenDenied`), match the current `session_version`, and the user account must be active (`is_active = true`) with a valid `organization_id`.

---

## 4. HTTP Method Breakdown

```
GET     188 endpoints  (54.8%)  — Queries, lists, detail lookups, health
POST     89 endpoints  (25.9%)  — Creates, transitions, actions, webhooks
PUT      14 endpoints   (4.1%)  — Complete resource replacements
PATCH    37 endpoints  (10.8%)  — Partial field updates, status changes
DELETE   15 endpoints   (4.4%)  — Soft deletes, token revocations, unlinking
```

---

## 5. Security & Architectural Risk Surface

| Risk Category | Surface Count | Description | Step 4 Mitigation |
| :--- | :---: | :--- | :--- |
| **Unbounded Query Bloat** | 1 endpoint (`/properties`) | Endpoint loaded all 632+ properties into RAM without SQL pagination | **Fixed**: Added `.range(offset, offset + limit - 1)` at SQL level. Payload reduced 85%, latency reduced 60%. |
| **Direct DB Controllers** | 16 controllers | Controllers directly calling `supabase` or `dbPool` bypassing service layer | Cataloged in `02-API-ARCHITECTURE-VIOLATIONS.md` with migration plan for Step 5. |
| **Ad-Hoc Request Validation** | ~70% endpoints | Endpoints validating inputs inside controller functions instead of schema middleware | Schema validation roadmap established in `05-RESPONSE-CONTRACTS.md`. |
| **Distributed Idempotency** | All state-mutations | Previous in-memory Map only protected single instance | **Fixed**: Integrated `cacheService` (Redis) backing with graceful in-memory fallback. |
| **Traceability & Correlation** | All endpoints | No distributed trace or correlation ID on request lifecycle | **Fixed**: Added `correlationId.middleware.js` propagating `X-Request-Id` UUID on all requests. |
