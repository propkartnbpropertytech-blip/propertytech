# PropKart KPI Service Migration Matrix — Step 8.2

This matrix tracks the migration of all backend KPI methods from scattered legacy inlined SQL queries to `CanonicalKpiRepository` delegations.

| Indicator / Method | File & Origin | Legacy Implementation | Step 8.2 Canonical Target | Status | Verification |
|---|---|---|---|---|---|
| **Available Inventory** (`getInventoryBreakdown`) | `kpi.service.js` | Direct query to `properties` table | `CanonicalKpiRepository.getInventoryBreakdown` | **MIGRATED** | 166 available, 183 total portfolio |
| **Total Leads** (`getLeadsBreakdown`) | `kpi.service.js` | Inlined `leads` query with date filters | `CanonicalKpiRepository.getTotalLeadsSummary` | **MIGRATED** | 1211 total master leads |
| **Active Telecallers** (`getTelecallersSummary`) | `kpi.service.js` | Joined `users` + `leads` in service | `CanonicalKpiRepository.getTelecallersSummary` | **MIGRATED** | Tenant-scoped duty roster |
| **Leads Allocated Breakdown** (`getLeadsAllocatedBreakdown`) | `kpi.service.js` | Direct query for new/old allocations & breakdown | `CanonicalKpiRepository.getLeadAllocationsDetailed` | **MIGRATED** | Total, new, old, listing, requirement, telecallers array |
| **Assigned to Sales Breakdown** (`getAssignedToSalesBreakdown`) | `kpi.service.js` | Inlined `leads` + `users` query | `CanonicalKpiRepository.getSalesAssignmentsDetailed` | **MIGRATED** | 296 assigned, 261 qualified handover, sales breakdown |
| **Site Visits Summary** (`getSiteVisitsSummary`) | `kpi.service.js` | Legacy snapshot query | `CanonicalKpiRepository.getSiteVisitsSummary` | **MIGRATED** | 17 completed site visits ledger |
| **Deal Won Summary** (`getDealWonSummary`) | `kpi.service.js` | Ambiguous contract/client counts | `CanonicalKpiRepository.getWonSummary` | **MIGRATED** | 2 active deals, 3 lifetime, 1 converted client |
| **Sales Users Summary** (`getSalesUsersSummary`) | `kpi.service.js` | Inlined `users` + `leads` query | `CanonicalKpiRepository.getSalesUsersSummary` | **MIGRATED** | Tenant-scoped sales user roster |
| **Not Interested Summary** (`getNotInterestedSummary`) | `kpi.service.js` | Multi-source string matching query | `CanonicalKpiRepository.getNotInterestedDetailed` | **MIGRATED** | Meta, Housing, Webhook, Manual counts |
| **Dashboard Group A: Inventory Sourcing** | `kpi.service.js` (`getDashboardKpis`) | 45-line SQL query executed on every dashboard load | `CanonicalKpiRepository.getDashboardGroupsSummary` | **MIGRATED** | Consolidated into single canonical query |
| **Dashboard Group B: Manual Leads** | `kpi.service.js` (`getDashboardKpis`) | 35-line SQL query executed on every dashboard load | `CanonicalKpiRepository.getDashboardGroupsSummary` | **MIGRATED** | Consolidated into single canonical query |
| **Dashboard Group C: Sales Pipeline** | `kpi.service.js` (`getDashboardKpis`) | 45-line SQL query executed on every dashboard load | `CanonicalKpiRepository.getDashboardGroupsSummary` | **MIGRATED** | Consolidated into single canonical query |
| **Dashboard Group D: Qualified Leads** | `kpi.service.js` (`getDashboardKpis`) | 40-line SQL query executed on every dashboard load | `CanonicalKpiRepository.getDashboardGroupsSummary` | **MIGRATED** | Consolidated into single canonical query |
| **Dashboard CNR** | `kpi.service.js` (`getDashboardKpis`) | Inline `leads` disposition query | `CanonicalKpiRepository.getLeadAllocationsSummary` | **MIGRATED** | Consumed via `cnr_count` |
| **Reports Site Visits** (`getOverallKpis`) | `reports.service.js` | Inlined `site_visits` count | `CanonicalKpiRepository.getSiteVisitsSummary` | **MIGRATED** | Unified with canonical event ledger |
| **Reports Followups** (`getOverallKpis`) | `reports.service.js` | Inlined `followups` count | `CanonicalKpiRepository.getFollowupsSummary` | **MIGRATED** | Unified with canonical followups query |
| **Reports Business Insight Site Visit** (`getBusinessInsightSummary`) | `reports.service.js` | Fallback to status strings | `CanonicalKpiRepository.getSiteVisitsSummary` | **MIGRATED** | Authoritative 17 completed visits |
| **Reports Business Insight Sales Handover** (`getBusinessInsightSummary`) | `reports.service.js` | Direct string filter on `allocation_status` | `CanonicalKpiRepository.getLeadAllocationsSummary` | **MIGRATED** | 296 assigned, 261 qualified handovers |

---

## Migration Summary
- **Total KPI summary methods in KpiService:** 10
- **Total migrated to CanonicalKpiRepository:** 10 (100%)
- **Raw SQL queries remaining in KpiService summary methods:** 0
- **Backward-compatibility breakages:** 0
