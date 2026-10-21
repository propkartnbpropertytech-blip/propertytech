# 01 — API Contract Inventory & Forensic Surface Analysis

## 1. Executive Overview
- **Service:** PropKart Backend REST API
- **Base Version:** v1.1.1 (`/api/v1`)
- **Protocol:** HTTP/1.1 & HTTP/2 over TLS
- **Primary Consumers:** PropKart Flutter Cross-Platform Client (Web, Android, iOS, Windows, macOS), External Webhook Ingestion (Meta, Housing.com, Google Sheets), External Integration Gateway (`/api/external`).
- **Core Governance:** Zero breaking changes, strict preservation of response envelopes, tenant isolation at server identity level, and backward compatibility for all legacy field aliases.

---

## 2. Global Middleware Pipeline

All incoming requests traverse the standardized Express middleware stack in `src/app.js`:

```text
Incoming HTTP Request
        ↓
1. correlationId()                 → Validates or generates X-Request-Id & X-Correlation-Id
        ↓
2. helmet()                        → Security headers (CSP, HSTS, frameguard, etc.)
        ↓
3. cors()                          → Ephemeral localhost & whitelisted domain validation
        ↓
4. compression()                   → Gzip/Deflate compression
        ↓
5. cookieParser()                  → Cookie parsing for secure auth tokens
        ↓
6. express.json({ limit: "50mb" }) → Body parsing & rawBody preservation
        ↓
7. Cache-Control Header Guard      → "no-store, no-cache, must-revalidate" on /api/v1
        ↓
8. apiRateLimit                    → Distributed IP-based burst rate limiting
        ↓
9. idempotency()                   → Distributed mutation deduplication (Idempotency-Key)
        ↓
10. Authentication / Tenant Guard  → authenticate / attachOrganization / requirePermission
        ↓
11. Controller Execution           → Service delegation (Zero raw SQL / Zero direct Redis in controllers)
        ↓
12. Standardized Response / Error  → res.status().json() / errorMiddleware
```

---

## 3. Exhaustive API Route Inventory Matrix

