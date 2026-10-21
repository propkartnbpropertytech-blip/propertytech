# PropKart Repository Layer Engineering Standard

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`src/modules/*/*.repository.js`)  

---

## 1. Role & Responsibilities of the Repository Layer

The Repository layer is the sole authorized gateway to persistent data stores in PropKart. It abstracts the database implementation details (PostgreSQL queries, Supabase PostgREST, indexes, joins) from the business domain layer.

### Core Responsibilities
1. **Parameterized SQL Execution:** Execute raw SQL via `dbPool.query(sql, params)` or query builders with strictly bound parameters (`$1, $2`).
2. **Tenant Scoping:** Always apply tenant filters (`organization_id = $X` or `applyOrgFilter(query, user)`).
3. **Soft-Delete Guard:** Always include `deleted_at IS NULL` on all active entity queries.
4. **Data Hydration & Mapping:** Map raw SQL result rows into clean JavaScript entity objects.
5. **No Transport Logic:** ZERO references to Express, `req`, `res`, HTTP headers, or status codes.

---

## 2. Canonical Method Signature & Design Pattern

Repositories must use static methods with **destructured object parameters** for extensibility and readability:

```javascript
// ✅ CANONICAL REPOSITORY PATTERN
import { dbPool } from "../../config/dbPool.js";

export class SearchRepository {
    /**
     * Executes universal search across active property inventory
     */
    static async searchProperties({ orgId, searchTerm, limit = 50, offset = 0 }) {
        const conditions = [`p.deleted_at IS NULL`];
        const params = [];

        if (orgId) {
            params.push(orgId);
            conditions.push(`p.organization_id = $${params.length}`);
        }

        if (searchTerm) {
            params.push(`%${searchTerm}%`);
            conditions.push(`(p.title ILIKE $${params.length} OR p.property_code ILIKE $${params.length})`);
        }

        params.push(limit);
        const limitParam = `$${params.length}`;
        params.push(offset);
        const offsetParam = `$${params.length}`;

        const sql = `
            SELECT 
                p.id, p.property_code, p.title, p.price, p.locality,
                pc.name as category_name, ps.name as status_name
            FROM properties p
            LEFT JOIN property_categories pc ON p.category_id = pc.id
            LEFT JOIN property_status ps ON p.property_status_id = ps.id
            WHERE ${conditions.join(" AND ")}
            ORDER BY p.created_at DESC
            LIMIT ${limitParam} OFFSET ${offsetParam}
        `;

        const result = await dbPool.query(sql, params);
        return result.rows;
    }
}

export default SearchRepository;
```

---

## 3. Strict Rules & Anti-Patterns

| Anti-Pattern | Why It Is Forbidden | Correct Pattern |
| :--- | :--- | :--- |
| `String interpolation in SQL`:  `"WHERE id = '" + id + "'"` | SQL Injection vulnerability | Parameterized placeholders: `WHERE id = $1` |
| `res.status(500).json(...)` in Repository | Couplings persistence to HTTP transport | Throw Error upward to Service / Controller |
| Querying without `deleted_at IS NULL` | Data integrity violation; revives soft-deleted rows | Always check `deleted_at IS NULL` |
| Missing `organization_id` filter | Multi-tenant data leak | Always scope queries by tenant ID |
| Direct cache reading in Repository | Violates separation of concerns | Services coordinate `CacheService` around Repositories |

---

## 4. Newly Refactored Repositories in Step 5

During Step 5, the following feature repositories were introduced to decouple formerly bloated controllers:
1. `src/modules/export/export.repository.js`: Encapsulates heavy streaming queries for Requirements, Properties, Leads, and Executive XLSX sheets.
2. `src/modules/search/search.repository.js`: Universal keyword and metadata search queries.
3. `src/modules/checklist/checklist.repository.js`: Lead verification task queries and transitions.
4. `src/modules/notifications/notifications.repository.js`: Direct alerts query and mark-read queries.
5. `src/modules/usage/usage.repository.js`: Telemetry counters and usage metrics.
6. `src/modules/places/places.repository.js`: Localities and places caching data access.
