# 06 — STANDARDIZED ERROR CONTRACT & SANITIZATION

## 1. Canonical Error Response Envelope

All API error responses in PropKart follow a strict JSON schema. This structure provides human-readable explanations for frontend users, stable machine-readable codes for Flutter logic, and a correlation tracking ID for debugging.

```json
{
  "success": false,
  "message": "The referenced entity was not found or cannot be linked.",
  "errorCode": "INVALID_REFERENCE",
  "details": [
    {
      "field": "category_id",
      "issue": "Category ID does not correspond to an active property category."
    }
  ],
  "requestId": "5e13d99e-7110-4f51-b0be-d069b188c81e"
}
```

---

## 2. Standardized Error Domain Hierarchy

In Step 2 (`src/utils/errors.js`), PropKart introduced a clean class-based error hierarchy extending `AppError`:

```
AppError (Base, 500)
├── BadRequestError (400, "BAD_REQUEST")
├── ValidationError (400, "VALIDATION_ERROR")
├── UnauthorizedError (401, "UNAUTHORIZED")
├── ForbiddenError (403, "ACCESS_DENIED")
├── NotFoundError (404, "NOT_FOUND")
└── ConflictError (409, "CONFLICT")
```

Controllers throw these errors directly or delegate to `handleControllerError(res, error, defaultMsg)`.

---

## 3. Database Error Sanitization (SQL Defense)

To prevent security vulnerabilities, schema reconnaissance, and accidental leakage of sensitive database information, `sanitizeDatabaseError(err)` intercepts raw PostgreSQL errors and maps them to sanitized domain errors:

| PostgreSQL Code | PostgreSQL Meaning | Sanitized Status | Sanitized `errorCode` | Sanitized Client Message |
| :--- | :--- | :---: | :--- | :--- |
| **`23505`** | unique_violation | 409 | `DUPLICATE_RECORD` | *"A record with this information already exists."* |
| **`23503`** | foreign_key_violation | 400 | `INVALID_REFERENCE` | *"The referenced entity was not found or cannot be linked."* |
| **`23502`** | not_null_violation | 400 | `MISSING_REQUIRED_FIELD` | *"A required database field was not provided."* |
| **`22P02`** | invalid_text_representation | 400 | `INVALID_DATA_FORMAT` | *"Invalid identifier or data format provided."* |
| **`23514`** | check_violation | 400 | `CHECK_CONSTRAINT_VIOLATION` | *"The submitted data violates database domain constraints."* |
| **`40P01`** | deadlock_detected | 409 | `CONCURRENCY_CONFLICT` | *"The operation encountered a temporary concurrency conflict. Please retry."* |
| **`40001`** | serialization_failure | 409 | `CONCURRENCY_CONFLICT` | *"The operation encountered a temporary concurrency conflict. Please retry."* |
| **`57014`** | query_canceled (timeout) | 504 | `QUERY_TIMEOUT` | *"The operation timed out. Please narrow your query filter."* |

> [!CAUTION]
> Raw database error properties (`err.detail`, `err.table`, `err.constraint`, `err.query`) are **never** returned in the HTTP response. They are logged server-side tagged with the `requestId`.

---

## 4. Unhandled Error Middleware (`src/middleware/error.middleware.js`)

All unhandled exceptions fall through to the global Express error middleware:

1. **Correlation Logging**: Logs `[UnhandledError:<requestId>] <stack>` via Winston.
2. **Error Monitoring**: Captures 5xx exceptions in Sentry / GlitchTip via `errorMonitoring.captureException(err, req)`.
3. **Production Masking**: In `production` environment, 500 error messages are sanitized to `"An unexpected server error occurred."` with the correlation `requestId` for support reference.
