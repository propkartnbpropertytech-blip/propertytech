# PropKart — Dynamic KPI Builder & Drilldown Composer Technical Documentation

## 1. System Architecture Overview
The **Dynamic KPI Registry & Drilldown Composer** provides a centralized, no-code, database-authoritative engine for creating, visualizing, analyzing, and drilling into metrics across PropKart without requiring backend code redeployments or frontend Flutter rebuilds.

```
┌────────────────────────────────────────────────────────┐
│            Admin Panel (No-Code Builder UX)            │
│  - Settings -> KPI Config (Registry & Visual Composer) │
└──────────────────────────┬─────────────────────────────┘
                           │ HTTPS REST (Parameterized)
                           ▼
┌────────────────────────────────────────────────────────┐
│               Backend Evaluation Engine                │
│  - kpi.service.js / kpi.controller.js                  │
│  - Circular Dependency Graph Validator (BFS)           │
│  - Dual-Layer RBAC & Multi-Tenant Scoping              │
│  - Safe Parameterized Query Aggregator                 │
└──────────────────────────┬─────────────────────────────┘
                           │ SQL with ON DELETE SET NULL
                           ▼
┌────────────────────────────────────────────────────────┐
│             PostgreSQL Database Storage                │
│  - admin_kpi_config (Definitions, Layouts, Roles)      │
│  - kpi_audit_logs (Immutable CRUD History & Diffs)     │
│  - Canonical Tables: properties, leads, site_visits... │
└──────────────────────────┬─────────────────────────────┘
                           │ Dynamic Hydration
                           ▼
┌────────────────────────────────────────────────────────┐
│             Dynamic Dashboard & Drilldown UI           │
│  - DashboardScreen (Generic Dynamic Card Renderers)    │
│  - GenericKpiDrilldownDialog (Multi-Level Recursive UI)│
│  - Breadcrumb Traversal & Strict Filter Inheritance    │
└────────────────────────────────────────────────────────┘
```

---

## 2. End-to-End Data Flow

1. **KPI Definition & Composition:**
   - Admin configures metric name, business purpose, trusted data source, aggregation type, filters, target dashboard page, and role permissions.
   - For interactive KPIs, visual Drilldown Composer configures nested components (`kpi_group`, `status_breakdown`, `chart`, `table`).
   - Saved as JSONB in `admin_kpi_config`.
2. **Dashboard Hydration:**
   - Client requests `GET /api/v1/dashboard/kpis`.
   - `KpiService.getDashboardKpis` loads all active canonical and dynamic KPIs enabled for `'Admin Dashboard'` scoped to the caller's `organization_id`.
   - Dynamic counts are evaluated on-the-fly via `calculateDynamicKpi` and returned in `results.counts[kpi_key]`.
3. **Generic Rendering:**
   - Flutter `DashboardScreen` iterates over `kpis.config`, rendering custom KPIs dynamically using `_buildStatCard` with clickable actions bound to `GenericKpiDrilldownDialog.show(...)`.
4. **Interactive Multi-Level Drilldowns:**
   - When clicked, `GenericKpiDrilldownDialog` calls `GET /api/v1/dashboard/drilldown/:kpiKey`.
   - Backend evaluates each component against caller's organization and inherited filters (`dateFilter`, `businessType`, `leadType`, `page`, `limit`).
   - Clicking sub-metrics or status chips recursively spawns nested drilldown dialogs with preserved breadcrumb trails and filter context.

---

## 3. KPI Lifecycle & States

| Lifecycle State | Dashboard Visibility | Configurable | Audit History | Description |
|-----------------|----------------------|--------------|---------------|-------------|
| `active` | Visible (if `is_enabled: true`) | Yes | Maintained | Metric actively calculated and displayed. |
| `draft` / `inactive` | Hidden from dashboard | Yes | Maintained | Metric retained in registry for maintenance. |
| `DELETED` | Removed from registry | No | Preserved (`kpi_id: NULL`) | Custom KPI deleted. Audit record preserved with full previous state JSON via `ON DELETE SET NULL`. |

---

## 4. Reusable Component Registry

