# 11 — REPOSITORY NAVIGATION & DIRECTORY MAP

## 1. Monorepo High-Level Layout
PropKart is structured across two primary local workspace directories:
- **`c:/NB/propkart`**: Flutter cross-platform client (Web, Android, Desktop).
- **`C:/NB/PropKart-Backend`**: Node.js/Express backend service and database migrations.

---

## 2. Flutter Client Directory Map (`c:/NB/propkart`)

```text
c:/NB/propkart/
├── AGENTS.md                  <── Primary AI Agent entry point and governance
├── pubspec.yaml               <── Pinned dependencies & build configuration
├── analysis_options.yaml       <── Linter rules & analyzer options
├── lib/
│   ├── main.dart              <── Application entry point & service bootstrap
│   ├── core/                  <── Foundational cross-cutting utilities
│   │   ├── api/               <── DioClient, logging interceptor, auth interceptor
│   │   ├── config/            <── App environment parameters
│   │   ├── constants/         <── Color palettes, spacing, UI constants
│   │   ├── design_system/     <── Shared UI widgets, app shell, navigation rails
│   │   ├── network/           <── Sync engine, durable outbox, Phoenix realtime
│   │   ├── security/          <── Token storage, biometric auth, encryption
│   │   ├── storage/           <── Isar local database collections & migrations
│   │   └── utils/             <── AppLogger, error formatters, date formatters
│   └── features/              <── Domain feature modules (Clean Architecture)
│       ├── admin/             <── User management, role assignment, system configs
│       ├── auth/              <── Login, MFA, captcha, session recovery
│       ├── campaign/          <── Ad campaigns, form webhooks, lead ingestion
│       ├── dashboard/         <── Executive KPI dashboard, analytics cards
│       ├── properties/        <── Inventory catalog, filtering, media uploads
│       ├── reports/           <── Business insight reports, CSV exports
│       ├── requirements/      <── Client requirements, budget matching
│       ├── sales/             <── Sales pipeline, stage transitions, won deals
│       └── telecaller/        <── Telecaller queue, call logs, qualification
├── test/                      <── Comprehensive test suites (952 tests)
│   ├── core/                  <── Architecture rules, safety tests, logging tests
│   ├── bloc/                  <── Reactive BLoC/Cubit unit tests
│   ├── features/              <── Feature-specific presentation and domain tests
│   └── sync/                  <── Offline sync and outbox test suites
└── docs/                      <── Architectural and operational documentation
    ├── ai-agent/              <── AI coding agent contexts and standards
    └── devops/                <── DevOps runbooks and release specifications
```

---

## 3. Backend Service Directory Map (`C:/NB/PropKart-Backend`)

```text
C:/NB/PropKart-Backend/
├── AGENTS.md                  <── Primary AI Agent entry point for backend
├── package.json               <── Dependencies, scripts, and test definitions
├── Dockerfile                 <── Production multi-stage Docker build
├── docker-compose.prod.yml    <── Production service orchestration & resource limits
├── scripts/
│   └── smoke_test.js          <── 6-probe automated deployment smoke test
├── sql/
│   └── migrations/            <── All 60 additive PostgreSQL migrations
├── src/
│   ├── app.js                 <── Express application setup, security middleware
│   ├── server.js              <── HTTP server listener & graceful shutdown lifecycle
│   ├── config/                <── Database pool, Redis, logger, env, metrics
│   ├── middleware/            <── Auth, correlationId, rateLimit, errorHandling
│   ├── modules/               <── Feature domain modules
│   │   ├── allocation/        <── Unified lead round-robin allocation engine
│   │   ├── auth/              <── Authentication, JWT issuance, captcha
│   │   ├── dashboard/         <── KPI controller, CanonicalKpiRepository, KpiService
│   │   ├── integrations/      <── Meta Graph API, Housing.com pull/push pollers
│   │   ├── properties/        <── Property repository, search, status transitions
│   │   ├── reports/           <── Report aggregations & CSV exports
│   │   ├── requirements/      <── Requirements lifecycle, matching engine
│   │   ├── site_visits/       <── Site visit scheduling & historical ledger
│   │   └── users/             <── User management, profiles, RBAC enforcement
│   └── services/              <── Cross-module services (cache, cron, snapshot)
└── test/                      <── Comprehensive backend test suites (239 tests)
    ├── ai_agent.guardrails.test.js
    ├── architecture.rules.test.js
    ├── canonical.kpi.repository.test.js
    └── devops.infrastructure.test.js
```
