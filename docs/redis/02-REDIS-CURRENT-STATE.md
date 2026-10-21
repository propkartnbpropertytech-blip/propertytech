# PROPKART — CURRENT REDIS STATE & USAGE INVENTORY
**Version:** 1.0.0  
**Status:** CANONICAL AUDIT INVENTORY (STEP 3)  
**Date:** October 20, 2026  
**Scope:** Forensic Catalog of Existing Redis Call-Sites, Key Patterns & Structural Defects  

---

## 1. Executive Summary & Forensic Audit

A comprehensive code search of `PropKart-Backend` identified **14 distinct modules** referencing the Redis data layer.

Prior to Step 3, the platform was operating on an **in-memory `Map()` mock (`src/config/redis.js`)** that mimicked Redis primitives without connecting to an actual distributed Redis cluster. This prevented crashes during local development, but introduced severe vulnerabilities and architectural bugs in multi-instance production environments.

---

## 2. Complete Call-Site Inventory

### 1. Dashboard Aggregations (`src/modules/dashboard/dashboard.service.js`)
- **Purpose:** Caching heavy multi-table dashboard summaries (followups, site visits, leads, tasks).
- **Key Pattern:** `dashboard_summary_v16:{user.id}`
- **Data Stored:** Full JSON dashboard object (up to 150 KB).
- **TTL:** 300 seconds (5 minutes).
- **Read Pattern:** `redisClient.get(userCacheKey)` on endpoint entry.
- **Write Pattern:** `redisClient.set(userCacheKey, JSON.stringify(result), { EX: 300 })`.
- **Invalidation:** Triggered via `kvDeleteByPrefix("dashboard_summary_")`.
- **Tenant Scope:** **FLAWED.** Keys contain only `user.id` without tenant namespacing. Invalidation blows away every user across all tenants.

### 2. User Profile & RBAC Caching (`src/middleware/auth.middleware.js`)
- **Purpose:** Caches authenticated user profiles to avoid database queries on every HTTP request.
- **Key Pattern:** `user_profile_cache:{userId}`
- **Data Stored:** Serialized `users` table row with attached roles and organization metadata.
- **TTL:** 300 seconds (5 minutes).
- **Read Pattern:** `redisClient.get(cacheKey)` before database fetch.
- **Write Pattern:** `redisClient.set(cacheKey, JSON.stringify(user), { EX: 300 })`.
- **Invalidation:** Evicted on password update, profile edit, or role change.
- **Tenant Scope:** Scoped to individual `userId`.

### 3. Account Lockout & Brute-Force Defense (`src/security/lockout.js`)
- **Purpose:** Rate-limiting failed logins by email and client IP to prevent credential stuffing.
- **Key Patterns:**
  - `lockout:email:{email}:attempts`
  - `lockout:email:{email}:locked`
  - `lockout:ip:{ip}:attempts`
  - `lockout:ip:{ip}:locked`
- **Data Stored:** Integer counter strings (`"1"`, `"2"`).
- **TTL:** Configured window (e.g. 900s) and duration (e.g. 1800s).
- **Read/Write Pattern:** Atomic increment via `kvIncr` and boolean flag check via `kvGet`.
- **Invalidation:** Explicit reset via `kvDel` upon successful login.

### 4. JWT Revocation & Session Management (`src/security/tokens.js`)
- **Purpose:** Token denylist for logged-out access tokens, refresh token rotation, and family reuse detection.
- **Key Patterns:**
  - `jwt:deny:{jti}` (Denylist)
  - `jwt:refresh:{tokenHash}` (Refresh Token Payload)
  - `jwt:refreshfam:{family}` (Family Owner Binding)
  - `jwt:sessions:{userId}` (Active Session JTI list)
- **Data Stored:** JSON session metadata and revocation flags.
- **TTL:** Matches token lifetime (15m for access token, 7d/30d for refresh token).
- **Read/Write Pattern:** `kvSet`, `kvGet`, `kvDel`.

### 5. Password History Enforcement (`src/security/password.js`)
- **Purpose:** Prevents users from reusing their last $N$ passwords upon password change.
- **Key Pattern:** `pwdhist:{userId}`
- **Data Stored:** JSON array of previous bcrypt hashes.
- **TTL:** 365 days (1 year).
- **Risk:** High. In-memory storage loses password history across server restarts.

### 6. Invalidation Call-Sites Across Core Controllers
The following controllers invoke prefix deletions upon data mutation:
- **`src/modules/followups/followups.controller.js`:** `kvDeleteByPrefix("dashboard_summary_")`
- **`src/modules/site_visits/site_visits.controller.js`:** `kvDeleteByPrefix("dashboard_summary_")`
- **`src/modules/requirements/requirements.service.js`:** `kvDeleteByPrefix("dashboard_summary_")`
- **`src/modules/integrations/integrations.service.js`:** `kvDeleteByPrefix("dashboard_summary_")`
- **`src/config/realtime.js`:** `kvDeleteByPrefix("dashboard_summary_cache")`
- **`src/modules/users/users.service.js`:** `redisClient.del("dashboard_summary_cache")` and `redisClient.del("user_profile_cache:{userId}")`
- **`src/modules/users/users.stats.controller.js`:** Loops through org users and deletes `user_profile_cache:{u.id}`.

---

## 3. Critical Structural Defects Identified

```
========================================================================================================================
                                STRUCTURAL DEFECTS AUDIT MATRIX
========================================================================================================================
  Defect Category                Forensic Finding                       Severity     Remediation Status
------------------------------------------------------------------------------------------------------------------------
  1. Key Prefix Mismatch         realtime.js and users.service.js       HIGH         RESOLVED (Prefix aligned to
                                 invalidated "dashboard_summary_cache"               dashboard_summary_ & CacheService)
                                 while service stored dashboard_summary_v16
------------------------------------------------------------------------------------------------------------------------
  2. Cross-Tenant Blast Radius   kvDeleteByPrefix("dashboard_summary_") HIGH         RESOLVED (Introduced tenant-
                                 evicted ALL tenants when one tenant                 scoped invalidation in CacheService)
                                 mutated a follow-up
------------------------------------------------------------------------------------------------------------------------
  3. No Distributed Connection   In-memory Map mock prevented           HIGH         RESOLVED (Equipped ioredis with
                                 multi-instance process synchronization              connection pooling & memory fallback)
------------------------------------------------------------------------------------------------------------------------
  4. Cache Stampede Hazard       Concurrent dashboard requests on       MEDIUM       RESOLVED (Implemented single-flight
                                 cache miss hit database simultaneously              promise mutex in getOrSet)
------------------------------------------------------------------------------------------------------------------------
  5. Unbounded Object Sizing     No maximum payload size protection     MEDIUM       RESOLVED (512 KB payload ceiling
                                 against oversized cache writes                      strictly enforced)
========================================================================================================================
```
