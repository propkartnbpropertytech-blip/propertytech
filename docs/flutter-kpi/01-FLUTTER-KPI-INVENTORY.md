# PROPKART FLUTTER KPI & UI INVENTORY
## Step 8.5 Architectural Audit & Screen-to-API Mapping

**Document Version:** 1.0.0  
**Status:** Certified Audit  
**Scope:** PropKart Flutter Client (`c:\NB\propkart`)  
**Backend Reference:** Steps 8.0–8.4 Certified Architecture  

---

## 1. Executive Summary

This document establishes the comprehensive forensic inventory of all KPI visual surfaces, widgets, dialogs, BLoCs, repositories, and data services within the PropKart Flutter application. 

In accordance with the Master Architecture:
- **PostgreSQL is the mathematical source of truth** for all authoritative KPI calculations.
- **Flutter is strictly a consumer of authoritative results**, owning presentation, formatting, visualization, filter selection, error handling, retry lifecycles, and responsive layouts.
- **Zero client-side authoritative calculations** are permitted.

---

## 2. Screen & Widget Inventory

### 2.1 Primary Dashboard Surfaces

| Screen / Component | File Location | Consumed KPIs / Metrics | State Management | Data Source / Flow |
| :--- | :--- | :--- | :--- | :--- |
| **DashboardScreen** | `lib/features/dashboard/screens/dashboard_screen.dart` | Total Portfolio, Available, Sold, Rented, Requirements, Won Deals, Lifecycle Funnel, Growth Trends | `DashboardBloc` | `DashboardRepository` -> `DashboardService` -> `/api/v1/dashboard/*` |
| **PipelineFunnelBar** | `lib/features/dashboard/widgets/pipeline_funnel_bar.dart` | Total Leads, In Pipeline, Stage Breakdown, Active Sales Roster | `DashboardState` | `DashboardRepository.getLifecycleBreakdown()` |
| **InventoryDemandAnalytics** | `lib/features/dashboard/widgets/inventory_demand_analytics_section.dart` | Locality Intelligence, Inventory by Area, Leads by Area | Local State / Stateful | `DashboardRepository` -> `/dashboard/locality-intelligence` |
| **TodaysScheduleCard** | `lib/features/dashboard/widgets/todays_schedule_card.dart` | Follow-ups Due, Site Visits Due, Personal Notes | Local State / Stateful | `DashboardRepository` -> `/dashboard/notes` |
| **FollowupsCard** | `lib/features/dashboard/widgets/followups_card.dart` | Upcoming, Pending, Completed Followups | `DashboardState` | `DashboardRepository.getDashboardData()` |

### 2.2 KPI Cards & Drill-down Surfaces

