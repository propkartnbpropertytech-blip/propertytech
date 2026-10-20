# PROPKART — STEP 1 FINAL ARCHITECTURE REPORT
## SYSTEM ARCHITECTURE FOUNDATION & CODEBASE STRUCTURE

**Date:** October 19, 2026  
**Architect:** Principal Software Architect + Senior Flutter Architect + Senior Backend Architect + Database Architect  
**Target Platform:** PropKart CRM & PropTech ERP (Web, Mobile, Desktop)  
**Repositories Governed:**
- Frontend: `c:\NB\propkart` (Flutter 3.x, Dart 3.x, BLoC Architecture)
- Backend: `C:\NB\PropKart-Backend` (Node.js 20+, Express 5.2.1, PostgreSQL 16)
- Database: PostgreSQL 16 (`public` schema, Port 54329 local / 5432 production)

---

## A. Current Architecture (What Actually Exists)

The PropKart system consists of a cross-platform Flutter client communicating via HTTP REST with a Node.js/Express backend service backed by PostgreSQL 16:

1. **Frontend Architecture (`c:\NB\propkart`):**
   - **Entry Points:** `lib/main.dart` (Sentry wrapping, Isar bootstrap, BLoC injection), `lib/splash.dart` (session restore, schema version check), `lib/get_started_screen.dart`.
   - **Routing & RBAC:** `go_router` (^17.3.0) via `lib/core/navigation/app_router.dart` (835 lines, 38 routes). Client route access guarded by `RoleGuard` and `PermissionMatrixService`.
   - **State Management:** Flutter BLoC (^9.1.1) across 16 feature BLoCs, heavily mixed with local `StatefulWidget` (`setState`) inside monolithic screen files.
   - **Persistence & Caching:** Isar Database (3.1.0+1) with 10 schemas in `isar_collections.g.dart` (34,342 lines); Web fallback bypasses Isar to in-memory `Map` caches. `FlutterSecureStorage` stores encrypted JWTs.
   - **Network & Sync:** `DioClient` singleton with logging interceptors; `SyncManager` (1,068 lines) and `SyncEngine` (270 lines) manage WebSocket heartbeats and offline outbox queuing.
2. **Backend Architecture (`C:\NB\PropKart-Backend`):**
   - **Server Entry:** `src/server.js` (health probes, additive schema checks, realtime, cron) and `src/app.js` (Express 5.2.1, Helmet, dynamic CORS, rate limiting, 30+ domain routers).
   - **Dual Database Driver Anomaly:** Parallel access via direct PostgreSQL pool (`pg.Pool` with `timedQuery`) AND `@supabase/supabase-js` service-role client.
   - **Cache Implementation:** In-memory `Map` key-value store with TTL (`src/config/redis.js`); standalone Redis is disabled/stubbed.
   - **Background Workers:** `src/services/cron.service.js` runs periodic untouched lead allocation, stale lead recovery, and database snapshot recording.
   - **Integrations:** Realtime webhooks for Meta Lead Ads (Graph API) and Housing.com; Cloudinary CDN for image/video assets.
3. **Database Architecture (PostgreSQL 16):**
   - 50+ relational tables across 57 sequential SQL migrations.
   - **Server-Only Public Access (Migration 33):** All direct PostgREST client permissions revoked from `anon` and `authenticated`; client access is 100% mediated through Node.js.
   - **Stored Logic & Triggers:** Lead allocation functions (`allocate_waiting_leads` with `FOR UPDATE SKIP LOCKED`) and recursive bi-directional synchronization triggers between `leads` and `requirements`.

---

## B. Target Architecture (What PropKart Should Become)

The target architecture enforces a strict Clean Architecture and Feature-Oriented Modular structure:

