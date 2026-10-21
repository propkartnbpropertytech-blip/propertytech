# 06 — PROPKART CANONICAL KPI API CONTRACT (STEP 8.4)

## 1. Primary Objective

Documents the exact JSON response contracts, field specifications, numeric types, and legacy aliases for all primary KPI endpoints powering PropKart mobile and administrative interfaces.

---

## 2. Core Dashboard KPI Endpoint: `GET /api/v1/dashboard/kpis`

### 2.1 Route & Auth Contract
- **Method**: `GET`
- **Path**: `/api/v1/dashboard/kpis`
- **Permission**: `dashboard.read`
- **Query Parameters**:
  - `businessType` (Optional): `Rent`, `Sale`, `Both` (default: `Rent`)
  - `leadType` (Optional): `Requirement`, `Listing`, `Both` (default: `Both`)
  - `dateFilter` (Optional): `Weekly`, `Monthly`, `All Time`, `Custom Range` (default: `Weekly`)
  - `startDate` (Optional): ISO-8601 string or `YYYY-MM-DD`
  - `endDate` (Optional): ISO-8601 string or `YYYY-MM-DD`

### 2.2 Response Schema
```json
{
  "success": true,
  "data": {
    "config": [ ... ],
    "filters": {
      "businessType": "Rent",
      "dateFilter": "Weekly",
      "leadType": "Both"
    },
    "date_range": {
      "from": "2026-10-14T00:00:00.000Z",
      "to": "2026-10-21T00:00:00.000Z",
      "display": "Past 7 Days",
      "filter": "Weekly"
    },
    "counts": {
      "available_inventory": 145,
      "all_available_inventory": 166,
      "global_available_inventory": 166,
      "total_leads": 35,
      "all_total_leads": 1211,
      "global_total_leads": 1211,
      "telecallers": 2,
      "leads_allocated": 33,
      "new_leads_allocated": 33,
      "new_allocated": 33,
      "old_leads_allocated": 5,
      "total_allocated": 1065,
      "assigned_to_sales": 42,
      "site_visits_done": 0,
      "rejected_after_site_visit": 0,
      "deal_won": 2,
      "closed_deals": 2,
      "lifetime_closed_deals": 3,
      "converted_clients": 0,
      "sales_users": 4,
      "not_interested": 9,
      "cnr": 223
    },
    "raw_counts": { ... }
  }
}
```

---

## 3. Inventory Breakdown: `GET /api/v1/dashboard/inventory-breakdown`

### 3.1 Response Contract
```json
{
  "success": true,
  "data": {
    "available": 145,
    "to_be_available": 12,
    "rented_out": 15,
    "sold_out": 2,
    "rental_count": 160,
    "resale_count": 23,
    "total": 183,
    "total_portfolio": 183
  }
}
```

---

## 4. Leads Breakdown: `GET /api/v1/dashboard/leads-breakdown`

### 4.1 Response Contract
```json
{
  "success": true,
  "data": {
    "total_leads": 35,
    "property_listing_leads": 8,
    "requirement_leads": 27,
    "sources": [
      { "source": "Meta", "count": 25 },
      { "source": "Housing", "count": 4 },
      { "source": "Webhook", "count": 1 },
      { "source": "Manual", "count": 5 }
    ],
    "by_source": {
      "meta": 25,
      "housing": 4,
      "webhook": 1,
      "manual": 5
    }
  }
}
```

---

## 5. Telecallers Summary: `GET /api/v1/dashboard/telecallers-summary`

### 5.1 Response Contract
```json
{
  "success": true,
  "data": {
    "total_telecallers": 2,
    "filters": {
      "dateFilter": "Weekly",
      "leadType": "Both"
    },
    "telecallers": [
      {
        "id": "uuid-1",
        "name": "Telecaller A",
        "email": "tc.a@propkart.com",
        "status": "Active",
        "leads_allocated": 18,
        "listing_leads": 4,
        "requirement_leads": 14
      }
    ]
  }
}
```

---

## 6. Sales Users Summary: `GET /api/v1/dashboard/sales-users-summary`

### 6.1 Response Contract
```json
{
  "success": true,
  "data": {
    "total_sales_users": 4,
    "filters": {
      "dateFilter": "Weekly"
    },
    "sales_users": [
      {
        "id": "uuid-sales-1",
        "name": "Sales Agent One",
        "email": "sales1@propkart.com",
        "leads_count": 15
      }
    ]
  }
}
```
