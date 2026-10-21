# PROPKART KPI FILTER ARCHITECTURE
## Step 8.5 Filter Semantics, Date Boundaries & Multi-Role Query Discipline

**Document Version:** 1.0.0  
**Status:** Certified Architecture  
**Scope:** Client Filter Models, Half-Open Date Range Semantics & State Synchronization  
**Backend Reference:** Steps 8.1–8.4 Certified Query Architecture  

---

## 1. Architectural Philosophy

Filtering in PropKart follows a strict authoritative model:
1. **The client selects and displays filter controls.**
2. **The client normalizes selections into an immutable `KpiFilterParams` value object.**
3. **The client transmits query parameters to `/api/v1/dashboard/kpis` without executing local math or in-memory array filtering on authoritative counts.**
4. **PostgreSQL computes authoritative aggregations using the half-open interval `[startDate, endDate)`.**

---

## 2. Filter Parameters Specification

### 2.1 Core Parameter Fields

| Field Name | Type | Allowed Enums / Values | Default | Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `businessType` | `String` | `'Rent'`, `'Re-sale'`, `'Both'` | `'Rent'` | Restricts properties and requirements to rental, resale, or combined portfolios. |
| `dateFilter` | `String` | `'Today'`, `'Weekly'`, `'Monthly'`, `'Yearly'`, `'Custom Range'`, `'All Time'` | `'Weekly'` | Preset window or custom date selector. |
| `startDate` | `String?` | `YYYY-MM-DD` | `null` | Inclusive lower bound of the interval. |
| `endDate` | `String?` | `YYYY-MM-DD` | `null` | Upper boundary of the interval (`[startDate, endDate)`). |
| `leadType` | `String` | `'Listing'`, `'Requirement'`, `'Both'` | `'Both'` | Segregates property sourcing leads from buyer/tenant requirement leads. |
| `outcome` | `String?` | `'INTERESTED'`, `'REJECTED_AFTER_VISIT'`, `'DEAL_WON'`, etc. | `null` | Optional outcome filter for pipeline drilldowns. |

---

## 3. Half-Open Interval Semantics: `[startDate, endDate)`

To eliminate end-of-day truncation, timezone skew between IST (+05:30) and UTC, and double-counting across day boundaries:

```text
[startDate 00:00:00.000) ───────────────► [endDate 00:00:00.000)
       ▲                                         ▲
   Inclusive                                 Exclusive
```

### Date Conversion Rules in Flutter:
1. When selecting a preset (e.g., `'Weekly'`), the client submits `dateFilter=Weekly`. The backend canonical resolver automatically determines exact canonical dates.
2. When the user picks a Custom Date Range in Flutter UI (e.g., Oct 1 to Oct 20):
   - `startDate`: `'2026-10-01'`
   - `endDate`: `'2026-10-21'` (or the date boundary matching backend half-open definition)
3. Under no circumstances does Flutter truncate timestamps or shift dates by local client device clock skew.

---

## 4. Immutability & BLoC Event Flow

`KpiFilterParams` is an immutable Equatable value object:

```dart
class KpiFilterParams {
  final String businessType;
  final String dateFilter;
  final String? startDate;
  final String? endDate;
  final String leadType;
  final String? outcome;

  const KpiFilterParams({
    this.businessType = 'Rent',
    this.dateFilter = 'Weekly',
    this.startDate,
    this.endDate,
    this.leadType = 'Both',
    this.outcome,
  });

  KpiFilterParams copyWith({ ... }) { ... }
}
```

### Event Flow:
```text
Filter Bar Dropdown / Date Picker
        │
        ▼ (User selects new date or business type)
Dispatch UpdateKpiFilter / LoadDashboardKpis
        │
        ▼
DashboardBloc receives event
  ├── Checks if filters actually changed (prevents duplicate queries)
  ├── Emits DashboardLoadedState with isKpiLoading: true (NO UI flickers, existing values preserved)
  └── Invokes DashboardRepository.getDashboardKpis(newFilters)
        │
        ▼
Authoritative counts returned from backend
  └── Emits DashboardLoadedState with updated kpis & isKpiLoading: false
```

---

## 5. Role-Based Filter Boundaries

| User Role | Permitted Business Types | Permitted Lead Types | Tenant Scope Enforcement |
| :--- | :--- | :--- | :--- |
| **Super Admin** | Rent, Re-sale, Both | Listing, Requirement, Both | Global or Organization-filtered |
| **Admin** | Rent, Re-sale, Both | Listing, Requirement, Both | Organization-bound (server derived) |
| **Telecaller** | Configured portfolio | Sourcing & Telecaller pipeline | Auto-scoped to assigned telecaller queue |
| **Sales** | Rent, Re-sale, Both | Requirements | Auto-scoped to assigned sales user portfolio |
