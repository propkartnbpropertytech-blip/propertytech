# 07 — Redis Observability

## 1. Redis Cache & Coordination Layer Telemetry

Redis operates strictly as an acceleration and temporary coordination layer in PropKart. All primary business data is stored authoritatively in PostgreSQL.

## 2. In-Memory Cache Metrics (`CacheService.getMetrics()`)

The canonical `CacheService` (`src/services/cache.service.js`) tracks comprehensive operational metrics:
- `hits`: Total successful cache lookups.
- `misses`: Total cache misses requiring database resolution.
- `hitRatio`: Computed cache efficiency `hits / (hits + misses)`.
- `sets`: Count of payload write operations.
- `deletes`: Invalidation and eviction events.
- `stampedeShields`: Concurrent requests collapsed via single-flight mutex promises.
- `lockAcquisitions` / `lockReleases` / `lockFailures`: Distributed lock lifecycle counts.
- `bytesStored`: Cumulative payload byte volume stored.
- `inFlightCount`: Number of currently unresolved single-flight promises.

## 3. Resilience & Fail-Open Telemetry

- **Fail-Open Invariant**: When Redis encounters connection failure (`ECONNREFUSED`, timeout, partition), all queries transparently fall back to PostgreSQL.
- **Circuit State Logging**: Redis connection state transitions (`ready`, `connect`, `error`, `close`, `reconnecting`) are logged with level `WARN` or `ERROR`.
- **Payload Ceiling Protection**: Payload serialization enforces a strict 512 KB ceiling. Oversized payloads reject cache writes with a structured warning to prevent Redis memory exhaustion.
