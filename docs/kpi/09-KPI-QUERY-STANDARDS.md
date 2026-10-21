# PROPKART — KPI QUERY & DATABASE ENGINEERING STANDARDS
**Step:** 8.1 — Canonical KPI Database & Query Architecture  
**Version:** 1.0.0  
**Date:** October 20, 2026  
**Role:** Lead Data Architect + KPI/Analytics Architect + Systems Auditor  
**Status:** MANDATORY ENGINEERING STANDARDS  

---

## 1. Golden Rules of KPI Query Engineering

All future backend services, analytics jobs, API endpoints, and reporting controllers MUST adhere strictly to the following 7 Golden Rules. Pull requests violating these rules will fail automated architecture checks.

### Rule 1: Zero Frontend Recalculations
- **Standard:** Flutter widgets MUST NOT compute metric sums, filters, or array lengths from in-memory lists.
- **Violation:** Calling `.where((l) => l.stage == 'WON').length` in Flutter `build()` or BLoC state.
- **Rationale:** Mobile pagination truncates datasets (e.g. at 200 items), causing mobile users to see distorted metrics while consuming excessive device RAM and battery.

### Rule 2: Event Ledgers for Historical Metrics
- **Standard:** Historical, physical, and operational completions MUST query append-only event ledgers.
- **Violation:** Querying mutable lifecycle status strings such as `requirements.status = 'Site Visit Done'`.
- **Rationale:** Lifecycle statuses are overwritten as leads progress to negotiation, closing, or rejection, which erases historical execution data.

### Rule 3: Explicit Entity Granularity (Customer vs. Contract Grain)
- **Standard:** Metrics MUST disambiguate customer grain from contract grain.
- **Specification:**
  - `converted_clients` = Unique human buyers/tenants won (`leads WHERE stage = 'WON'`).
  - `closed_deals` = Unique property lease/sale transactions won (`requirements WHERE status = 'Won'`).

### Rule 4: Operational Qualification vs. Assignment Foreign Keys
- **Standard:** Qualification metrics MUST NOT naively test `assigned_to IS NOT NULL`.
- **Specification:**
  - Raw assignee count: `l.assigned_to IS NOT NULL AND l.deleted_at IS NULL` (296).
  - Qualified sales handover: `(l.stage = 'SALES' OR l.allocation_status = 'HANDED_TO_SALES') AND l.deleted_at IS NULL` (261).

### Rule 5: Strict Multi-Tenant Parametric Isolation
- **Standard:** Every query must enforce tenant isolation via `table.organization_id = $tenantId`.
- **Prohibited:** `(organization_id IS NULL OR organization_id = $1)` or raw string interpolation.
- **Fail-Safe Requirement:** If a non-super-admin user lacks an `organization_id`, the query must evaluate to `1=0` (zero rows returned).

### Rule 6: Half-Open Temporal Intervals `[start, end)`
- **Standard:** All date-bounded queries MUST use half-open intervals:
  ```sql
  timestamp_column >= $start_datetime AND timestamp_column < $end_datetime
  ```
- **Prohibited:** `BETWEEN $start AND $end` or `<= $end` which causes duplicate counting at midnight boundaries.
- **Timezone Invariant:** All calendar day conversions MUST use Indian Standard Time (IST, UTC+5:30).

### Rule 7: Zero Join Multiplication
- **Standard:** When aggregating across 1:N relational tables, queries MUST use `COUNT(DISTINCT id)` or CTE subquery pre-aggregation.
- **Prohibited:** Raw `COUNT(*)` on multi-table joins.

---

## 2. Mandatory SQL Query Template

Every canonical KPI query must follow this standardized architectural pattern:

```javascript
export class CanonicalKpiRepository {
    static async getMetricSummary(user, filters = {}) {
        const { businessType = "Both" } = filters;
        const { from, to } = resolveDateBounds(filters);

        const conditions = ["root.deleted_at IS NULL"];
        const params = [];

        // 1. Strict Tenant Isolation
        const tenant = buildTenantScope(user, "root", params.length + 1);
        conditions.push(tenant.clause);
        params.push(...tenant.params);

        // 2. Role-Based Scoping
        if (user?.role === "Sales") {
            params.push(user.id);
            conditions.push(`root.assigned_to = $${params.length}`);
        }

        // 3. Half-Open Temporal Bound [from, to)
        if (from && to) {
            params.push(from, to);
            conditions.push(`root.event_time >= $${params.length - 1} AND root.event_time < $${params.length}`);
        }

        // 4. Isolated Distinct Aggregation
        const sql = `
            SELECT COUNT(DISTINCT root.id)::int as metric_count
            FROM source_table root
            WHERE ${conditions.join(" AND ")};
        `;

        const res = await timedQuery(sql, params);
        return res.rows[0]?.metric_count || 0;
    }
}
```

---

## 3. SLA & Performance Standards

1. **Latency SLA:** Every canonical KPI query MUST execute in under **10 ms** on production datasets.
2. **Index Usage:** Seq scans on tables with > 500 rows are strictly prohibited. An appropriate composite index must support every canonical WHERE filter.
3. **Execution Budget:** Dashboard aggregation endpoints MUST complete all sub-queries concurrently via `Promise.all` in under **50 ms** total database execution time.
