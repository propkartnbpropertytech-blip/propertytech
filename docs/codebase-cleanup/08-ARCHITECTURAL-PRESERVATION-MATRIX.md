# 08-ARCHITECTURAL-PRESERVATION-MATRIX.md — PropKart Architectural Preservation Matrix

## 1. Executive Preservation Mandate
Step 15 operates under the absolute constraint that all architectural boundaries, authoritative models, security envelopes, and synchronization mechanics established across Steps 1 through 14 must remain **100% PRESERVED AND FROZEN**.

---

## 2. Preservation Matrix by Subsystem

| Subsystem | Authoritative Source File(s) | Architectural Invariant | Why Preserved | Protecting Tests | Protection Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL 16 DB** | `C:/NB/PropKart-Backend/src/config/dbPool.js` | Authoritative persistence tier; multi-tenant RLS | Single source of truth for business data | `transaction.integrity.error.test.js`, `pool.timeout.concurrency.test.js` | **FROZEN / CERTIFIED** |
| **Database Migrations**| `C:/NB/PropKart-Backend/sql/migrations/*.sql` (62 files) | Additive forward-only schema progression | Prevents data loss; supports zero-downtime deploys | `ensureAdditiveSchema.js`, `architecture.rules.test.js` | **FROZEN / CERTIFIED** |
| **KPI Engine** | `src/modules/dashboard/kpi/canonicalKpi.repository.js` | Single canonical SQL source for all business metrics | Prevents split-brain metrics across UI and backend | `canonical.kpi.repository.test.js`, `kpi.reconciliation.test.js` | **FROZEN / CERTIFIED** |
| **Transient Cache** | `src/services/cache.service.js`, `src/config/redis.js` | Fail-open transient Redis cache; 300s TTL; 512KB payload ceiling | High performance with zero data loss risk on failure | `redis.cache.architecture.test.js` | **FROZEN / CERTIFIED** |
| **Multi-Tenancy** | `src/middleware/auth.middleware.js`, `src/security/rbac.js` | Multi-tenant isolation via JWT verified `organization_id` | Prevents cross-tenant data leaks | `rbac.team.isolation.test.js`, `permissions.telecaller.test.js` | **FROZEN / CERTIFIED** |
| **Local Offline DB** | `c:/NB/propkart/lib/core/storage/local_database.dart` | Isar v3 local presentation cache; never authoritative | Enables local-first UI rendering and offline mode | `offline_sync_test.dart`, `local_database_test.dart` | **FROZEN / CERTIFIED** |
| **Durable Outbox** | `c:/NB/propkart/lib/core/storage/isar_collections.dart` | Durable outbox ledger with idempotency keys | Guarantees at-least-once offline mutations | `durable_outbox_test.dart`, `sync_manager_test.dart` | **FROZEN / CERTIFIED** |
| **10-State Sync Engine**| `c:/NB/propkart/lib/core/sync/sync_engine.dart` | Strict 10-state synchronization state machine | Reliable offline-to-online transitions | `sync_state_machine_test.dart` | **FROZEN / CERTIFIED** |
| **Phoenix Realtime** | `c:/NB/propkart/lib/core/network/websocket_service.dart` | WebSocket channel subscriptions for live events | Low-latency state synchronization | `realtime_events_test.dart` | **FROZEN / CERTIFIED** |
| **Generated Code** | `c:/NB/propkart/lib/core/storage/isar_collections.g.dart` | Build runner generated Isar schema | Required for Isar DB queries; manual edits forbidden | `ai_agent_safety_test.dart` | **FROZEN / CERTIFIED** |
| **Observability** | `src/config/metrics.js`, `lib/core/observability/` | Prometheus `/metrics`, Sentry error monitoring, Pino | SRE production monitoring | `observability.telemetry.test.js`, `audit.telemetry.test.js` | **FROZEN / CERTIFIED** |
| **AI Governance** | `AGENTS.md`, `docs/ai-agent/project-manifest.json` | Machine-readable architecture rules and guardrails | Governs AI agent changes safely | `ai_agent.guardrails.test.js`, `ai_agent_safety_test.dart` | **FROZEN / CERTIFIED** |

---

## 3. Preservation Governance Assertion
Every code edit in Step 15 has been audited against this matrix. Any proposed modification touching a FROZEN layer was rejected.
