# 01-CLEANUP-BASELINE.md — PropKart Step 15 Codebase Cleanup Forensic Baseline

## 1. Executive Summary & Audit Mandate
- **Phase**: Step 15 — Codebase Cleanup & Structural Hardening (Final Phase)
- **Preceding Status**: Steps 1 through 14 CERTIFIED PASS & FROZEN
- **Governance Mandate**: Zero-Behavior-Change Cleanup. Remove provably dead code, consolidate provably duplicated logic, eliminate unused imports, and harden repository structure without modifying any business logic, API contract, database schema, KPI formulation, RBAC boundary, or telemetry hook.
- **Auditor Roles**:
  - Principal Software Architect
  - Senior Flutter Architect
  - Senior Node.js/Express Architect
  - Codebase Refactoring Specialist
  - Dead-Code Analysis Engineer
  - Dependency Graph Engineer
  - Regression & Compatibility Auditor

---

## 2. Verified Test Suite Baselines

Prior to performing any modifications, the full test suites across both repositories were executed and recorded:

```text
================================================================================
PROPKART STEP 15 PRE-CLEANUP TEST BASELINE
================================================================================
Backend Test Suite (node:test):
  Total Suites:         63
  Total Tests:          239
  Passing Tests:        239 (100.0%)
  Failed Tests:         0
  Skipped Tests:        0
  Execution Time:       14.63s

Flutter Test Suite (flutter test):
  Total Tests:          958
  Passing Tests:        958 (100.0%)
  Failed Tests:         0
  Skipped Tests:        0
  Execution Time:       38.0s

AI-Agent Safety Guardrails:
  Backend Guardrails:   7 / 7 PASS
  Flutter Safety:       6 / 6 PASS
  Total AI Tests:       13 / 13 PASS (100.0%)

GRAND TOTAL VERIFIED:   1,197 / 1,197 PASSING (100.0%)
FAILURES:               0
REGRESSION RATE:        0.00%
================================================================================
```

---

## 3. Static Analysis & Diagnostics Baseline

### Backend Static Analysis (`C:/NB/PropKart-Backend`)
- **Runtime Syntax & Import Verification**: 0 syntax errors, 0 unresolved imports.
- **Node.js Native Modules**: ESM (`type: module`) strictly enforced.
- **Database Model Guardrails**: 0 direct database references in routes; 0 shadow/bloat table queries.

### Flutter Static Analysis (`c:/NB/propkart`)
- Command: `flutter analyze --no-fatal-infos --no-fatal-warnings`
- Result: **0 compilation errors** (Command exited with code 0).
- Issue Breakdown (1,123 total informational/lint issues):
  - `deprecated_member_use`: 503
  - `use_build_context_synchronously`: 136
  - `avoid_print`: 66
  - `unused_import`: 59 (Candidate for Safe Pruning)
  - `use_null_aware_elements`: 43
  - `unused_element`: 33 (Private unreferenced methods/classes)
  - `dead_code`: 27
  - `dead_null_aware_expression`: 27
  - `invalid_null_aware_operator`: 25
  - `unnecessary_non_null_assertion`: 24
  - `unnecessary_cast`: 23
  - `curly_braces_in_flow_control_structures`: 21
  - `unnecessary_brace_in_string_interps`: 19
  - `unused_field`: 15
  - `unused_local_variable`: 15
  - `unnecessary_import`: 12 (Candidate for Safe Pruning)
  - Other styling/formatting lints: 95

---

## 4. Repository Inventory Baseline

| Metric | Backend (`PropKart-Backend`) | Frontend (`propkart`) | Ecosystem Combined |
| :--- | :--- | :--- | :--- |
| **Source Files** | 206 files (`src/**/*.js`) | 379 files (`lib/**/*.dart`) | 585 files |
| **Source Lines of Code (SLOC)** | 56,857 lines | 258,695 lines | 315,552 lines |
| **Test Files** | 49 files (`test/**/*.js`) | 116 files (`test/**/*.dart`) | 165 test files |
| **Test Lines of Code** | 7,836 lines | 21,886 lines | 29,722 lines |
| **Database Migrations** | 62 `.sql` files (8,210 lines) | N/A (Local Isar Schema) | 62 migrations |
| **Production Dependencies** | 24 (`package.json`) | 42 (`pubspec.yaml`) | 66 packages |
| **Development Dependencies**| 4 (`package.json`) | 10 (`pubspec.yaml`) | 14 packages |
| **TODO / FIXME / HACK Count**| 0 instances | 0 instances | 0 instances |
| **Identified Root Scratch Files** | 48 scripts/files | 3 log/temp files | 51 root files |

---

## 5. Architectural Invariants to Preserve (Non-Negotiable)

1. **PostgreSQL Authoritative Tier**: All financial, property, lead, customer, and user data remains authoritatively governed in PostgreSQL 16.
2. **Canonical KPI Calculations**: `CanonicalKpiRepository` remains the sole mathematical source of truth for all business metrics.
3. **Transient Redis Caching**: Redis remains strictly fail-open transient cache (`KpiCacheService`, 300s TTL).
4. **Isar Local Presentation**: Isar v3 remains local UI offline store; `OutboxEntry` remains durable sync ledger.
5. **Sync Engine State Machine**: 10-state offline synchronization engine and idempotency tokens remain unchanged.
6. **Phoenix Realtime**: Realtime channels and subscription protocols remain active.
7. **Security & RBAC/RLS**: Multi-tenant isolation (`organization_id`), JWT claims, password hashing, and role hierarchies are immutable.
8. **Observability Hooks**: Request correlation IDs (`X-Request-Id`), structured Pino/AppLogger logging, and Prometheus metrics endpoints remain untouched.
