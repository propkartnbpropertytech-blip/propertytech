# 01 — AI AGENT OPERATING CONTRACT & GOVERNANCE SPECIFICATION

## 1. Constitutional Purpose
This document establishes the binding operational contract governing every AI coding agent operating on the PropKart codebase. AI agents are untrusted without guardrails; therefore, all automated or semi-automated interventions must adhere strictly to these non-negotiable clauses.

---

## 2. The Three Phases of Coding Execution

### Phase 1: Before Modifying Code (Pre-Execution Audit)
1. **Repository & Layer Discovery:**
   - Locate the target feature using [Repository Navigation](file:///c:/NB/propkart/docs/ai-agent/11-REPOSITORY-NAVIGATION.md).
   - Identify the owning architectural layer (Presentation, Domain Use Case, BLoC, Express Controller, Domain Service, Canonical Repository).
2. **Authoritative Store Determination:**
   - Verify whether the entity is authoritative in PostgreSQL or a downstream projection in Isar/Redis.
   - For any KPI query, confirm alignment with [`CanonicalKpiRepository`](file:///C:/NB/PropKart-Backend/src/modules/dashboard/kpi/canonicalKpi.repository.js).
3. **Boundary Identification:**
   - Identify multi-tenant isolation requirements (`organization_id` foreign key check).
   - Enforce RBAC permission checks at controller and service boundaries.
4. **Change Plan Formulation:**
   - For changes touching >1 file, draft a structured plan following [`templates/CHANGE-PLAN.md`](file:///c:/NB/propkart/docs/ai-agent/templates/CHANGE-PLAN.md).

### Phase 2: During Code Modification (Execution Discipline)
1. **Minimum Correct Change:**
   - Edit the fewest lines and fewest files necessary to solve the exact issue.
   - Strictly avoid opportunistic refactoring, mass variable renaming, or cosmetic restructuring of adjacent functions.
2. **Contract Preservation:**
   - Preserve existing JSON envelopes: `{ success: true, data: {}, error: {}, meta: {} }`.
   - Never alter database schemas without purely additive migrations (`sql/migrations/`).
3. **Clean Architecture Isolation:**
   - Presentation screens must never import `dio_client.dart` or `isar_collections.dart`.
   - Express controllers must never query `dbPool` directly (delegate to services and repositories).
4. **Generated Code Immutability:**
   - Never edit `*.g.dart` files manually.

### Phase 3: After Modifying Code (Verification & Stop)
1. **Targeted Test Execution:** Run the specific unit test suite for the modified module.
2. **Static Analysis:** Run `flutter analyze --no-fatal-infos` on Flutter code.
3. **Regression Baseline Verification:** Execute `npm test` and `flutter test`. Ensure zero test failures and zero skipped tests.
4. **Empirical Reporting:** Emit a completed [`templates/IMPLEMENTATION-REPORT.md`](file:///c:/NB/propkart/docs/ai-agent/templates/IMPLEMENTATION-REPORT.md) containing measured test counts.
5. **HARD STOP:** Cease execution immediately. Do not jump to unprompted subsequent tasks.
