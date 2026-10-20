# PROPKART — SOURCE OF TRUTH & DATA OWNERSHIP REGISTRY
**Version:** 1.0.0  
**Status:** CANONICAL GOVERNANCE REGISTRY (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** PropKart Data Architecture (PostgreSQL, Isar, Redis/Memory, S3/Cloudinary)  

---

## 1. Fundamental Source-of-Truth Axioms

To prevent data divergence, split-brain conditions, and conflicting business calculations, PropKart establishes the following absolute data ownership axioms:

1. **Axiom 1: PostgreSQL is the Single Authoritative Source of Business Truth (`INV-001`)**  
   All persistent business entities, status progressions, relationships, and historical ledgers reside authoritatively in PostgreSQL (`public` schema). Client storage (Isar, SharedPreferences) and server caching (Redis / in-memory KV) are non-authoritative read projections or transient staging buffers.
2. **Axiom 2: Historical Event Ledgers are Immutable (`INV-002`)**  
   Business events that have occurred in reality (a completed site visit, a logged call attempt, an audit log entry) must never be updated or deleted when subsequent mutable state changes.
3. **Axiom 3: Transient Staging is Non-Authoritative**  
   The Flutter offline outbox queue is a temporary staging area for intent. It becomes authoritative only when acknowledged and committed by the backend PostgreSQL database.
4. **Axiom 4: KPIs Have a Single Canonical Calculation Owner**  
   Under no circumstances may the Flutter client calculate canonical business metrics independently from the backend domain service.

---

## 2. Domain Data Ownership Matrix

### 2.1 Property Inventory & Media
```text
Data: Property Inventory (Listings, Pricing, Status, Amenities, Specs)
Authoritative Source: PostgreSQL (`public.properties`, `public.property_amenities`)
Local Cache: Flutter Isar Database (`PropertyLocal` collection) / In-memory Web cache
Cache: Backend Cache-Aside / In-memory Map (TTL: 5 min)
Calculation Owner: Backend Properties Domain Service (`src/modules/properties/`)
Mutation Owner: Backend Properties Service (validated via PostgreSQL transaction)
Read Owner: Flutter Properties Repository (`lib/features/properties/`) via Backend REST API
Synchronization Mechanism: HTTP GET incremental sync via `SyncEngine` diffing + WebSocket invalidation
```

```text
Data: Property Media Assets (Photos, Floorplans, Videos)
Authoritative Source: Cloudinary CDN / AWS S3 (Binary media) & PostgreSQL (`public.property_images`, `public.property_videos` metadata)
Local Cache: Flutter `cached_network_image` cache & device temporary storage
Cache: Cloudinary Global Edge CDN
Calculation Owner: Cloudinary image optimization pipeline (dynamic transforms)
Mutation Owner: Backend Media Service (Upload signed by backend; direct upload via secure token)
Read Owner: Flutter UI via Cloudinary HTTPS CDN URLs
Synchronization Mechanism: Lazy load on demand with local LRU disk caching
```

---

### 2.2 Ingested Leads & Integration Pipeline
```text
Data: Leads (Inbound Meta Ads, Housing.com, Webhook, Manual)
Authoritative Source: PostgreSQL (`public.leads`, `public.integration_leads`)
Local Cache: Flutter Isar Database (`CampaignLeadLocal` collection)
Cache: Backend In-Memory Cache (TTL: 60s on active lead feeds)
Calculation Owner: Backend Ingest Engine (`src/services/leadIngestEngine.service.js`)
Mutation Owner: Backend Ingestion Service & Telecaller Allocation Engine
Read Owner: Flutter Campaign & Telecaller Modules via Backend REST API
Synchronization Mechanism: Realtime Webhooks -> Backend -> DB -> Polling / WebSocket to Flutter client
```

```text
Data: Lead Status & Assignment History
Authoritative Source: PostgreSQL (`public.lead_status_history`, `public.lead_assignment_history`)
Local Cache: None (Query on demand for detail views)
Cache: None (Strict ACID transactional ledger)
Calculation Owner: PostgreSQL Triggers (`trg_record_lead_status_history`) & Allocation Service
Mutation Owner: Backend Lead Lifecycle Service
Read Owner: Admin & Audit screens via Backend REST API
Synchronization Mechanism: On-demand HTTP fetch
```

---

### 2.3 Requirements & Matching Engine
```text
Data: Buyer & Tenant Requirements (Budget, Unit Types, Preferred Localities)
Authoritative Source: PostgreSQL (`public.requirements`, `public.requirement_areas`)
Local Cache: Flutter Isar Database (`RequirementLocal` collection)
Cache: Backend In-Memory Cache (TTL: 3 min)
Calculation Owner: Backend Requirements Service (`src/modules/requirements/`)
Mutation Owner: Backend Requirements Controller & DB Bi-Directional Triggers
Read Owner: Flutter Requirements Screen & Property Matching View
Synchronization Mechanism: Incremental sync via `SyncManager` + Outbox mutation queue
```

```text
Data: Property-Requirement Match Scores
Authoritative Source: Dynamic computation by Backend Matching Service (`src/modules/matching/`)
Local Cache: Transient Flutter BLoC state (screen lifecycle only)
Cache: None (Dynamic scoring based on live inventory)
Calculation Owner: Backend Matching Service (`matching.service.js`)
Mutation Owner: Read-only derived data (No persistent mutation)
Read Owner: Flutter Requirement Details & Match Dialogs
Synchronization Mechanism: Calculated on-demand via `GET /api/v1/requirements/:id/matches`
```

---

### 2.4 Followups, Callbacks & Call Attempts
```text
Data: Communication Followups & Reminders
Authoritative Source: PostgreSQL (`public.followups`)
Local Cache: Flutter Isar Database (`FollowupLocal` collection)
Cache: None (High-frequency operational data)
Calculation Owner: Backend Followups Service (`src/modules/followups/`)
Mutation Owner: Backend Followups Controller & Campaign Sync Triggers
Read Owner: Flutter Telecaller Callbacks & Sales Followup Calendars
Synchronization Mechanism: Bidirectional sync via Flutter `FollowupLocalRepository` and REST API
```

```text
Data: Telecaller Call Attempts & Disposition Outcomes (CNR, Busy, Callback, NI)
Authoritative Source: PostgreSQL (`public.lead_call_attempts`, `public.campaign_lead_callbacks`)
Local Cache: Flutter Outbox Queue (offline staging)
Cache: None (Transactional ledger)
Calculation Owner: Backend Allocation & Telecaller Service (`allocation.service.js`)
Mutation Owner: Backend Telecaller API (`POST /api/v1/telecaller/callbacks`)
Read Owner: Telecaller Dashboard & Admin Monitor
Synchronization Mechanism: Immediate online POST; offline queued in `OutboxLocal`
```

---

### 2.5 Site Visits & Conversion Pipeline
```text
Data: Site Visits (Scheduled, Rescheduled, Conducted, Cancelled)
Authoritative Source: PostgreSQL (`public.site_visits`)
Local Cache: Transient BLoC state
Cache: None (Transactional)
Calculation Owner: Backend Site Visits Service (`src/modules/site_visits/`)
Mutation Owner: Backend Site Visits Controller (Validated by unique constraint `idx_site_visits_unique_booking`)
Read Owner: Sales Agent Dashboard & Admin Reporting
Synchronization Mechanism: REST API calls with optimistic UI updates
```

---

### 2.6 Identity, Authentication & Sessions
```text
Data: User Accounts, Credentials & Roles
Authoritative Source: PostgreSQL (`public.users`, `public.roles`)
Local Cache: Flutter `SecureStorage` (stores current user ID, name, role)
Cache: In-Memory Security Store (`src/config/redis.js`) for lockout counters and session validity
Calculation Owner: Backend Auth Service (`src/modules/auth/`)
Mutation Owner: Super Admin / Admin API via `bcryptjs` password hashing
Read Owner: Auth Middleware & Profile Screen
Synchronization Mechanism: JWT Claims token + `GET /api/v1/auth/me` profile refresh
```

```text
Data: Active User Sessions & JWT Tokens
Authoritative Source: PostgreSQL (`public.user_sessions`) & In-Memory Denylist (`redis.js`)
Local Cache: Flutter `FlutterSecureStorage` (access_token, refresh_token)
Cache: In-Memory Denylist / Lockout Map
Calculation Owner: Backend Auth Service (`src/modules/auth/`)
Mutation Owner: Backend Auth Controller (`login`, `refresh`, `logout`)
Read Owner: Express `authenticate` Middleware & Flutter `Dio` Interceptor
Synchronization Mechanism: HTTP Bearer header & automated 401 token refresh interceptor
```

---

### 2.7 Multi-Tenancy & Dynamic RBAC
```text
Data: Role Permissions & User Feature Overrides
Authoritative Source: PostgreSQL (`public.role_feature_permissions`, `public.user_feature_overrides`)
Local Cache: Flutter `PermissionMatrixService` in-memory map & SharedPreferences
Cache: Backend In-Memory KV (TTL: 10 min, invalidated on admin change)
Calculation Owner: Backend Security Guard (`src/security/architecturalGuard.js`)
Mutation Owner: Backend Super Admin API (`PATCH /super-admin/feature-permissions/role`)
Read Owner: Express `requirePermission` middleware & Flutter `RoleGuard`
Synchronization Mechanism: Fetched on application login/resume + WebSocket invalidation
```

```text
Data: Organization Boundaries
Authoritative Source: PostgreSQL (`public.organizations`)
Local Cache: Encrypted session claim (`organization_id`) in `FlutterSecureStorage`
Cache: In-Memory tenant cache in backend
Calculation Owner: Backend Tenant Guard (`src/security/tenant.js`)
Mutation Owner: Super Admin database administrator
Read Owner: All backend queries (enforces `organization_id = $1`)
Synchronization Mechanism: Injected into all database transactions via user context
```

---

### 2.8 KPI Formulations & Analytical Metrics
```text
Data: Executive KPIs, Conversion Rates, Pipeline Analytics
Authoritative Source: Backend Domain KPI Service (`src/modules/dashboard/kpi.service.js`) querying PostgreSQL
Local Cache: Flutter `DashboardLocal` Isar collection (cached summary bar)
Cache: Backend In-Memory KPI Cache (TTL: 2 min, invalidated on relevant entity mutation)
Calculation Owner: Backend KPI Service (`kpi.service.js`) strictly aligned with `kpiRulebook.master.js`
Mutation Owner: Read-only derived data (No direct mutation permitted)
Read Owner: Flutter Dashboard, Telecaller, Sales, and Reports screens
Synchronization Mechanism: Polled on screen entry or filter update via `GET /api/v1/dashboard/summary`
```

---

### 2.9 System Lookups & Configuration
```text
Data: Cities, Localities, Property Types, Configurations, Amenities
Authoritative Source: PostgreSQL (`public.cities`, `public.areas`, `public.configurations`, etc.)
Local Cache: Flutter Isar Database (`LookupItemLocal` collection)
Cache: Long-term backend in-memory cache (TTL: 24 hours)
Calculation Owner: System Administrator
Mutation Owner: Backend Lookup & Settings Controller
Read Owner: All UI dropdowns, form pickers, search filters
Synchronization Mechanism: Schema version handshake (`GET /api/v1/sync/status` vs `last_lookup_version`)
```

---

### 2.10 Compliance & Audit Logs
```text
Data: Transactional Security & Business Audit Logs
Authoritative Source: PostgreSQL (`public.audit_logs`, `public.kpi_audit_logs`)
Local Cache: None (Server-only ledger)
Cache: None
Calculation Owner: Backend Audit Service (`src/modules/audit/`)
Mutation Owner: Backend Audit Middleware and Database Triggers (Append-only)
Read Owner: Super Admin Audit Log Viewer
Synchronization Mechanism: Server-side capture; UI fetches paginated log stream
```

```text
Data: UI Dwell Time & User Journey Telemetry
Authoritative Source: PostgreSQL (`public.admin_security_tracking` / telemetry sink)
Local Cache: Flutter `AuditDwellTracker` in-memory queue
Cache: None
Calculation Owner: Flutter `AuditTelemetryService` (`lib/core/telemetry/`)
Mutation Owner: Flutter Telemetry Engine (Flushed in batches to `/api/v1/audit/telemetry`)
Read Owner: Super Admin Security Dashboard
Synchronization Mechanism: Low-priority asynchronous batched background POST
```
