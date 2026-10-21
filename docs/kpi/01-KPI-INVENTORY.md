# PROPKART — COMPLETE KPI & REPORTING INVENTORY
**Step:** 8.0 — Baseline & Canonical Definition Audit  
**Version:** 1.0.0  
**Date:** October 20, 2026  
**Role:** Lead Data Architect + KPI/Analytics Architect + Systems Auditor  
**Status:** CANONICAL AUDIT BASELINE  

---

## 1. Executive Summary

This inventory catalogs all **64 distinct Key Performance Indicator (KPI) metrics** identified across the PropKart CRM platform. 

The indicators are distributed across **6 primary operational and analytical modules** servicing all three core organizational user personas:
1. **Executive / Management (Admin & Super Admin)**: High-frequency operational throughput, revenue velocity, inventory availability, team capacity, and marketing channel ROI.
2. **Operations Desk (Telecaller)**: Ingested lead triage, callable queues, connection rates, callbacks, CNR pools, and sales qualification transfers.
3. **Field Closers (Sales Executives / RMs)**: Qualified requirements, property matching, calendar walkthroughs, site visit completions, negotiations, and closed deals.

```
========================================================================================================
                                PROPKART KPI INVENTORY TOPOLOGY (64 TOTAL METRICS)
========================================================================================================
  #  Module Name                     Screen / Location               Count  Primary Source Table
--------------------------------------------------------------------------------------------------------
  1  Main Admin Dashboard            dashboard_screen.dart             8-13 properties, leads, site_visits
  2  Campaign Leads Screen           campaign_leads_screen.dart          9  integration_leads, callbacks
  3  Reports & Business Insights     overall_business_insight_screen    19  leads, requirements, site_visits
  4  Telecaller Workspace Dashboard  telecaller_dashboard_screen.dart   10  integration_leads, lead_call_attempts
  5  Sales Dashboard                 sales_dashboard_screen.dart         8  requirements, site_visits, followups
  6  Telecaller Performance Report   telecaller_report_screen.dart      10  leads, lead_call_attempts, users
  7  Sourcing & Direct Breakdown     reports_screen.dart (tabs)          5  properties, leads, users
========================================================================================================
```

---

## 2. Module 1: Main Admin Dashboard KPIs (8 Core + 5 Extended)

- **Flutter Surface:** `lib/features/dashboard/screens/dashboard_screen.dart`
- **Widget Component:** `StatCard` (`lib/features/dashboard/widgets/stat_card.dart`)
- **Backend Service:** `PropKart-Backend/src/modules/dashboard/kpi.service.js` (`KpiService.getDashboardKpis`)
- **API Endpoint:** `GET /api/v1/dashboard/kpis`
- **Default Date Window:** Weekly (rolling 7 days with IST UTC+5:30 boundaries)
- **Default Business Mode:** Rent (toggleable to Re-Sale / Both)

