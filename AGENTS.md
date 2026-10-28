# AGENTS.md — PROPKART AI CODING AGENT OPERATING MANDATE & GOVERNANCE

Welcome, AI Coding Agent.

You are operating on **PropKart**, an enterprise multi-tenant Real Estate CRM & ERP ecosystem comprising a Flutter frontend client (`c:/NB/propkart`) and a Node.js/PostgreSQL backend service (`C:/NB/PropKart-Backend`).

This repository is strictly governed. You are **NOT** an unrestricted code generator. You must operate as an **architecture-aware, security-aware, test-aware, change-minimizing, and evidence-driven** software engineer.

---

## 1. The Core Law: "No Isolated Change"
In PropKart, **NO ISOLATED CHANGE EXISTS**.
Every change must be evaluated as a holistic system modification. A modification is never complete merely because its immediate screen renders without error or an endpoint returns HTTP 200. A change is considered architecturally compliant **ONLY** when:
$$\text{Business Invariant} + \text{Authoritative Data Model} + \text{Database Integrity} + \text{Lifecycle Progression} + \text{RBAC} + \text{KPI Semantics} + \text{Audit} + \text{Performance} + \text{Offline Sync}$$
have all been evaluated and verified against the [Master Engineering Rulebook](file:///c:/NB/propkart/PROPKART_MASTER_ENGINEERING_RULEBOOK.md) and the [AI Agent Operating Contract](file:///c:/NB/propkart/docs/ai-agent/01-AI-AGENT-OPERATING-CONTRACT.md).

---

## 2. Mandatory AI Task Lifecycle Protocol
Every non-trivial task executed by an AI agent must strictly follow this phased protocol:

```text
DISCOVER ──> UNDERSTAND ──> PLAN ──> IMPLEMENT ──> TEST ──> VERIFY ──> REPORT ──> STOP
```

1. **DISCOVER**: Inspect the repository structure, read [Project Manifest](file:///c:/NB/propkart/docs/ai-agent/project-manifest.json), and locate existing code ownership.
2. **UNDERSTAND**: Identify the authoritative source of truth, security boundaries, tenant constraints, and existing test contracts.
3. **PLAN**: For any change touching >1 file or any core subsystem, create an explicit [Change Plan](file:///c:/NB/propkart/docs/ai-agent/templates/CHANGE-PLAN.md) identifying files allowed to change, files forbidden to change, and required test suites.
4. **IMPLEMENT**: Execute the **Minimum Correct Change**. Do NOT perform opportunistic refactoring, mass renaming, or "while I'm here" code cleanup.
5. **TEST**: Run targeted unit and feature tests immediately after editing.
6. **VERIFY**: Run static analysis, architecture guardrail tests, and full regression baselines.
7. **REPORT**: Emit an [Implementation Report](file:///c:/NB/propkart/docs/ai-agent/templates/IMPLEMENTATION-REPORT.md) with exact measured test counts and evidence.
8. **STOP**: Strictly stop execution. Do not proceed to unprompted subsequent phases or steps.

---

## 3. System Architecture & Authoritative Sources

| Subsystem | Authoritative Source | Secondary / Transient | Forbidden Actions |
| :--- | :--- | :--- | :--- |
| **Business Data** | PostgreSQL 16 (`public` schema) | Isar v3 (local-first UI store) | Never bypass PostgreSQL; never treat client storage as authoritative. |
| **KPI Metrics** | `CanonicalKpiRepository` (PostgreSQL) | `KpiCacheService` (Redis, 300s TTL) | Never calculate authoritative KPIs in Flutter UI; never bypass canonical queries. |
| **Cache Tier** | Redis (`ioredis`, Port 6379) | In-memory fallback | Redis is transient fail-open; never store permanent business truth in Redis. |
| **Client Sync** | 10-state Sync Engine & Durable Outbox | Realtime WebSockets | Never perform ad-hoc direct writes bypassing outbox during offline states. |
| **Tenant Boundary** | JWT verified `organization_id` | Client claims | Never trust client-supplied tenant IDs from query/body parameters. |
| **Generated Code** | `*.dart` source definitions | `*.g.dart` (build_runner artifacts) | **NEVER MANUALLY EDIT `*.g.dart`**; modify source and run build_runner. |

---

## 4. Documentation & Context Sitemap (`docs/ai-agent/`)

Read the dedicated AI context file before touching any respective subsystem:

- **Operating Rules**: [`01-AI-AGENT-OPERATING-CONTRACT.md`](file:///c:/NB/propkart/docs/ai-agent/01-AI-AGENT-OPERATING-CONTRACT.md)
- **Architecture Layers**: [`02-ARCHITECTURE-CONTEXT-MAP.md`](file:///c:/NB/propkart/docs/ai-agent/02-ARCHITECTURE-CONTEXT-MAP.md)
- **Database Context**: [`03-DATABASE-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/03-DATABASE-AGENT-CONTEXT.md)
- **API Contract Context**: [`04-API-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/04-API-AGENT-CONTEXT.md)
- **KPI Engine Context**: [`05-KPI-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/05-KPI-AGENT-CONTEXT.md)
- **Sync & Realtime Context**: [`06-SYNC-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/06-SYNC-AGENT-CONTEXT.md)
- **Security Context**: [`07-SECURITY-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/07-SECURITY-AGENT-CONTEXT.md)
- **Testing Context**: [`08-TESTING-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/08-TESTING-AGENT-CONTEXT.md)
- **Observability Context**: [`09-OBSERVABILITY-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/09-OBSERVABILITY-AGENT-CONTEXT.md)
- **DevOps Context**: [`10-DEVOPS-AGENT-CONTEXT.md`](file:///c:/NB/propkart/docs/ai-agent/10-DEVOPS-AGENT-CONTEXT.md)
- **Navigation Map**: [`11-REPOSITORY-NAVIGATION.md`](file:///c:/NB/propkart/docs/ai-agent/11-REPOSITORY-NAVIGATION.md)
- **File Ownership**: [`12-FILE-OWNERSHIP-AND-EDITABILITY.md`](file:///c:/NB/propkart/docs/ai-agent/12-FILE-OWNERSHIP-AND-EDITABILITY.md)
- **Change Safety & Scoping**: [`13-AI-CHANGE-SAFETY.md`](file:///c:/NB/propkart/docs/ai-agent/13-AI-CHANGE-SAFETY.md)
- **Impact Analysis**: [`14-AI-IMPACT-ANALYSIS.md`](file:///c:/NB/propkart/docs/ai-agent/14-AI-IMPACT-ANALYSIS.md)
- **Architecture Guardrails**: [`15-AI-ARCHITECTURE-GUARDRAILS.md`](file:///c:/NB/propkart/docs/ai-agent/15-AI-ARCHITECTURE-GUARDRAILS.md)
- **Task Protocol Lifecycle**: [`16-AI-TASK-PROTOCOL.md`](file:///c:/NB/propkart/docs/ai-agent/16-AI-TASK-PROTOCOL.md)
- **Verification Protocol**: [`17-AI-VERIFICATION-PROTOCOL.md`](file:///c:/NB/propkart/docs/ai-agent/17-AI-VERIFICATION-PROTOCOL.md)
- **Anti-Patterns Catalog**: [`18-AI-ANTI-PATTERNS.md`](file:///c:/NB/propkart/docs/ai-agent/18-AI-ANTI-PATTERNS.md)
- **AI Security Standards**: [`19-AI-SECURITY-STANDARD.md`](file:///c:/NB/propkart/docs/ai-agent/19-AI-SECURITY-STANDARD.md)
- **Documentation Standards**: [`20-AI-DOCUMENTATION-STANDARD.md`](file:///c:/NB/propkart/docs/ai-agent/20-AI-DOCUMENTATION-STANDARD.md)
- **Self-Testing Guide**: [`21-AI-AGENT-TESTING.md`](file:///c:/NB/propkart/docs/ai-agent/21-AI-AGENT-TESTING.md)
- **Maintainability Scorecard**: [`22-AI-MAINTAINABILITY-SCORECARD.md`](file:///c:/NB/propkart/docs/ai-agent/22-AI-MAINTAINABILITY-SCORECARD.md)

---

## 5. Standard Verification Commands

### Backend (`C:/NB/PropKart-Backend`)
- Run Full Verified Test Suite (239 tests):
  ```powershell
  npm test
  ```
- Run AI-Agent Guardrail Tests:
  ```powershell
  node --import ./test/setup-env.js --test test/ai_agent.guardrails.test.js
  ```
- Run Production Smoke Test:
  ```powershell
  node scripts/smoke_test.js
  ```
- Run Production Dependency Audit:
  ```powershell
  npm audit --omit=dev --audit-level=high
  ```

### Flutter Frontend (`c:/NB/propkart`)
- Run Full Verified Test Suite (952 tests):
  ```powershell
  flutter test
  ```
- Run AI-Agent Safety Tests:
  ```powershell
  flutter test test/core/ai_agent_safety_test.dart
  ```
- Run Static Analysis (0 errors required):
  ```powershell
  flutter analyze --no-fatal-infos
  ```
- Regenerate Isar / Codegen Artifacts:
  ```powershell
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

---

## 6. Strict Stop Conditions
You must immediately **HALT** and ask for clarification / guidance when:
1. **Scope Expansion**: A task requires modifying files outside the declared change scope.
2. **Architecture Conflict**: A requested change requires violating clean architecture layering (e.g. asking UI to call database directly).
3. **Database Schema Mutation**: An unapproved destructive migration (`DROP TABLE`, `DROP COLUMN`) is suggested.
4. **Test Failures**: Existing regression tests fail and cannot be explained by the current change.
5. **Security Boundary Breach**: Any request requires bypassing RBAC, RLS, or hardcoding tenant credentials.
6. **Ambiguous Requirements**: Business logic or KPI formulations are underspecified.
