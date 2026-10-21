# PROPKART — CACHE KEY ARCHITECTURE & NAMESPACING STANDARD
**Version:** 1.0.0  
**Status:** CANONICAL CACHE SPECIFICATION (STEP 3)  
**Date:** October 20, 2026  
**Scope:** Key Formatting Standards, Segment Taxonomy, Tenant Isolation & Versioning  

---

## 1. Executive Summary & The Namespacing Standard

To prevent data leakage between tenants, eliminate collisions between staging and production, and allow instant cache flushing during schema deployments, PropKart enforces a **strict, multi-segment hierarchical cache key standard**.

Every key in Redis must strictly follow this pattern:

```
propkart:{environment}:{tenant}:{domain}:{resource}:{identifier}:{version}
```

---

## 2. Segment Taxonomy & Definition

```
========================================================================================================================
                                CACHE KEY SEGMENT SPECIFICATION
========================================================================================================================
  Segment            Allowable Values                   Purpose & Operational Rule
------------------------------------------------------------------------------------------------------------------------
  1. Root Namespace  "propkart"                         Global root namespace for all application data
  2. Environment     "dev" | "test" | "staging" | "prod" Prevents staging traffic from overwriting production cache
  3. Tenant          UUID | "global"                    Multi-tenant boundary. Zero cross-tenant sharing permitted
  4. Domain          "kpi" | "dashboard" | "crm" |      Functional business area
                     "inventory" | "auth" | "lock"
  5. Resource        "leads" | "properties" |           Entity or calculation target
                     "site_visits" | "user" | "summary"
  6. Identifier      UUID | MD5 Query Hash | "all"      Specific instance, user id, or query filter combination
  7. Version         "v1" | "v2"                        Enables zero-downtime cache invalidation on payload changes
========================================================================================================================
```

---

## 3. Real-World Concrete Key Examples

### 3.1 Tenant KPI Dashboard Summary
```text
propkart:prod:c88ed9f1-5261-4e5f-8a34-e9fade752c70:dashboard:summary:user_a1b2c3d4:v1
```
- **Tenant:** Specific brokerage organization.
- **Resource:** Dashboard summary.
- **Identifier:** Scoped to the individual sales rep or admin (`user_a1b2c3d4`).

### 3.2 Canonical Site Visits Completed KPI (Filter: This Month)
```text
propkart:prod:c88ed9f1-5261-4e5f-8a34-e9fade752c70:kpi:site_visits_completed:range_this_month:v1
```
- **Scope:** Aggregated tenant metric for current calendar month.

### 3.3 Property Detail Record
```text
propkart:prod:c88ed9f1-5261-4e5f-8a34-e9fade752c70:inventory:property:pr-10492-uuid:v1
```
- **Scope:** Cached property detail view with verified media links.

### 3.4 Global Master Data Lookup (Property Categories)
```text
propkart:prod:global:inventory:categories:all:v1
```
- **Tenant:** `global` (accessible across all tenants).
- **Identifier:** `all` (complete active categories array).

### 3.5 Distributed Coordination Lock
```text
propkart:lock:sync:nightly_allocation_rebalance
```
- **Scope:** Global execution lock preventing duplicate worker execution.

---

## 4. Collision & Leakage Prevention Rules

1. **Strict Tenant Segregation:** Every query for tenant-scoped data MUST pass `organization_id` into the key constructor. Omitting the tenant segment for operational data is rejected.
2. **Deterministic Filter Hashing:** If a query accepts multiple filters (e.g. `min_price=1000000`, `max_price=5000000`, `bhk=3`), the identifier segment must be a deterministic SHA256 or MD5 hash of the normalized filter object.
3. **Instant Schema Invalidation via Version Bump:** When a backend change alters the JSON structure of a cached response, developers simply increment the version segment (`v1` $\to$ `v2`). Old keys naturally expire via TTL without requiring dangerous `FLUSHDB` commands.

---

## 5. Programmatic Key Construction

Keys must be constructed via `cacheService.buildKey()`. Manual string concatenation of Redis keys is forbidden in application code:

```javascript
import { cacheService } from "../services/cache.service.js";

const key = cacheService.buildKey({
    env: process.env.NODE_ENV,
    tenantId: req.user.organization_id,
    domain: "kpi",
    resource: "deals_won",
    identifier: "range_this_year",
    version: "v1",
});
// Outputs: propkart:production:c88ed9f1...:kpi:deals_won:range_this_year:v1
```