1. **Flutter Target Architecture:**
   - Top-level directories: `lib/app/` (bootstrap, config, router, theme), `lib/core/` (api, database, errors, logging, storage, sync, security), `lib/features/` (autonomous domain modules), `lib/shared/` (widgets, components, dialogs, forms, models).
   - Each feature is organized into 5 strict layers:
     - `presentation/` (BLoC state machine, thin screen scaffolds <400 lines, atomic widgets <250 lines).
     - `application/` (Discrete use cases and exported public `Facade`).
     - `domain/` (Pure Dart entities, value objects, abstract repository contracts).
     - `data/` (Remote Dio DataSources, local Isar DAOs, concrete repository implementations).
     - `tests/` (Feature-specific unit and widget tests).
2. **Backend Target Architecture:**
   - Layered modular structure: `src/routes/` $\rightarrow$ `src/controllers/` $\rightarrow$ `src/services/` $\rightarrow$ `src/repositories/` $\rightarrow$ `src/database/`.
   - Controllers only parse requests and return standard `ApiResponse` envelopes.
   - Domain services encapsulate pure business workflows and transactions (`withTransaction`).
   - Repositories encapsulate all SQL queries using parameterized statements.
   - Cache operations abstracted behind a unified `CacheService`.

---

## C. Major Architecture Problems (Prioritized)

### Priority 0 (P0) — Critical Structural Violations
- **P0-01:** Gross presentation violation: 2,050 lines of `LeadAllocationMonitorScreen` UI embedded inside `lead_allocation_monitor_bloc.dart`.
- **P0-02:** Inverted core dependency: `lib/core/network/sync_manager.dart` directly imports 15 feature files from `lib/features/*`.
- **P0-03:** Extreme 15,925-line monolith: `lib/features/requirements/screens/requirements_screen.dart` mixing UI, matching algorithms, direct Dio calls, Isar caching, PDF generation, and WhatsApp intents.
- **P0-04:** Extreme 13,121-line monolith: `lib/features/campaign/screens/campaign_leads_screen.dart` mixing campaign sources, lead tables, direct Dio mutations, and Excel generation.
- **P0-05:** Backend KPI monolith: `src/modules/dashboard/kpi.service.js` (5,541 lines) containing thousands of lines of raw SQL string concatenations and duplicate formula definitions.
- **P0-06:** Backend Webhook monolith: `src/modules/integrations/integrations.service.js` (4,624 lines) mixing HMAC signature validation, Graph API calls, phone normalizers, and auto-provisioning.
- **P0-07:** Split backend database drivers (`@supabase/supabase-js` vs `pg.Pool`).
- **P0-08:** Recursive database-level bi-directional triggers (`trg_sync_leads_to_requirements` $\leftrightarrow$ `trg_sync_requirements_to_leads`).

### Priority 1 (P1) — High Impact Modularity
- **P1-01:** Direct Dio HTTP calls inside screen widgets bypassing Repository contracts.
- **P1-02:** Monolithic property screens: `properties_screen.dart` (6,860 lines) and `add_edit_property_screen.dart` (3,611 lines).
- **P1-03:** Monolithic responsive shell: `app_shell.dart` (3,846 lines).
- **P1-04:** Monolithic telecaller screens: `telecaller_callbacks_screen.dart` (3,730 lines) and `telecaller_dashboard_screen.dart` (2,903 lines).
- **P1-05:** Backend allocation service monolith: `allocation.service.js` (2,464 lines).
- **P1-06:** Backend auth controller monolith: `auth.controller.js` (1,247 lines).
- **P1-07:** Client-side KPI and count recalculation in screen widgets diverging from server totals.

### Priority 2 (P2) — Quality & Architecture Hygiene
- **P2-01:** Dashboard analytics sections decomposition (`inventory_demand_analytics_section.dart` 4.3k lines, `analytics_section.dart` 3.7k lines).
- **P2-02:** Health portal embedded HTML asset extraction (`health.html.js` 2.9k lines).
- **P2-03:** User management screens decomposition (`employee_detail_screen.dart` 2.1k lines, `users_screen.dart` 2.0k lines).
- **P2-04:** Dedicated Redis caching implementation to replace in-memory Map stub.

