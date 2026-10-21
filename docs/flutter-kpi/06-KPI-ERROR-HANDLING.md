# PROPKART KPI ERROR ARCHITECTURE
## Step 8.5 Machine-Readable Error Parsing, Leakage Prevention & Offline Resilience

**Document Version:** 1.0.0  
**Status:** Certified Architecture  
**Scope:** Client Exception Parsing, Correlation Tracking & Security Leakage Masking  

---

## 1. Step 8.4 Error Contract Integration

The Flutter client integrates directly with the Step 8.4 Machine-Readable Error Contract:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid date range: 'startDate' (2026-12-31) must be before or equal to 'endDate' (2026-01-01).",
    "details": [
      {
        "field": "startDate",
        "issue": "startDate cannot be after endDate"
      }
    ]
  },
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## 2. `ApiException` Architecture

`ApiException` parses both legacy error objects and modern Step 8.4 structured envelopes:

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final String? requestId;
  final List<dynamic>? details;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.requestId,
    this.details,
  });

  factory ApiException.fromDioException(DioException dioException) {
    // Extracts structured code, message, details, and correlation requestId
    // from headers or payload
  }
}
```

---

## 3. Security Leakage Prevention

To protect internal schema structures and server integrity:
- **Zero Raw SQL in UI:** If a database error or unhandled backend failure leaks through, `ApiException` catches PostgreSQL markers (`syntax error`, `relation does not exist`, `pg_`, `column does not exist`) and masks them:
  ```dart
  if (message.contains('syntax error at or near') ||
      message.contains('relation') && message.contains('does not exist') ||
      message.contains('pg_') ||
      message.contains('column') && message.contains('does not exist')) {
    message = "A database processing error occurred. Please contact support.";
    code ??= "INTERNAL_SERVER_ERROR";
  }
  ```
- **Correlation ID Tracking:** In all error toasts and logs, the `requestId` is retained for developer tracing without exposing internal stack traces.

---

## 4. Network Retry & Offline Degradation

1. **User-Triggered Retry:**
   When an error occurs during dashboard loading, `DashboardError` is emitted with the friendly message. The UI displays a retry button triggering `LoadDashboard()`.
2. **Offline Mode:**
   If network is completely disconnected (`NETWORK_ERROR` / `connectionError`), the client retrieves the most recent local Isar snapshot, preserving operational continuity.
