# PropKart KPI Architecture — Step 8.2: Service Architecture & Orchestration

## 1. Architectural Mandate & Principle of Zero Raw SQL

In Step 8.2 of the Master Engineering Transformation, the PropKart Backend KPI Service was refactored into a pure orchestration and business-logic service layer.

### Core Architectural Invariants:
1. **PostgreSQL as Authoritative Source of Truth:**
   PostgreSQL remains the single source of mathematical truth for all PropKart KPIs.
2. **Canonical Repository Exclusivity:**
   `CanonicalKpiRepository` (`src/modules/dashboard/kpi/canonicalKpi.repository.js`) is the **sole authoritative SQL query layer** for PropKart KPIs. No service, controller, or helper is permitted to execute raw SQL against KPI tables.
3. **Pure Orchestration Service Layer:**
   `KpiService` (`src/modules/dashboard/kpi.service.js`) orchestrates KPI calculations, manages configuration toggles (`admin_kpi_config`), evaluates dynamic custom formulas, and formats response structures.
4. **Unified Reports Integration:**
   `ReportsService` (`src/modules/reports/reports.service.js`) delegates to `CanonicalKpiRepository` for site visits, lead allocations, and follow-ups instead of keeping separate query implementations.
5. **Strict Multi-Tenant Fail-Safe Boundary:**
   If a request lacks an authorized tenant context (`organization_id`), the repository fails safe and returns zero rows rather than leaking cross-tenant data.
6. **Zero API Contract Redesign (Strict Backward Compatibility):**
   Response formats, top-level envelopes, and field aliases (`deal_won`, `leads_allocated`, `all_available_inventory`, etc.) are preserved verbatim to maintain complete client compatibility.

---

## 2. Layered Architecture Diagram

```
+-------------------------------------------------------------------------+
|                           Flutter UI Clients                            |
|             (Admin Dashboard, Reports, Telecaller, Sales)               |
+-------------------------------------------------------------------------+
                                     |
                                     v  (HTTP / JSON)
+-------------------------------------------------------------------------+
|                           Thin API Controllers                          |
|         (kpi.controller.js, reports.controller.js)                      |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                        Business Service Layer                           |
|       - KpiService (Orchestration, Config, Dynamic Custom KPIs)         |
|       - ReportsService (Reporting Aggregations, Performance Views)       |
|       ⚠️ MANDATE: ZERO Raw SQL in KPI Summary Methods                   |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                      Authoritative Query Layer                          |
|                       CanonicalKpiRepository                            |
|  - getSiteVisitsSummary()        - getDashboardGroupsSummary()          |
|  - getWonSummary()               - getLeadAllocationsDetailed()         |
|  - getLeadAllocationsSummary()   - getSalesAssignmentsDetailed()        |
|  - getInventoryBreakdown()       - getNotInterestedDetailed()           |
|  - getTotalLeadsSummary()        - getTelecallersSummary()              |
|  - getFollowupsSummary()         - getSalesUsersSummary()               |
+-------------------------------------------------------------------------+
                                     |
                                     v  (Timed SQL / Connection Pool)
+-------------------------------------------------------------------------+
|                       PostgreSQL Event Ledgers                          |
|  - site_visits (immutable completed ledger)                             |
|  - leads (master CRM leads with temporal allocation columns)            |
|  - requirements (deal lifecycle & contracts)                            |
|  - properties (portfolio status & listing types)                        |
|  - users / roles (tenant-scoped active duty rosters)                    |
+-------------------------------------------------------------------------+
```

---

## 3. Service Layer Refactoring Details

### Methods Refactored in `KpiService`:

| Method Name | Previous State | Step 8.2 Canonical Delegation |
|---|---|---|
| `getDashboardKpis` | 220+ lines of inlined SQL (CNR, Groups A-D) | Delegates CNR to `CanonicalKpiRepository.getLeadAllocationsSummary` and Groups A-D to `CanonicalKpiRepository.getDashboardGroupsSummary`. Zero SQL in method. |
| `getInventoryBreakdown` | Inlined `properties` SQL queries | Delegates to `CanonicalKpiRepository.getInventoryBreakdown`. |
| `getLeadsBreakdown` | Inlined `leads` SQL queries | Delegates to `CanonicalKpiRepository.getTotalLeadsSummary`. |
| `getSiteVisitsSummary` | Inlined query | Delegates to `CanonicalKpiRepository.getSiteVisitsSummary`. |
| `getDealWonSummary` | Inlined query | Delegates to `CanonicalKpiRepository.getWonSummary`. |
| `getLeadsAllocatedBreakdown` | Inlined `leads` + `users` SQL | Delegates to `CanonicalKpiRepository.getLeadAllocationsDetailed`. |
| `getAssignedToSalesBreakdown` | Inlined `leads` + `users` SQL | Delegates to `CanonicalKpiRepository.getSalesAssignmentsDetailed`. |
| `getNotInterestedSummary` | Inlined `leads` + `integration_leads` SQL | Delegates to `CanonicalKpiRepository.getNotInterestedDetailed`. |
| `getTelecallersSummary` | Inlined `users` + `leads` SQL | Delegates to `CanonicalKpiRepository.getTelecallersSummary`. |
| `getSalesUsersSummary` | Inlined `users` + `leads` SQL | Delegates to `CanonicalKpiRepository.getSalesUsersSummary`. |

---

## 4. Multi-Tenant Fail-Safe Security Protocol

Every canonical query path enforces strict multi-tenant boundaries via `buildTenantScope`:
- For Super Admins with tenant filters, the query targets the specified tenant.
- For Tenant users (Admin, Telecaller, Sales), `organization_id = $tenantId` is mandatory.
- If a user lacks an `organization_id` and is not a super-admin, the query evaluates `1=0` or `organization_id IS NULL AND FALSE`, guaranteeing **zero rows returned and zero cross-tenant data leakage**.
- Observable security tests confirm zero records are returned when tenant context is missing.
