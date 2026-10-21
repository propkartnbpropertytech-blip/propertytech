# PropKart Service & Use-Case Layer Engineering Standard

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`src/modules/*/*.service.js`)  

---

## 1. Role & Domain Invariants of the Service Layer

The Service layer encapsulates the **business rules, domain invariants, and operational workflows** of PropKart. It is the core intellectual property of the platform.

### Core Responsibilities
1. **Business Invariant Validation:** Enforces CRM rules (e.g., duplicate phone check before lead insertion, status transitions, role permission boundaries).
2. **Transaction Demarcation:** Wraps multi-table mutations in PostgreSQL ACID transactions via `withTransaction(...)`.
3. **Audit Trail Logging:** Records state changes via `AuditService.log(...)` for all critical business events.
4. **Cache Orchestration:** Integrates `CacheService.getOrSet(...)` to ensure single-flight cache stampede protection and optimal latency.
5. **Transport Agnosticism:** Services know NOTHING about HTTP. They accept plain JavaScript arguments and return plain JavaScript domain objects.

---

## 2. Canonical Service Pattern

```javascript
// ✅ CANONICAL SERVICE PATTERN
import { SearchRepository } from "./search.repository.js";
import { CacheService } from "../../services/cache.service.js";
import { BadRequestError } from "../../utils/errors.js";

export class SearchService {
    /**
     * Executes cached, sanitized search across active properties
     */
    static async searchProperties({ user, searchTerm, limit, offset }) {
        const orgId = user?.organization_id;
        if (!orgId) {
            throw new BadRequestError("Organization context is required for property search.");
        }

        const safeTerm = String(searchTerm || "").trim().toLowerCase();
        const cacheKey = CacheService.buildKey(orgId, "search", `prop:${safeTerm}:${limit}:${offset}`);

        return CacheService.getOrSet(
            cacheKey,
            async () => {
                return SearchRepository.searchProperties({
                    orgId,
                    searchTerm: safeTerm,
                    limit,
                    offset
                });
            },
            60 // 60s TTL for fast search results
        );
    }
}

export default SearchService;
```

---

## 3. Transaction Management in Services

When a business operation touches multiple database tables (e.g., transferring a lead to sales, closing a deal, reassigning quotas), it **MUST** use `withTransaction`:

```javascript
import { withTransaction } from "../../config/dbPool.js";
import { AuditService } from "../../services/audit.service.js";

static async transferLeadToSales({ leadId, salesUserId, actorUser }) {
    return withTransaction(async (client) => {
        // 1. Update lead record
        await client.query(
            `UPDATE leads SET assigned_to = $1, stage = 'SALES' WHERE id = $2`,
            [salesUserId, leadId]
        );

        // 2. Insert lead history record
        await client.query(
            `INSERT INTO lead_history (lead_id, changed_by, action) VALUES ($1, $2, 'TRANSFER')`,
            [leadId, actorUser.id]
        );

        // 3. Log audit event
        await AuditService.log({
            userId: actorUser.id,
            action: "LEAD_TRANSFER",
            recordId: leadId
        });

        return { success: true, leadId, assignedTo: salesUserId };
    });
}
```

---

## 4. Sub-Domain Decomposition & Monolith Splitting

When a service grows beyond **800 lines**, it must be decomposed into sub-domain services:
- **Case Study 1: `integrations.service.js` (4,624 lines):**
  - Campaign column preferences were decoupled into `src/modules/integrations/campaignColumns.service.js` (110 lines).
  - Parent `IntegrationsService` acts as a facade delegating column operations to `CampaignColumnsService`.
- **Case Study 2: `kpi.service.js` (5,541 lines):**
  - All date filtering, canonical SQL definitions, and column mapping helpers were extracted to `src/modules/dashboard/kpi/kpi.definitions.js`.

---

## 5. Standard Error Domain Usage

Services never invoke `res.status(...)`. Instead, they throw typed domain errors:
- `BadRequestError`: Invalid business inputs or missing prerequisites (400).
- `UnauthorizedError`: Missing authentication credentials (401).
- `ForbiddenError`: Tenant or role permission violation (403).
- `NotFoundError`: Target entity does not exist or has been soft-deleted (404).
- `ConflictError`: Unique constraint collision or concurrent conflict (409).