| Endpoint | Method | Auth | Tenant Scoped | Role / Permission | Request Payload / Params | Response Envelope / Model | Status Codes | Pagination | Filters / Notes |
|---|---|---|---|---|---|---|---|---|---|
| **`/api/v1`** | GET | Public | Global | Public | None | `{ success: true, version }` | 200 | No | Version metadata |
| **`/api/v1/sync/status`** | GET | Public | Global | Public | None | `{ serverTime, schemaVersion, ... }` | 200 | No | Offline sync compatibility |
| **`/api/v1/health`** | GET | Public | Global | Public | None | `{ status: "UP", timestamp }` | 200, 503 | No | Liveness probe |
| **`/api/v1/health/detailed`** | GET | Bearer | Global | `health.detailed` / Super Admin | None | Full system health & metrics | 200, 401, 403, 503 | No | Readiness & ops diagnostic |
| **`/api/v1/auth/captcha`** | GET | Public | Global | Public | None | SVG captcha | 200, 429 | No | Rate-limited |
| **`/api/v1/auth/login`** | POST | Public | Resolved | Public | `{ email, password, captchaToken }` | `{ success: true, token, user }` | 200, 400, 401, 429 | No | Sets HttpOnly cookie |
| **`/api/v1/auth/refresh`** | POST | Public | Resolved | Public | `{ refreshToken }` or Cookie | `{ success: true, token }` | 200, 401 | No | Token rotation |
| **`/api/v1/auth/me`** | GET | Bearer | Tenant | Authenticated | None | `{ success: true, user }` | 200, 401 | No | Profile & permissions |
| **`/api/v1/auth/mfa/*`** | POST | Bearer/Otp | Tenant | Authenticated | TOTP code / setup params | `{ success: true, ... }` | 200, 400, 401 | No | MFA workflow |
| **`/api/v1/dashboard`** | GET | Bearer | Tenant | `dashboard.read` | None | `{ success: true, data: { ... } }` | 200, 401, 403, 500 | No | Legacy summary metrics |
| **`/api/v1/dashboard/notes`** | GET, POST | Bearer | Tenant | Authenticated | Note content | `{ success: true, data }` | 200, 201, 400, 500 | No | Dashboard sticky notes |
| **`/api/v1/dashboard/kpis`** | GET | Bearer | Tenant | `dashboard.read` | Query: `businessType, dateFilter, startDate, endDate, leadType` | `{ success: true, data: { counts, percentages, raw_counts, ... } }` | 200, 400, 401, 403 | No | **Authoritative Canonical Master KPIs** |
| **`/api/v1/dashboard/inventory-breakdown`** | GET | Bearer | Tenant | `dashboard.read` | Query: `businessType, dateFilter, startDate, endDate` | `{ success: true, data: { available, rentedOut, ... } }` | 200, 400, 401, 403 | No | Inventory distribution |
| **`/api/v1/dashboard/inventory-properties`** | GET | Bearer | Tenant | `dashboard.read` | Query: `status, businessType, areaId, page, limit` | `{ success: true, data: { properties, count, page, ... } }` | 200, 400, 401, 403 | Yes (Clamped) | Drilldown property items |
| **`/api/v1/dashboard/leads-breakdown`** | GET | Bearer | Tenant | `dashboard.read` | Query: `leadType, dateFilter, startDate, endDate` | `{ success: true, data: { totalLeads, newLeads, ... } }` | 200, 400, 401, 403 | No | Lead intake pipeline |
| **`/api/v1/dashboard/leads-list`** | GET | Bearer | Tenant | `dashboard.read` | Query: `source, leadType, stage, isDealWon, page, limit` | `{ success: true, data: { leads, count, ... } }` | 200, 400, 401, 403 | Yes (Clamped) | Drilldown leads items |
| **`/api/v1/dashboard/telecallers-summary`** | GET | Bearer | Tenant | `dashboard.read` | Query: `dateFilter, startDate, endDate, leadType` | `{ success: true, data: { telecallers, summary } }` | 200, 400, 401, 403 | No | Agent duty roster & calls |
| **`/api/v1/dashboard/telecaller-drilldown/:id`** | GET | Bearer | Tenant | `dashboard.read` | Path: `id`, Query: filters | `{ success: true, data }` | 200, 400, 401, 403 | No | Individual agent stats |
| **`/api/v1/dashboard/telecaller-leads/:id`** | GET | Bearer | Tenant | `dashboard.read` | Path: `id`, Query: `category, search, page, limit` | `{ success: true, data: { leads, count, ... } }` | 200, 400, 401, 403 | Yes (Clamped) | Telecaller lead list |
| **`/api/v1/dashboard/leads-allocated-breakdown`** | GET | Bearer | Tenant | `dashboard.read` | Query: `leadType, dateFilter, startDate, endDate` | `{ success: true, data: { telecallers, totalAllocated, ... } }` | 200, 400, 401, 403 | No | Disambiguated telecaller queue |
| **`/api/v1/dashboard/assigned-to-sales-breakdown`** | GET | Bearer | Tenant | `dashboard.read` | Query: `leadType, dateFilter, startDate, endDate` | `{ success: true, data: { salesUsers, summary } }` | 200, 400, 401, 403 | No | Sales qualification pipeline |
| **`/api/v1/dashboard/sales-users-summary`** | GET | Bearer | Tenant | `dashboard.read` | Query: `dateFilter, startDate, endDate` | `{ success: true, data: { salesUsers, summary } }` | 200, 400, 401, 403 | No | Sales closers roster |
| **`/api/v1/dashboard/sales-user-drilldown/:id`** | GET | Bearer | Tenant | `dashboard.read` | Path: `id`, Query: filters | `{ success: true, data }` | 200, 400, 401, 403 | No | Individual sales rep stats |
| **`/api/v1/dashboard/sales-user-requirements/:id`** | GET | Bearer | Tenant | `dashboard.read` | Path: `id`, Query: `status, search, page, limit` | `{ success: true, data: { requirements, count } }` | 200, 400, 401, 403 | Yes (Clamped) | Sales user active leads |
| **`/api/v1/dashboard/site-visits-list`** | GET | Bearer | Tenant | `dashboard.read` | Query: `businessType, outcome, search, page, limit` | `{ success: true, data: { visits, count } }` | 200, 400, 401, 403 | Yes (Clamped) | Authoritative site visits |
| **`/api/v1/dashboard/deal-won-list`** | GET | Bearer | Tenant | `dashboard.read` | Query: `businessType, search, page, limit` | `{ success: true, data: { deals, count } }` | 200, 400, 401, 403 | Yes (Clamped) | Authoritative deals won |
| **`/api/v1/dashboard/not-interested-summary`** | GET | Bearer | Tenant | `dashboard.read` | Query: `dateFilter, startDate, endDate` | `{ success: true, data: { byReason, summary } }` | 200, 400, 401, 403 | No | Dropped lead reasons |
| **`/api/v1/dashboard/not-interested-leads`** | GET | Bearer | Tenant | `dashboard.read` | Query: `reason, page, limit` | `{ success: true, data: { leads, count } }` | 200, 400, 401, 403 | Yes (Clamped) | Dropped leads drilldown |
| **`/api/v1/dashboard/executive-kpis`** | GET | Bearer | Tenant | `dashboard.read` | None | `{ success: true, data: { inventory, leads, ... } }` | 200, 401, 403, 500 | No | C-Level overview |
| **`/api/v1/dashboard/drilldown`** | GET | Bearer | Tenant | `dashboard.read` | Query: `type, status, page, limit` | `{ success: true, data: { type, items, pagination } }` | 200, 400, 401, 403 | Yes (Clamped) | Dynamic KPI drilldown |
| **`/api/v1/dashboard/lifecycle-breakdown`** | GET | Bearer | Tenant | `dashboard.read` | Query: `dateFilter, startDate, endDate, leadType` | `{ success: true, data: { stages, telecallerRoster, ... } }` | 200, 400, 401, 403 | No | Lifecycle pipeline funnel |
| **`/api/v1/dashboard/lifecycle-leads`** | GET | Bearer | Tenant | `dashboard.read` | Query: `stage, salesUserId, telecallerId, page, limit` | `{ success: true, data: { items, pagination } }` | 200, 400, 401, 403 | Yes (Clamped) | Funnel drilldown leads |
| **`/api/v1/reports/overall`** | GET | Bearer | Tenant | Authenticated | Query: `start_date, end_date, source` | `{ success: true, data: { kpis: { ... }, ...kpis } }` | 200, 401, 500 | No | Aggregate KPI reports |
| **`/api/v1/reports/telecallers`** | GET | Bearer | Tenant | Authenticated | Query: date filters | `{ success: true, data: [ ... ] }` | 200, 401, 500 | No | Telecaller performance |
| **`/api/v1/reports/sales`** | GET | Bearer | Tenant | Authenticated | Query: date filters | `{ success: true, data: [ ... ] }` | 200, 401, 500 | No | Sales conversions |
| **`/api/v1/reports/campaigns`** | GET | Bearer | Tenant | Authenticated | Query: date filters | `{ success: true, data: [ ... ] }` | 200, 401, 500 | No | Campaign attribution |
| **`/api/v1/reports/business-insight`** | GET | Bearer | Tenant | Authenticated | Query: date filters | `{ success: true, data: { ... } }` | 200, 401, 500 | No | Business insights summary |
| **`/api/v1/properties`** | GET, POST | Bearer | Tenant | `properties.read`, `properties.create` | Query/Body | `{ success: true, data: { properties, count, page, ... } }` | 200, 201, 400, 403 | Yes (Clamped) | Master property catalog |
| **`/api/v1/properties/:id`** | GET, PUT, DELETE | Bearer | Tenant | `properties.read`, `properties.update`, `delete` | Path: `id`, Body | `{ success: true, data }` | 200, 400, 404 | No | Property CRUD |
| **`/api/v1/requirements`** | GET, POST | Bearer | Tenant | `requirements.read`, `requirements.create` | Query/Body | `{ success: true, data: { requirements, ... } }` | 200, 201, 400, 403 | Yes (Clamped) | Client requirement intake |
| **`/api/v1/site-visits`** | GET, POST | Bearer | Tenant | `site_visits.read`, `site_visits.write` | Query/Body | `{ success: true, data }` | 200, 201, 400, 403 | Yes (Clamped) | Site visit appointments |
| **`/api/v1/site-visits/:id/status`**| PATCH | Bearer | Tenant | `site_visits.write` | Body: `{ status, remarks }` | `{ success: true, data }` | 200, 400, 404 | No | Status update |
| **`/api/v1/followups`** | GET, POST | Bearer | Tenant | `followups.read`, `followups.write` | Query/Body | `{ success: true, data }` | 200, 201, 400, 403 | Yes (Clamped) | Lead followups |
| **`/api/v1/telecaller/dashboard`** | GET | Bearer | Tenant | `telecaller.leads` | None | `{ success: true, data }` | 200, 401, 403 | No | Telecaller operational inbox |
| **`/api/v1/telecaller/kpi-summary`**| GET | Bearer | Tenant | `telecaller.leads` / `dashboard.read` | Query: date filters | `{ success: true, data }` | 200, 401, 403 | No | Telecaller agent KPI stats |
| **`/api/v1/sales/dashboard-summary`**| GET | Bearer | Tenant | `sales.dashboard` / `dashboard.read` | None | `{ success: true, data }` | 200, 401, 403 | No | Sales agent operational inbox |
| **`/api/v1/admin/allocation-monitor`**| GET | Bearer | Tenant | `allocation.monitor` | None | `{ success: true, data }` | 200, 401, 403 | No | Queue & capacity monitor |
| **`/api/v1/integrations/leads`** | GET | Bearer | Tenant | `campaign.manage`, `telecaller.leads` | Query: filters, pagination | `{ success: true, data }` | 200, 401, 403 | Yes (Clamped) | Ingested campaign leads |
| **`/api/v1/export/*`** | GET | Bearer | Tenant | Authenticated | Query: filters | File stream / Excel / CSV | 200, 401, 403 | No | Data export workbook |
| **`/api/v1/audit/events`** | POST | Bearer | Tenant | Authenticated | Body: `{ events: [...] }` | `{ success: true, count }` | 200, 400, 401 | No | Telemetry event ingest |
| **`/api/v1/audit/logs`** | GET | Bearer | Global | Super Admin | Query: filters, pagination | `{ success: true, data }` | 200, 401, 403 | Yes (Clamped) | Security audit trail |
| **`/api/external/*`** | GET | API Key | Scoped | Read-Only Key | Query: `resource, ...` | `{ success: true, data }` | 200, 401, 403, 429 | Yes (Clamped) | External portal gateway |

