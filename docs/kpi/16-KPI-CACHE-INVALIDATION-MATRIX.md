# PropKart — KPI Cache Invalidation Matrix & Blast Radius Specification (Step 8.3)

## 1. Mutation Event to Cache Namespace Mapping

Whenever a write, update, or status mutation occurs, the backend triggers targeted cache invalidation through `kpiCacheService.invalidateOnMutation(mutationType, tenantId)`:

| Mutation Event | Trigger Location | Target Namespace(s) Invalidated | Affected KPI Indicators |
| :--- | :--- | :--- | :--- |
| **Site Visit Scheduled / Rescheduled** | `SiteVisitsController.createSiteVisit` | `admin`, `sales`, `reports`, `telecaller` | `site_visits_done`, `dashboard_summary` |
| **Site Visit Completed / Outcome Logged** | `SiteVisitsController.updateStatus` | `admin`, `sales`, `reports`, `telecaller` | `site_visits_done`, `rejected_after_site_visit`, `deal_won` |
| **Lead Ingestion / Webhook Ingest** | `IntegrationsService.ingest*` | `admin`, `telecaller`, `reports` | `total_leads`, `new_leads_allocated`, `leads_breakdown` |
| **Lead Allocation / Reassignment** | `AllocationService.reassignLead` | `admin`, `telecaller`, `sales` | `leads_allocated`, `old_leads_allocated`, `assigned_to_sales` |
| **Lead Call Disposition (CNR / Callback)** | `AllocationService.recordOutcome` | `admin`, `telecaller` | `cnr`, `callbacks`, `telecaller_summary` |
| **Lead Handover to Sales (Picked Up)** | `AllocationService.recordOutcome` | `admin`, `telecaller`, `sales` | `assigned_to_sales`, `telecaller_summary` |
| **Requirement Status Updated (Won/Closed)** | `RequirementsService.updateRequirement` | `admin`, `sales`, `reports` | `deal_won`, `closed_deals`, `converted_clients` |
| **Property Created / Listed** | `PropertiesService.createProperty` | `admin`, `sales`, `reports` | `available_inventory`, `total_portfolio` |
| **Property Status Changed (Sold/Rented)** | `PropertiesService.updateProperty` | `admin`, `sales`, `reports` | `available_inventory`, `rented_out`, `sold_out` |
| **Property Soft Deleted** | `PropertiesService.softDeleteProperty` | `admin`, `sales`, `reports` | `available_inventory`, `total_portfolio` |

---

## 2. Multi-Tenant Blast Radius Analysis

### Architectural Invariant
Invalidation patterns are strictly anchored to the mutating organization's UUID:
```text
propkart:kpi:{env}:{targetTenantId}:{scope}:*
```

### Safety Verification
1. **Tenant Isolation**: When an event occurs in Tenant Alpha (`c88ed9f1-...`), the SCAN stream strictly filters on `propkart:kpi:{env}:c88ed9f1-...*`.
2. **Zero Blast Radius**: Tenant Beta (`d99fe0f2-...`) keys are never matched, deleted, or expired.
3. **Non-Blocking SCAN**: Deletions use `scanStream` (count 100) and atomic Redis pipeline `del` commands to prevent blocking the Redis event loop.
4. **Legacy Compatibility**: Also invalidates legacy prefix `dashboard_summary_` to guarantee backward compatibility with legacy endpoints.
