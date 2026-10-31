# AI AGENT CHANGE PLAN TEMPLATE

## 1. Task Metadata
- **Task Title**: Search, follow-up filters, and persistent builders
- **Target Subsystem**: Search, properties, follow-ups, builders, telemetry
- **Requester / Prompt Reference**: Search and filter improvements (online/offline, pagination, follow-up windows, builder tenancy, search privacy)
- **Assigned Agent Role**: Full-stack engineer

## 2. Objective & Scope Definition
- **Primary Objective**: Apply property text search and filters before SQL pagination; paginate global search; align directory search fields; debounce list search; add Due today, Overdue, and Next 7 days; persist builders with permissions; stop storing raw search text.
- **Non-Goals / Explicit Out-of-Scope**: Canonical KPI SQL, Super Admin dashboard, historical migrations 11–87, generated `*.g.dart`, allocation engine behavior.
- **Current Architecture Layer**: Flutter screens and local repositories, Express controllers, PostgreSQL.
- **Authoritative Source of Truth**: PostgreSQL. Isar remains the offline cache.

## 3. Scope Boundaries & File Ownership
### Files to Inspect (Read-Only)
- Existing search, property, follow-up, builder, and audit modules
- `docs/ai-agent/12-FILE-OWNERSHIP-AND-EDITABILITY.md`

### Files Allowed to Change
- Property, search, follow-up, builder, audit, and permission backend modules
- `sql/migrations/88_persistent_builders.sql` (new) and `ensureAdditiveSchema.js`
- Flutter property, directory, follow-up, telemetry, and a global results screen
- New targeted tests and `package.json` test registration
- This plan and the implementation report

### Files Strictly FORBIDDEN to Change
- `src/modules/dashboard/kpi/canonicalKpi.repository.js`
- `*.g.dart`
- Historical migrations already applied
- `src/config/env.js`

## 4. Architectural Invariants & Constraints
- [x] **Multi-Tenant Isolation**: Builder and property queries use the JWT organization.
- [x] **Authoritative Persistence**: PostgreSQL, not process memory, stores builders.
- [x] **Cache Semantics**: No new Redis search index.
- [x] **Clean Layering**: New search screen uses a service, not a raw Dio import in the widget if a service exists. Existing screens that already call blocs stay on blocs.
- [x] **Security Boundaries**: Builder routes use `requirePermission`.
- [x] **Telemetry Invariant**: Search audit rows keep counts, not raw query text.

## 5. Implementation Strategy
1. Put property filters in the same SQL `WHERE` as text search, then paginate.
2. Page one global-search category and rank exact identifiers first.
3. Align offline directory fields, debounce list search, and add follow-up windows.
4. Replace in-memory builders with a tenant table and permissions.
5. Redact search telemetry and add the required tests.

## 6. Verification & Test Plan
- Targeted backend and Flutter tests for the acceptance cases
- `EXPLAIN` on the local database for the property text query
- Architecture guardrails, `npm test`, `flutter test`, `flutter analyze --no-fatal-infos`

## 7. Stop Conditions
- Halt if a follow-up date rule cannot be read from the existing scheduler.
- Do not change canonical KPI calculations.
