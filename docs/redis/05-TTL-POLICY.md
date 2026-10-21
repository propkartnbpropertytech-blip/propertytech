# PROPKART — TIME-TO-LIVE (TTL) STRATEGY & POLICY
**Version:** 1.0.0  
**Status:** CANONICAL CACHE SPECIFICATION (STEP 3)  
**Date:** October 20, 2026  
**Scope:** Expiration Policies, Staleness Tolerances & Memory Eviction Controls  

---

## 1. Executive Summary & The Bounded-TTL Rule

An unexpiring cache is an architectural defect. Every key stored in PropKart Redis **MUST** have an explicit, bounded Time-To-Live (TTL).

Data is categorized into five distinct lifespan tiers based on volatility, business criticality, and staleness tolerance:

```
========================================================================================================================
                                TTL LIFESPAN CLASSIFICATION MATRIX
========================================================================================================================
  Tier               Lifespan Range      Target Resources                       Staleness Tolerance
------------------------------------------------------------------------------------------------------------------------
  Tier 1: Ephemeral  30 – 60 seconds     Live Dashboard Counters, Queue Length  Maximum 60 seconds
  Tier 2: Short      3 – 5 minutes       User Profiles, Operational Summaries   Maximum 5 minutes (Evicted on Edit)
  Tier 3: Medium     15 – 60 minutes     Property Details, Search Facets        Maximum 1 hour (Evicted on Edit)
  Tier 4: Long       24 hours            Master Lookups (Categories, Amenities) Maximum 24 hours (Static Data)
  Tier 5: No Cache   Strictly 0 seconds  Financials, Passwords, Ingestion Queues Zero Staleness (Strict ACID Only)
========================================================================================================================
```

---

## 2. Resource-by-Resource TTL Specification

| Resource | TTL | Freshness Requirement | Invalidation Event | Max Staleness | Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Dashboard Summary** | **60 sec** | High | Follow-up, site visit, or lead status update | 60 sec | High user polling rate. Short TTL prevents outdated counts during sales sprints. |
| **Canonical KPIs** | **300 sec (5m)** | Medium | Nightly rebalance or admin sync | 5 min | Complex aggregation over thousands of records. High database savings. |
| **User Profile / RBAC** | **300 sec (5m)** | High | User update, role change, password reset | Immediate on edit | Evaluated on every HTTP request. Eliminates database load while honoring instant revocation. |
| **Property Detail** | **900 sec (15m)** | Medium | Property edit, price change, status update | Immediate on edit | Frequently viewed by buyers. Changes infrequently. |
| **Master Categories** | **86,400 sec (24h)**| Low | Master table DDL migration | 24 hours | Static configuration tables (`property_types`, `facing_types`, `amenities`). |
| **Account Lockout Window**| **900 sec (15m)** | Critical | Successful login or admin manual unlock | Exact window | Security brute-force tracking window. |
| **JWT Revocation Deny** | **900 sec (15m)** | Critical | Token natural expiration | Exact token exp | Ensures logged-out tokens cannot access API for remainder of validity. |
| **Distributed Mutex Lock**| **5 – 30 sec** | Critical | Task completion or crash timeout | Exact lock exp | Auto-expires to prevent deadlocks if worker container crashes mid-execution. |

---

## 3. TTL Jitter to Prevent Expiration Waves

### 3.1 The Synchronized Expiration Hazard
If 1,000 active users refresh their dashboard at 9:00 AM with a fixed 300-second TTL, all 1,000 cache entries will expire simultaneously at 9:05 AM. This produces a sudden, synchronized load spike on PostgreSQL known as an **Expiration Wave**.

### 3.2 Jitter Formula
To disperse database refresh requests, `CacheService` applies a $\pm 10\%$ pseudo-random jitter to medium and short-lived TTLs:

$$\text{Effective TTL} = \text{Base TTL} + \text{randomInt}(-\Delta, +\Delta) \quad \text{where } \Delta = 0.10 \times \text{Base TTL}$$

```javascript
export function applyTtlJitter(baseTtlSec) {
    if (baseTtlSec <= 60) return baseTtlSec; // Do not jitter ephemeral locks or short counters
    const variance = Math.floor(baseTtlSec * 0.10);
    const offset = Math.floor(Math.random() * (variance * 2 + 1)) - variance;
    return baseTtlSec + offset;
}
```

---

## 4. Redis Memory Eviction Policy

PropKart Redis clusters must be configured with:
```text
maxmemory 512mb
maxmemory-policy volatile-lru
```
- **`volatile-lru`:** Evicts the least recently used keys **only among keys that have an explicit TTL set**.
- If memory is exhausted, ephemeral dashboard and search caches are evicted first, preserving critical locks and security denylists until their natural expiration.
