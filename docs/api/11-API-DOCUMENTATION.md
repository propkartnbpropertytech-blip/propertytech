# 11 — API DOCUMENTATION & AI-AGENT MAINTAINABILITY STANDARDS

## 1. Principles of Maintainable API Engineering

As PropKart evolves through multi-agent AI pair-programming and distributed engineering teams, code clarity, module boundaries, and contract stability are critical requirements.

Every API module must be:
1. **Self-Documenting**: Route paths, accepted query parameters, mutation schemas, and return DTOs must be immediately inferrable from the route file and its associated Zod schema.
2. **Context-Friendly**: Controllers, services, and repositories must adhere to strict size ceilings so that any single file can fit comfortably within an AI agent's active reasoning context without truncation.
3. **Strictly Layered**: Code in a controller must never perform database access or SQL manipulation.

---

## 2. API Contract Specification Format

Every endpoint in PropKart must adhere to this standardized specification format:

```text
METHOD /api/v1/{resource}/{sub-resource}
Description: Brief summary of business purpose.
Authentication: Required | Public | Optional
Required Permissions: ["permission.name"]
Rate Limit Tier: standard | mutation | sensitive | auth

Headers:
  Authorization: Bearer <jwt> (if authenticated)
  Idempotency-Key: <uuid> (recommended for POST/PUT)
  X-Request-Id: <uuid> (optional, returned in response)

Query Parameters:
  page: integer (>= 1, default 1)
  limit: integer (1..100, default 25)
  search: string (sanitized, optional)

Request Body:
  Validated via Zod schema (e.g. EntityCreateSchema)

Response Codes:
  200 OK / 201 Created: Standard success envelope { success: true, message, data }
  400 Bad Request: Validation failure { success: false, errorCode: "VALIDATION_ERROR", details }
  401 Unauthorized: Expired/missing token
  403 Forbidden: Insufficient permissions
  409 Conflict: Concurrent duplicate submission
```

---

## 3. Codebase File Size & Modularity Ceilings

To preserve AI-agent reasoning quality and prevent monolithic sprawl, the following limits are established:

| Code Layer | Target Size | Maximum Allowed Ceiling | Enforcement Action |
| :--- | :---: | :---: | :--- |
| **Routes File** (`*.routes.js`) | 50 – 150 lines | 250 lines | Split by resource sub-domain |
| **Controller File** (`*.controller.js`) | 100 – 300 lines | 500 lines | Split into specialized sub-controllers |
| **Service File** (`*.service.js`) | 150 – 400 lines | 600 lines | Split into domain services & use cases |
| **Repository File** (`*.repository.js`) | 150 – 400 lines | 600 lines | Split queries into domain entity repositories |
| **Validation Schema** (`*.schemas.js`) | 50 – 200 lines | 350 lines | Group into domain schema files |

### Monolith Refactoring Target for Step 5:
- `integrations.service.js` (4,688 lines) → Split into `meta.service.js`, `housing.service.js`, `portal.service.js`.
- `auth.controller.js` (1,363 lines) → Split into `auth.controller.js`, `mfa.controller.js`, `session.controller.js`.
- `properties.controller.js` (1,162 lines) → Split into `properties.controller.js`, `propertyMedia.controller.js`, `propertyExport.controller.js`.

---

## 4. Contract Verification Test Discipline

No API contract change may be committed without an accompanying automated test in `test/`:
- **Header Tests**: Verify `X-Request-Id`, `Cache-Control`, and `Idempotency-Key` headers.
- **Pagination Tests**: Verify that limit clamping prevents database exhaustion.
- **Error Tests**: Verify that raw database error codes are sanitized and never leak SQL.
- **Status Code Tests**: Verify that success responses return 200/201 and not 200 with `{ error: true }`.
