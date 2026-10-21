# 11 — REALTIME SECURITY & WEBSOCKET CHANNEL ISOLATION

## 1. Realtime Architecture

PropKart uses Phoenix Channels over Secure WebSockets (`wss://`) for realtime event delivery (e.g. new lead notifications, status updates, sync triggers).

---

## 2. Authentication & Authorization Handshake

1. **Connection Authentication**:
   - WebSockets require a valid JWT bearer token provided during initial handshake.
   - Unauthenticated connection attempts are closed immediately (`4401 Unauthorized`).
2. **Channel Authorization**:
   - Clients join scoped topics such as `realtime:propkart`.
   - The server verifies that the requesting connection possesses active tenant authorization.
3. **Table Scope Allowlist**:
   - The client explicitly requests replication only for allowed CRM tables:
     `properties`, `requirements`, `notifications`, `followups`, `site_visits`, `integration_leads`, `leads`, `campaign_connections`, `campaign_lead_followups`.
   - Sensitive security tables (`users`, `passwords`, `sessions`, `tokens`, `audit_logs`) are strictly excluded from realtime publication.

---

## 3. Disconnection & State Cleanup

When a user logs out or is forced to disconnect:
- The WebSocket sink is closed cleanly: `_channel?.sink.close()`.
- Channel stream subscriptions are cancelled: `_channelSubscription?.cancel()`.
- The incoming message buffer is cleared: `_incomingBuffer.clear()`.
- Reconnect timers and heartbeats are disposed, preventing orphaned socket streams from receiving subsequent events.