### Priority 3 (P3) — Nice-to-Have Cleanup
- **P3-01:** Upgrade deprecated `WillPopScope` in `splash.dart` to `PopScope`.
- **P3-02:** Clean up 1,080 `flutter analyze` linter notices (unused imports, `avoid_print`, `withOpacity`).
- **P3-03:** Remove unlinked Hero animation tag on splash logo.

---

## D. Module Boundaries (Flutter + Backend)

1. **Flutter Feature Boundaries:**
   - Bounded contexts established for: `admin`, `auth`, `campaign`, `clients`, `dashboard`, `followups`, `library`, `owners`, `properties`, `reports`, `requirements`, `settings`, `support`, `team_messages`, `users`.
   - Features interact strictly through public facades (`application/facades/`). Direct imports of private feature widgets, data sources, or models are forbidden.
2. **Backend Module Boundaries:**
   - Distinct routers and controllers for each domain under `src/modules/`.
   - Domain services communicate via explicit repository contracts. Controllers are forbidden from making direct database calls.

---

## E. Data Ownership (Canonical Source of Truth)

- **PostgreSQL is the single authoritative source of business truth.**
- **Client Caches (Isar, SharedPreferences):** Read-only local projections. Offline mutations in `OutboxLocal` are non-authoritative staging buffers.
- **Server Cache (Redis / In-Memory Map):** Transient cache-aside layer; never authoritative.
- **KPI Formulations:** Canonical calculation owner is the Backend KPI Service (`src/modules/dashboard/kpi.service.js`). The Flutter client must NEVER recalculate or count metrics independently.
- **Multi-Tenancy:** Authoritatively bounded by `organization_id` on all database queries and enforced via `assertTenantContext()`.

---

## F. Dependency Violations

- **Inward Inversion:** `lib/core/network/sync_manager.dart` imports 15 feature files from `lib/features/`.
- **Layer Collapse:** `lead_allocation_monitor_bloc.dart` embeds 2,050 lines of UI widgets inside a BLoC file.
- **Skipped Repositories:** UI screens (`requirements_screen.dart`, `campaign_leads_screen.dart`) make direct calls to `DioClient.dio.get(...)`.
- **Uncontrolled Cross-Feature Coupling:** Requirements screen directly imports `PropertiesRepository`, `PropertiesService`, `DashboardRepository`, and `UsersBloc`.
- **Inline Bootstrap Queries:** `src/app.js` runs raw database queries in an inline `/diagnostics/crud` endpoint.

---

## G. Giant / High-Complexity Files Catalog

