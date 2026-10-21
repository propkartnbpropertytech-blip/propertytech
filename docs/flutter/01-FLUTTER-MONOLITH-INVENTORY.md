# Flutter Monolith & Codebase Architecture Inventory

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  
> **Framework:** Flutter 3.47.1 • Dart 3.13.1  
> **Baseline Status:** Authoritative Architectural Audit  

---

## 1. Executive Summary & Codebase Dimensions

A comprehensive static analysis of the PropKart Flutter codebase was conducted across all Dart source files in `lib/`:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       FLUTTER CODEBASE METRICS                              │
├────────────────────────────────────────┬────────────────────────────────────┤
│ Total Dart Source Files (excl .g.dart) │ 367 files                          │
│ Total Lines of Dart Code               │ 215,872 lines                      │
│ Average File Size                      │ 588 lines                          │
│ Monolith Files (>= 1,000 lines)        │ 50 files                           │
│ Critical Monoliths (>= 5,000 lines)    │ 4 files (43,738 lines combined!)   │
│ Widgets with Direct Dio Network Calls  │ 28 files                           │
│ Widgets with Direct Isar / Supabase    │ 4 files                            │
└────────────────────────────────────────┴────────────────────────────────────┘
```

---

## 2. Monolith Classification by Size Tiers

The 367 Dart files in `lib/` are categorized into strict size tiers:

```text
  >= 10,000 lines ─── [2 files]   (29,046 lines | 13.5% of codebase)
 5,000-9,999 lines ─── [2 files]   (14,692 lines |  6.8% of codebase)
 2,000-4,999 lines ─── [19 files]  (56,384 lines | 26.1% of codebase)
 1,000-1,999 lines ─── [27 files]  (38,125 lines | 17.7% of codebase)
   500-999 lines   ─── [42 files]  (29,410 lines | 13.6% of codebase)
     < 500 lines   ─── [275 files] (48,215 lines | 22.3% of codebase)