| # | KPI Identifier | Display Name | Underlying Table(s) & Column(s) | Calculation & Aggregation Logic | Business Purpose |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1** | `available_inventory` | Available Inventory | `properties p JOIN property_status ps JOIN listing_types lt` | `COUNT(*) WHERE ps.name = 'Available' AND p.deleted_at IS NULL AND lt.name ILIKE '%Rent%'` | Quantifies immediately marketable property units ready for tenant placement. |
| **2** | `total_leads` | Total Leads | `leads l` | `COUNT(*) WHERE l.deleted_at IS NULL AND l.created_at BETWEEN $from AND $to` | Evaluates total top-of-funnel customer intake volume across all acquisition channels. |
| **3** | `telecallers` | Telecallers | `users u JOIN roles r` | `COUNT(*) WHERE r.name = 'Telecaller' AND u.is_active = true AND u.deleted_at IS NULL` | Tracks operational intake workforce actively handling incoming lead queues. |
| **4** | `leads_allocated` | New Leads Allocated | `leads l` | `COUNT(*) WHERE l.assigned_telecaller_id IS NOT NULL AND l.deleted_at IS NULL AND (l.created_at >= $from OR l.is_old = 0)` | Tracks fresh, first-time lead assignments distributed to telecallers in period. |
| **5** | `old_leads_allocated` | Old Leads Allocated | `leads l` | `COUNT(*) WHERE l.assigned_telecaller_id IS NOT NULL AND l.deleted_at IS NULL AND (l.created_at < $from OR l.is_old = 1)` | Monitors backlog re-engagement and recycled older lead distributions. |
| **6** | `cnr` | CNR (No Response) | `leads l` | `COUNT(*) WHERE l.deleted_at IS NULL AND (l.call_disposition = 'CNR' OR l.allocation_status = 'CNR')` | Quantifies uncontacted leads where dials went unanswered; drives redial cycles. |
| **7** | `assigned_to_sales` | Assigned to Sales | `leads l` | `COUNT(*) WHERE l.deleted_at IS NULL AND (l.assigned_to IS NOT NULL OR l.stage = 'SALES' OR l.allocation_status = 'HANDED_TO_SALES')` | Measures telecaller qualification yield transferred to field sales agents. |
| **8** | `site_visits_done` | Site Visits Done | `site_visits sv` | `COUNT(DISTINCT sv.id) WHERE UPPER(sv.status) = 'COMPLETED'` | Authoritative count of physical property walkthroughs completed with clients. |
| **9** | `deal_won` | Deal Won | `requirements r JOIN listing_types lt` | `COUNT(*) WHERE r.status = 'Won' AND r.deleted_at IS NULL` | Tracks closed commercial property transactions and revenue conversions. |
| **10** | `sales_users` | Sales Users | `users u JOIN roles r` | `COUNT(*) WHERE r.name IN ('Sales', 'Employee') AND u.is_active = true AND u.deleted_at IS NULL` | Tracks field relationship managers and closers on duty. |
| **11** | `rejected_after_site_visit` | Rejected After Visit | `site_visits sv LEFT JOIN requirements r` | `COUNT(DISTINCT sv.id) WHERE UPPER(sv.outcome) = 'REJECTED_AFTER_VISIT' OR r.status ILIKE 'Rejected%'` | Identifies client drop-off post walkthrough due to price, size, or locality mismatch. |
| **12** | `not_interested` | Not Interested | `leads l` | `COUNT(*) WHERE l.deleted_at IS NULL AND (l.call_disposition = 'NOT_INTERESTED' OR l.stage = 'LOST')` | Monitors early top-of-funnel lead disqualification and ad targeting fallout. |
| **13** | `lifecycle_cnr` | Lifecycle Active CNR | `leads l` | `COUNT(*) WHERE (call_disposition = 'CNR' OR allocation_status = 'CNR') AND stage NOT IN ('LOST','ARCHIVED')` | Tracks active callable CNR backlog, conserving 100% of pipeline inventory. |

---

## 3. Module 2: Campaign Leads Screen KPIs (9 KPIs)

- **Flutter Surface:** `lib/features/campaign/screens/campaign_leads_screen.dart`
- **Widget Component:** Header summary badges & status tab pills
- **Backend Service:** `PropKart-Backend/src/modules/integrations/integrations.service.js` (`IntegrationsService.getLeads`)
- **API Endpoint:** `GET /api/v1/integrations/campaign-leads`
- **Current Execution Flaw:** Fetches raw lead batches and re-computes counts in memory using Dart list filters.

