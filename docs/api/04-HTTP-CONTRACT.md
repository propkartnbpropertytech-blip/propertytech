# 04 — HTTP PROTOCOL & STATUS CODE CONTRACT

## 1. HTTP Methods & Semantic Rules

The PropKart API adheres strictly to RFC 9110 HTTP semantics:

| HTTP Verb | Operation Semantics | Idempotent? | Safe? | Typical Response Codes |
| :--- | :--- | :---: | :---: | :--- |
| **GET** | Retrieve resource or collection representation | Yes | Yes | 200 OK, 304 Not Modified |
| **POST** | Create a new entity or execute a stateful command | No (without key) | No | 201 Created, 200 OK, 400, 409 |
| **PUT** | Replace an entire resource with new representation | Yes | No | 200 OK, 400, 404 |
| **PATCH** | Update specific fields of an existing resource | Yes | No | 200 OK, 400, 404 |
| **DELETE** | Soft-delete a resource (sets `deleted_at = NOW()`) | Yes | No | 200 OK, 204 No Content, 404 |
| **OPTIONS** | Pre-flight CORS negotiation | Yes | Yes | 204 No Content |

---

## 2. Standard HTTP Status Codes

PropKart APIs return standard HTTP status codes. Controllers and error middleware MUST NOT return `200 OK` with an embedded error status (anti-pattern).

### 2.1 Success Status Codes (2xx)
- **`200 OK`**: Standard response for successful `GET`, `PATCH`, `PUT`, or state transitions.
  ```json
  {
    "success": true,
    "message": "Properties retrieved successfully",
    "data": { ... }
  }
  ```
- **`201 Created`**: Returned by `POST` endpoints that successfully insert a new resource (e.g. `POST /api/v1/properties`, `POST /api/v1/requirements`).
- **`204 No Content`**: Returned on pre-flight CORS or operations where no response body is needed.

### 2.2 Client Error Status Codes (4xx)
- **`400 Bad Request`**: Malformed JSON, missing required headers, schema validation failure, or foreign key invalidity (`INVALID_REFERENCE`).
- **`401 Unauthorized`**: Missing Bearer token, expired JWT, revoked token JTI, or mismatched session version (`UNAUTHORIZED`, `TOKEN_REVOKED`).
- **`403 Forbidden`**: Authenticated user lacks RBAC permission or attempted cross-tenant access (`ACCESS_DENIED`, `NO_ORGANIZATION`).
- **`404 Not Found`**: Target resource ID does not exist, or unmapped URL route (`NOT_FOUND`, `ROUTE_NOT_FOUND`).
- **`409 Conflict`**: Unique constraint violation (e.g. duplicate mobile number), or duplicate in-flight idempotent request (`DUPLICATE_RECORD`, `IDEMPOTENT_REQUEST_IN_FLIGHT`).
- **`422 Unprocessable Entity`**: Payload schema is valid JSON but violates domain logic (e.g. possession date in the past for pre-launch property).
- **`429 Too Many Requests`**: Rate limit exceeded on login, OTP, or general API window (`RATE_LIMIT_EXCEEDED`).

### 2.3 Server Error Status Codes (5xx)
- **`500 Internal Server Error`**: Unexpected application or database failure. Handled by `errorMiddleware`. SQL queries and stack traces are stripped in production to prevent information disclosure.
- **`503 Service Unavailable`**: Database connection pool exhausted or health probe failure (`DATABASE_UNAVAILABLE`).

---

## 3. Mandatory HTTP Headers

### 3.1 Request Headers
- `Authorization: Bearer <jwt_access_token>` (Mandatory for authenticated endpoints)
- `X-Request-Id: <uuid>` (Optional; generated if absent, propagated through all logs and responses)
- `Idempotency-Key: <unique-string>` (Recommended for `POST` mutations; maximum 128 characters)
- `Content-Type: application/json` (Required for request bodies)

### 3.2 Response Headers
- `X-Request-Id: <uuid>` (Matches request trace)
- `X-Correlation-Id: <uuid>` (Standard correlation alias)
- `Cache-Control: no-store, no-cache, must-revalidate, proxy-revalidate` (Enforced on all `/api/v1` routes to prevent client caching of tenant data)
- `X-Idempotent-Replay: true` (Included when response is served from the idempotency cache)
