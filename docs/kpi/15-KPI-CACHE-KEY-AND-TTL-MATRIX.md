# PropKart — KPI Cache Key & TTL Matrix (Step 8.3)

## 1. Canonical Key Schema

Every cached KPI key strictly follows the canonical namespaced format:

```text
propkart:kpi:{env}:{tenantId}:{scope}:{kpiKey}:{filterHash}
```

### Segment Breakdown

| Segment | Allowed Values | Description | Security / Invariant |
| :--- | :--- | :--- | :--- |
| **Prefix** | `propkart:kpi` | Universal root namespace for KPI caching. | Distinguishes KPI cache from other domains. |
| **`env`** | `development`, `test`, `production` | Deployment environment. | Prevents staging/test data from colliding with prod. |
| **`tenantId`** | UUID string or `global` | Organization identifier. | **STRICT TENANT ISOLATION**: Non-superadmin without tenant ID returns `null` (no cache). |
| **`scope`** | `admin`, `telecaller_u{id}`, `sales_u{id}`, `reports` | Perspective / role boundary. | User-specific caches encode user ID in scope. |
| **`kpiKey`** | e.g. `dashboard_summary`, `inventory_breakdown`, `site_visits_summary` | Canonical metric indicator. | Distinguishes distinct KPI calculations. |
| **`filterHash`** | 16-character SHA-256 hex string or `default` | Deterministic hash of sorted filter parameters. | **ZERO PII**: Personal data never leaks into keys. |

---

## 2. Deterministic Filter Hashing Rules

1. **Allowed Keys Only**: Only recognized filter parameters (`businessType`, `dateFilter`, `startDate`, `endDate`, `leadType`, `areaId`, `source`, `sourceFilter`, `stage`, `status`, `isDealWon`, `rejectionReason`) are included.
2. **Alphabetical Sorting**: Object keys are sorted alphabetically before stringifying.
3. **Enum Normalization**: Strings are trimmed and lower-cased (`rent`, `buy`, `both`, `weekly`, `today`).
4. **Zero PII**: Customer names, phone numbers, and emails are stripped out and NEVER hashed or stored in keys.
5. **Hash Algorithm**: `crypto.createHash('sha256').update(sortedStr).digest('hex').slice(0, 16)`.

---

## 3. Comprehensive KPI TTL Matrix

| KPI Identifier | Cache Key (`kpiKey`) | Filter Scope | Recommended TTL | Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **Overall Dashboard Summary** | `dashboard_summary` | Today / Yesterday | **60 seconds** | High-velocity live counts for active calling floor. |
| **Overall Dashboard Summary** | `dashboard_summary` | Weekly / Last 7 Days | **120 seconds** | Balances responsiveness with cache efficiency. |
| **Overall Dashboard Summary** | `dashboard_summary` | Monthly / Quarterly | **900 seconds (15 min)** | Slower-moving historical aggregation. |
| **Overall Dashboard Summary** | `dashboard_summary` | All Time / Lifetime | **1800 seconds (30 min)** | Read-heavy master dataset overview. |
| **Available Inventory** | `inventory_breakdown` | Any Filter | **300 seconds (5 min)** | Moderate update frequency on listing updates. |
| **Total Leads Breakdown** | `leads_breakdown` | Today / Weekly | **120 seconds** | Real-time campaign lead ingestion acceleration. |
| **Total Leads Breakdown** | `leads_breakdown` | All Time | **1800 seconds (30 min)** | Master catalog query optimization. |
| **Site Visits Completed** | `site_visits_summary` | Any Filter | **180 seconds (3 min)** | Operational visit completions and scheduling. |
| **Deals Won Summary** | `deal_won_summary` | Any Filter | **300 seconds (5 min)** | Closed deal contracts ledger. |
| **Leads Allocated Breakdown** | `leads_allocated_breakdown` | Any Filter | **120 seconds** | Dynamic telecaller allocation queue monitoring. |
| **Assigned to Sales** | `assigned_to_sales_breakdown` | Any Filter | **120 seconds** | Sales handover pipeline responsiveness. |
| **Telecallers Roster** | `telecallers_summary` | Any Filter | **300 seconds (5 min)** | Staff availability and workload roster. |
| **Sales Users Roster** | `sales_users_summary` | Any Filter | **300 seconds (5 min)** | Sales representative team roster. |
| **Not Interested Leads** | `not_interested_summary` | Any Filter | **300 seconds (5 min)** | Disqualified lead audit metrics. |
| **Telecaller Dashboard KPIs** | `telecaller_summary` | Today | **60 seconds** | Real-time agent performance tracking. |
