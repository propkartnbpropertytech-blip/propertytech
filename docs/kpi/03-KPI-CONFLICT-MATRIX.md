# PROPKART — KPI DIVERGENCE & ARCHITECTURAL CONFLICT MATRIX
**Step:** 8.0 — Baseline & Canonical Definition Audit  
**Version:** 1.0.0  
**Date:** October 20, 2026  
**Role:** Lead Data Architect + KPI/Analytics Architect + Systems Auditor  
**Status:** CANONICAL AUDIT BASELINE  

---

## 1. Executive Summary & Forensic Divergence Table

During Step 8.0 discovery, we conducted automated and manual cross-service forensics comparing live PostgreSQL query results against what each dashboard screen renders.

The audit revealed **6 critical architectural conflicts** where different screens display mutually contradictory numbers for identical metric titles, or where client-side Flutter widgets recalculate raw in-memory arrays.

```
========================================================================================================================
                                 KPI FORENSIC DIVERGENCE AUDIT (LIVE DATABASE MEASUREMENTS)
========================================================================================================================
  Metric Name            Query Source A (Legacy UI)             Query Source B (Admin Dashboard)       Canonical Truth
------------------------------------------------------------------------------------------------------------------------
  Site Visits Done       requirements.status = 'Site Visit Done' site_visits.status = 'COMPLETED'      17 Visits Done
                         Result: 1                              Result: 17                             (Immutable Ledger)
------------------------------------------------------------------------------------------------------------------------
  Deals Won              leads.stage = 'WON'                    requirements.status = 'Won'            1 Converted Customer
                         Result: 1 Customer                     Result: 3 Deals                        3 Property Contracts
------------------------------------------------------------------------------------------------------------------------
  Assigned to Sales      leads.assigned_to IS NOT NULL          stage = 'SALES' OR HANDED_TO_SALES     296 Qualified Handed
                         Result: 1,211 (Default Assigned)       Result: 296 (Qualified to Sales)       to Sales
------------------------------------------------------------------------------------------------------------------------
  Campaign Leads Total   integration_leads (DB exact count)     in-memory array .length                1,203 Ingested Leads
                         Result: 1,203                          Result: Page Limit (e.g. 200)          (DB Query is Truth)
------------------------------------------------------------------------------------------------------------------------
  Active Follow-ups      followups (DB scheduled >= TODAY)     in-memory list categorization          Followups Table
                         Result: Authoritative DB Count         Result: Client memory slice            is Canonical Truth
========================================================================================================================
```

---

## 2. Deep Dive: The 6 Major Architectural Conflicts

### 2.1 Conflict 1: Site Visits Done (The State-Overwrite Trap)
- **Observed Numbers Across Codebase:**
  1. `reports.service.js` (Leads Page KPIs): `status = 'Site Visit Done'` -> **1**
  2. `reports.service.js` (Dedicated Site Visit Query): `site_visits FULL OUTER JOIN requirements` -> **14**
  3. `kpi.service.js` (Admin Dashboard): `site_visits WHERE status = 'COMPLETED'` -> **17**
  4. `requirements` with at least one completed site visit: `EXISTS (SELECT 1 FROM site_visits ...)` -> **13**
- **Forensic Root Cause:**
  When a sales executive finishes a property inspection with a client, the requirement status is initially marked `'Site Visit Done'`. However, when that client moves into negotiations, closes, or is rejected, the status string is overwritten with `'Negotiation'`, `'Won'`, or `'Rejected (Budget Mismatch)'`.
  Querying `requirements.status = 'Site Visit Done'` only counts requirements currently frozen in that stage, causing **16 real physical visits to disappear**!
- **Severity:** 🔴 **P0 (Severe Executive Metric Distortion)**
- **Architectural Resolution:**
  Enforce `public.site_visits` as the sole authoritative source of truth:
  ```sql
  SELECT count(DISTINCT sv.id) 
  FROM site_visits sv 
  WHERE sv.organization_id = $1 
    AND UPPER(sv.status) = 'COMPLETED' 
    AND COALESCE(sv.completed_at, sv.visit_date) BETWEEN $from AND $to;
  ```

---

### 2.2 Conflict 2: Converted Clients vs. Closed Deals
- **Observed Numbers Across Codebase:**
  1. `leads WHERE stage = 'WON'`: **1**
  2. `requirements WHERE status = 'Won'`: **3**
  3. `site_visits WHERE outcome = 'DEAL_WON'`: **0**
  4. `docs/kpis_dump.txt` hybrid definition: `requirements.status ILIKE '%Won%' OR site_visits.outcome = 'DEAL_WON'`
- **Forensic Root Cause:**
  Entity granularity mismatch. Real estate transactions can have a one-to-many relationship: one high-net-worth customer (`leads`, $N=1$) can acquire multiple property assets (`requirements`, $N=3$). 
  Furthermore, the `site_visits.outcome` field is rarely updated to `'DEAL_WON'` by sales agents in the field, making it unreliable as a primary metric.
- **Severity:** 🔴 **P0 (Revenue & Conversion Rate Divergence)**
- **Architectural Resolution:**
  Disambiguate the metrics into two distinct, clearly labeled canonical indicators:
  - **Converted Clients (`kpi_converted_clients`):** `SELECT count(DISTINCT id) FROM leads WHERE organization_id = $1 AND stage = 'WON' AND deleted_at IS NULL`
  - **Closed Deals (`kpi_closed_deals`):** `SELECT count(DISTINCT id) FROM requirements WHERE organization_id = $1 AND status = 'Won' AND deleted_at IS NULL`

