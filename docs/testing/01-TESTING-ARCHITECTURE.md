# 01 — Testing Architecture & Layer Isolation Standard

## 1. Executive Overview

The PropKart quality assurance and verification architecture is engineered as a risk-based, layered, deterministic testing pyramid. Rather than relying on superficial line-coverage statistics or flaky, high-latency UI tests, PropKart implements a rigorous testing hierarchy that proves correctness, tenant isolation, security regression resistance, data integrity, sync correctness, and API contract stability.

```
                  ▲
                 / \
                / L5\     End-to-End & Critical Workflow Smoke (Fast & Deterministic)
               /-----\
              /  L4   \    API Contract & Envelope Validation (Backend + Flutter)
             /---------\
            /    L3     \   Integration, Sync & Realtime Engine, Database RLS & Outbox
           /-------------\
          /      L2       \  Component & Widget Tests (Mobile Viewport Matrix, BLoC State)
         /-----------------\
        /        L1         \ Unit Tests (Repositories, Services, Models, Calculations)
       /---------------------\
```

---

## 2. Test Layer Definitions & Boundaries

### L1: Unit Testing (Deterministic, Zero-I/O)
- **Scope:** Pure functions, domain calculations, entity serialization/deserialization, KPI aggregation engines, state machine transitions.
- **Invariants:**
  - Zero network I/O, zero disk I/O, zero process spawning.
  - Zero dependency on external database or Redis instances.
  - Execution speed: sub-millisecond per test (< 1ms target).
- **Tooling:** Flutter `test` runner, Node.js native test runner (`node --test`).

### L2: Component & Widget Testing (Design System & Viewports)
- **Scope:** Flutter UI widget layout, accessibility tap targets (minimum 48x48 px), responsive viewport matrix (320px to 1280px), text scale factors (1.0x to 1.3x), BLoC event-to-state stream transformations.
- **Invariants:**
  - Mocked repository and data source dependencies.
  - Use of `TargetPlatformVariant.only(TargetPlatform.iOS)` for font determinism without external web font loading.
  - Verification of observable user interactions rather than private internal implementation details.

### L3: Integration Testing (Database, Cache & Offline Sync)
- **Scope:**
  - PostgreSQL transaction rollbacks, foreign keys, cascade rules, soft-delete filters, and Row-Level Security (RLS) tenant isolation.
  - Redis cache behavior: cache hits, cache misses, TTL enforcement, invalidation triggers, single-flight stampede protection, fail-open resilience.
  - Flutter Isar local persistence, durable outbox queueing, state machine transition logic, and Phoenix WebSocket message handling.
- **Invariants:**
  - Explicit multi-tenant verification: Tenant A vs. Tenant B isolation.
  - Deterministic test seed data cleaned up after each test suite execution.

### L4: Contract Testing (API & Schema Verification)
- **Scope:**
  - Canonical API envelope structure: `{ "success": boolean, "data": ..., "error": ..., "meta": ... }`.
  - HTTP status codes (200, 201, 400, 401, 403, 404, 409, 422, 500).
  - Backend Fastify schemas vs. Flutter model DTO parsers (`fromJson` / `toJson`).
  - Invariant: Zero drift between backend API contract and client data models.

### L5: Critical Workflow & Security Regression Testing
- **Scope:**
  - End-to-end multi-role workflows: Lead Capture → Allocation Engine → Telecaller Qualification → Sales Reassignment → Site Visit Logging → Deal Won Closure.
  - Security gates: RBAC permission boundaries, token expiration & invalidation, IDOR / BOLA authorization enforcement, input sanitization against SQL injection / XSS.

---

## 3. Technology Stack & Automation Harness

| Component | Framework / Runner | Target Environment | Mocking & Stubs | Isolation Mechanism |
| :--- | :--- | :--- | :--- | :--- |
| **Backend Suites** | Node.js Test Runner (`node --test`) | Node.js v20+ / Fastify | In-memory fixtures, Sinon/native mocks | Isolated tenant IDs, per-test DB transactions |
| **Flutter Frontend** | `flutter_test` | Flutter SDK 3.24+ | Mockito, MockBloc, FakeRepositories | Scoped Provider trees, Local Isar sandbox |
| **Database Tier** | PostgreSQL 15+ Integration | Authoritative DB | Real schemas + Migration runner | Isolated tenant schemas, Rollback wrappers |
| **Cache Tier** | Redis 7+ In-Memory Cache | Authoritative Redis | MockRedis / Test Redis instance | Isolated key prefixes per tenant |

---

## 4. Architectural Invariants Enforced by Quality Gates

1. **PostgreSQL as Authoritative Source of Truth:**
   - No calculation or critical mutation occurs in memory or on the client without database authority.
   - Redis cache failures never compromise database integrity or result in client application crashes (Fail-Open guarantee).
2. **Deterministic Test Execution:**
   - Flaky tests, arbitrary sleep/delay timers (`sleep(5000)`), and network-dependent test runs are strictly prohibited.
   - All tests run deterministically in any order without inter-test state bleed.
3. **Multi-Tenant Boundary Protection:**
   - Every read and write test asserts tenant isolation. Tenant A can never read, modify, delete, or infer metadata from Tenant B.
4. **Authoritative KPI Isolation:**
   - Client-side derivation of canonical KPIs is strictly forbidden; frontend tests verify that UI components bind only to backend-supplied canonical KPIs.
