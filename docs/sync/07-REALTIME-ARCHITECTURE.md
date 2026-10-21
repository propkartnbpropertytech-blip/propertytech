# PropKart Realtime Architecture & WebSocket Event Processing

## 1. Realtime Subsystem Overview

PropKart uses a Phoenix / Supabase Realtime-compatible WebSocket connection to stream PostgreSQL Change Data Capture (CDC) events directly to connected clients.

### Non-Negotiable Realtime Rule
> **Realtime events are strictly change notifications and fast-path transports. They are NOT the authoritative source of truth and must never bypass validation, tenant checks, or local transaction boundaries.**

---

## 2. Channel Lifecycle & Communication Protocol

### 2.1. Handshake & Channel Subscription
1. Client dials WebSocket endpoint: `wss://<host>/realtime/v1/websocket?apikey=<key>&vsn=2.0.0`.
2. Client sends `phx_join` message to channel `realtime:propkart`:
   ```json
   {
     "topic": "realtime:propkart",
     "event": "phx_join",
     "payload": {
       "config": {
         "postgres_changes": [
           { "event": "*", "schema": "public", "table": "properties" },
           { "event": "*", "schema": "public", "table": "requirements" },
           { "event": "*", "schema": "public", "table": "notifications" },
           { "event": "*", "schema": "public", "table": "followups" },
           { "event": "*", "schema": "public", "table": "site_visits" },
           { "event": "*", "schema": "public", "table": "integration_leads" },
           { "event": "*", "schema": "public", "table": "leads" },
           { "event": "*", "schema": "public", "table": "campaign_connections" },
           { "event": "*", "schema": "public", "table": "campaign_lead_followups" }
         ]
       }
     },
     "ref": "1"
   }
   ```
3. Scoped subscription: PropKart explicitly whitelists subscribed tables. It **never** subscribes to wildcards or the entire database schema.

### 2.2. Heartbeat & Connection Health
- Frequency: Sent every **30 seconds** (`_startHeartbeat()`).
- Payload: `{"topic": "phoenix", "event": "heartbeat", "payload": {}, "ref": "<ref>"}`.
- If no heartbeat acknowledgement or socket activity is detected within 45 seconds, the socket is considered dead and closed.

### 2.3. Exponential Backoff Reconnection Loop
- On socket disconnect, `_handleDisconnect(reason)` executes:
  1. Cancels active heartbeat timer and socket subscriptions.
  2. Increments `_reconnectAttempts`.
  3. Computes backoff delay: `delay = clamp(_reconnectAttempts * 2, 2, 30)` seconds.
  4. Triggers re-dial after timer expires.
  5. Upon successful reconnect, `_reconnectAttempts` resets to 0 and delta sync triggers to catch up on missed events.

---

## 3. Realtime Event Validation & Ingestion Pipeline

Incoming messages must pass through a 6-stage validation gate before touching the local database:

```text
                  Incoming WebSocket Message
                              │
                              ▼
                 Stage 1: JSON Parse & Envelope Check
                 (Reject malformed syntax or bad frames)
                              │
                              ▼
                 Stage 2: Channel & Event Whitelist Check
                 (Reject unknown topics or unwhitelisted tables)
                              │
                              ▼
                 Stage 3: Tenant & Auth Isolation Check
                 (Reject records belonging to another tenant)
                              │
                              ▼
                 Stage 4: Deduplication & Version Ordering
                 (Reject duplicate events or stale versions)
                              │
                              ▼
                 Stage 5: Conflict Resolution Check
                 (Arbitrate against pending local outbox edits)
                              │
                              ▼
                 Stage 6: Batched Isar Write Transaction
                 (Atomic commit + RepositoryCoordinator refresh)
```

### Validation Invariants:
1. **Malformed Payloads**: If JSON parsing fails or mandatory fields (`table`, `type`, `record`/`old_record`) are missing, the frame is dropped with a warning.
2. **Tenant Spoofing**: The record's `organization_id` is matched against the authenticated user's active session. Cross-tenant events are rejected immediately.
3. **Stale Records**: If an incoming record has an `updated_at` older than the currently cached local record, it is discarded.
4. **Debounced Batching**: Incoming events are pushed to `_incomingBuffer` and processed in batches every 100ms (`_processBatch`), preventing main-isolate UI freezing under bursty event streams.