---

### 2.3 Conflict 3: Assigned to Sales vs. Raw Lead Assignee
- **Observed Numbers Across Codebase:**
  1. `leads WHERE assigned_to IS NOT NULL`: **1,211**
  2. `leads WHERE stage = 'SALES' OR allocation_status = 'HANDED_TO_SALES'`: **296**
- **Forensic Root Cause:**
  In the ingestion and webhook pipeline, almost all incoming leads have an `assigned_to` user set by default (e.g. system admin or initial owner). 
  Naively counting `leads WHERE assigned_to IS NOT NULL` marks 100% of the entire database as "Assigned to Sales" (1,211 leads)!
  The genuine operational metric—leads that have been triaged by a telecaller, deemed qualified, and actively handed over to field sales—is captured by `allocation_status = 'HANDED_TO_SALES'` or `stage = 'SALES'` (296 leads).
- **Severity:** 🔴 **P0 (Operational Pipeline Inflation)**
- **Architectural Resolution:**
  Deprecate `leads.assigned_to IS NOT NULL` as a qualification predicate. Standardize on:
  ```sql
  WHERE l.deleted_at IS NULL 
    AND (l.allocation_status = 'HANDED_TO_SALES' OR l.stage = 'SALES')
  ```

---

### 2.4 Conflict 4: In-Memory Client-Side Recalculations
- **Observed Flaws in Flutter Codebase:**
  1. `lib/features/campaign/screens/campaign_leads_screen.dart` (Lines 7199–7250):
     Computes `totalLeadsCount`, `propListingTotalCount`, `requirementTotalCount`, `totalAssignedCount`, and `unallocatedCount` by filtering in-memory Dart lists:
     ```dart
     final totalLeadsCount = dateFilteredSourceLeads.length;
     final propListingTotalCount = dateFilteredSourceLeads.where((l) => l.leadType == 'Property Listing').length;
     final unallocatedCount = totalLeadsCount - totalAssignedCount;
     ```
  2. `lib/features/telecaller/screens/telecaller_dashboard_screen.dart`:
     `_openLeadsKpiCount` falls back to querying in-memory `IntegrationService().leads.length`.
  3. `lib/features/sales/screens/sales_dashboard_screen.dart`:
     Categorizes in-memory `allFollowups` array into 'today', 'future', and 'due', taking `.length` on the client.
- **Forensic Consequences:**
  - **Pagination Truncation:** If the API paginates or limits results to 200 items, the KPI count displayed to the user is capped at 200, concealing the true database volume!
  - **Memory & Battery Drain:** Pulling thousands of records just to count them burns mobile memory, triggers garbage collection stutter, and violates the Master KPI Rulebook.
- **Severity:** 🟡 **P1 (Client Scalability & Accuracy Defect)**
- **Architectural Resolution:**
  Zero frontend recalculation. Flutter widgets must bind strictly to precomputed server-side aggregation envelopes.

---

### 2.5 Conflict 5: Timezone Shifts & Date Boundary Mismatches
- **Observed Discrepancies:**
  1. PropKart operates in India (Asia/Kolkata, UTC+5:30).
  2. `DateTime.toIso8601String()` from Flutter sends timestamps without timezone offset (e.g. `"2026-10-20T00:00:00.000"`).
  3. Cloud PostgreSQL interprets bare timestamps as UTC, causing a 5.5-hour day shift. Dials or leads created between 00:00 and 05:30 AM IST were being counted under the previous day!
  4. `metrics.service.js` (Sales Dashboard) uses `new Date(now.getFullYear(), now.getMonth(), now.getDate())` using server host time, while `kpi.service.js` computes an explicit `+05:30` offset.
  5. Inconsistent date column selection: `created_at` vs. `updated_at` vs. `visit_date` vs. `completed_at`.
- **Severity:** 🟡 **P1 (Intra-Day Temporal Reporting Mismatch)**
- **Architectural Resolution:**
  Enforce standardized ISO 8601 strings with explicit `+05:30` offsets across all client requests, and standardize canonical timestamp columns per entity type.

---

### 2.6 Conflict 6: Redis Cache Key & Invalidation Chaos
- **Observed Cache Inconsistencies:**
  1. `DashboardService` writes to: `dashboard_summary_v16:${user.id}` (No tenant prefix, no date hash, no environment tag).
  2. `users.service.js` attempts to invalidate: `dashboard_summary_cache` (Completely different key! Invalidation fails silently).
  3. `KpiService` (`GET /api/v1/dashboard/kpis`): **Zero Redis caching!** Executes up to 10+ un-cached cross-table SQL queries on every app load.
  4. `ReportsService` (`GET /api/v1/reports/business-insight`): **Zero Redis caching!** Executes 8 sequential SQL queries on every screen visit.
- **Severity:** 🟡 **P1 (Database Load Bottleneck & Stale Cache Hazard)**
- **Architectural Resolution:**
  Enforce the Step 3 Redis Key Standard:
  `propkart:{env}:{tenantId}:kpi:{scope}:{dateHash}:v1`
  with single-flight mutex locks and centralized invalidation triggers.
