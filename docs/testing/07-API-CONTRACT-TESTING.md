# 07 — API Contract Testing & Canonical Envelope Specification

## 1. Principles & Objectives

PropKart enforces strict API contract consistency between the Node.js backend services and the Flutter client applications. Contract testing ensures that neither backend refactoring nor frontend updates can introduce schema drift, missing fields, type mismatches, or unhandled error envelopes.

---

## 2. Canonical API Response Envelopes

Every HTTP endpoint exposed by the PropKart API must strictly adhere to one of the two canonical envelope formats.

### 2.1 Success Envelope
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "requestId": "req-98f2b7a1-c812",
    "timestamp": "2026-10-21T14:15:00.000Z",
    "page": 1,
    "limit": 20,
    "total": 142
  }
}
```

- `success`: Always boolean `true`.
- `data`: Object, Array, or `null` containing the primary payload.
- `meta`: Standardized metadata object containing request tracing identifier, ISO-8601 timestamp, and optional pagination or telemetry information.

### 2.2 Error Envelope
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Invalid input parameters provided.",
    "details": [
      {
        "field": "budgetMax",
        "issue": "Must be greater than budgetMin"
      }
    ]
  },
  "meta": {
    "requestId": "req-98f2b7a1-c812",
    "timestamp": "2026-10-21T14:15:00.000Z"
  }
}
```

- `success`: Always boolean `false`.
- `error.code`: High-level uppercase snake_case machine-readable error string.
- `error.message`: Human-readable explanation.
- `error.details`: Optional array of specific field-level validation issues or context objects.
- **Security Rule:** Stack traces and internal database error messages must never be leaked into `error.message` or `error.details`.

---

## 3. Standard HTTP Status Code Matrix

| Status Code | Semantics | Typical Scenario |
|:---|:---|:---|
| **200 OK** | Request succeeded | Successful GET, PUT, or DELETE. |
| **201 Created** | Resource created | Successful POST creating a record (Lead, Property, Requirement). |
| **400 Bad Request** | Malformed request syntax | Invalid query parameters, unparseable JSON. |
| **401 Unauthorized** | Missing or invalid auth | Expired JWT, missing Bearer token, invalid signature. |
| **403 Forbidden** | Insufficient permissions | Role cannot perform action or cross-tenant access attempt. |
| **404 Not Found** | Resource does not exist | Invalid ID or soft-deleted record. |
| **409 Conflict** | State collision | Duplicate unique field (email/phone) or optimistic concurrency failure. |
| **422 Unprocessable**| Schema validation failure| Input fails Zod/Joi field validation rules. |
| **500 Server Error** | Internal exception | Unhandled server error (returns sanitized error envelope). |

---

## 4. Dual-Sided Contract Verification

### 4.1 Backend Route Contract Assertions
All backend route tests verify the structure of responses using automated assertions:

```javascript
// Test helper for contract verification
export function assertCanonicalSuccess(res, expectedStatus = 200) {
  assert.strictEqual(res.status, expectedStatus);
  assert.strictEqual(res.body.success, true);
  assert.ok(res.body.data !== undefined, 'Response must contain data');
  assert.ok(res.body.meta, 'Response must contain meta');
  assert.ok(res.body.meta.requestId, 'Meta must contain requestId');
  assert.ok(res.body.meta.timestamp, 'Meta must contain timestamp');
}

export function assertCanonicalError(res, expectedStatus, expectedCode) {
  assert.strictEqual(res.status, expectedStatus);
  assert.strictEqual(res.body.success, false);
  assert.ok(res.body.error, 'Response must contain error object');
  assert.strictEqual(res.body.error.code, expectedCode);
  assert.ok(typeof res.body.error.message === 'string');
}
```

### 4.2 Flutter Client Deserialization Testing
On the Flutter client, all model classes have corresponding unit tests that verify:
1. Parsing from complete canonical JSON responses.
2. Parsing with optional fields missing or `null` without throwing `TypeError`.
3. Round-trip serialization (`toJson(fromJson(json)) == json`).
4. Proper fallback handling for unknown enum values.

```dart
test('RequirementModel deserializes canonical API payload without error', () {
  final json = {
    'id': 'req-123',
    'tenantId': 'tenant-abc',
    'clientId': 'user-456',
    'budgetMin': 5000000,
    'budgetMax': 10000000,
    'locationPreferences': ['Whitefield', 'Sarjapur'],
    'status': 'ACTIVE',
    'createdAt': '2026-10-21T14:00:00.000Z',
  };

  final model = RequirementModel.fromJson(json);
  expect(model.id, equals('req-123'));
  expect(model.budgetMin, equals(5000000));
  expect(model.locationPreferences, hasLength(2));
});
```
