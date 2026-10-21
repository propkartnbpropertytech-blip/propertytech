# 01 — BACKEND MONOLITH INVENTORY & COMPLEXITY REGISTER

## 1. Executive Summary

As part of **Step 5: Backend Layer Restructuring & Monolith Decoupling**, a complete static code and architectural analysis was performed across all **188 JavaScript files** in `src/`.

The analysis cataloged:
- Line counts and distribution tiers.
- Function count, class definitions, and exports.
- Direct database (`supabase`, `dbPool`) and Redis calls inside controllers.
- Multi-domain conflation and responsibilities.
- AI-agent reasoning difficulty scores.

```
Total Files Scanned in src/:       188 JavaScript files
Extreme Monoliths (>= 4000 lines): 2 files (kpi.service.js, integrations.service.js)
Heavy Monoliths (2000–3999 lines): 2 files (health.html.js, allocation.service.js)
Large Modules (1000–1999 lines):   5 files (reports.service, auth.controller, properties.controller, external.service, requirements.repository)
Moderate Modules (500–999 lines):  19 files
Controllers Directly Accessing DB: 15 files
```

---

## 2. Monolith Tiers & Complexity Breakdown

### Tier 1: Extreme Monoliths (>= 4,000 Lines)

| File Path | Lines | Functions | Exports | Primary Responsibilities | Architectural Debt |
| :--- | :---: | :---: | :---: | :--- | :--- |
| `src/modules/dashboard/kpi.service.js` | **5,541** | 54 | 3 | Dynamic KPI builder, telecaller metrics, sales KPIs, inventory analytics, locality intelligence, raw SQL queries. | Mixes domain business calculations, raw SQL aggregations, and caching. File size exceeds AI context windows. |
| `src/modules/integrations/integrations.service.js` | **4,624** | 50 | 1 | Meta lead webhook verification, Housing.com poller, lead normalization, CRM conversion, campaign column config. | Contains 4 external integration adapters in one file with duplicate normalization logic. |

### Tier 2: Heavy Monoliths (2,000 – 3,999 Lines)

| File Path | Lines | Functions | Exports | Primary Responsibilities | Architectural Debt |
| :--- | :---: | :---: | :---: | :--- | :--- |
| `src/modules/health/health.html.js` | **3,197** | 32 | 2 | Inline HTML/CSS/JS dashboard rendering for VPS operations. | Static asset and presentation markup embedded inside backend JS code. |
| `src/modules/allocation/allocation.service.js` | **2,464** | 56 | 1 | Telecaller capacity, lead scoring, round-robin allocation, status transitions, partner reassignments. | Business orchestration, state transitions, and DB queries tightly coupled. |

### Tier 3: Large Modules (1,000 – 1,999 Lines)

| File Path | Lines | Functions | Exports | Primary Responsibilities | Architectural Debt |
| :--- | :---: | :---: | :---: | :--- | :--- |
| `src/modules/reports/reports.service.js` | **1,656** | 14 | 1 | Multi-team reporting aggregations, CSV/Excel export formatting. | Direct SQL queries mixed with tabular presentation mapping. |
| `src/modules/auth/auth.controller.js` | **1,363** | 19 | 14 | Login, logout, refresh, MFA setup/verification, password reset, profile update. | Controller executes Supabase queries, Redis calls, token generation directly. |
| `src/modules/properties/properties.controller.js` | **1,162** | 24 | 1 | Property CRUD, status transitions, Cloudinary upload signatures, duplicate checking, metadata lookups. | Direct Supabase queries in controller; lookup dropdown management inside property module. |
| `src/modules/external/external.service.js` | **1,069** | 15 | 1 | External CRM sync, third-party webhook dispatching. | Direct database operations coupled with network retry logic. |
| `src/modules/requirements/requirements.repository.js` | **1,057** | 16 | 1 | Requirement persistence, target area mapping, tokenized search. | Repository contains client-side metadata formatting and string parsing. |

### Tier 4: Moderate Modules (500 – 999 Lines)

