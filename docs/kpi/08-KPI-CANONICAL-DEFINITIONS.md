# PROPKART — CANONICAL KPI DEFINITIONS CATALOG
**Step:** 8.1 — Canonical KPI Database & Query Architecture  
**Version:** 1.0.0  
**Date:** October 20, 2026  
**Role:** Lead Data Architect + KPI/Analytics Architect + Systems Auditor  
**Status:** CANONICAL PRODUCTION SPECIFICATION  

---

## 1. Executive Summary

This catalog establishes the single authoritative mathematical definition, table origin, and SQL predicate for every core Key Performance Indicator (KPI) across the PropKart platform.

Every consumer (Admin Dashboard, Telecaller Dashboard, Sales Dashboard, Business Insights, Campaign Reports, and Redis caching layers) MUST conform strictly to these definitions.

---

## 2. Core KPI Canonical Definitions Table

| KPI ID | Canonical Metric Name | Primary Table & Column | Entity Grain | Authoritative SQL Predicate | Live Canonical Value (Oct 20, 2026) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **KPI-01** | **Site Visits Done** | `site_visits.status` | Event Ledger | `UPPER(sv.status) = 'COMPLETED'` | **17** |
| **KPI-02** | **Rejected After Visit** | `site_visits.outcome` | Event Ledger | `UPPER(sv.outcome) = 'REJECTED_AFTER_VISIT'` | **7** |
| **KPI-03** | **Site Visits Scheduled** | `site_visits.visit_date` | Forward Ledger | `sv.status IN ('Pending', 'SCHEDULED') AND sv.visit_date >= CURRENT_DATE` | **1** |
| **KPI-04** | **Converted Clients** | `leads.stage` | Customer Master | `l.stage = 'WON' AND l.deleted_at IS NULL` | **1** |
| **KPI-05** | **Closed Deals (Active)** | `requirements.status` | Property Contract | `r.status = 'Won' AND r.deleted_at IS NULL` | **2** |
| **KPI-05b**| **Closed Deals (Lifetime)**| `requirements.status` | Property Contract | `r.status = 'Won'` | **3** |
| **KPI-06** | **Assigned to Sales** | `leads.assigned_to` | Lead Assignment | `l.assigned_to IS NOT NULL AND l.deleted_at IS NULL` | **296** |
| **KPI-07** | **Qualified Sales Handover**| `leads.stage / status`| Qualification Grain | `(l.stage = 'SALES' OR l.allocation_status = 'HANDED_TO_SALES') AND l.deleted_at IS NULL` | **261** |
| **KPI-08** | **Total Allocated (Tele)** | `leads.assigned_telecaller_id` | Telecaller Assignment | `l.assigned_telecaller_id IS NOT NULL AND l.deleted_at IS NULL` | **1,065** |
| **KPI-09** | **Available Inventory** | `properties.status` | Available Stock | `p.status = 'Available' AND p.deleted_at IS NULL` | **166** |
| **KPI-10** | **Total Portfolio** | `properties.id` | Total Portfolio | `p.deleted_at IS NULL` | **183** |
| **KPI-11** | **Rental Inventory** | `properties.listing_type_id` | Rental Stock | `lt.name = 'Rent' AND p.deleted_at IS NULL` | **160** |
| **KPI-12** | **Resale Inventory** | `properties.listing_type_id` | Resale Stock | `lt.name = 'Resale' AND p.deleted_at IS NULL` | **23** |
| **KPI-13** | **Total Active Leads** | `leads.id` | Lead Master | `l.deleted_at IS NULL` | **1,211** |
| **KPI-14** | **Meta Ingested Leads** | `leads.source` | Source Grain | `l.source = 'Meta' AND l.deleted_at IS NULL` | **824** |
| **KPI-15** | **Housing Ingested Leads** | `leads.source` | Source Grain | `l.source = 'Housing' AND l.deleted_at IS NULL` | **213** |
| **KPI-16** | **Webhook Ingested Leads** | `leads.source` | Source Grain | `l.source = 'Webhook' AND l.deleted_at IS NULL` | **112** |
| **KPI-17** | **Manual Ingested Leads** | `leads.source` | Source Grain | `l.source = 'Manual' AND l.deleted_at IS NULL` | **60** |
| **KPI-18** | **Pending Follow-ups** | `followups.status` | Action Queue | `f.status = 'Pending' AND f.deleted_at IS NULL` | **200** |
| **KPI-19** | **Follow-ups Due** | `followups.scheduled_date` | Action Queue | `f.status = 'Pending' AND f.scheduled_date < CURRENT_DATE` | **195** |
| **KPI-20** | **Follow-ups Today** | `followups.scheduled_date` | Action Queue | `f.status = 'Pending' AND f.scheduled_date::date = CURRENT_DATE` | **2** |

---

## 3. Disambiguation Standards & Reconciliation Rules

### 3.1 P0 Reconciliation: Site Visits Completed (17 vs. 1 vs. 14)
- **The Defect:** Legacy reports checked `requirements.status = 'Site Visit Done'`, yielding **1**. When negotiations proceed or fail, status is overwritten to `'Negotiation'` or `'Rejected'`, erasing physical visits.
- **The Rule:** Site Visits Completed MUST ALWAYS query `public.site_visits` where `UPPER(status) = 'COMPLETED'`.
- **Authoritative Value:** **17 completed site visits**.

### 3.2 P0 Reconciliation: Converted Clients vs. Closed Deals (1 vs. 2 vs. 3)
- **The Defect:** Dashboards interchanged customer count with deal count.
- **The Rule:** Disambiguated into two distinct indicators:
  1. `kpi_converted_clients`: Number of unique human clients won (`COUNT(DISTINCT l.id) FROM leads WHERE stage = 'WON' AND deleted_at IS NULL`) = **1** (Manisha Upadhyay).
  2. `kpi_closed_deals`: Number of property contracts won (`COUNT(DISTINCT r.id) FROM requirements WHERE status = 'Won' AND deleted_at IS NULL`) = **2 active** (Sumit, Manisha Upadhyay). Total lifetime deals closed (including deduplicated historical leads) = **3** (Aruna Pandya, Sumit, Manisha Upadhyay).

### 3.3 P0 Reconciliation: Sales Assignment vs. Qualified Handover (296 vs. 1,211 vs. 261)
- **The Defect:** Naive queries without soft-delete or checking default assignees yielded 1,211 (entire active lead base) or 426 (including soft-deleted).
- **The Rule:** Disambiguated into two distinct operational metrics:
  1. `assigned_to_sales`: Active leads assigned to a sales agent (`l.assigned_to IS NOT NULL AND l.deleted_at IS NULL`) = **296**.
  2. `qualified_handed_to_sales`: Leads verified, qualified by telecallers, and handed over to field sales (`(l.stage = 'SALES' OR l.allocation_status = 'HANDED_TO_SALES') AND l.deleted_at IS NULL`) = **261**.

---

## 4. Multi-Tenant Scoping Standard

All canonical queries apply the standardized tenant clause:
```sql
-- For Super Admin across all tenants:
WHERE 1=1

-- For Organization User:
WHERE table_alias.organization_id = $tenantId

-- For Non-Super-Admin missing organization_id (Fail-Safe):
WHERE 1=0
```
The legacy leak pattern `(organization_id IS NULL OR organization_id = $1)` is prohibited.
