# 08 — TESTING AGENT CONTEXT & VERIFICATION PYRAMID

## 1. Testing Philosophy: "Working Code is Verified Code"
In PropKart, **no feature, bugfix, or refactoring task is complete merely because the code compiles or an HTTP probe responds.**
A task is complete only when all targeted unit tests, architectural rule checks, and platform regression suites pass with 0 failures, 0 errors, and 0 skipped tests.

## 2. Test Suites Inventory & Execution Matrix

### A. Backend Test Matrix (`C:/NB/PropKart-Backend`)
- **Primary Regression Suite (239 tests):**
  ```powershell
  npm test
  ```
  Runs core architectural rules, RBAC isolation, payload validation, ACID transactions, auth tokens, portal health, lead ingest engine, Meta/Housing integrations, telecaller permissions, security hardening, user sanitization, audit telemetry, allocation engine, KPI reconciliation, canonical KPI repo, captcha hardening, Redis architecture, API contract architecture, observability telemetry, and DevOps infrastructure.
- **AI Agent Guardrails Suite (7 tests):**
  ```powershell
  node --import ./test/setup-env.js --test test/ai_agent.guardrails.test.js
  ```
- **Extended Full Suite:**
  ```powershell
  npm run test:all
  ```

### B. Flutter Frontend Test Matrix (`c:/NB/propkart`)
- **Primary Regression Suite (952 tests):**
  ```powershell
  flutter test
  ```
  Covers BLoCs, cubits, repositories, offline storage, design system widgets, responsive layouts, sales dashboards, telecaller screens, campaign managers, and sync state machines.
- **AI Agent Safety Suite (6 tests):**
  ```powershell
  flutter test test/core/ai_agent_safety_test.dart
  ```
- **Architecture Compliance Suite:**
  ```powershell
  flutter test test/core/flutter_architecture_rules_test.dart
  ```
- **Static Code Analysis (0 issues):**
  ```powershell
  flutter analyze --no-fatal-infos
  ```

## 3. Strict Rules for AI Agents
1. **Never Delete or Comment Out Tests:** If an existing test fails after a change, investigate and fix the root cause. Never delete or weaken test assertions.
2. **Never Mask Failures with Fake Mocks:** Test assertions must verify real invariants, error states, and boundary conditions.
3. **Always Run Regression Before Reporting:** Do not claim completion without executing the full regression suite.
