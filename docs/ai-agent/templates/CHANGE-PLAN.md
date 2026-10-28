# AI AGENT CHANGE PLAN TEMPLATE

> **MANDATE:** For any change impacting more than 1 file or modifying any core subsystem (auth, database, KPI, sync, security, telemetry, DevOps), the AI agent must complete this plan **BEFORE** modifying code.

---

## 1. Task Metadata
- **Task Title**: [Concise description of the task]
- **Target Subsystem**: [e.g. Properties, Leads, KPI Dashboard, Offline Sync]
- **Requester / Prompt Reference**: [User prompt summary]
- **Assigned Agent Role**: [e.g. Full-Stack Architect, Frontend Engineer, Database Reliability Engineer]

---

## 2. Objective & Scope Definition
- **Primary Objective**: [What exact outcome must be achieved?]
- **Non-Goals / Explicit Out-of-Scope**: [What will NOT be touched?]
- **Current Architecture Layer**: [e.g. Flutter Presentation, BLoC, Express Controller, PostgreSQL Schema]
- **Authoritative Source of Truth**: [e.g. PostgreSQL public.leads, CanonicalKpiRepository]

---

## 3. Scope Boundaries & File Ownership
### Files to Inspect (Read-Only)
- `...`
- `...`

### Files Allowed to Change (Minimum Necessary)
- `...`
- `...`

### Files Strictly FORBIDDEN to Change
- `src/modules/dashboard/kpi/canonicalKpi.repository.js` (unless authorized for canonical KPI changes)
- `lib/core/storage/isar_collections.g.dart` (generated code)
- `sql/migrations/*` (historical applied migrations)
- `src/config/env.js` (environment isolation guardrails)
- Unrelated feature modules and test suites

---

## 4. Architectural Invariants & Constraints
- [ ] **Multi-Tenant Isolation**: Verified `organization_id` is applied at database query layer.
- [ ] **Authoritative Persistence**: PostgreSQL is authoritative; no client-side authoritative calculations.
- [ ] **Cache Semantics**: Any Redis caching is fail-open with explicit TTL.
- [ ] **Clean Layering**: UI does not import Dio/Isar; controllers do not execute raw SQL.
- [ ] **Security Boundaries**: RBAC enforced; zero credentials/secrets in code.
- [ ] **Telemetry Invariant**: Telemetry logging failure never crashes request processing.

---

## 5. Implementation Strategy
1. **Step 1**: [First granular modification]
2. **Step 2**: [Second granular modification]
3. **Step 3**: [Third granular modification]

---

## 6. Verification & Test Plan
- **Targeted Unit Tests**:
  - `[Command to execute local unit tests]`
- **Architecture Guardrail Tests**:
  - `[Command to verify layer rules]`
- **Full Regression Baseline**:
  - `npm test` (Backend: 239/239 PASS)
  - `flutter test` (Flutter: 952/952 PASS)
- **Static Analysis**:
  - `flutter analyze --no-fatal-infos` (0 errors)

---

## 7. Stop Conditions
The agent must halt immediately and request human guidance if:
- [ ] An unexpected database schema change or migration is needed.
- [ ] An unrelated test suite fails.
- [ ] Scope expands beyond the declared files.
