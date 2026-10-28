# 05 — KPI AGENT CONTEXT & CANONICAL REPOSITORY SPECIFICATION

## 1. Constitutional Law of KPI Aggregations
In PropKart, **KPI counts and dashboard analytics must NEVER be computed on the client side or via ad-hoc SQL queries scattered across controllers.**

```text
PostgreSQL Canonical Queries
             │
             ▼
[ CanonicalKpiRepository ]  <── ONLY authoritative SQL definitions allowed
             │
             ▼
[ KpiService ]              <── Business delegation & parameter resolution
             │
             ▼
[ KpiCacheService (Redis) ] <── Fail-open caching (300s TTL, single-flight mutex)
             │
             ▼
[ Express API Gateway ]     <── Backward-compatible response JSON
             │
             ▼
[ Flutter Presentation UI ] <── Pure rendering (zero arithmetic overrides)
```

## 2. Authoritative Repository: `CanonicalKpiRepository`
Located in `C:\NB\PropKart-Backend\src\modules\dashboard\kpi\canonicalKpi.repository.js`:
- All summary metrics (`getSiteVisitsSummary`, `getWonSummary`, `getLeadAllocationsSummary`, `getInventoryBreakdown`, `getTotalLeadsSummary`, `getDashboardKpis`) are authored and audited in this single class.
- Uses half-open temporal intervals: `[start_date, end_date)` to prevent boundary overlaps.
- Dates are normalized to Indian Standard Time (IST / UTC+05:30) for calendar consistency.

## 3. Canonical Metric Definitions Reference

| KPI Metric Key | Canonical Definition | Authoritative Source Table & Condition |
| :--- | :--- | :--- |
| **`site_visits_done`** | Total completed site visits conducted | `public.site_visits WHERE status = 'Completed' AND deleted_at IS NULL` |
| **`deal_won` / `closed_deals`**| Active deals won by sales agents | `public.requirements WHERE stage = 'WON' AND deleted_at IS NULL` |
| **`converted_clients`** | Unique customer leads converted to won | `public.leads WHERE stage = 'WON' AND deleted_at IS NULL` |
| **`total_allocated`** | Total leads assigned to active telecallers | `public.leads WHERE assigned_telecaller_id IS NOT NULL AND deleted_at IS NULL` |
| **`assigned_to_sales`** | Active leads currently assigned to a sales agent | `public.leads WHERE assigned_to IS NOT NULL AND deleted_at IS NULL` |
| **`available_inventory`**| Properties available for tenant/buyer placement | `public.properties WHERE status = 'Available' AND deleted_at IS NULL` |
| **`total_leads`** | Master non-deleted lead count | `public.leads WHERE deleted_at IS NULL` |

## 4. Redis Caching & Invalidation Rules
- Cache entries are namespaced: `propkart:kpi:{tenantId}:{scope}:{hash}`.
- All cache lookups are fail-open: if Redis throws or times out, `KpiService` transparently queries PostgreSQL.
- Mutations to leads, properties, or site visits trigger tenant-scoped invalidation (`kpiCacheService.invalidateTenantScope(tenantId)`).
