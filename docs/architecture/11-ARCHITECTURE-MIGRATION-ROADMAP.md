# PROPKART — ARCHITECTURE MIGRATION ROADMAP
**Version:** 1.0.0  
**Status:** CANONICAL MIGRATION ROADMAP (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** Phased Architecture Remediation Plan for PropKart  

---

## 1. Governance & Execution Principles

This roadmap establishes the phased remediation plan to transition the PropKart codebase into the target architecture without disrupting live operations.

### Execution Invariants:
1. **No Speculative Mass Refactoring:** Refactoring must proceed module by module in dedicated, bounded steps.
2. **Strangler Fig Pattern:** New code adheres to the target architecture immediately. Monolithic components are decomposed behind existing facade/repository contracts.
3. **Continuous Regression Verification:** Every migration step must run static analysis (`flutter analyze`), backend unit test suites (`npm test`), and Flutter unit tests (`flutter test`) before sign-off.

---

## 2. Priority 0 (P0) — Critical Structural Violations & Extreme Monoliths

Problems causing severe architectural coupling, impossible maintenance, high risk of data divergence, or gross pattern violations.

---

### Item: P0-01
```text
ID: P0-01
Problem: Gross architectural violation: The entire 2,050-line LeadAllocationMonitorScreen UI widget tree is embedded directly inside the BLoC file.
Current Location: `lib/features/admin/bloc/lead_allocation_monitor_bloc.dart` (lines 254–2303)
Target Location:
  - `lib/features/admin/presentation/bloc/lead_allocation_monitor_bloc.dart` (<250 lines)
  - `lib/features/admin/presentation/screens/lead_allocation_monitor_screen.dart` (<400 lines)
  - `lib/features/admin/presentation/widgets/telecaller_capacity_table.dart` (<300 lines)
Reason: Violates presentation vs state management boundary; blocks headless BLoC testing and AI agent comprehension.
Dependencies: None (Internal to admin feature)
Risk: Low (UI visual presentation remains unchanged)
Estimated Scope: 1 day
Verification Method: `flutter test test/admin/` & `flutter analyze`
```

---

### Item: P0-02
```text
ID: P0-02
Problem: Inverted core dependency: `SyncManager` in `lib/core/network/` directly imports 15 feature files from `lib/features/*`.
Current Location: `lib/core/network/sync_manager.dart` (lines 13–31)
Target Location:
  - `lib/core/network/sync_manager.dart` (Depends only on `SyncParticipant` interface)
  - `lib/core/network/sync_participant.dart` (Abstract contract)
  - Feature sync participants registered in `lib/app/bootstrap/sync_registration.dart`
Reason: Prevents modular builds, causes circular dependency risks, violates inward dependency rule.
Dependencies: `SyncEngine`, `LocalRepositories`
Risk: Medium (Core offline sync flow)
Estimated Scope: 2 days
Verification Method: `flutter test test/core/` & full offline/online sync verification
```

---

### Item: P0-03
```text
ID: P0-03
Problem: Monolithic 15,925-line screen (`requirements_screen.dart`) mixing UI, matching algorithms, direct Dio network calls, Isar caching, PDF generation, and WhatsApp launching.
Current Location: `lib/features/requirements/screens/requirements_screen.dart`
Target Location:
  - `lib/features/requirements/presentation/screens/requirements_screen.dart` (Scaffold, <400 lines)
  - `lib/features/requirements/presentation/widgets/requirements_table_view.dart` (<500 lines)
  - `lib/features/requirements/presentation/widgets/requirements_card_view.dart` (<400 lines)
  - `lib/features/requirements/presentation/widgets/requirements_filter_bar.dart` (<350 lines)
  - `lib/features/requirements/presentation/dialogs/requirement_detail_dialog.dart` (<450 lines)
  - `lib/features/requirements/application/usecases/export_requirement_pdf_usecase.dart` (<200 lines)
Reason: Impossible for AI agents or human developers to modify without regressions; high risk of merge conflicts.
Dependencies: `RequirementsBloc`, `PropertiesFacade`, `LocalRepositories`
Risk: High (Core lead matching and sales consultation screen)
Estimated Scope: 3–4 days
Verification Method: `flutter test test/requirements/` & manual requirement workflow QA
```

---

### Item: P0-04
```text
ID: P0-04
Problem: Monolithic 13,121-line screen (`campaign_leads_screen.dart`) mixing campaign tab navigation, lead reassignments, direct Dio mutations, and Excel generation.
Current Location: `lib/features/campaign/screens/campaign_leads_screen.dart`
Target Location:
  - `lib/features/campaign/presentation/screens/campaign_leads_screen.dart` (<350 lines)
  - `lib/features/campaign/presentation/widgets/campaign_leads_data_table.dart` (<500 lines)
  - `lib/features/campaign/presentation/widgets/campaign_source_tabs.dart` (<250 lines)
  - `lib/features/campaign/presentation/dialogs/reassign_lead_dialog.dart` (<350 lines)
  - `lib/features/campaign/application/usecases/export_campaign_excel_usecase.dart` (<200 lines)
Reason: Monolithic file size; mixes business logic, presentation, and data export.
Dependencies: `CampaignLeadsBloc`, `IntegrationService`, `UsersRepository`
Risk: High (Inbound lead intake & telecaller assignment interface)
Estimated Scope: 3 days
Verification Method: `flutter test test/campaign/` & lead disposition QA
```

---

### Item: P0-05
```text
ID: P0-05
Problem: Backend KPI service monolith (`kpi.service.js`, 5,541 lines) containing thousands of lines of raw SQL string composition, metric calculations, and drilldown queries.
Current Location: `C:\NB\PropKart-Backend\src\modules\dashboard\kpi.service.js`
Target Location:
  - `src/modules/dashboard/services/kpi_executive.service.js` (<400 lines)
  - `src/modules/dashboard/services/kpi_telecaller.service.js` (<400 lines)
  - `src/modules/dashboard/services/kpi_sales.service.js` (<400 lines)
  - `src/modules/dashboard/repositories/kpi_query.repository.js` (Encapsulates SQL queries)
Reason: Single point of failure for all platform dashboards and KPI reconciliation; high risk of formula divergence.
Dependencies: `dbPool.js`, `kpiRulebook.master.js`
Risk: High (Must guarantee 100% numerical equivalence with existing KPIs)
Estimated Scope: 3 days
Verification Method: `npm test test/kpi.reconciliation.test.js` & dashboard verification
```

---

### Item: P0-06
```text
ID: P0-06
Problem: Backend integrations monolith (`integrations.service.js`, 4,624 lines) mixing Meta webhook challenges, Housing.com payloads, phone sanitization, and auto-provisioning.
Current Location: `C:\NB\PropKart-Backend\src\modules\integrations\integrations.service.js`
Target Location:
  - `src/modules/integrations/services/meta_webhook.service.js` (<300 lines)
  - `src/modules/integrations/services/housing_webhook.service.js` (<300 lines)
  - `src/modules/integrations/services/lead_sanitizer.service.js` (<200 lines)
  - `src/modules/integrations/services/lead_auto_provision.service.js` (<350 lines)
Reason: Core ingestion path for revenue-generating leads; mixing webhook security with database mutations.
Dependencies: `dbPool.js`, `leadIngestEngine.service.js`
Risk: High (Must maintain webhook response times <500ms to avoid Meta retries)
Estimated Scope: 3 days
Verification Method: `npm test test/meta.integration.test.js test/housing.integration.test.js`
```

---

### Item: P0-07
```text
ID: P0-07
Problem: Split backend database drivers (`@supabase/supabase-js` service role vs `pg.Pool`).
Current Location: `C:\NB\PropKart-Backend\src\config\supabase.js` and `dbPool.js`
Target Location: Unify all data access behind `src/config/dbPool.js` and dedicated repositories.
Reason: Dual connection overhead, divergent transaction scopes, and unpredictable error formats.
Dependencies: All backend modules querying Supabase client
Risk: Medium
Estimated Scope: 3–4 days
Verification Method: `npm test test/architecture.contract.test.js` & database stress tests
```

---

### Item: P0-08
```text
ID: P0-08
Problem: Recursive database-level bi-directional triggers (`trg_sync_leads_to_requirements` and `trg_sync_requirements_to_leads`).
Current Location: PostgreSQL migration 56 & 57 (`fn_sync_leads_to_requirements`, `fn_sync_requirements_to_leads`)
Target Location: Relocate sync coordination into backend `LeadLifecycleService` with atomic transactions.
Reason: Eliminates circular trigger firing risks, hidden database side-effects, and lock contention.
Dependencies: `leads` & `requirements` repositories
Risk: High (Must prevent data desynchronization)
Estimated Scope: 2 days
Verification Method: Automated sync verification tests & database transaction rollback tests
```

---

## 3. Priority 1 (P1) — High Impact Maintainability & Modularity

Problems significantly affecting developer velocity, code modularity, and operational reliability.

---

### Item: P1-01
```text
ID: P1-01
Problem: Direct Dio HTTP calls inside UI screens and BLoC classes bypassing Repository contracts.
Current Location: Multiple screens across `lib/features/`
Target Location: Route all API calls through `features/<name>/data/repositories/`
Reason: Enforces the API boundary, enables mocking for unit tests, enables offline queuing.
Dependencies: Feature BLoCs
Risk: Low
Estimated Scope: 2 days
Verification Method: Static grep for `DioClient` in `lib/features/*/screens/` and `bloc/`
```

---

### Item: P1-02
```text
ID: P1-02
Problem: Decomposition of 6,860-line `properties_screen.dart` and 3,611-line `add_edit_property_screen.dart`.
Current Location: `lib/features/properties/screens/`
Target Location: Separate into filter bar, card/table view widgets, and step wizard forms.
Reason: High complexity; daily operational tool for brokers and sales agents.
Dependencies: `PropertiesBloc`, `PropertiesRepository`
Risk: Medium
Estimated Scope: 2–3 days
Verification Method: `flutter test test/properties/`
```

---

### Item: P1-03
```text
ID: P1-03
Problem: Monolithic responsive layout wrapper (`app_shell.dart`, 3,846 lines).
Current Location: `lib/core/design_system/widgets/app_shell.dart`
Target Location: Split into `DesktopNavigationRail`, `MobileBottomNav`, `AppHeaderBar`, and `NotificationsMenu`.
Reason: Modifying navigation rails requires reading nearly 4,000 lines of mixed layout code.
Dependencies: `AppRouter`, `RoleGuard`
Risk: Medium
Estimated Scope: 1.5 days
Verification Method: `flutter test test/mobile/` & multi-device layout visual inspection
```

---

### Item: P1-04
```text
ID: P1-04
Problem: Telecaller operational screens decomposition (`telecaller_callbacks_screen.dart` 3.7k lines, `telecaller_dashboard_screen.dart` 2.9k lines).
Current Location: `lib/features/telecaller/screens/`
Target Location: Split into callback cards, dialer action sheets, and time-slot filter widgets.
Reason: Telecaller workflow performance and UI responsiveness.
Dependencies: `TelecallerLeadsBloc`
Risk: Medium
Estimated Scope: 2 days
Verification Method: `flutter test test/telecaller/`
```

---

### Item: P1-05
```text
ID: P1-05
Problem: Backend allocation service decomposition (`allocation.service.js`, 2,464 lines).
Current Location: `C:\NB\PropKart-Backend\src\modules\allocation/allocation.service.js`
Target Location: Split into `AllocationDispatcher`, `TelecallerCapacityService`, and `StaleRecoveryService`.
Reason: Central engine for distributing inbound leads; mixes timers, status validation, and SQL.
Dependencies: `dbPool.js`
Risk: High
Estimated Scope: 2 days
Verification Method: `npm test test/allocation.engine.test.js`
```

---

### Item: P1-06
```text
ID: P1-06
Problem: Backend auth controller decomposition (`auth.controller.js`, 1,247 lines).
Current Location: `C:\NB\PropKart-Backend\src\modules\auth/auth.controller.js`
Target Location: Move password hashing, MFA TOTP generation, and captcha handling into dedicated services.
Reason: Controller should only translate HTTP requests, not execute cryptography or MFA math.
Dependencies: `bcryptjs`, `jsonwebtoken`
Risk: Medium
Estimated Scope: 1 day
Verification Method: `npm test test/auth.tokens.test.js test/captcha.hardening.test.js`
```

---

### Item: P1-07
```text
ID: P1-07
Problem: Client-side KPI and count recalculation in screen widgets.
Current Location: `requirements_screen.dart`, `campaign_leads_screen.dart`
Target Location: Bind header badges directly to API response `meta.counts` / `meta.kpis`.
Reason: Prevents count divergence between table headers and executive dashboards.
Dependencies: Backend KPI response envelope
Risk: Low
Estimated Scope: 1 day
Verification Method: Cross-screen count comparison against database totals
```

---

## 4. Priority 2 (P2) — Quality & Architecture Hygiene

- **P2-01: Dashboard Analytics Sections Decomposition** (`inventory_demand_analytics_section.dart` 4.3k lines, `analytics_section.dart` 3.7k lines). Split into standalone chart and gauge widgets.
- **P2-02: Health HTML Asset Extraction** (`health.html.js` 2.9k lines). Extract static HTML/CSS/JS to standalone files.
- **P2-03: User Management Screens Decomposition** (`employee_detail_screen.dart` 2.1k lines, `users_screen.dart` 2.0k lines). Separate into employee profile card, permissions matrix tab, and attendance history.
- **P2-04: Settings & Location Configuration Decomposition** (`settings_screen.dart` 2.2k lines, `location_config_screen.dart` 1.9k lines). Separate lookup editors.
- **P2-05: Dedicated Redis Caching Implementation**. Replace the temporary in-memory `Map` stub in `src/config/redis.js` with an enterprise Redis connection for multi-process clustering.

---

## 5. Priority 3 (P3) — Nice-to-Have Cleanup

- **P3-01: Deprecate `WillPopScope` in `splash.dart`**. Upgrade to modern Flutter `PopScope`.
- **P3-02: Flutter Static Analysis Warnings Cleanup**. Resolve 1,080 `flutter analyze` info/warnings (unused imports, `avoid_print` in tests, `withOpacity` vs `withValues`).
- **P3-03: Redundant Hero Tag Cleanup**. Remove unlinked Hero animation tag on splash logo.