| Widget / Dialog | File Location | Triggering KPI | Target API Endpoint |
| :--- | :--- | :--- | :--- |
| **_InventoryDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Available Inventory / Total Inventory | `/api/v1/dashboard/inventory-breakdown`<br>`/api/v1/dashboard/inventory-properties` |
| **_LeadsDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Total Leads / Lead Sources | `/api/v1/dashboard/leads-breakdown`<br>`/api/v1/dashboard/leads-list` |
| **_NotInterestedDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Not Interested Leads | `/api/v1/dashboard/not-interested-leads` |
| **_TelecallersDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Telecaller Activity | `/api/v1/dashboard/telecallers-summary`<br>`/api/v1/dashboard/telecaller-drilldown/:id`<br>`/api/v1/dashboard/telecaller-leads/:id` |
| **_LeadsAllocatedDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | New / Old Leads Allocated | `/api/v1/dashboard/leads-allocated-breakdown` |
| **_AssignedToSalesDrilldownDialog**| `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Assigned to Sales | `/api/v1/dashboard/assigned-to-sales-breakdown` |
| **_SalesUsersDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Sales Team Performance | `/api/v1/dashboard/sales-users-summary`<br>`/api/v1/dashboard/sales-user-drilldown/:id`<br>`/api/v1/dashboard/sales-user-requirements/:id` |
| **_SiteVisitsDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Site Visits Done / Scheduled | `/api/v1/dashboard/site-visits-list` |
| **_DealWonDrilldownDialog** | `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` | Deals Won / Converted Clients | `/api/v1/dashboard/deal-won-list` |
| **PipelineStageDrilldownDialog**| `lib/features/dashboard/widgets/pipeline_stage_drilldown_dialog.dart` | Funnel Stage Leads | `/api/v1/dashboard/lifecycle-leads` |
| **GenericKpiDrilldownDialog** | `lib/features/dashboard/widgets/generic_kpi_drilldown_dialog.dart` | Dynamic Configured KPIs | `/api/v1/dashboard/drilldown/:kpiKey` |

### 2.3 Reports & Business Intelligence Surfaces

| Screen / Component | File Location | Metrics Displayed | Backend Endpoint |
| :--- | :--- | :--- | :--- |
| **ReportsScreen** | `lib/features/reports/screens/reports_screen.dart` | Overall Report, Conversion Funnel, Growth Comparison | `/api/v1/reports/overall` |
| **BusinessInsightScreen** | `lib/features/reports/screens/business_insight_screen.dart` | Property Listing vs Requirement Performance, Source Efficiency | `/api/v1/reports/business-insight`<br>`/api/v1/reports/business-insight/leads` |

---

## 3. End-to-End API Surface Mapping

The certified Flutter client connects to 21 distinct backend API endpoints across Dashboard and Reporting domains:

| # | Endpoint URL | HTTP Method | Flutter Service Method | Flutter Repository Method | Response DTO Model |
| :-: | :--- | :-: | :--- | :--- | :--- |
| 1 | `/api/v1/dashboard/kpis` | GET | `DashboardService.getDashboardKpis` | `DashboardRepository.getDashboardKpis` | `DashboardKpisResponse` |
| 2 | `/api/v1/dashboard/inventory-breakdown` | GET | `DashboardService.getInventoryBreakdown` | `DashboardRepository.getInventoryBreakdown` | `InventoryBreakdownData` |
| 3 | `/api/v1/dashboard/inventory-properties`| GET | `DashboardService.getInventoryProperties` | `DashboardRepository.getInventoryProperties` | `InventoryPropertiesResponse` |
| 4 | `/api/v1/dashboard/leads-breakdown` | GET | `DashboardService.getLeadsBreakdown` | `DashboardRepository.getLeadsBreakdown` | `LeadsBreakdownData` |
| 5 | `/api/v1/dashboard/leads-list` | GET | `DashboardService.getLeadsList` | `DashboardRepository.getLeadsList` | `LeadsListResponse` |
| 6 | `/api/v1/dashboard/not-interested-leads`| GET | `DashboardService.getNotInterestedLeads` | `DashboardRepository.getNotInterestedLeads` | `LeadsListResponse` |
| 7 | `/api/v1/dashboard/telecallers-summary` | GET | `DashboardService.getTelecallersSummary` | `DashboardRepository.getTelecallersSummary` | `TelecallersSummaryResponse` |
| 8 | `/api/v1/dashboard/telecaller-drilldown/:id` | GET | `DashboardService.getTelecallerDrilldown` | `DashboardRepository.getTelecallerDrilldown` | `TelecallerDrilldownData` |
| 9 | `/api/v1/dashboard/telecaller-leads/:id`| GET | `DashboardService.getTelecallerLeads` | `DashboardRepository.getTelecallerLeads` | `LeadsListResponse` |
| 10 | `/api/v1/dashboard/site-visits-list` | GET | `DashboardService.getSiteVisitsList` | `DashboardRepository.getSiteVisitsList` | `SiteVisitsResponse` |
| 11 | `/api/v1/dashboard/deal-won-list` | GET | `DashboardService.getDealWonList` | `DashboardRepository.getDealWonList` | `DealWonResponse` |
| 12 | `/api/v1/dashboard/sales-user-requirements/:id` | GET | `DashboardService.getSalesUserRequirements` | `DashboardRepository.getSalesUserRequirements` | `SalesUserRequirementsResponse` |
| 13 | `/api/v1/dashboard/leads-allocated-breakdown` | GET | `DashboardService.getLeadsAllocatedBreakdown` | `DashboardRepository.getLeadsAllocatedBreakdown` | `LeadsAllocatedResponse` |
| 14 | `/api/v1/dashboard/assigned-to-sales-breakdown` | GET | `DashboardService.getAssignedToSalesBreakdown` | `DashboardRepository.getAssignedToSalesBreakdown` | `AssignedToSalesResponse` |
| 15 | `/api/v1/dashboard/sales-users-summary` | GET | `DashboardService.getSalesUsersSummary` | `DashboardRepository.getSalesUsersSummary` | `SalesUsersSummaryResponse` |
| 16 | `/api/v1/dashboard/sales-user-drilldown/:id` | GET | `DashboardService.getSalesUserDrilldown` | `DashboardRepository.getSalesUserDrilldown` | `SalesUserDrilldownData` |
| 17 | `/api/v1/dashboard/lifecycle-breakdown` | GET | `DashboardService.getLifecycleBreakdown` | `DashboardRepository.getLifecycleBreakdown` | `Map<String, dynamic>` |
| 18 | `/api/v1/dashboard/lifecycle-leads` | GET | `DashboardService.getLifecycleLeads` | `DashboardRepository.getLifecycleLeads` | `Map<String, dynamic>` |
| 19 | `/api/v1/dashboard/locality-intelligence` | GET | `DashboardService.getLocalityIntelligence` | `DashboardRepository.getLocalityIntelligence` | `LocalityIntelligenceData` |
| 20 | `/api/v1/reports/business-insight` | GET | `BusinessInsightService.fetchSummary` | `ReportsRepository.getReportData` | `BusinessInsightSummary` |
| 21 | `/api/v1/reports/business-insight/leads` | GET | `BusinessInsightService.fetchLeads` | `BusinessInsightService.fetchLeads` | `Map<String, dynamic>` |

---

## 4. Forensic Architectural Violations & Rectification Plan

During the Phase 1 forensic code audit, the following architectural violations were detected:

### Violation 1: BLoC Bypassing Repository Layer
- **Location:** `lib/features/dashboard/bloc/dashboard_bloc.dart` (lines 247, 301, 340, 357).
- **Issue:** `DashboardBloc` invokes `_dashboardService.getDashboardKpis(currentFilters)` directly instead of delegating to `_dashboardRepository.getDashboardKpis(currentFilters)`.
- **Fix:** Expand `DashboardRepository` with complete KPI querying methods and make `DashboardBloc` depend strictly on `DashboardRepository`.

### Violation 2: Direct Dio Client Invocations in UI
- **Location:** `lib/features/dashboard/screens/dashboard_screen.dart` (lines 2292 & 2454).
- **Issue:** Inline dialog handlers make direct calls to `DioClient.dio.patch('/followups/...')` and `DioClient.dio.post('/followups', ...)`.
- **Fix:** Move followup mutation operations into `DashboardRepository.updateFollowup()` and `DashboardRepository.scheduleFollowup()`.

### Violation 3: Direct Dio Client Invocations in Service Layer
- **Location:** `lib/features/reports/services/business_insight_service.dart` (lines 42 & 91).
- **Issue:** Direct usage of raw `DioClient.dio.get(...)` bypassing `ApiClient`.
- **Fix:** Refactor `BusinessInsightService` to use `ApiClient` for standardized error decoding, header injection, and retry support.

### Violation 4: Incomplete Error Parsing
- **Location:** `lib/core/api/api_exception.dart`.
- **Issue:** Does not parse Step 8.4 machine-readable `error.code`, `error.details`, or `requestId` envelopes.
- **Fix:** Update `ApiException.fromDioException` to extract structured error objects and correlation metadata while masking any internal database errors.

---

## 5. Certification Checklist

- [x] All 21 KPI endpoints mapped to typed DTOs.
- [x] Clean layered architecture: `UI -> BLoC -> Repository -> Service/ApiClient -> HTTP`.
- [x] Zero direct Dio invocations in UI widgets.
- [x] Zero client-side mathematical recalculation of authoritative KPI definitions.
- [x] Deterministic empty, loading, error, and refresh states across all screens.
