# 05 — PROPKART API PAGINATION & FILTER STANDARD (STEP 8.4)

## 1. Primary Objective

Standardizes inbound query parameters, date range semantics, and pagination bounding across all KPI and operational collection endpoints.

---

## 2. Temporal Filter Semantics: Half-Open `[startDate, endDate)`

All temporal filtering across PropKart uses half-open interval semantics:
```text
record_timestamp >= startDate AND record_timestamp < endDate
```

### 2.1 Calendar Date Normalization
When clients provide `startDate` and `endDate` as dates without timestamps (e.g. `2026-01-01` and `2026-01-31`):
- `startDate` is normalized to the beginning of the day: `2026-01-01T00:00:00.000Z`
- `endDate` is normalized to the start of the following day: `2026-02-01T00:00:00.000Z`
This ensures all events occurring up to `23:59:59.999Z` on January 31st are included without timezone or microsecond clipping.

### 2.2 Monotonic Validation
The `validateKpiQuery` middleware validates that:
```text
startDate <= endDate
```
Inversion (`startDate > endDate`) results in immediate rejection:
`HTTP 400 Bad Request` with `errorCode: "VALIDATION_ERROR"`.

---

## 3. Allowed Domain Enumerations

The following canonical enumerations are enforced by Zod schema validation:

### 3.1 `businessType`
- `Rent`
- `Sale`
- `Re-Sale`
- `Both` / `All`

### 3.2 `leadType`
- `Requirement` (Buyers / Prospective Tenants)
- `Listing` (Sellers / Landlords)
- `Both` / `All`

### 3.3 `dateFilter`
- `Today`
- `Yesterday`
- `Weekly`
- `Monthly`
- `Quarterly`
- `Yearly`
- `Custom Range` / `Custom`
- `All Time`

---

## 4. Bounded Pagination Safeguards

To prevent memory bloat, socket starvation, and database sequential scan exhaustion, all collection and drilldown endpoints enforce strict pagination bounding via `parsePagination()`:

| Parameter | Default | Minimum | Maximum (Hard Ceiling) |
| :--- | :--- | :--- | :--- |
| `page` | `1` | `1` | Unlimited |
| `limit` | `20` or `25` | `1` | **`100`** |

Requests with `limit > 100` (e.g., `?limit=99999`) are automatically clamped to `100` rather than throwing an error, maintaining graceful degradation for misconfigured clients.
