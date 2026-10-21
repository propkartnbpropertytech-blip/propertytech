# PropKart Feature Module Boundaries & Cross-Module Rules

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`src/modules/`)  

---

## 1. Domain-Driven Feature Module Standard

PropKart organizes all backend logic into self-contained feature modules located under `src/modules/`. Each module represents a cohesive bounded context within the real estate CRM ecosystem.

### Feature Module Directory Contract
Every module must conform to this standardized structure:

```text
src/modules/<feature>/
  ├── <feature>.routes.js         # Endpoint definitions and middleware bindings
  ├── <feature>.schemas.js        # Request payload Zod validation schemas
  ├── <feature>.controller.js     # HTTP request/response handling and translation
  ├── <feature>.service.js        # Business domain logic and orchestration
  ├── <feature>.repository.js     # Direct SQL / Supabase data access layer
  └── <feature>.sanitize.js       # Field-level mass-assignment allowlists (optional)
```

---

## 2. PropKart Feature Module Catalogue

The PropKart backend comprises the following primary feature modules:

| Module Domain | Bounded Context Responsibility | Decoupling Status |
| :--- | :--- | :--- |
| `properties` | Property inventory, catalog, duplicate detection, media, bin | Layered (Controller -> Service -> Repo) |
| `requirements` | Client requirements, budget matching, buyer criteria | Layered (Controller -> Service -> Repo) |
| `dashboard` / `kpi` | Executive analytics, conversion rates, operational KPIs | Layered (`kpi.definitions.js` modularized) |
| `export` | CSV streaming, Excel multi-sheet executive workbooks | Layered (Controller -> Service -> Repo) |
| `search` | Full-text keyword search across inventory & requirements | Layered (Controller -> Service -> Repo) |
| `checklist` | Lead verification workflows and operational task lists | Layered (Controller -> Service -> Repo) |
| `notifications` | In-app alerts, push notifications, read states | Layered (Controller -> Service -> Repo) |
| `usage` | Tenant API consumption and telemetry metrics | Layered (Controller -> Service -> Repo) |
| `places` | Google Places autocomplete and locality resolution | Layered (Controller -> Service -> Repo) |
| `integrations` | Meta Ads webhooks, Housing.com lead ingest, columns | Layered (`campaignColumns.service.js` modularized) |
| `allocation` | Telecaller lead assignment, capacity, round-robin engine | Core Engine Layered |
| `matching` | AI requirement-to-property matching algorithms | Service Layered |
| `auth` | Authentication, JWT token issuance, session refresh, MFA | Controller Layered |
| `users` | User roster, team assignments, RBAC role administration | Repository Layered |

---

## 3. Cross-Module Interaction Rules

To maintain high AI maintainability and prevent spaghetti coupling:

### Rule 1: Public Service Facade
Modules must only interact with each other through their **public Service or Repository methods**. Direct access to another module's internal controller methods or non-exported helper functions is strictly forbidden.

```javascript
// ✅ CORRECT: Dashboard queries Requirements via RequirementsRepository
import { RequirementsRepository } from "../requirements/requirements.repository.js";
const pendingReqs = await RequirementsRepository.getRequirementById(reqId);

// ❌ FORBIDDEN: Dashboard controller importing requirements controller
import { RequirementsController } from "../requirements/requirements.controller.js";
```

### Rule 2: Shared Cross-Cutting Infrastructure
Infrastructure capabilities that span multiple feature domains live in centralized shared directories:
- `src/config/`: `dbPool.js` (PostgreSQL), `redis.js` (Redis client), `env.js`, `logger.js`.
- `src/services/`: `cache.service.js` (CacheService), `audit.service.js` (AuditService), `notification.service.js`.
- `src/security/`: `tenant.js` (Tenant context), `tokens.js` (JWTs), `architecturalGuard.js`, `password.js`.
- `src/middleware/`: `auth.middleware.js`, `zodValidate.middleware.js`, `error.middleware.js`.

### Rule 3: Single Direction of Domain Flow
Higher-level orchestrators may import lower-level entities, but lower-level entities must never import higher-level orchestrators:
- `AllocationService` may import `IntegrationsService` or `RequirementsRepository`.
- `RequirementsRepository` must **NEVER** import `AllocationService`.

---

## 4. Verification

Module boundaries are enforced via static analysis and automated testing in `test/architecture.rules.test.js` and `test/architecture.contract.test.js`.
