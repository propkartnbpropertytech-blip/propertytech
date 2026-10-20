# PROPKART — API BOUNDARY ARCHITECTURE
**Version:** 1.0.0  
**Status:** CANONICAL BOUNDARY SPECIFICATION (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** Client-Server Communication, Data Contracts & Boundary Discipline  

---

## 1. Architectural Mandate

In the target architecture, all communication between the Flutter client and the backend server must be strictly mediated through an explicit 5-tier pipeline:

```text
UI (Widgets / Screens)
      ↓ Dispatches user events
Presentation State (BLoC / Cubit)
      ↓ Executes application command
Application Layer (Use Case / Facade)
      ↓ Requests domain data
Domain Repository Interface (Contract)
      ↓ Implemented by Data Layer
Data Repository Implementation
      ↓ Invokes network client
API Client (Dio singleton with interceptors)
      ↓ HTTP REST / JSON over TLS
Backend API (Express 5.x Controllers)
```

### Prohibited Anti-Patterns:
1. **No Direct HTTP in UI Widgets:** A Flutter widget must NEVER import `dio.dart`, instantiate `DioClient`, or trigger HTTP requests.
2. **No Direct HTTP in BLoC:** A BLoC must NEVER call `DioClient.dio.get(...)` directly. It must consume an abstract repository or use case.
3. **No Hardcoded Endpoints:** URL paths must not be scattered as literal strings across screen files. All endpoints must reside in a centralized, typed API registry (`ApiConstants` / `ApiEndpoints`).
4. **No Ad-Hoc Response Parsing:** Screens must not manually inspect `res.data['data']['items'][0]`. All responses must be deserialized into typed models via `fromJson` mappers in the repository layer.
5. **No Ad-Hoc Header Construction:** Authentication tokens, tenant headers, and device IDs must be attached uniformly via Dio interceptors, never manually built in individual requests.

---

## 2. Standard API Request & Response Contracts

### 2.1 Standard Success Envelope
All `/api/v1/*` endpoints must return a predictable, uniform JSON structure:

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-10-19T18:20:00.000Z",
    "version": "1.1.2",
    "pagination": {
      "page": 1,
      "limit": 25,
      "totalRecords": 350,
      "totalPages": 14,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

### 2.2 Standard Error Envelope
All backend errors returned to the client must conform to the unified error schema:

```json
{
  "success": false,
  "message": "Human-readable, user-safe error message",
  "errorCode": "RESOURCE_CONFLICT",
  "details": [
    {
      "field": "phone",
      "issue": "Phone number +919876543210 is already registered to an active lead."
    }
  ]
}
```

### 2.3 Standard HTTP Status Code Matrix
| Status Code | Meaning in PropKart | Example Scenario |
| :--- | :--- | :--- |
| **200 OK** | Standard successful retrieval or update. | Property details fetched; lead updated. |
| **201 Created** | Entity successfully created in PostgreSQL. | New property created; new requirement added. |
| **204 No Content** | Action completed successfully with no response body. | Soft delete of an image; session logout. |
| **400 Bad Request** | Schema validation failed or payload invalid. | Missing required field; invalid phone format. |
| **401 Unauthorized** | Missing or expired JWT access token. | Expired session; invalid Bearer token. |
| **403 Forbidden** | Authenticated, but role lacks required permission. | Telecaller attempting to reassign another user's lead. |
| **404 Not Found** | Target resource does not exist in tenant. | Property ID PR-9999 does not exist. |
| **409 Conflict** | Business rule invariant or unique constraint violated. | Duplicate phone number; simultaneous lead allocation race. |
| **422 Unprocessable** | Semantically invalid state transition. | Attempting to conduct a site visit on an archived lead. |
| **429 Too Many Req** | Rate limit exceeded. | More than 120 req/min from single IP or user. |
| **500 Server Error** | Unexpected unhandled server exception. | Database connection pool timeout; internal bug. |
| **503 Unavailable** | Critical dependency down or maintenance mode. | PostgreSQL unreachable; schema migration active. |

---

## 3. Mandatory Request Headers

Every request dispatched by `DioClient` must automatically include:

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <access_token>
X-Device-Id: <unique_client_hardware_uuid>
Idempotency-Key: <uuid_v4_generated_per_mutation>
```

- **Authentication Interceptor:** Injects the valid JWT Bearer token from `FlutterSecureStorage`.
- **401 Refresh Interceptor:** Intercepts 401 Unauthorized, queues pending requests, invokes `POST /auth/refresh`, and retries original requests with the new token.
- **Idempotency Interceptor:** Generates an `Idempotency-Key` UUID on `POST`, `PUT`, and `PATCH` requests to protect against duplicate transactions on poor network connections.

---

## 4. Current Architecture Boundary Violations Catalog

| File | Line | Current Anti-Pattern | Target Architecture Requirement |
| :--- | :--- | :--- | :--- |
| `lib/features/admin/bloc/lead_allocation_monitor_bloc.dart` | 99, 195 | BLoC calls `DioClient.dio.get(...)` and `DioClient.dio.post(...)` directly. | Extract to `AdminAllocationRepository` interface and implementation. BLoC consumes repository only. |
| `lib/features/requirements/screens/requirements_screen.dart` | 38, 1204, 3450 | Screen widget imports `DioClient` and calls endpoints directly inside widget methods. | Move all API calls into `RequirementsRepository`. Screen listens to `RequirementsBloc`. |
| `lib/features/campaign/screens/campaign_leads_screen.dart` | 11, 410, 890 | Screen widget makes direct Dio GET/POST calls to toggle leads and update statuses. | Route all actions through `CampaignLeadsBloc` -> `CampaignRepository`. |
| `lib/features/properties/screens/add_edit_property_screen.dart`| 45, 1100 | Screen executes direct HTTP multipart POSTs for property creation. | Move multipart upload orchestration into `PropertiesRepository.saveProperty()`. |
| `C:\NB\PropKart-Backend\src\app.js` | 204–375 | Direct inline database queries executed in `/api/v1/diagnostics/crud` route inside `app.js`. | Relocate diagnostic logic to `health.controller.js` and `health.service.js`. |

---

## 5. Migration Strategy for API Boundary

1. **Step Foundation (Current):** Document all current violations. No code is randomly broken.
2. **Dedicated API Step (Future):**
   - Refactor `DioClient` to enforce strict response envelope checking.
   - Introduce strongly-typed API route enums.
   - Create explicit remote data sources for each feature module (`features/<name>/data/datasources/remote/`).
   - Deprecate all direct `DioClient` usages outside `datasources/remote/`.