---

## 4. Response Envelope Archetypes Found

1. **Standard Envelope (`ApiResponse.success` & `kpi.controller.js`):**
   ```json
   {
     "success": true,
     "message": "Optional human-readable string",
     "data": { ... }
   }
   ```
2. **Paginated Standard Envelope (`PropertiesController` & `parsePagination`):**
   ```json
   {
     "success": true,
     "message": "Properties retrieved successfully",
     "data": {
       "properties": [ ... ],
       "count": 166,
       "page": 1,
       "limit": 50,
       "totalPages": 4
     }
   }
   ```
3. **Reports Hybrid Envelope (`ReportsController.getOverall`):**
   ```json
   {
     "success": true,
     "data": {
       "kpis": { ...metrics },
       ...metrics
     }
   }
   ```
   *(Dual-nested for 100% backward compatibility with Flutter clients reading either `data.kpis.total_leads` or `data.total_leads`)*.
4. **Standard Error Envelope (`error.middleware.js` & `handleControllerError`):**
   ```json
   {
     "success": false,
     "message": "Sanitized client message",
     "errorCode": "VALIDATION_ERROR | UNAUTHORIZED | ACCESS_DENIED | NOT_FOUND | INTERNAL_SERVER_ERROR",
     "details": { ... },
     "requestId": "UUIDv4 or sanitized X-Request-Id"
   }
   ```

---

## 5. Security & Boundary Inventory Findings

1. **Tenant ID Injection Guard:**
   - In `auth.middleware.js`, `req.user.organization_id` is assigned directly from database rows.
   - For all roles other than Super Admin, any incoming `req.query.organization_id` or `req.body.organization_id` is discarded by the backend service layer, enforcing the database-authenticated tenant scope.
2. **Correlation ID Sanitization Gap Identified:**
   - `correlationId.middleware.js` accepts any string under 128 chars. Needs strict regex validation (`/^[a-zA-Z0-9_\-\.]{1,128}$/`) to block potential header/log injection vectors.
3. **Controller Error Inconsistencies:**
   - Multiple methods in `kpi.controller.js` return `res.status(400).json({ success: false, message: err.message })` directly instead of channeling through `handleControllerError(res, err, ...)` with machine-readable `errorCode` and `requestId`.
4. **Date Semantics Standard:**
   - Endpoints require canonical `[startDate, endDate)` semantics formatted as ISO-8601 strings (`YYYY-MM-DD` or full ISO).
   - Inconsistent date inputs currently bubble to database queries rather than being rejected early with `400 Bad Request (VALIDATION_ERROR)`.
