# 02-REPOSITORY-INVENTORY.md — PropKart Full-Stack Architecture & Module Inventory

## 1. Inventory Overview
This document establishes the comprehensive module-level inventory for both the Node.js/PostgreSQL backend service (`C:/NB/PropKart-Backend`) and the Flutter client (`c:/NB/propkart`).

---

## 2. Backend Module Structure (`C:/NB/PropKart-Backend/src`)

### Core Subsystems & Directories
| Layer / Directory | File Count | SLOC | Primary Architectural Responsibility | Authoritative Status |
| :--- | :--- | :--- | :--- | :--- |
| `src/config/` | 10 | 1,842 | Environment validation, DB pooling, Redis client, metrics setup | Authoritative |
| `src/middleware/` | 12 | 2,150 | Auth JWT, RBAC guards, correlation ID, rate limiters | Authoritative |
| `src/security/` | 8 | 1,620 | ACID transaction manager, Zod validator, sanitizer, encryption | Authoritative |
| `src/services/` | 14 | 3,980 | Cache service, cron scheduler, snapshot engine, mailers | Authoritative |
| `src/utils/` | 2 | 410 | Standard API responses and HTTP errors | Authoritative |
| `src/modules/allocation/` | 6 | 2,140 | Lead distribution engine, round-robin cursor, telecaller capacity | Authoritative |
| `src/modules/analytics/` | 5 | 1,480 | Operational funnel logs and conversion reporting | Authoritative |
| `src/modules/audit/` | 4 | 920 | Audit telemetry ledger and change logging | Authoritative |
| `src/modules/auth/` | 8 | 2,850 | Login, MFA, refresh tokens, role resolution | Authoritative |
| `src/modules/campaigns/` | 6 | 1,980 | Lead campaign ingestion and multi-source tracking | Authoritative |
| `src/modules/dashboard/` | 12 | 4,520 | Canonical KPI repository, KPI service, reconciliation engine | Authoritative |
| `src/modules/health/` | 4 | 860 | Deep health check portal, liveness/readiness probes | Authoritative |
| `src/modules/housing/` | 5 | 1,350 | Housing.com integration adapter and lead normalizer | Authoritative |
| `src/modules/integrations/` | 8 | 2,640 | Meta webhook handlers, external CRM adapters | Authoritative |
| `src/modules/leads/` | 14 | 5,120 | Authoritative leads CRUD, lifecycle stages, lead activities | Authoritative |
| `src/modules/notifications/`| 5 | 1,240 | FCM dispatch, in-app notification state | Authoritative |
| `src/modules/properties/` | 16 | 6,450 | Property portfolio, media links, listing metadata | Authoritative |
| `src/modules/reports/` | 6 | 1,890 | Business insight reports, PDF generation adapters | Authoritative |
| `src/modules/settings/` | 5 | 1,120 | Organization config, team quotas, custom fields | Authoritative |
| `src/modules/share/` | 6 | 1,410 | Customer share links, tracking sessions | Authoritative |
| `src/modules/tasks/` | 5 | 1,220 | Follow-up scheduling and reminders | Authoritative |
| `src/modules/teams/` | 6 | 1,640 | Team hierarchy and assignment scopes | Authoritative |
| `src/modules/users/` | 10 | 3,420 | User management, RBAC profiles, password rotation | Authoritative |
| `sql/migrations/` | 62 | 8,210 | 62 Additive SQL migration files | Authoritative |
| `scripts/` | 18 | 3,120 | Database backup, smoke tests, restore scripts | Operational Tooling |

---

## 3. Flutter Client Module Structure (`c:/NB/propkart/lib`)

### Core Subsystems & Directories
| Layer / Directory | File Count | SLOC | Primary Architectural Responsibility | Authoritative Status |
| :--- | :--- | :--- | :--- | :--- |
| `lib/core/api/` | 12 | 4,210 | Dio HTTP client, auth/logging/fallback interceptors | Core Foundation |
| `lib/core/config/` | 6 | 1,180 | App environment configuration, endpoints, feature flags | Core Foundation |
| `lib/core/constants/` | 8 | 2,450 | KPI rulebook, app strings, asset paths | Core Foundation |
| `lib/core/design_system/` | 45 | 28,400 | Enterprise design tokens, CRM forms, buttons, layout | Presentation UI |
| `lib/core/errors/` | 4 | 720 | App exceptions, failure models, network error mapping | Core Foundation |
| `lib/core/observability/` | 8 | 2,140 | Sentry client, performance traces, breadcrumb logger | Core Observability |
| `lib/core/security/` | 5 | 1,460 | Token storage, session manager, biometric guards | Core Security |
| `lib/core/services/` | 14 | 5,820 | Audio player, background notifications, deep link service | Core Services |
| `lib/core/storage/` | 8 | 6,940 | Isar local presentation database, outbox repository | Local-First Store |
| `lib/core/sync/` | 12 | 8,450 | 10-state offline sync engine, retry queue, conflict resolver | Sync Engine |
| `lib/core/theme/` | 4 | 1,680 | Material 3 themes, color palettes, dark/light modes | Presentation UI |
| `lib/core/utils/` | 15 | 4,890 | Formatters, date helpers, phone validators, SEO helpers | Shared Utilities |
| `lib/features/auth/` | 14 | 8,230 | Login, MFA screens, auth BLoC, token refresh | Feature Domain |
| `lib/features/campaign/` | 18 | 14,200 | Campaign leads management, filters, batch reclassifier | Feature Domain |
| `lib/features/clients/` | 12 | 7,850 | Client directory, interaction histories | Feature Domain |
| `lib/features/dashboard/` | 24 | 18,920 | KPI dashboard, drilldowns, activity graphs, schedule card | Feature Domain |
| `lib/features/developer_options/`| 6 | 3,110 | Diagnostic tools, sync inspector, cache flusher | Diagnostic Tooling |
| `lib/features/followup/` | 10 | 6,420 | Followup calendar, call logs, reminder sheets | Feature Domain |
| `lib/features/home/` | 8 | 4,950 | Navigation rail, app shell integration, quick actions | Presentation UI |
| `lib/features/library/` | 16 | 11,200 | Document management, collateral attachments | Feature Domain |
| `lib/features/notifications/`| 8 | 5,140 | Notification drawer, push delivery logs | Feature Domain |
| `lib/features/profile/` | 8 | 4,680 | User profile, password management, session info | Feature Domain |
| `lib/features/properties/` | 42 | 34,200 | Property listing catalog, media upload, add/edit wizard | Feature Domain |
| `lib/features/reports/` | 14 | 9,870 | PDF/Excel export, business insights, performance graphs | Feature Domain |
| `lib/features/requirements/`| 28 | 22,400 | Buyer requirements, property matching, stage tracker | Feature Domain |
| `lib/features/settings/` | 16 | 11,540 | App settings, backup controls, organization preferences | Feature Domain |
| `lib/features/telecaller/` | 26 | 21,800 | Telecaller dialer, call disposition sheets, lead queues | Feature Domain |

---

## 4. Architectural Boundaries Summary
- **No Direct DB Calls from UI**: Flutter communicates strictly through RESTful API endpoints and WebSocket channels.
- **Isar Boundary**: Isar database is strictly a presentation and offline cache layer. Authoritative records reside in PostgreSQL.
- **Codegen Immutability**: `lib/core/storage/isar_collections.g.dart` is strictly code-generated and must never be edited manually.
