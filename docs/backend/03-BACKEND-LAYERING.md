# PropKart Backend Layering Architecture & Protocols

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`PropKart-Backend`)  
> **Layer Flow:** `Route -> Middleware -> Controller -> Service -> Repository -> PostgreSQL / Redis`  

---

## 1. Architectural Topology Overview

PropKart enforces a strict unidirectional dependency graph across 6 distinct architectural layers. Flow of control moves strictly top-to-bottom. Upward dependencies or cross-layer short-circuiting are architectural violations.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PROPKART 6-LAYER TOPOLOGY                             │
├─────────────────┬───────────────────────────────────────────────────────────┤
│ Layer           │ Responsibilities & Invariants                             │
├─────────────────┼───────────────────────────────────────────────────────────┤
│ 1. Routes       │ Defines HTTP URL endpoints, HTTP methods, mounts         │
│                 │ rate-limits and authentication. ZERO domain logic.        │
├─────────────────┼───────────────────────────────────────────────────────────┤
│ 2. Middleware   │ Request validation (Zod), JWT token verification,        │
│                 │ tenant context stamping, RBAC boundary assertion.         │
├─────────────────┼───────────────────────────────────────────────────────────┤
│ 3. Controllers  │ Unmarshals req.params/query/body, checks req.user claims, │
│                 │ delegates to Service, returns standardized JSON envelope.  │
│                 │ FORBIDDEN: Direct SQL, supabase queries, redis calls.      │
├─────────────────┼───────────────────────────────────────────────────────────┤
│ 4. Services     │ Pure business logic, lifecycle workflows, cross-entity    │
│                 │ orchestration, transaction atomicity, audit logging.      │
│                 │ Uses CacheService for caching.                            │
├─────────────────┼───────────────────────────────────────────────────────────┤
│ 5. Repositories │ Encapsulates all SQL statements, prepared queries,        │
│                 │ Supabase PostgREST queries, and database functions.        │
│                 │ FORBIDDEN: HTTP res/req objects, status codes.             │
├─────────────────┼───────────────────────────────────────────────────────────┤
│ 6. Data/Cache   │ PostgreSQL database (Hostinger Production via dbPool)     │
│                 │ Redis Cache & Mutex Lock Engine (via CacheService)        │
└─────────────────┴───────────────────────────────────────────────────────────┘
```

---

## 2. Layer-by-Layer Specifications

### Layer 1: Route Layer (`src/modules/<feature>/<feature>.routes.js`)
- **Purpose:** Connect incoming HTTP paths to controller handler functions.
- **Rules:**
  1. Only import Express `Router`, route middleware (`authenticate`, `validate`), and `<feature>.controller.js`.
  2. Never write route callback inline logic (`router.get("/", (req, res) => { ... })`).
  3. Never import `supabase` or `dbPool` or `redis`.
  4. Mount rate limiters explicitly per endpoint type (`loginRateLimit`, `refreshRateLimit`).

```javascript
// ✅ CANONICAL ROUTE EXAMPLE
import express from "express";
import { authenticate } from "../../middleware/auth.middleware.js";
import { validate } from "../../middleware/zodValidate.middleware.js";
import { ExportController } from "./export.controller.js";

const router = express.Router();

router.get("/requirements", authenticate, ExportController.exportRequirements);
router.get("/properties", authenticate, ExportController.exportProperties);
router.get("/leads", authenticate, ExportController.exportLeads);
router.get("/executive-report", authenticate, ExportController.exportExecutiveWorkbook);