| Component Type | Supported Layouts | Primary Options | Data Resolver Method | Security / Context |
|----------------|-------------------|-----------------|----------------------|--------------------|
| `kpi_group` | Horizontal wrap card row | `items`: `label`, `kpi_key`, `status`, `aggregation` | Evaluates sub-KPI or counts by status | Checks child KPI permissions |
| `chart` | Full-width container | `chart_type`: `donut`, `bar`, `line`; `dimension`: `status`, `stage`, `source` | SQL GROUP BY dimension | Parameterized org & date |
| `status_breakdown` | Interactive filter chips | `dimension`: status / stage / source | Frequency distribution | Clicking toggles active status filter |
| `table` | Paginated data grid | `columns`: string list; `data_source`: table name; `limit`: 20 | Filtered entity records with LIMIT/OFFSET | Preserves soft-delete & tenant boundaries |

---

## 5. Security & RBAC Model

1. **Dual-Layer Role Visibility:**
   - **Frontend:** Widgets conditionally render metrics based on user role (`adminVisible`, `telecallerVisible`, `salesVisible`).
   - **Backend Authoritative Enforcement:** Direct API endpoints (`GET /dashboard/kpi-registry/:id`, `GET /dashboard/drilldown/:kpiKey`) verify the user's database role. If an unauthorized role attempts access, the backend terminates execution immediately with **HTTP 403 Forbidden**.
2. **Registry Mutation Protection:**
   - `POST /api/v1/dashboard/kpi-registry`
   - `PUT /api/v1/dashboard/kpi-registry/:id`
   - `PATCH /api/v1/dashboard/kpi-registry/:id/status`
   - `DELETE /api/v1/dashboard/kpi-registry/:id`
   - `GET /api/v1/dashboard/kpi-audit-logs`
   - All mutation and audit log routes require `lookup.manage` permission (exclusively granted to `Admin` and `Super Admin`). Telecallers and Sales Users receive HTTP 403 Forbidden.
3. **Multi-Tenant Isolation:**
   - Every dynamic query enforces `WHERE (organization_id IS NULL OR organization_id = $orgId)`.
   - Cross-organization access is strictly prevented. Tenant A users cannot access, view, or modify Tenant B KPIs.
4. **SQL Injection Resilience:**
   - Zero string interpolation.
   - Table names and column dimensions strictly validated against internal allowlists.
   - Operators allowlisted (`=`, `!=`, `>`, `<`, `>=`, `<=`, `ILIKE`).
   - 100% parameterized arguments (`$1`, `$2`, etc.).

---

## 6. Circular Dependency Detection

The system prevents infinite recursion loops in nested drilldowns via a database-authoritative Breadth-First Search (BFS) cycle detector before saving:
- **Direct Self-Reference ($A \to A$):** Prohibited.
- **Mutual Cycle ($A \to B \to A$):** Prohibited.
- **Multi-Hop Cycle ($A \to B \to C \to A$):** Prohibited.
- **Acyclic Hierarchy ($A \to B \to C$):** Allowed.
- **Diamond / Reuse ($A \to B \to X$ and $A \to C \to X$):** Allowed.

---

## 7. How to Add a New Trusted Data Source

To add a new entity table (e.g. `commissions`):
1. In `src/modules/dashboard/kpi.service.js`:
   - Add the table name to `tableMap` in `calculateDynamicKpi`.
   - Add the table to `allowedSources` in `createKpiRegistryItem`.
   - Add to `safeTables` in `getKpiDrilldownData`.
2. In `kpi.controller.js`:
   - Add entity metadata to `getKpiBuilderMetadata` with allowed columns and date fields.
3. Re-run `test/kpi.builder.production.audit.test.js`.

---

## 8. How to Troubleshoot KPI Count Mismatches

If an API count differs from raw database queries:
1. **Check Timezone Boundaries:** PropKart standardizes on Asia/Kolkata (UTC+5:30). Verify `parseDateFilter` is called.
2. **Check Soft Deletion:** Tables with soft delete (`leads`, `properties`, `requirements`, `users`) require `deleted_at IS NULL`.
3. **Check Tenant Scope:** Verify whether the KPI has `organization_id` set or `organization_id IS NULL` (global template).