| Rank | File Path | Line Count | Current Defect | Recommended Decomposition Target |
| :---: | :--- | :---: | :--- | :--- |
| **1** | `lib/features/requirements/screens/requirements_screen.dart` | **15,925** | UI, matching, Dio calls, Isar, PDF, WhatsApp | Split into scaffold shell, table view, card view, filter bar, and use cases. |
| **2** | `lib/features/campaign/screens/campaign_leads_screen.dart` | **13,121** | Tabs, lead table, reassignment, Excel export | Split into scaffold, data table, source tabs, reassignment dialog, and export use case. |
| **3** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | **7,269** | 20+ KPI drilldown dialogs in one file | Decompose into individual drilldown widgets under `presentation/dialogs/drilldowns/`. |
| **4** | `lib/features/properties/screens/properties_screen.dart` | **6,860** | Inventory list/grid, filters, map drawer | Split into thin coordinator, card item, table item, and filter drawer. |
| **5** | `src/modules/dashboard/kpi.service.js` | **5,541** | Monolithic SQL composition & KPI math | Split into `kpi_executive.service.js`, `kpi_telecaller.service.js`, `kpi_query.repository.js`. |
| **6** | `src/modules/integrations/integrations.service.js` | **4,624** | Webhooks, Graph API, phone normalizers | Split into `meta_webhook.service.js`, `housing_webhook.service.js`, `lead_sanitizer.js`. |
| **7** | `lib/features/dashboard/widgets/inventory_demand_analytics_section.dart` | **4,370** | Canvas chart drawing & supply/demand math | Split into demand container, supply/demand chart, and locality deficit table. |
| **8** | `lib/features/integration/services/integration_service.dart` | **4,185** | HTTP calls, CSV/Excel parsing, sync staging | Split into `integration_api_service.dart` and `lead_text_parser.dart`. |
| **9** | `lib/core/design_system/widgets/app_shell.dart` | **3,846** | Desktop rail, mobile nav, header, popovers | Split into `desktop_navigation_rail.dart`, `mobile_bottom_nav.dart`, `app_header_bar.dart`. |
| **10**| `lib/features/dashboard/widgets/analytics_section.dart` | **3,794** | Conversion funnel, trend charts, leaderboard | Split into standalone chart and leaderboard widgets. |
| **11**| `lib/features/telecaller/screens/telecaller_callbacks_screen.dart` | **3,730** | Calendar, callback cards, dialer, outcome modal | Split into callback card, time filter bar, and disposition sheet. |
| **12**| `lib/features/properties/screens/add_edit_property_screen.dart` | **3,611** | Wizard form, map picker, media uploads | Split into stepper coordinator and discrete step form widgets. |
| **13**| `src/modules/health/health.html.js` | **2,945** | 2,900 lines of raw HTML/CSS/JS in Node file | Extract static files to `assets/health_portal/`. |
| **14**| `lib/features/telecaller/screens/telecaller_dashboard_screen.dart` | **2,903** | Telecaller metrics, queues, quick actions | Split into metric cards and queue widgets. |
| **15**| `src/modules/allocation/allocation.service.js` | **2,464** | Workload logic, capacity, round robin, SQL | Split into `allocation_dispatcher.js`, `telecaller_capacity.js`, `allocation.repository.js`. |
| **16**| `lib/features/admin/bloc/lead_allocation_monitor_bloc.dart` | **2,303** | 2,050 lines of UI widgets inside BLoC file | Separate BLoC state machine from UI screen widget. |
| **17**| `src/modules/reports/reports.service.js` | **1,521** | Analytical SQL queries and Excel building | Separate query repository from streaming export service. |
| **18**| `src/modules/auth/auth.controller.js` | **1,247** | Password hashing, MFA TOTP math, Captcha | Move cryptography to `auth.service.js` and `mfa.service.js`. |

---

## H. AI-Agent Maintainability

Under the established target architecture:
1. **Local Context Isolation:** An AI agent task (e.g. updating a lead disposition outcome or fixing a property status chip) requires reading only the bounded feature directory (`lib/features/<feature>/`), inspecting $< 1,200$ lines across 3–4 files.
2. **Strict Public Facades:** Features expose typed Facades. An AI agent never needs to parse or modify private implementation details of adjacent features.
3. **Autonomous Feature Structure:** Every feature contains its own presentation, application use cases, domain entities, data sources, and unit tests, enabling safe automated testing without booting full application integration environments.

---

## I. Migration Roadmap Summary

- **Phase 1 (Immediate Next Step — Step 2):** Database & Data Access Layer Foundation — Unify `@supabase/supabase-js` and `pg.Pool`, isolate repository SQL queries, and stabilize multi-table transactions.
- **Phase 2:** API Boundary & Remote DataSource Isolation — Route all network calls through typed repositories; eliminate direct Dio calls in UI and BLoC.
- **Phase 3:** P0 Extreme Monolith Decomposition — Decompose `lead_allocation_monitor_bloc.dart` (UI extraction), `SyncManager` (interface decoupling), `requirements_screen.dart`, and `campaign_leads_screen.dart`.
- **Phase 4:** Backend Service Decomposition — Decompose `kpi.service.js`, `integrations.service.js`, and `allocation.service.js`.
- **Phase 5:** P1 & P2 Quality Improvements & Redis Implementation.

