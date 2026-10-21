# PropKart Controller Layer Engineering Standard

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`src/modules/*/*.controller.js`)  

---

## 1. Role & Architectural Boundaries of Controllers

In PropKart’s layered architecture, a Controller is strictly an **HTTP Transport Adapter**. Its sole reason for existence is to translate between the HTTP network layer (headers, parameters, body, status codes) and the internal domain services.

```text
HTTP Request (Express) ──► Controller ──► Service (Domain)
                                │
HTTP Response (JSON)  ◄────────┴──────── Service Result
```

### Mandatory Invariants:
1. **NO DIRECT SQL:** Controllers must NEVER import `dbPool` or execute raw SQL queries.
2. **NO DIRECT SUPABASE DATA QUERIES:** Controllers must NEVER query `supabase.from(...)` directly.
3. **NO DIRECT REDIS:** Controllers must NEVER import or invoke Redis clients directly.
4. **NO BUSINESS RULES:** Business logic, status transition rules, and validation of business state belong exclusively in the Service layer.

---

## 2. Canonical Controller Pattern

```javascript
// ✅ CANONICAL CONTROLLER PATTERN
import { SearchService } from "./search.service.js";
import { handleControllerError } from "../../utils/errors.js";

export class SearchController {
    /**
     * Handles universal property search requests
     */
    static async searchProperties(req, res) {
        try {
            const { q, limit, offset } = req.query;
            const user = req.user;

            const results = await SearchService.searchProperties({
                user,
                searchTerm: q,
                limit: limit ? parseInt(limit, 10) : 50,
                offset: offset ? parseInt(offset, 10) : 0
            });

            return res.status(200).json({
                success: true,
                data: results
            });
        } catch (error) {
            return handleControllerError(error, res);
        }
    }
}

export default SearchController;
```

---

## 3. Standard Response Envelopes & HTTP Status Codes

PropKart APIs strictly adhere to standardized response envelopes across all endpoints.

### Standard Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Standard Error Response
```json
{
  "success": false,
  "message": "Descriptive, non-leaking error explanation",
  "errorCode": "VALIDATION_FAILED",
  "details": []
}
```

### Standard HTTP Status Codes

| Code | Meaning | When to Use |
| :--- | :--- | :--- |
| `200` | OK | Successful GET, PUT, PATCH, or non-resource-creation POST |
| `201` | Created | Successfully created a new entity (POST /properties) |
| `204` | No Content | Successful DELETE with no return payload |
| `400` | Bad Request | Malformed payload, invalid query parameters, validation failure |
| `401` | Unauthorized | Missing, expired, or revoked JWT access token |
| `403` | Forbidden | Authenticated user lacks permission (RBAC or cross-tenant) |
| `404` | Not Found | Requested entity does not exist or has been soft-deleted |
| `409` | Conflict | Duplicate unique key collision (e.g. duplicate lead phone) |
| `429` | Too Many Requests | Rate limit ceiling reached |
| `500` | Internal Error | Unhandled server exception (sanitized in production) |

---

## 4. Error Handling Protocol: `handleControllerError`

To prevent SQL leakage, stack trace exposure, and inconsistent error structures, controllers route all errors through `handleControllerError(error, res)`:
- Maps `AppError` subclasses to their declared status code and `errorCode`.
- Maps PostgreSQL constraint violations (e.g., `23505` unique violation) to safe HTTP `409 Conflict` messages without leaking internal table or column names.
- Maps unhandled unexpected exceptions to `500 Internal Server Error` with masked error descriptions while logging full diagnostic traces to Winston.
