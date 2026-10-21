# 10 — REDIS SECURITY & CACHE ISOLATION

## 1. Role of Redis in PropKart

Redis acts as a high-performance **caching and ephemeral state tier** (KPI caching, token blacklists, session tracking, rate limiting).
- **Non-Authoritative Invariant**: Redis is NEVER the authoritative source of truth for business logic or security state. PostgreSQL remains the single mathematical and relational source of truth.
- **Fail-Safe Operation**: If Redis becomes unavailable, the backend fails gracefully to PostgreSQL without crashing or elevating privileges (`kpi.redis.failure.test.js`).

---

## 2. Key Namespace Isolation & Tenant Prefixing

Every key stored in Redis conforms to a structured, tenant-partitioned namespace:

```text
jwt:deny:<jti>                  ── Token revocation blacklist (TTL = remaining exp)
jwt:refresh:<sha256(token)>     ── Hashed refresh token state
jwt:refreshfam:<familyId>       ── Session family tracking
jwt:sessions:<userId>           ── Active user session descriptor list
rate:ip:<ip_hash>               ── IP-level request counter
rate:user:<userId>              ── Account-level request counter
tenant:<org_id>:kpi:<hash>      ── Cached KPI calculations (Strict tenant isolation)
```

### Defense Against Cache Bleed
- An API request for Tenant A will never query or access keys prefixed with Tenant B's organization ID.
- Cache invalidation events (e.g. `clearTenantKpiCache(orgId)`) target only that specific tenant's prefix.

---

## 3. Data Protection in Redis

1. **No Plaintext Tokens**:
   - Refresh tokens are hashed using SHA-256 before being used as key identifiers or values in Redis.
   - Leaking a Redis snapshot or dump does NOT reveal valid refresh tokens.
2. **Strict TTL Bounding**:
   - All session and cache keys have strict time-to-live expiration values.
   - Orphaned cache records expire automatically without manual intervention.
3. **Payload Bounds**:
   - Cache values are serialized JSON objects with size checks, preventing cache pollution or memory ballooning.
