# 06 — MULTI-TENANT ISOLATION ARCHITECTURE

## 1. Multi-Tenant Tenets

In PropKart, tenant isolation is a non-negotiable architectural requirement. Every brokerage operates as a separate organization.
- **Tenant Key**: `organization_id` (UUID format).
- **Mandatory Server Enforcement**: Every tenant-scoped database query and API operation attaches `organization_id` derived exclusively from the authenticated user's session token.
- **Never Trust Client Inputs**: Any `organization_id`, `tenant_id`, or `admin_id` supplied in request bodies, path parameters, or query strings is ignored or strictly verified against the user's authentic session context.

---

## 2. Server-Side Enforcement Mechanisms

### 2.1 Middleware & Context Assertion (`tenant.js`)
```javascript
export function applyOrgFilter(query, user) {
    if (!isSuperAdmin(user)) {
        return query.eq("organization_id", user.organization_id);
    }
    return query;
}

export function stampTenantFields(user) {
    return {
        created_by: user.id,
        organization_id: user.organization_id,
        admin_id: user.admin_id,
    };
}
```

### 2.2 Architectural Guard Assertion (`architecturalGuard.js`)
```javascript
export function assertTenantContext(user, entityName = "record", { resourceOrgId = null, crossTenant = false } = {}) {
    if (!user) throw new TenantViolationError("TENANT_CONTEXT_MISSING");
    if (isSuperAdmin(user)) return crossTenant ? null : user.organization_id;
    if (!user.organization_id) throw new TenantViolationError("TENANT_CONTEXT_MISSING");
    if (resourceOrgId && user.organization_id !== resourceOrgId) {
        throw new TenantViolationError(`[TENANT_ISOLATION_VIOLATION] Cross-tenant access forbidden`);
    }
    return user.organization_id;
}
```

---

## 3. Database-Level Schema Contracts

All primary business domain tables in PostgreSQL enforce the presence of `organization_id`:
- `leads.organization_id`
- `requirements.organization_id`
- `properties.organization_id`
- `users.organization_id`
- `followups.organization_id`
- `site_visits.organization_id`
- `clients.organization_id`
- `owners.organization_id`

Database schema contract verification is automated via `test/architecture.contract.test.js`, ensuring no new table or migration can omit tenant partitioning.

---

## 4. Cache & Realtime Isolation

1. **Redis Cache Namespace**:
   Cache keys follow strict tenant prefixing: `tenant:{organization_id}:kpi:...`
   Cross-tenant cache bleed is architecturally prevented.
2. **WebSocket Realtime Subscriptions**:
   Replication payloads are scoped by organization before being emitted over Phoenix WebSocket channels.

---

## 5. Client-Side Device Wipe (`SessionCleanup`)

When a user logs out or switches accounts:
- In-memory repository stores (`PropertyLocalRepository.inMemory`, etc.) are purged.
- Isar local collections are wiped via `IsarService().clearAll()`.
- User-scoped SharedPreferences keys (e.g. `cached_properties`, `cached_requirements`, `shortlisted_properties`) are deleted.
- Pending Outbox mutation queues are cleared to prevent cross-tenant delivery.