| # | KPI Identifier | Display Name | Source Column | Current Calculation Logic | Target Purpose |
| :- | :--- | :--- | :--- | :--- | :--- |
| **14** | `campaign_total_leads` | Total Leads (Source) | `integration_leads` | `dateFilteredSourceLeads.length` (In-memory) | Total leads ingested from Meta Ads or Housing.com in selected date window. |
| **15** | `campaign_prop_listing` | Property Listing Leads | `integration_leads.lead_type` | `leads.where((l) => l.leadType == 'Property Listing').length` | Ingested landlord / owner supply inquiries. |
| **16** | `campaign_requirement` | Requirement Leads | `integration_leads.lead_type` | `leads.where((l) => l.leadType == 'Requirement').length` | Ingested prospective tenant / buyer demand inquiries. |
| **17** | `campaign_assigned` | Leads Allotted to Telecallers | `integration_leads.assigned_telecaller_id` | `leads.where((l) => isLeadAssignedToTelecaller(l)).length` | Volume of campaign leads pushed to telecalling workforce. |
| **18** | `campaign_unallocated` | Unallocated Leads | Derived | `totalLeadsCount - totalAssignedCount` | Backlog in triage queue awaiting agent availability. |
| **19** | `campaign_not_interested` | Not Interested (Badge) | `integration_leads.campaign_status` | `leads.where((l) => isNotInterested(l.campaignStatus)).length` | Ad fallout and disqualified leads. |
| **20** | `campaign_active_tab` | Active Leads (Tab) | `integration_leads` | Filtered list excluding Archived, Not Interested, Closed | Callable working pipeline for telecalling team. |
| **21** | `campaign_followups_tab` | Follow-ups (Tab) | `campaign_lead_callbacks` | Pending callback records count | Scheduled callback reminders. |
| **22** | `campaign_not_interested_tab`| Not Interested (Tab) | `integration_leads.campaign_status` | Filtered list where status ILIKE '%not interested%' | Historical log of disqualified leads. |

---

## 4. Module 3: Reports & Business Insights KPIs (19 KPIs)

- **Flutter Surface:** `lib/features/reports/screens/leads/overall_business_insight_screen.dart`
- **Widget Component:** `BusinessInsightsSection`, `KpiCardWidget`, `OperationalKpiBreakdownSection`
- **Backend Service:** `PropKart-Backend/src/modules/reports/reports.service.js` (`ReportsService.getBusinessInsightSummary`)
- **API Endpoint:** `GET /api/v1/reports/business-insight`

### Section 3.1: Campaign Performance & Lead Intake (10 KPIs)

| # | KPI Identifier | Display Name | Database Source | Filter Predicate |
| :- | :--- | :--- | :--- | :--- |
| **23** | `insight_total_leads` | Total Ingested Leads | `leads l` | `COUNT(*) WHERE deleted_at IS NULL AND created_at BETWEEN $from AND $to` |
| **24** | `insight_prop_listing` | Property Listing Leads | `leads l` | `COUNT(*) WHERE lead_type = 'Property Listing'` |
| **25** | `insight_requirement` | Requirement Leads | `leads l` | `COUNT(*) WHERE lead_type = 'Requirement'` |
| **26** | `insight_telecallers` | Active Telecallers | `users u JOIN roles r` | `COUNT(DISTINCT u.id) WHERE r.name = 'Telecaller'` |
| **27** | `insight_new_open` | New / Open Leads | `leads l` | `stage = 'NEW' AND call_disposition = 'NOT_ATTEMPTED' AND allocation_status = 'UNASSIGNED_WAITING'` |
| **28** | `insight_cnr` | Could Not Reach (CNR) | `leads l` | `call_disposition = 'CNR' OR allocation_status = 'CNR'` |
| **29** | `insight_callback` | Callback Requested | `leads l` | `call_disposition = 'CALLBACK' OR allocation_status = 'CALLBACK'` |
| **30** | `insight_followups` | Follow-ups Scheduled | `leads l / followups` | `stage = 'FOLLOWUP' OR EXISTS(SELECT 1 FROM followups f WHERE f.lead_id = l.id)` |
| **31** | `insight_not_interested` | Not Interested | `leads l` | `call_disposition = 'NOT_INTERESTED' OR stage = 'LOST'` |
| **32** | `insight_handed_to_sales` | Assigned to Sales | `leads l` | `allocation_status IN ('HANDED_TO_SALES', 'DIRECT_SALES') OR stage = 'SALES'` |

### Section 3.2: CRM Sales Pipeline (from `requirements`) (9 KPIs)

