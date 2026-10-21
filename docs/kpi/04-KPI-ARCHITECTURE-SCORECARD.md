# PROPKART — KPI & REPORTING ARCHITECTURE SCORECARD
**Step:** 8.0 — Baseline & Canonical Definition Audit  
**Version:** 1.0.0  
**Date:** October 20, 2026  
**Role:** Lead Data Architect + KPI/Analytics Architect + Systems Auditor  
**Status:** CANONICAL AUDIT BASELINE  

---

## 1. Executive Summary & Composite Architecture Grade

A comprehensive forensic audit of PropKart's KPI and reporting infrastructure was conducted across PostgreSQL schema and queries, Redis caching, Express API handlers, and Flutter UI consumers.

While Steps 1 through 7 established high-performance foundation layers (clean BLoC architectures, virtualized lists, bounded render passes, and 103 passing tests), the **KPI calculation and reporting subsystem currently operates in a state of architectural divergence**:

```
========================================================================================================
                                PROPKART KPI ARCHITECTURE SCORECARD (STEP 8.0)
========================================================================================================
  #  Architectural Dimension           Weight  Score (0-100)  Grade   Status
--------------------------------------------------------------------------------------------------------
  1  Canonicity & Truth Alignment       20%         52        F / FAIL Multi-source definitions across screens
  2  Ledger Integrity (Event Sourcing)  15%         58        F / FAIL Mutable state queried instead of ledgers
  3  Redis Caching & Stampede Guard     15%         40        F / FAIL Zero caching on main KPI endpoints
  4  Query Latency & DB Efficiency      10%         65        D        Multiple unindexed sequential roundtrips
  5  Multi-Tenancy & RBAC Isolation     15%         68        D+       Leaking (organization_id IS NULL)
  6  Frontend Purity (Zero Compute)     10%         55        F / FAIL In-memory recalculation in 3 screens
  7  Timezone & Temporal Bounds          5%         72        C        IST boundary inconsistencies (+05:30)
  8  Test Coverage & Regressions        10%         78        C+       103 tests pass; KPI end-to-end gaps
--------------------------------------------------------------------------------------------------------
  COMPOSITE WEIGHTED SCORE:                        58.9 / 100 [ GRADE: F / CRITICAL REMEDIATION REQUIRED ]
========================================================================================================
```

---

## 2. Dimensional Forensic Evaluations

### 2.1 Canonicity & Truth Alignment — Score: 52 / 100 (FAIL)
- **Defect:** Identical KPI names (e.g. "Site Visits Done", "Deals Won", "Assigned to Sales") return contradictory numerical counts depending on which screen is opened.
- **Root Cause:** Lack of a single canonical database view or single-source query aggregator. Each module was authored independently with its own WHERE clauses and joins.

### 2.2 Ledger Integrity & Event Sourcing — Score: 58 / 100 (FAIL)
- **Defect:** Historical operational metrics query mutable parent snapshots (`requirements.status`, `leads.stage`) rather than immutable event ledgers (`site_visits`, `lead_call_attempts`, `lead_status_history`).
- **Consequence:** 16 completed site visits vanish when client requirements advance to negotiation or won stages.

### 2.3 Redis Caching & Stampede Defense — Score: 40 / 100 (FAIL)
- **Defect:** 
  - `KpiService.getDashboardKpis` (powers 13 headline KPIs): **Zero Redis caching**. Runs 10+ raw database queries on every page visit.
  - `ReportsService.getBusinessInsightSummary`: **Zero Redis caching**.
  - `DashboardService` has an un-namespaced key (`dashboard_summary_v16:${userId}`) which is never invalidated by `users.service.js` due to a key mismatch.
  - No single-flight mutex locking is applied to high-traffic KPI endpoints, creating a severe cache-stampede risk during peak morning logins.

### 2.4 Query Latency & DB Efficiency — Score: 65 / 100 (POOR)
- **Defect:** Multiple sequential database queries executed via `Promise.all` without database-level CTE or unified view aggregation. Under concurrent load, multiple sales users loading dashboards simultaneously generate up to 50 concurrent aggregation queries on PostgreSQL.