```

> [!CAUTION]
> Just **4 files** (1.1% of all files) account for **43,738 lines** (over 20.2% of the entire application codebase). These giant monoliths cause severe token context overflow for AI coding agents and create catastrophic regression risks during edits.

---

## 3. Tier 1 & Tier 2 Monoliths (Critical Giants)

| Rank | File Path | Line Count | Architectural Role | Boundary Violations Identified |
| :---: | :--- | :---: | :---: | :--- |
| **1** | `lib/features/requirements/screens/requirements_screen.dart` | **15,925** | UI Screen | Direct Dio HTTP calls, direct Isar storage, inline WhatsApp launchers, 12 embedded dialogs, manual PDF builders, inline sorting algorithms |
| **2** | `lib/features/campaign/screens/campaign_leads_screen.dart` | **13,121** | UI Screen | Direct Dio HTTP calls, massive inline campaign table cells, custom column mapping forms, lead reclassification modals, raw query pipelines |
| **3** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | **7,542** | UI Widget | Giant multi-tab modal dialog containing deep analytics queries, chart builders, raw pagination loops, and complex filter pipelines |
| **4** | `lib/features/properties/screens/properties_screen.dart` | **7,150** | UI Screen | Direct Dio HTTP calls, property grid view models, sharing sheets, inline card renderers, price filtering math |

---

## 4. Tier 3 Monoliths (2,000 – 4,999 Lines)

| File Path | Lines | Architectural Role | Mixed Responsibilities |
| :--- | :---: | :---: | :--- |
| `lib/features/dashboard/widgets/inventory_demand_analytics_section.dart` | **4,535** | Widget | Analytical demand calculations, chart layouts, complex state |
| `lib/features/integration/services/integration_service.dart` | **4,534** | Service | Direct Isar sync, Dio requests, Meta lead transformation |
| `lib/core/design_system/widgets/app_shell.dart` | **4,044** | Core Widget | Navigation routing, drawer rendering, responsive layout breakpoints, notification polling, role guards |
| `lib/features/dashboard/widgets/analytics_section.dart` | **3,997** | Widget | Conversion rate math, operational KPI aggregation |
| `lib/features/telecaller/screens/telecaller_callbacks_screen.dart` | **3,885** | Screen | Callback tables, direct Dio requests, date formatters |
| `lib/features/properties/screens/add_edit_property_screen.dart` | **3,817** | Screen | Giant 40-field form, image uploaders, coordinate geocoders |
| `lib/features/sales/screens/sales_my_leads_screen.dart` | **3,736** | Screen | Sales rep lead queue, inline call logs, direct status mutation |
| `lib/features/telecaller/screens/telecaller_dashboard_screen.dart` | **3,040** | Screen | Telecaller KPIs, active call counters, round-robin telemetry |
| `lib/features/campaign/screens/connections_screen.dart` | **2,864** | Screen | Meta webhook setup dialogs, token exchange forms |
| `lib/features/admin/screens/admin_dashboard_screen.dart` | **2,785** | Screen | System health tiles, staff rosters, audit log viewers |
| `lib/features/admin/bloc/lead_allocation_monitor_bloc.dart` | **2,303** | BLoC | Queue monitoring state, allocation trigger use-cases, telemetry |
| `lib/features/reports/screens/reports_screen.dart` | **2,152** | Screen | Multi-tab reporting suite, Excel generation, date filters |
| `lib/features/sales/screens/sales_lead_detail_screen.dart` | **2,042** | Screen | Detailed lead lifecycle view, timeline widgets, deal stages |

---

## 5. Architectural Boundary Violations Audit

### 1. Direct Database Access in UI Widgets (Screen ➔ Isar / Supabase)
The target architecture mandates: `Screen -> BLoC -> Use Case -> Repository -> Local/Remote DataSource`.  
Currently, **4 widget files** directly query Isar or Supabase:
- `lib/features/requirements/screens/requirements_screen.dart` (`isar.requirementModels...`)
- `lib/features/properties/screens/properties_screen.dart` (`isar.propertyModels...`)
- `lib/core/storage/local_repositories.dart`
- `lib/features/integration/services/integration_service.dart`

### 2. Direct Network Calls in UI Widgets (Widget ➔ Dio)
A staggering **28 widget files** bypass BLoCs, Use Cases, and Repositories by instantiating or calling `DioClient` or `dio.get()` / `dio.post()` directly within widget helper methods and `onPressed` callbacks!
- `requirements_screen.dart` (Makes direct Dio calls for status updates, exports, notes)
- `campaign_leads_screen.dart` (Makes direct Dio calls for campaign column saves and lead reassignments)
- `properties_screen.dart` (Direct Dio calls for property verification toggling)
- `telecaller_callbacks_screen.dart` (Direct Dio calls for disposition logging)
- `add_edit_property_screen.dart` (Direct Dio calls for metadata lookups)

### 3. Mixed Responsibility & God BLoCs
- `lib/features/admin/bloc/lead_allocation_monitor_bloc.dart` (2,303 lines):
  - Contains queue polling timers, direct API request payloads, allocation rule calculation, and WebSocket/SSE reconnection handlers inside a single BLoC class.

---

## 6. Priority Decoupling Roadmap

```text
Priority 1: requirements_screen.dart (15,925 lines)
  ├── Extract RequirementsHeaderWidget (~600 lines)
  ├── Extract RequirementsFilterBarWidget (~1,200 lines)
  ├── Extract RequirementsSummaryBar (~800 lines)
  ├── Extract RequirementCard / RequirementRow (~1,500 lines)
  ├── Extract RequirementActionsDialogs (~2,000 lines)
  └── Isolate data fetching to RequirementsBloc & RequirementsRepository

Priority 2: campaign_leads_screen.dart (13,121 lines)
  ├── Extract CampaignSubshellHeader (~500 lines)
  ├── Extract CampaignColumnSettingsDialog (~900 lines)
  ├── Extract CampaignLeadsTable (~2,500 lines)
  ├── Extract LeadReclassifyDialog (~1,100 lines)
  └── Route mutations through CampaignBloc & CampaignRepository

Priority 3: lead_allocation_monitor_bloc.dart (2,303 lines)
  ├── Extract AllocationMonitorState & Events into separate files
  ├── Extract AllocationPollingEngine to a domain service
  └── Keep BLoC focused exclusively on UI state mapping
```
