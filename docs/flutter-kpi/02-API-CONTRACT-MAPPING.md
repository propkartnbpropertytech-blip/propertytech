# PROPKART API CONTRACT MAPPING
## Step 8.5 Flutter DTO Alignment & Legacy Alias Governance

**Document Version:** 1.0.0  
**Status:** Certified Architecture  
**Scope:** Client DTO Serialization, Field Normalization & Type Safety  
**Backend Reference:** Step 8.4 API Contract & Response Architecture  

---

## 1. Primary Contract Conventions

All responses returned by the PropKart API (Steps 8.1–8.4) follow deterministic envelope structures:

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "version": "1.0.0",
    "timestamp": "2026-10-21T05:30:00.000Z",
    "requestId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"
  }
}
```

Or for paginated lists:
```json
{
  "success": true,
  "data": {
    "items": [ ... ],
    "pagination": {
      "page": 1,
      "limit": 25,
      "total": 142,
      "totalPages": 6,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  },
  "meta": { ... }
}
```

---

## 2. Detailed Endpoint Mapping & Contract Matrix

### 2.1 `/api/v1/dashboard/kpis`

- **Purpose:** Primary KPI overview for Admin and Manager dashboards.
- **Request Parameters:**
  - `businessType`: `'Rent' | 'Re-sale' | 'Both'` (default `'Rent'`)
  - `dateFilter`: `'Today' | 'Weekly' | 'Monthly' | 'Yearly' | 'Custom Range'` (default `'Weekly'`)
  - `startDate`: `YYYY-MM-DD` (inclusive start)
  - `endDate`: `YYYY-MM-DD` (exclusive end boundary)
  - `leadType`: `'Listing' | 'Requirement' | 'Both'` (default `'Both'`)
- **Backend Response Payload (`data`):**
  - `counts`: Map of authoritative counts (`available_inventory`, `total_leads`, `deal_won`, `telecallers`, etc.)
  - `config`: List of user/role KPI display preferences
  - `filters`: Normalized query filters applied by the server
  - `dateRange`: Resolved interval `{ "startDate": "...", "endDate": "..." }`
- **Flutter Model:** `DashboardKpisResponse` containing `DashboardKpiCounts`.

### 2.2 Bidirectional Alias Support Matrix

To ensure zero regressions across legacy clients and backend versions, the Flutter DTO models implement resilient deserialization with alias fallback:

| Canonical Field (Step 8.4) | Legacy / Alternative Aliases | Flutter Getter | Deserialization Precedence |
| :--- | :--- | :--- | :--- |
| `deal_won` | `closed_deals`, `converted_clients` | `counts.dealWon`<br>`counts.closedDeals`<br>`counts.convertedClients` | 1. `deal_won`<br>2. `closed_deals`<br>3. `converted_clients`<br>Default: `0` |
| `leads_allocated` | `new_leads_allocated`, `total_allocated`, `allocated_leads` | `counts.leadsAllocated`<br>`counts.totalAllocated` | 1. `leads_allocated`<br>2. `new_leads_allocated`<br>3. `total_allocated`<br>Default: `0` |
| `all_available_inventory` | `global_available_inventory`, `total_available_inventory` | `counts.allAvailableInventory`<br>`counts.globalAvailableInventory` | 1. `all_available_inventory`<br>2. `global_available_inventory`<br>Default: `0` |
| `all_total_leads` | `global_total_leads`, `total_leads_all` | `counts.allTotalLeads`<br>`counts.globalTotalLeads` | 1. `all_total_leads`<br>2. `global_total_leads`<br>Default: `0` |
| `site_visits_done` | `site_visits_done_req`, `site_visits` | `counts.siteVisitsDone` | 1. `site_visits_done`<br>2. `site_visits_done_req`<br>Default: `0` |

### 2.3 Breakdown & List Endpoints

| Endpoint | Primary Response Key | Pagination Structure | Flutter DTO Model |
| :--- | :--- | :--- | :--- |
| `/dashboard/inventory-breakdown` | `byCategory`, `byBhk`, `byArea` | Non-paginated aggregation | `InventoryBreakdownData` |
| `/dashboard/inventory-properties`| `properties`, `total` | Standard page/limit pagination | `InventoryPropertiesResponse` |
| `/dashboard/leads-breakdown` | `byStatus`, `bySource`, `byArea` | Non-paginated aggregation | `LeadsBreakdownData` |
| `/dashboard/leads-list` | `leads`, `total` | Standard page/limit pagination | `LeadsListResponse` |
| `/dashboard/not-interested-leads`| `leads`, `total` | Standard page/limit pagination | `LeadsListResponse` |
| `/dashboard/telecallers-summary` | `telecallers`, `activeCount` | Aggregated roster list | `TelecallersSummaryResponse` |
| `/dashboard/telecaller-drilldown/:id` | `stats`, `breakdowns` | Profile + Aggregated stats | `TelecallerDrilldownData` |
| `/dashboard/telecaller-leads/:id`| `leads`, `total` | Tab-scoped pagination | `LeadsListResponse` |
| `/dashboard/site-visits-list` | `siteVisits`, `total` | Standard page/limit pagination | `SiteVisitsResponse` |
| `/dashboard/deal-won-list` | `deals`, `total` | Standard page/limit pagination | `DealWonResponse` |
| `/dashboard/sales-users-summary` | `salesUsers`, `summary` | Aggregated team list | `SalesUsersSummaryResponse` |
| `/dashboard/sales-user-drilldown/:id`| `stats`, `stageCounts` | User profile + performance | `SalesUserDrilldownData` |
| `/dashboard/sales-user-requirements/:id`| `requirements`, `total`| Status-filtered pagination | `SalesUserRequirementsResponse` |
| `/dashboard/lifecycle-breakdown` | `stages`, `sales_roster`, `total_leads` | Multi-table pipeline snapshot | `Map<String, dynamic>` |
| `/dashboard/lifecycle-leads` | `leads`, `total` | Pipeline-stage pagination | `Map<String, dynamic>` |
| `/reports/business-insight` | `source_summary`, `property_listing`, `requirements` | Full BI summary counts | `BusinessInsightSummary` |
| `/reports/business-insight/leads` | `leads`, `total` | Filtered BI leads | `Map<String, dynamic>` |

---

## 3. Defensive Deserialization Patterns

To guarantee that no API contract change or edge-case null field causes a client crash or unhandled exception:

1. **Numeric Coercion:**
   All numeric counts in JSON are parsed via `(json['key'] as num?)?.toInt() ?? 0`. This safely accepts integers, floats, strings convertible to numbers, or null without runtime type cast errors.
2. **List Coercion:**
   Lists are mapped via `(json['key'] as List?)?.map(...).toList() ?? const []`.
3. **Map Coercion:**
   Nested dictionaries are safely handled with `json['key'] is Map ? Map<String, dynamic>.from(json['key']) : const {}`.
4. **Date Parsing:**
   All dates are stored as ISO 8601 strings and parsed using `DateTime.tryParse()` with a fallback to `null` or epoch baseline.
