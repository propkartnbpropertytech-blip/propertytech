# PROPKART KPI STATE MANAGEMENT ARCHITECTURE
## Step 8.5 BLoC State Lifecycles, Refresh Semantics & Empty States

**Document Version:** 1.0.0  
**Status:** Certified Architecture  
**Scope:** DashboardBloc & ReportsBloc State Machines, Stream Synchronization & Event Flow  

---

## 1. State Machine Hierarchy

The KPI presentation state machine is managed by `DashboardBloc` adhering to standard `flutter_bloc` architecture:

```text
               ┌─────────────────────┐
               │  DashboardInitial   │
               └──────────┬──────────┘
                          │
                   LoadDashboard
                          │
                          ▼
               ┌─────────────────────┐
         ┌────►│  DashboardLoading   │
         │     └──────────┬──────────┘
         │                │
         │         Data & KPIs Loaded
         │                │
         │                ▼
         │     ┌─────────────────────────────────────────────────────────┐
         │     │                  DashboardLoadedState                   │
         │     │  - data: DashboardData                                  │
         │     │  - kpis: DashboardKpisResponse?                         │
         │     │  - kpiFilters: KpiFilterParams                          │
         │     │  - isKpiLoading: bool                                   │
         │     └──────┬──────────────────────┬───────────────────────────┘
         │            │                      │
   Network Failure    │                      │  Filter Changed
   on first load      │                      ▼  (LoadDashboardKpis)
         │            │           Emit with isKpiLoading: true
         │            │           Fetch new authoritative KPIs
         │            │           Emit with isKpiLoading: false
         │            ▼                      │
         │     RefreshDashboard              │
         │            │                      │
         │            ▼                      │
         │     ┌─────────────────────┐       │
         │     │ DashboardRefreshing │───────┘
         │     └─────────────────────┘
         │                │
         │          Fetch Failed
         │                │
         │                ▼
         └─────┌─────────────────────┐
               │   DashboardError    │
               └─────────────────────┘
```

---

## 2. Empty State Discipline

A core architectural invariant:
- **Zero is a valid authoritative KPI count.**
- If `counts.totalLeads == 0` or `counts.availableInventory == 0`, Flutter displays `0` and a clear, user-friendly empty state widget (e.g. "No active leads for this filter period").
- Under NO circumstances does the UI treat zero results as a network error, missing data, or an unhandled exception.

---

## 3. Pull-to-Refresh & Synchronization

1. **Pull-to-Refresh:**
   Dispatches `RefreshDashboard()`, which passes `forceRefresh: true` to bypass local Isar cache and request fresh results from Redis/PostgreSQL.
2. **Local Mutation Debounce:**
   When local mutations occur in the requirements or property modules, `RepositoryCoordinator` emits change events. `DashboardBloc` buffers these with a 500ms debounce timer before dispatching `RefreshDashboard()`, preventing rapid successive network queries during bulk actions.