### 2.5 Multi-Tenancy & RBAC Isolation — Score: 68 / 100 (MARGINAL)
- **Defect:** In `kpi.service.js`, conditions like `(organization_id IS NULL OR organization_id = $1)` leak unassigned or legacy records across tenant boundaries. In `salesDashboard`, queries lack tenant filtering altogether.

### 2.6 Frontend Purity (Zero Compute) — Score: 55 / 100 (FAIL)
- **Defect:** Violates the Master Rulebook directive: *"Never Calculate KPIs in Frontend Flutter Code"*.
  - `campaign_leads_screen.dart` performs Dart `.length` and `.where()` filtering over in-memory arrays.
  - `telecaller_dashboard_screen.dart` falls back to in-memory `IntegrationService().leads.length`.
  - `sales_dashboard_screen.dart` categorizes follow-ups in Flutter memory.

### 2.7 Timezone & Temporal Consistency — Score: 72 / 100 (ACCEPTABLE)
- **Finding:** `kpi.definitions.js` and `reports.service.js` correctly recognize Indian Standard Time (`+05:30`), but client ISO strings and `metrics.service.js` lack strict uniform enforcement, causing intra-day count shifts.

### 2.8 Test Coverage & Regression Guardrails — Score: 78 / 100 (PASSING)
- **Finding:** Step 7 established 103 passing tests for BLoC and performance rendering. However, there are zero automated cross-screen divergence verification tests ensuring Admin Dashboard equals Reports Business Insights.

---

## 3. Top 10 High-Impact Defect Register

| Priority | Defect Title | Impact Area | Architectural Root Cause |
| :---: | :--- | :--- | :--- |
| 🔴 **P0** | **Site Visit Count Discrepancy (1 vs 17)** | Executive Reporting | Querying mutable `requirements.status` instead of canonical `site_visits` ledger. |
| 🔴 **P0** | **Deals Won vs Converted Clients Mismatch (1 vs 3)** | Sales Reporting | Entity granularity confusion (`leads.stage` vs `requirements.status`). |
| 🔴 **P0** | **Assigned to Sales Total Database Inflation (1,211)** | Operations Intake | Querying `assigned_to IS NOT NULL` instead of qualified `HANDED_TO_SALES`. |
| 🔴 **P0** | **Un-cached KPI Query Avalanche** | Backend / Postgres | Main KPI endpoint (`/api/v1/dashboard/kpis`) completely bypasses Redis. |
| 🟡 **P1** | **Client-Side Array Recalculations** | Flutter UI / Memory | Campaign Leads screen takes `.length` on client memory; truncated by pagination. |
| 🟡 **P1** | **Multi-Tenant Leakage Risk** | Security / Tenancy | Predicate `(organization_id IS NULL OR organization_id = $1)` leaks null rows. |
| 🟡 **P1** | **Redis Invalidation Key Mismatch** | Cache Invalidation | `users.service.js` clears `dashboard_summary_cache` while service writes `dashboard_summary_v16`. |
| 🟡 **P1** | **Intra-Day IST Timezone Shifts** | Temporal Reporting | Server UTC host time splits day at 5:30 AM IST instead of midnight IST. |
| 🟢 **P2** | **Zero Cross-Screen Verification Tests** | Testing / QA | No CI tests validating numerical equivalence between Dashboard and Reports. |
| 🟢 **P2** | **Redundant Query Duplication** | Backend Architecture | 4 different services execute 4 slightly different queries for the same business metric. |

---

## 4. Technical Debt Assessment & Executive Conclusion

The current KPI architecture represents a significant source of operational friction and executive confusion. Management cannot reliably discern whether 1 site visit occurred or 17 occurred, or whether 1 deal was won or 3 deals were won.

Because Step 8.0 is strictly discovery and audit, **no production code changes have been made**. 

Step 8.1 through 8.6 will systematically remediate all 10 defects listed above, establishing a unified, database-authoritative, Redis-accelerated, zero-compute KPI architecture.