| # | KPI Identifier | Display Name | Database Source | Filter on `requirements.status` |
| :- | :--- | :--- | :--- | :--- |
| **33** | `req_not_started` | Not Started | `requirements r` | `status = 'Not Started'` |
| **34** | `req_call_attempted` | Call Attempted | `requirements r` | `status IN ('Call Attempted (Picked Up)', 'Call Attempted (Open)', 'Call Attempted')` |
| **35** | `req_followups` | Follow-ups | `requirements r` | `status = 'Follow-up'` |
| **36** | `req_refollowups` | Re-Followups | `requirements r` | `status IN ('Re-Followup', 'Re-Follow-Up')` |
| **37** | `req_interested` | Interested | `requirements r` | `status = 'Interested'` |
| **38** | `req_site_visit_scheduled` | Site Visit Scheduled | `requirements r` | `status IN ('Site Visit', 'Site Visit Scheduled')` |
| **39** | `req_site_visit_done` | Site Visit Done | `requirements r` | `status = 'Site Visit Done' OR EXISTS(SELECT 1 FROM site_visits sv WHERE sv.requirement_id = r.id AND status = 'COMPLETED')` |
| **40** | `req_negotiation` | Negotiation | `requirements r` | `status = 'Negotiation'` |
| **41** | `req_rejected_leads` | Rejected Leads | `requirements r` | `LOWER(status) LIKE 'rejected%'` |

---

## 4. Module 4: Telecaller Workspace Dashboard (10 KPIs)

- **Flutter Surface:** `lib/features/telecaller/screens/telecaller_dashboard_screen.dart`
- **Widget Component:** Responsive grid of `_clickableKpi` cards
- **Backend Service:** `PropKart-Backend/src/modules/allocation/allocation.service.js` (`AllocationService.dashboard`)
- **API Endpoint:** `GET /api/v1/telecaller/dashboard` & `GET /api/v1/dashboard/telecallers-summary`

| # | KPI Identifier | Display Name | Source Logic | Telecaller Scoping |
| :- | :--- | :--- | :--- | :--- |
| **42** | `tc_assigned_leads` | My Assigned Leads | `integration_leads` | `assigned_telecaller_id = currentUser.id` |
| **43** | `tc_open_leads` | Open Leads (Uncontacted) | `integration_leads` | `call_attempt_count = 0 AND first_call_at IS NULL` |
| **44** | `tc_callbacks` | Pending Callbacks | `campaign_lead_callbacks` | `telecaller_id = currentUser.id AND status = 'Pending'` |
| **45** | `tc_today_callbacks` | Today's Callbacks | `campaign_lead_callbacks` | `scheduled_at::date = CURRENT_DATE` |
| **46** | `tc_cnr_retries` | CNR / Retries Pool | `integration_leads` | `allocation_status = 'CNR' OR campaign_status = 'CNR'` |
| **47** | `tc_picked_up` | Picked Up Today | `lead_call_attempts` | `outcome = 'PICKED_UP' AND created_at >= TODAY_START_IST` |
| **48** | `tc_handed_to_sales` | Handed to Sales | `integration_leads` | `allocation_status = 'HANDED_TO_SALES'` |
| **49** | `tc_not_interested` | Not Interested Leads | `integration_leads` | `campaign_status ILIKE '%not%interested%'` |
| **50** | `tc_workload` | Current Workload | `telecaller_availability` | Active leads count vs max queue capacity limit |
| **51** | `tc_remaining_capacity` | Remaining Capacity | Calculated | `max_capacity - currentWorkload` |

---

## 5. Module 5: Sales Dashboard KPIs (8 KPIs)

- **Flutter Surface:** `lib/features/sales/screens/sales_dashboard_screen.dart`
- **Widget Component:** Mode-aware `_clickableKpi` cards (`isRentMode` toggle)
- **Backend Service:** `PropKart-Backend/src/modules/allocation/metrics.service.js` (`AllocationMetricsService.salesDashboard`)
- **API Endpoint:** `GET /api/v1/sales/dashboard`

