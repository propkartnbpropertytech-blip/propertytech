# AI AGENT CHANGE PLAN

## 1. Task Metadata
- **Task Title**: AI Search in the AppShell
- **Target Subsystem**: Global search, AppShell chrome
- **Requester / Prompt Reference**: Implement AI Search with a distinctive AppShell control and a natural-language flow that stays on PostgreSQL
- **Assigned Agent Role**: Full-stack architect

## 2. Objective & Scope Definition
- **Primary Objective**: Make AI Search recognizable in the shell, interpret a natural-language query into an allowlisted intent, and return authorized grouped records. Keyword search keeps working when no AI provider is configured or the provider fails.
- **Non-Goals / Explicit Out-of-Scope**: Elasticsearch or a new search dependency. Builders. Canonical KPI SQL. Destructive migrations. Generated `*.g.dart`. Client-held provider credentials. Sending CRM rows to a model.
- **Current Architecture Layer**: Flutter shell and search service; Express search controller; PostgreSQL search repository
- **Authoritative Source of Truth**: PostgreSQL, scoped by the verified JWT organization and role

## 3. Scope Boundaries & File Ownership
### Files to Inspect (Read-Only)
- `lib/core/design_system/widgets/app_shell.dart`
- `lib/features/shell/widgets/top_bar.dart`
- `src/modules/search/*`
- `src/services/audit.service.js`
- `src/modules/followups/followupWindow.js`

### Files Allowed to Change (Minimum Necessary)
- AppShell, top bar, mobile search chrome, owners/clients initial search, search service and panel
- Backend search module, audit redaction, `.env.example`, `package.json` test list
- New intent, provider, filter, panel, session, and test files
- This plan and the implementation report

### Files Strictly FORBIDDEN to Change
- `src/modules/dashboard/kpi/canonicalKpi.repository.js`
- `lib/core/storage/isar_collections.g.dart` and any `*.g.dart`
- Historical `sql/migrations/*`
- `src/config/env.js`
- Builder persistence and allocation engine

## 4. Architectural Invariants & Constraints
- [x] **Multi-Tenant Isolation**: Organization comes from `req.user` only. A model cannot supply a tenant id.
- [x] **Authoritative Persistence**: Matches are PostgreSQL rows. The model returns an intent, never SQL or records.
- [x] **Cache Semantics**: No new Redis cache. The shell keeps the last successful result when the network fails.
- [x] **Clean Layering**: The new panel does not import Dio. The search controller does not query the pool.
- [x] **Security Boundaries**: `search.read` stays on the route. Provider key is read from the server environment only.
- [x] **Telemetry Invariant**: Search audit drops raw query text. A logging failure does not fail the search.

## 5. Implementation Strategy
1. Add a strict intent validator and a deterministic parser for listing, BHK, area, budget, and follow-up windows.
2. Add an optional OpenAI-compatible adapter. Missing configuration, timeout, rate limit, or malformed JSON falls back to the parser.
3. Apply the validated filters in the existing parameterized search SQL before `LIMIT`, using the current role and organization scope.
4. Replace the shell search control with an AI Search label, sparkle, and gradient, and open a panel with examples, chips, grouped results, and distinct states.
5. Debounce interpretation by 700ms, ignore stale responses, and keep keyword search when the provider is absent.

## 6. Verification & Test Plan
- **Targeted Unit Tests**:
  - `node --import ./test/setup-env.js --test --test-concurrency=1 --test-force-exit test/ai.search.test.js`
  - `flutter test test/search/ai_search_test.dart test/search_filter_contract_test.dart`
- **Architecture Guardrail Tests**:
  - `node --import ./test/setup-env.js --test --test-concurrency=1 --test-force-exit test/ai_agent.guardrails.test.js test/architecture.contract.test.js test/architecture.rules.test.js test/security.hardening.test.js`
  - `flutter test test/core/ai_agent_safety_test.dart`
- **Full Regression Baseline**:
  - `npm test`
  - `flutter test`
- **Static Analysis**:
  - `flutter analyze --no-fatal-infos`

## 7. Stop Conditions
The agent must halt immediately and request human guidance if:
- [ ] An unexpected database schema change or migration is needed.
- [ ] An unrelated test suite fails and the failure cannot be separated from this change.
- [ ] Scope expands beyond the declared files.
