# 09 — DISTRIBUTED IDEMPOTENCY & MUTATION SAFETY

## 1. The Distributed Mutation Risk

In mobile real estate applications, agents and external webhooks operate over unstable cellular networks:
1. **Network Drops**: An agent taps "Create Property" or "Confirm Site Visit". The server processes the record, but the connection drops before the HTTP 200 response reaches the phone.
2. **Aggressive Client Retries**: Flutter retries the HTTP request, creating duplicate properties, multiple conflicting calendar appointments, or duplicate leads.
3. **Webhook Duplicate Deliveries**: Meta, Housing, and MagicBricks webhooks guarantee at-least-once delivery; without idempotency, the same lead is created multiple times.

---

## 2. Idempotency Architecture (`src/middleware/idempotency.middleware.js`)

In Step 4, PropKart upgraded the idempotency middleware to a distributed, multi-instance model backed by **Redis** (`cacheService`) with in-memory fallback.

```
Incoming Request (POST / PUT / PATCH)
       ↓
Contains Idempotency-Key Header?
  ├─ No  → Pass through to route controller
  └─ Yes ↓
Validate Key Length (<= 128 chars)
       ↓
Build Composite Key: `${userId}:${method}:${path}:${key}`
       ↓
Check Cache (Redis → Memory Fallback)
  ├─ Exists & status == "PENDING"
  │     └─ Return 409 Conflict ("IDEMPOTENT_REQUEST_IN_FLIGHT")
  │
  ├─ Exists & status == "COMPLETED"
  │     └─ Replay Cached Response + Set Header `X-Idempotent-Replay: true` (Skip Controller!)
  │
  └─ Not Found (Fresh Request)
        ├─ Store status: "PENDING" (60s lock TTL)
        ├─ Execute Controller Logic
        └─ On res.json():
              ├─ Status < 500: Store status: "COMPLETED" (TTL = 10 min) + Set Header `X-Idempotent-Saved: true`
              └─ Status >= 500: Delete key (Allow client retry on server crashes)
```

---

## 3. Request Header Specification

Clients send the idempotency key in either of two standard headers:

```http
POST /api/v1/properties HTTP/1.1
Host: api.propkart.com
Authorization: Bearer eyJhbGci...
Idempotency-Key: e8b9415c-3f92-491b-8ec6-3faeeeb40bc1
Content-Type: application/json
```

- **Format**: Any unique client string up to 128 characters (UUIDv4 strongly recommended).
- **Scope**: Keys are namespaced by `userId`, HTTP method, and path. Two different users can safely use the same client-generated UUID without collision.

---

## 4. Replay & Conflict Responses

### 4.1 Replay Response (Idempotent Cache Hit)
When a duplicate request arrives after completion, the server does not execute database queries. It returns the original response instantly:

```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Idempotent-Replay: true
X-Request-Id: 981ecbf6-2911-4091-bb23-e408ecab3114

{
  "success": true,
  "message": "Property created successfully",
  "data": { "id": "PR-1088", ... }
}
```

### 4.2 In-Flight Conflict Response
When a client retries before the first request completes:

```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "success": false,
  "message": "A request with this Idempotency-Key is currently processing. Please wait.",
  "errorCode": "IDEMPOTENT_REQUEST_IN_FLIGHT"
}
```

---

## 5. Resilience & Fault Tolerance

1. **Redis Outage**: If Redis is offline or disconnected, the middleware seamlessly falls back to the in-memory `Map()` store without dropping requests.
2. **Server Crashes**: If an unhandled error (500) occurs during processing, the `PENDING` key is immediately deleted, ensuring the client is not permanently locked out.
3. **Deadlock Guard**: `PENDING` records carry a hard 60-second expiration. Even if a Node.js process crashes mid-flight, the lock auto-releases after 60 seconds.