| # | KPI Identifier | Display Name | Database Source | Calculation & Scope |
| :- | :--- | :--- | :--- | :--- |
| **52** | `sales_available_inventory` | Available Inventory | `properties` | Total active properties ready for rent/sale matching mode. |
| **53** | `sales_site_visits_done` | Site Visit Done | `site_visits sv` | Completed visits where `scheduled_by = user.id` or linked to assigned requirement. |
| **54** | `sales_active_leads` | Active Leads | `requirements r` | Requirements assigned to user where `status NOT IN ('Won') AND status NOT ILIKE 'Rejected%'`. |
| **55** | `sales_deals_won` | Deals Won | `requirements r` | Requirements assigned to user where `status = 'Won'`. |
| **56** | `sales_assigned_leads` | Assigned Leads | `requirements r` | All active requirements currently assigned to sales executive. |
| **57** | `sales_new_leads` | New Leads | `requirements r` | Freshly transferred requirements where `status = 'New'`. |
| **58** | `sales_followups_due` | Follow-ups Due | `followups f` | Pending followups where `followup_date < TODAY_START` (Overdue). |
| **59** | `sales_active_followups` | Active Follow-ups | `followups f` | Pending followups scheduled for today and future calendar dates. |

---

## 6. Module 6: Telecaller Performance Report (10 KPIs)

- **Flutter Surface:** `lib/features/reports/screens/telecaller_report_screen.dart`
- **Backend Service:** `PropKart-Backend/src/modules/reports/reports.service.js` (`ReportsService.getTelecallerReports`)
- **API Endpoint:** `GET /api/v1/reports/telecallers`

| # | KPI Identifier | Display Name | Source Table | Formula / Query Logic |
| :- | :--- | :--- | :--- | :--- |
| **60** | `tc_perf_assigned` | Leads Assigned | `leads` | `COUNT(*) WHERE assigned_telecaller_id = $tcId` |
| **61** | `tc_perf_contacted` | Leads Contacted | `leads` | `COUNT(*) WHERE call_disposition IN ('CONTACTED', 'QUALIFIED')` |
| **62** | `tc_perf_dials` | Call Attempts Made | `leads` | `SUM(call_attempt_count)` |
| **63** | `tc_perf_qualification_rate`| Lead Qualification Rate | Calculated | `(qualified_count / total_assigned) * 100` |
| **64** | `tc_perf_converted_won` | Converted to Won | `requirements` | Closed deals originating from this telecaller's qualified leads. |

---

## 7. Inventory Sourcing & Direct Sourcing Breakdown (5 Auxiliary KPIs)

- **Flutter Surface:** `lib/features/reports/screens/leads/overall_business_insight_screen.dart` (Sourcing Tab)
- **Backend Service:** `PropKart-Backend/src/modules/dashboard/kpi.service.js` (`getInventoryBreakdown`)

| # | KPI Identifier | Display Name | Source Table | Query Logic |
| :- | :--- | :--- | :--- | :--- |
| **[A]** | `portfolio_total` | Total Portfolio | `properties` | Total properties managed: `p.deleted_at IS NULL` |
| **[B]** | `sourcing_sales` | Inventory Added by Sales | `properties p JOIN users u` | Properties created by users with role `'Sales'` |
| **[C]** | `sourcing_telecaller` | Inventory Added by Telecaller | `properties p JOIN users u` | Properties created by users with role `'Telecaller'` |
| **[D]** | `sourcing_admin` | Inventory Added by Admin | `properties p JOIN users u` | Properties created by users with role `'Admin'` or `'Super Admin'` |
| **[E]** | `direct_leads_total` | Total Direct / Organic Leads | `leads` | Inbound leads from non-paid sources (`MANUAL`, `DIRECT`, `REFERRAL`, `Walk-in`) |

---

## 8. Summary of Inventory Findings

1. **Entity Granularity Divide:** 
   - Top of funnel operates on `leads` and `integration_leads` (customer level).
   - Sales operations operate on `requirements` (deal / contract level).
   - Operations operate on `site_visits` and `lead_call_attempts` (event ledgers).
2. **Redundant Re-implementations:** The same metric (e.g. `site_visits_done` or `deals_won`) is currently queried via **4 different query expressions** across 4 different backend services and re-filtered in 3 Flutter screens.
3. **Purity Violations:** The Campaign Leads and Sales Dashboard screens violate Step 7/8 rules by fetching un-virtualized arrays and computing KPI sums client-side in Flutter build cycles.
