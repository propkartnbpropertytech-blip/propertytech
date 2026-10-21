# PropKart Backend Refactoring Status & Exemption Registry

> **Document Version:** 1.0.0  
> **Status:** Step 5 Verified Baseline  
> **Target:** PropKart Backend Engine (`src/`)  
> **Test Suite Status:** 199 / 199 Passing Across 47 Suites (100% Pass Rate)  

---

## 1. Executive Summary

During Step 5 (Backend Layer Restructuring & Monolith Decoupling), the backend was systematically transitioned from partially coupled monolithic files into a strictly layered, feature-oriented architecture.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       REFACTORING PROGRESS SUMMARY                          │
├────────────────────────────────────────┬────────────────────────────────────┤
│ Total Monolith Controllers Decoupled   │ 7 Major Feature Controllers        │
│ Total Monolith Services Modularized   │ 2 Giant Monolith Services          │
│ Total Architecture Rules Tests Added   │ 5 Automated Tests (All Green)      │
│ Total Test Suite Baseline              │ 199 / 199 Passing (47 Suites)      │
│ Breaking Changes / Regressions         │ 0 (Zero Breaking Changes)          │
└────────────────────────────────────────┴────────────────────────────────────┘
```

---

## 2. Refactored Module Inventory

### Phase 1: Controller Decoupling Batches (Completed & Verified)
| Module Path | Pre-Refactor Violation | Post-Refactor Architecture | Verification |
| :--- | :--- | :--- | :--- |
| `src/modules/export/` | Controller connected directly to `dbPool` | `ExportRepository` + `ExportService` + Clean `ExportController` | 100% Decoupled |
| `src/modules/properties/` | Direct `supabase` queries for imports & duplicates | Moved to `PropertiesService.checkDuplicate` & `processImportProperties` | 100% Decoupled |
| `src/modules/search/` | Direct `supabase.from("properties")` | `SearchRepository` + `SearchService` + Clean `SearchController` | 100% Decoupled |
| `src/modules/checklist/` | Direct `supabase.from("leads")` | `ChecklistRepository` + `ChecklistService` + Clean `ChecklistController` | 100% Decoupled |
| `src/modules/notifications/` | Direct `supabase.from("notifications")` | `NotificationsRepository` + `NotificationsService` + Clean `NotificationsController` | 100% Decoupled |
| `src/modules/usage/` | Direct `supabase.from("api_usage")` | `UsageRepository` + `UsageService` + Clean `UsageController` | 100% Decoupled |
| `src/modules/places/` | Direct `supabase.from("places_cache")` | `PlacesRepository` + `PlacesService` + Clean `PlacesController` | 100% Decoupled |

### Phase 2: Monolith Service Decomposition (Completed & Verified)
| Monolith Service | Initial Lines | Decoupled Extraction | Status |
| :--- | :--- | :--- | :--- |
| `src/modules/dashboard/kpi.service.js` | 5,541 lines | `src/modules/dashboard/kpi/kpi.definitions.js` (canonical SQL, date parsing, column maps) | Active & Re-exported |
| `src/modules/integrations/integrations.service.js` | 4,624 lines | `src/modules/integrations/campaignColumns.service.js` (campaign column layout settings) | Active & Re-exported |

---

## 3. Legacy Exemption Registry

The following 8 legacy controller files maintain direct database access and are catalogued in `test/architecture.rules.test.js` under the `legacyExemptions` registry. They are scheduled for systematic extraction in subsequent optimization steps:

1. `src/modules/auth/auth.controller.js` (Session, MFA, and profile database access)
2. `src/modules/allocation/allocation.controller.js` (Direct queue inspection fallback)
3. `src/modules/followups/followups.controller.js` (Scheduled followup table access)
4. `src/modules/site_visits/site_visits.controller.js` (Site visit scheduling lookups)
5. `src/modules/users/users.controller.js` (User management data lookups)
6. `src/modules/users/users.stats.controller.js` (Aggregated user dial metrics)
7. `src/modules/users/users.upload.controller.js` (Bulk staff roster import queries)
8. `src/modules/health/health.controller.js` (Intentionally tests raw PostgreSQL ping & Supabase connectivity for diagnostic endpoints)

> [!NOTE]
> Any new controller created outside this registry will immediately fail CI/CD if it attempts direct database or Redis client imports.

---

## 4. Verification Test Suite Matrix

```bash
node --test test/architecture.rules.test.js
# Output:
# ✔ 1. Route Layer Purity: No routes file imports supabase or dbPool directly
# ✔ 2. Controller Decoupling: Refactored feature controllers do not import supabase or dbPool directly
# ✔ 3. Redis Layer Boundary: Controllers and Routes do not import raw Redis client
# ✔ 4. Repository Layer Protocol: Repositories do not manipulate HTTP responses
# ✔ 5. Modular Extraction Integrity: Separated services are cleanly integrated
# ℹ tests 5 | pass 5 | fail 0
```
