# 09 — Sync & Realtime Observability

## 1. Offline Sync Engine & Realtime Telemetry

PropKart’s offline-first mobile sync architecture connects the local embedded Isar database with the authoritative remote PostgreSQL backend via delta synchronization and Phoenix WebSocket channels.

## 2. Sync Manager State Machine Telemetry

The client-side `SyncManager` exposes state transitions across 10 deterministic states:
`INITIALIZING` → `OFFLINE` → `CONNECTING` → `SYNCING` → `LIVE` → `DEGRADED` → `RECONNECTING` → `CONFLICT_RESOLUTION` → `ERROR` → `STOPPED`

### Key Telemetry Signals:
- `sync_cycle_duration_ms`: Latency of delta pull, local persistence, and outbox drain.
- `sync_cycles_total`: Cumulative counter of sync cycles initiated.
- `sync_success_total` & `sync_failure_total`: Reliability indicators.
- `outbox_pending_count`: Gauge tracking local offline mutations waiting for server dispatch.
- `outbox_drain_latency_ms`: Duration to replay offline changes upon connectivity restoration.
- `conflict_resolutions_total`: Count of conflicts resolved via deterministic three-tier strategies.

## 3. Phoenix Realtime Channel Telemetry

Realtime notifications broadcast over WebSocket topics (e.g. `tenant:<id>:leads`, `user:<id>:notifications`):
- `realtime_connected`: Binary status of WebSocket connection.
- `realtime_events_received`: Total messages ingested over active topics.
- `realtime_events_dropped`: Messages dropped due to backpressure or unparseable frames.
- `reconnect_attempts`: Exponential backoff telemetry during network flaps.
- `topic_auth_failures`: Unauthorized attempts to join foreign tenant channels (logged as security warnings).