export default router;
```

---

### Layer 2: Middleware Layer (`src/middleware/`, `src/security/`)
- **Purpose:** Pre-controller processing, request sanitization, security enforcement.
- **Canonical Components:**
  - `auth.middleware.js`: Extracts and verifies JWT bearer tokens, checks token denial list (revocation), attaches `req.user`.
  - `zodValidate.middleware.js`: Validates input against strict Zod schemas; strips unwhitelisted fields; rejects malformed inputs with 400.
  - `rateLimits.js`: Protects authentication, webhook, and mutation routes with distributed or memory rate-limiting.
  - `architecturalGuard.js`: Runtime assertion guards for tenant boundaries and role boundaries.

---

### Layer 3: Controller Layer (`src/modules/<feature>/<feature>.controller.js`)
- **Purpose:** HTTP transport translation. Translates HTTP semantics into domain operations and domain results into HTTP responses.
- **Rules:**
  1. **Zero SQL:** Never import `dbPool` or execute raw SQL.
  2. **Zero Supabase Data Queries:** Never query `supabase.from(...)` directly inside a controller.
  3. **Zero Direct Redis:** Never import or call Redis commands directly.
  4. Always format responses using the standard envelope:
     ```json
     {
       "success": true,
       "message": "Optional human-readable confirmation",
       "data": { ... }
     }
     ```
  5. Use `handleControllerError(err, res)` or standardized error classes to guarantee sanitized error payloads.

```javascript
// ✅ CANONICAL CONTROLLER EXAMPLE
import logger from "../../config/logger.js";
import { ExportService } from "./export.service.js";

export class ExportController {
    static async exportRequirements(req, res) {
        try {
            const orgId = req.user?.organization_id;
            const role = req.user?.role;
            const userId = req.user?.id;

            await ExportService.streamRequirementsCsv(res, { orgId, role, userId });
        } catch (err) {
            logger.error(`[ExportController] Requirements export error: ${err.message}`);
            if (!res.headersSent) {
                res.status(500).json({ success: false, message: "Export failed" });
            } else {
                res.end();
            }
        }
    }
}
```

---

### Layer 4: Service Layer (`src/modules/<feature>/<feature>.service.js`)
- **Purpose:** Core business engine of PropKart.
- **Responsibilities:**
  - Validates domain invariants (e.g. lead status transition graphs, deposit rules, role assignments).
  - Orchestrates multi-step operations (e.g., Lead transfer -> Audit log -> Notification dispatch).
  - Coordinates database transactions via `withTransaction(...)`.
  - Coordinates caching through `CacheService.getOrSet(...)`.
- **Rules:**
  1. Never accept Express `req` or `res` objects.
  2. Never send HTTP headers or call `res.json()`.
  3. Throw standard `AppError` subclasses (`BadRequestError`, `ForbiddenError`, `NotFoundError`).

---

### Layer 5: Repository Layer (`src/modules/<feature>/<feature>.repository.js`)
- **Purpose:** Encapsulate all database interaction and data mapping.
- **Responsibilities:**
  - Raw parameterized SQL execution via `dbPool.query(sql, params)`.
  - Supabase client queries where appropriate.
  - Prepared statements and query optimization.
  - Row-to-domain object mapping.
- **Rules:**
  1. Always enforce tenant filtering (`r.organization_id = $1` or `applyOrgFilter`).
  2. Never expose SQL injection vectors; always use parameterized placeholders (`$1, $2`).
  3. Never import Express transport libraries or reference HTTP status codes.

```javascript
// ✅ CANONICAL REPOSITORY EXAMPLE
import { dbPool } from "../../config/dbPool.js";

export class ExportRepository {
    static async getRequirementsForExport({ orgId, role, userId }) {
        const conditions = [`r.deleted_at IS NULL`];
        const params = [];

        if (orgId) {
            params.push(orgId);
            conditions.push(`r.organization_id = $${params.length}`);
        }

        const sql = `
            SELECT r.id, r.customer_name, r.mobile, pc.name as category_name
            FROM requirements r
            LEFT JOIN property_categories pc ON r.category_id = pc.id
            WHERE ${conditions.join(" AND ")}
            ORDER BY r.created_at DESC
        `;
        const result = await dbPool.query(sql, params);
        return result.rows;
    }
}
```

---

### Layer 6: Data & Cache Layer (`src/config/dbPool.js`, `src/services/cache.service.js`)
- **PostgreSQL (`dbPool`):** Authoritative persistent storage. Configured with statement timeouts (15s), connection pooling (10 connections max), keepalives, and connection metrics.
- **Redis (`CacheService`):** Distributed performance and ephemeral coordination layer. Namespaced keys (`pk:<tenant>:<namespace>:<hash>`), TTLs, single-flight cache stampede protection (`getOrSet`), and distributed locks (`withLock`).
