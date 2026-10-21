# 04 — PROPKART API ERROR CONTRACT (STEP 8.4)

## 1. Primary Objective

Defines the centralized error response architecture, stable machine-readable error codes, HTTP status mappings, and zero-leakage security boundaries.

---

## 2. Standard Error Response Envelope

All error responses (HTTP 4xx and 5xx) adhere to the following schema:

```json
{
  "success": false,
  "message": "Human-readable explanation suitable for frontend toast or alert",
  "errorCode": "MACHINE_READABLE_ERROR_CODE",
  "requestId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "errors": [
    {
      "field": "startDate",
      "message": "startDate cannot be after endDate"
    }
  ]
}
```

---

## 3. Canonical Error Code Registry

| HTTP Status | Canonical `errorCode` | Description & Trigger Context |
| :--- | :--- | :--- |
| **400** | `BAD_REQUEST` | Malformed JSON, illegal query syntax, unparseable payload |
| **400** | `VALIDATION_ERROR` | Schema validation failure (Zod `superRefine`, out-of-bounds dates) |
| **400** | `INVALID_REFERENCE` | Foreign key violation (sanitized from PostgreSQL error `23503`) |
| **401** | `UNAUTHORIZED` | Missing or unparseable Bearer authentication header |
| **401** | `INVALID_TOKEN` | Malformed, corrupted, or expired JWT access token |
| **401** | `TOKEN_REVOKED` | Token JTI identified on Redis revocation list |
| **403** | `ACCESS_DENIED` | Valid credentials, but insufficient RBAC role or tenant boundary violation |
| **404** | `ROUTE_NOT_FOUND` | Unmapped API endpoint or missing URI route |
| **404** | `NOT_FOUND` | Referenced entity ID does not exist in tenant domain |
| **409** | `DUPLICATE_RECORD` | Unique constraint violation (sanitized from PostgreSQL error `23505`) |
| **409** | `CONCURRENCY_CONFLICT` | Deadlock / serialization failure (sanitized from PostgreSQL `40P01`) |
| **429** | `RATE_LIMIT_EXCEEDED` | Request rate ceiling reached for client IP or API key |
| **500** | `INTERNAL_SERVER_ERROR`| Unhandled server exception (strictly sanitized, zero internal leakage) |

---

## 4. Zero Data Leakage Policy

In accordance with PropKart security mandates, all error responses adhere to the following guarantees:
1. **Zero Raw SQL**: Error strings containing `SELECT`, `UPDATE`, `DELETE`, `FROM public.`, or column names are stripped by `sanitizeDatabaseError()`.
2. **Zero Internal Paths**: File paths (e.g., `C:\NB\...`, `/var/app/...`) and node module internals are omitted in non-development environments.
3. **Zero Stack Traces in Production**: `err.stack` is strictly withheld from HTTP response bodies.
4. **Correlation Propagation**: `requestId` is included in all error responses, allowing developers to correlate frontend error reports directly with backend Pino/CloudWatch structured logs.
