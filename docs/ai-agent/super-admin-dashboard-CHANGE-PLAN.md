# AI AGENT CHANGE PLAN — Super Admin platform dashboard

## 1. Task Metadata
- **Task Title**: Distinct Super Admin platform overview at `/dashboard`
- **Target Subsystem**: Dashboard, subscriptions, support, navigation
- **Requester / Prompt Reference**: Super Admin dashboard with read-only organization snapshots
- **Assigned Agent Role**: Full-stack architect

## 2. Objective & Scope Definition
- **Primary Objective**: Super Admin sees a platform overview at `/dashboard`. Admin, Sales, Telecaller, and Broker sessions keep their current dashboards.
- **Non-Goals / Explicit Out-of-Scope**: No impersonation, no JWT/tenant switch, no MRR, no plan/permission/onboarding/ticket mutations, no canonical KPI formula changes, no historical migrations, no generated `*.g.dart` edits.
- **Current Architecture Layer**: Flutter presentation → BLoC → repository → service → Express route/controller → service → PostgreSQL repository. Business snapshot metrics delegate to `CanonicalKpiRepository`.
- **Authoritative Source of Truth**: PostgreSQL. Workspace kind is the organization owner's role (`Broker` or `Admin`; anything else is unclassified, including a missing owner). Active subscription: `organization_subscriptions.status = 'ACTIVE'` and (`expiry_date` is null or in the future). Expired: a subscription row whose status is not `ACTIVE`, or `ACTIVE` with `expiry_date` in the past. Nearing expiry: `ACTIVE`, `expiry_date` in the future, and within 14 days. Null `expiry_date` is active and not nearing expiry. Pending onboarding: `broker_onboarding_requests.status = 'PENDING'`. Open support: `LOWER(support_issues.status) = 'open'`. In progress stays a separate existing count.

## 3. Scope Boundaries & File Ownership
### Files Allowed to Change
- `C:\NB\PropKart-Backend\src\modules\dashboard\superAdminOverview.repository.js` (new)
- `C:\NB\PropKart-Backend\src\modules\dashboard\superAdminOverview.service.js` (new)
- `C:\NB\PropKart-Backend\src\modules\dashboard\superAdminOverview.controller.js` (new)
- `C:\NB\PropKart-Backend\src\modules\dashboard\dashboard.routes.js`
- `C:\NB\PropKart-Backend\test\superAdminOverview.test.js` (new)
- `C:\NB\PropKart-Backend\package.json` (register the new test in `npm test`)
- `C:\NB\propkart\lib\features\dashboard\models\super_admin_platform_overview.dart` (new)
- `C:\NB\propkart\lib\features\dashboard\services\super_admin_dashboard_service.dart` (new)
- `C:\NB\propkart\lib\features\dashboard\repository\super_admin_dashboard_repository.dart` (new)
- `C:\NB\propkart\lib\features\dashboard\bloc\super_admin_dashboard_bloc.dart` (new)
- `C:\NB\propkart\lib\features\dashboard\screens\super_admin_dashboard_screen.dart` (new)
- `C:\NB\propkart\lib\features\dashboard\screens\dashboard_screen.dart` (role branch only)
- `C:\NB\propkart\lib\features\shell\widgets\sidebar.dart` (desktop Super Admin Metrics link)
- `C:\NB\propkart\lib\core\api\api_constants.dart`
- `C:\NB\propkart\test\dashboard\super_admin_dashboard_test.dart` (new)
- `C:\NB\propkart\docs\ai-agent\templates\IMPLEMENTATION-REPORT.md`

### Files Strictly FORBIDDEN to Change
- `src/modules/dashboard/kpi/canonicalKpi.repository.js`
- `lib/core/storage/isar_collections.g.dart` and any `*.g.dart`
- `sql/migrations/*`
- `src/config/env.js`
- Existing Admin/Sales/Telecaller dashboard KPI semantics
- Mobile navigation (Super Admin Metrics already exists there)

## 4. Architectural Invariants & Constraints
- [x] **Multi-Tenant Isolation**: Organization id is accepted only after the caller is verified Super Admin. Canonical snapshot queries receive that id on a copy of the Super Admin user and do not rewrite the session.
- [x] **Authoritative Persistence**: Summary counts are PostgreSQL aggregates. Flutter renders those fields and does not sum organization rows.
- [x] **Cache Semantics**: No new Redis cache. Canonical KPI reads keep their existing cache behavior.
- [x] **Clean Layering**: Screen does not import Dio. Controller does not execute SQL. Service does not touch `req`/`res`.
- [x] **Security Boundaries**: Route middleware and service both require role `Super Admin`.
- [x] **Telemetry Invariant**: KPI snapshot failures are logged and returned as zeros; they do not fail the overview.

## 5. Implementation Strategy
1. Add `GET /api/v1/dashboard/platform-overview` with Super Admin enforcement and PostgreSQL aggregates.
2. When `organizationId` is a valid id, return one read-only snapshot and canonical KPI counts scoped to that organization.
3. Branch `/dashboard` to the new screen for Super Admin only, and add the missing desktop metrics link.
4. Test access control, SQL definitions against a rolled-back transaction, organization scoping, and responsive dashboard states.

## 6. Verification & Test Plan
- Targeted backend: `node --import ./test/setup-env.js --test test/superAdminOverview.test.js`
- Targeted Flutter: `flutter test test/dashboard/super_admin_dashboard_test.dart test/mobile/admin_screens_step35_test.dart`
- Guardrails: backend `test/ai_agent.guardrails.test.js` and `flutter test test/core/ai_agent_safety_test.dart`
- Regression: `npm test`, `flutter test`, `flutter analyze --no-fatal-infos`

## 7. Stop Conditions
- Halt if an unexpected migration is required.
- Halt if an unrelated suite fails for a reason this change cannot explain.
- Do not invent a revenue card or a root-organization exclusion.