| File Path | Lines | Functions | Exports | Focus Area |
| :--- | :---: | :---: | :---: | :--- |
| `src/services/snapshot.service.js` | 971 | 19 | 1 | System state snapshot & diagnostics |
| `src/modules/allocation/metrics.service.js` | 955 | 13 | 1 | Telecaller performance telemetry |
| `src/services/health.service.js` | 819 | 14 | 4 | Multi-service health monitoring probes |
| `src/modules/sync/sync.service.js` | 817 | 6 | 1 | Mobile delta synchronization |
| `src/services/leadIngestEngine.service.js` | 816 | 21 | 1 | Asynchronous lead ingestion queue |
| `src/modules/dashboard/kpi.controller.js` | 810 | 35 | 35 | HTTP endpoints for KPI requests |
| `src/modules/users/users.controller.js` | 775 | 14 | 8 | User administration & RBAC endpoints |
| `src/modules/properties/properties.repository.js` | 760 | 25 | 1 | Property database queries & joins |
| `src/modules/integrations/housing.service.js` | 712 | 17 | 1 | Housing.com specific integration adapter |
| `src/modules/health/snapshot.controller.js` | 667 | 11 | 1 | Health snapshot HTTP endpoints |
| `src/modules/dashboard/executiveKpi.service.js` | 654 | 2 | 1 | High-level executive KPI queries |
| `src/modules/support/support.repository.js` | 638 | 10 | 1 | Support ticket persistence |
| `src/modules/export/export.controller.js` | 629 | 5 | 1 | Excel export streaming (direct dbPool) |
| `src/modules/followups/followups.controller.js` | 626 | 10 | 1 | Follow-up pipeline controller |
| `src/modules/matching/matching.service.js` | 626 | 9 | 1 | Property-requirement matching engine |
| `src/modules/site_visits/site_visits.controller.js` | 624 | 10 | 1 | Site visit inspection controller |
| `src/modules/dashboard/dashboard.service.js` | 605 | 4 | 1 | Dashboard aggregation coordinator |
| `src/modules/portal_integrations/portalConnector.engine.js` | 581 | 28 | 17 | Portal connector runtime engine |
| `src/modules/allocation/allocation.controller.js` | 502 | 36 | 1 | Lead allocation HTTP controller |

---

## 3. Direct Database & Redis Access in Controllers (Violation Register)

The 15 controllers violating the layered architecture boundary:

| Controller | Supabase | dbPool | Redis | Root Cause |
| :--- | :---: | :---: | :---: | :--- |
| `auth.controller.js` | **YES** | NO | **YES** | Directly updates `users`, tokens, and Redis blacklists. |
| `properties.controller.js` | **YES** | NO | NO | Directly queries `properties`, `property_images`, cities, areas. |
| `users.controller.js` | **YES** | NO | NO | Direct queries for user creation, roles, organizations. |
| `export.controller.js` | NO | **YES** | NO | Directly executes large streaming SQL queries. |
| `followups.controller.js` | **YES** | NO | **YES** | Queries `followups` directly; invalidates Redis directly. |
| `site_visits.controller.js` | **YES** | NO | **YES** | Queries `site_visits` directly; invalidates Redis directly. |
| `allocation.controller.js` | **YES** | NO | NO | Queries availability and telecaller assignment directly. |
| `health.controller.js` | **YES** | **YES** | NO | Executes DB pings and pool diagnostics directly. |
| `users.stats.controller.js` | **YES** | NO | **YES** | Aggregates user activity directly with raw queries. |
| `places.controller.js` | **YES** | NO | NO | Directly queries `cities` and `areas`. |
| `users.upload.controller.js` | NO | **YES** | NO | Direct PostgreSQL queries for avatar and document files. |
| `usage.controller.js` | **YES** | NO | NO | Direct queries for tenant storage calculation. |
| `notifications.controller.js` | **YES** | NO | NO | Directly queries and marks `notifications` read. |
| `checklist.controller.js` | **YES** | NO | NO | Directly creates and updates `checklist` items. |
| `search.controller.js` | **YES** | NO | NO | Directly queries search across tables. |

---

## 4. Refactoring Priority Matrix

```
┌─────────────────────────────────────────────────────────────────────────┐
│ REFACTORING BATCHES & EXECUTION PLAN                                    │
├─────────┬───────────────────────────┬───────────────┬───────────────────┤
│ Batch   │ Module Target             │ Risk Level    │ Architecture Goal │
├─────────┼───────────────────────────┼───────────────┼───────────────────┤
│ Batch 1 │ Controller Decoupling:    │ Low           │ Eliminate direct  │
│         │ search, checklist, notif, │               │ Supabase calls;   │
│         │ usage, places             │               │ route via repos.  │
├─────────┼───────────────────────────┼───────────────┼───────────────────┤
│ Batch 2 │ kpi.service.js            │ Medium-High   │ Extract raw SQL to│
│         │ (5,541 lines)             │               │ kpi.repository.js │
│         │                           │               │ & definitions.    │
├─────────┼───────────────────────────┼───────────────┼───────────────────┤
│ Batch 3 │ integrations.service.js   │ Medium-High   │ Extract providers:│
│         │ (4,624 lines)             │               │ meta, housing,    │
│         │                           │               │ portal adapters.  │
├─────────┼───────────────────────────┼───────────────┼───────────────────┤
│ Batch 4 │ auth.controller.js        │ Medium        │ Extract DB/token  │
│         │ (1,363 lines) &           │               │ logic to service/ │
│         │ properties.controller.js  │               │ repository layers.│
└─────────┴───────────────────────────┴───────────────┴───────────────────┘
```