---

## J. System Validation & Static Analysis Baseline

Validation commands were executed directly on the repository with actual outputs recorded:

### 1. Backend Test Suite (`npm test` in `C:\NB\PropKart-Backend`)
- **Command:** `npm test`
- **Executed Test Files:** `test/architecture.contract.test.js`, `test/rbac.team.isolation.test.js`, `test/payload.validation.hardening.test.js`, `test/transaction.integrity.error.test.js`, `test/pool.timeout.concurrency.test.js`, `test/auth.tokens.test.js`, `test/health.portal.test.js`, `test/leadIngestEngine.test.js`, `test/meta.integration.test.js`, `test/permissions.telecaller.test.js`, `test/security.hardening.test.js`, `test/allocation.engine.test.js`, `test/kpi.reconciliation.test.js`, `test/captcha.hardening.test.js`.
- **Result:**
  ```text
  ℹ tests 168
  ℹ suites 32
  ℹ pass 168
  ℹ fail 0
  ℹ cancelled 0
  ℹ skipped 0
  ℹ todo 0
  ℹ duration_ms 17487.9154
  ```
- **Status:** **100% PASSED (168 of 168 tests passed).**

### 2. Flutter Static Analysis (`flutter analyze` in `c:\NB\propkart`)
- **Command:** `flutter analyze`
- **Execution Time:** 199.9s
- **Result:**
  ```text
  1080 issues found. (ran in 199.9s)
  ```
- **Diagnosis:** Issues consist of deprecation notices (`withOpacity` $\rightarrow$ `withValues`, `WillPopScope` $\rightarrow$ `PopScope`), unused imports in test files, and `avoid_print` warnings in unit test helpers. Zero breaking compilation errors.

### 3. Flutter Unit Tests (`flutter test` in `c:\NB\propkart`)
- **Command:** `flutter test test/security/role_guard_test.dart test/security/permission_matrix_test.dart`
- **Result:**
  ```text
  00:00 +16: All tests passed!
  ```
- **Status:** **100% PASSED (16 of 16 tests passed).**

---

## K. Architecture Foundation Registry Deliverables

The 13 required architecture foundation governance documents have been authored and deposited in `docs/architecture/`:
1. `docs/architecture/01-CURRENT-ARCHITECTURE.md`
2. `docs/architecture/02-TARGET-ARCHITECTURE.md`
3. `docs/architecture/03-SOURCE-OF-TRUTH.md`
4. `docs/architecture/04-BUSINESS-LOGIC-OWNERSHIP.md`
5. `docs/architecture/05-API-BOUNDARY.md`
6. `docs/architecture/06-DATABASE-BOUNDARY.md`
7. `docs/architecture/07-CODE-SIZE-POLICY.md`
8. `docs/architecture/08-AI-MAINTAINABILITY.md`
9. `docs/architecture/09-DEPENDENCY-RULES.md`
10. `docs/architecture/10-CONFIGURATION.md`
11. `docs/architecture/ARCHITECTURE-RULES.md`
12. `docs/architecture/DEPENDENCY-GRAPH.md`
13. `docs/architecture/11-ARCHITECTURE-MIGRATION-ROADMAP.md`
14. `docs/architecture/STEP-1-SYSTEM-ARCHITECTURE-REPORT.md` (This document)

---

## L. Step 1 Status

```text
PASS — ARCHITECTURE FOUNDATION ESTABLISHED
```

---

## STOP CONDITION COMPLIANCE

Step 1 is complete.  
No database indexes have been altered.  
No Redis infrastructure has been installed.  
No APIs have been optimized or modified.  
No working functionality has been refactored.  
Awaiting explicit approval before proceeding to Step 2.
