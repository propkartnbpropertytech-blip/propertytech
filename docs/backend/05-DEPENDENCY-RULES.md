# PropKart Backend Dependency Direction Rules

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`src/`)  

---

## 1. Allowed & Forbidden Dependency Vectors

PropKart enforces strict unidirectional dependencies across its architectural components.

```text
ALLOWED VECTORS                               FORBIDDEN VECTORS
==================================            ==================================
Routes      ───►  Controllers                 Controllers ───►  Raw SQL / dbPool  ❌
Controllers ───►  Services                    Controllers ───►  Raw Redis Client  ❌
Services    ───►  Repositories                Controllers ───►  Repositories      ❌
Services    ───►  Services (Cross-domain)     Repositories───►  Controllers       ❌
Services    ───►  CacheService                Repositories───►  HTTP req / res    ❌
Repositories───►  dbPool / Supabase           Services    ───►  HTTP res.json()   ❌
Repositories───►  PostgreSQL                  Circular    ───►  A -> B -> A       ❌
```

---

## 2. Dependency Invariants by Layer

### 1. Route Files (`*.routes.js`)
- **MAY IMPORT:**
  - Express `Router`
  - Route-specific middleware (`authenticate`, `validate`, rate limiters)
  - Sibling `<feature>.controller.js`
- **MUST NOT IMPORT:**
  - `<feature>.service.js` or `<feature>.repository.js`
  - `dbPool.js` or `supabase.js`
  - `redis.js` or `ioredis`
  - Other modules' controllers or services

### 2. Controller Files (`*.controller.js`)
- **MAY IMPORT:**
  - Sibling `<feature>.service.js`
  - Logger (`logger.js`)
  - Error formatting utilities (`handleControllerError`, `AppError`)
  - Input schemas or sanitizer allowlists
- **MUST NOT IMPORT:**
  - `dbPool.js` or any direct database connection pool
  - `supabase.js` (for direct database queries)
  - `redis.js` or raw Redis clients
  - Other feature controllers

### 3. Service Files (`*.service.js`)
- **MAY IMPORT:**
  - Sibling `<feature>.repository.js`
  - External module repositories or services for cross-domain orchestration (e.g. `NotificationService`, `AuditService`, `RequirementsRepository`)
  - `CacheService` (`src/services/cache.service.js`)
  - Transaction runners (`withTransaction`, `withSavepoint`)
  - Error domain classes (`BadRequestError`, `ForbiddenError`, `NotFoundError`)
- **MUST NOT IMPORT:**
  - Express `req`, `res`, `next` objects
  - Route definitions

### 4. Repository Files (`*.repository.js`)
- **MAY IMPORT:**
  - `dbPool.js` (PostgreSQL client pool)
  - `supabase.js` (Supabase query builder where appropriate)
  - Security tenant filter helpers (`applyOrgFilter`, `sanitizeSearchTerm`)
- **MUST NOT IMPORT:**
  - Controllers or Route definitions
  - Express transport objects (`req`, `res`)
  - Services (to eliminate circular dependencies)

---

## 3. Circular Dependency Elimination

Circular dependencies (`A -> B -> A`) cause module loading deadlocks, undefined export bindings at runtime, and confuse AI coding assistants.

**Elimination Pattern:**
When two services require information from one another:
1. Extract shared definitions, types, or pure utility functions into a third, independent file (e.g., `kpi.definitions.js`).
2. Alternatively, move the cross-domain orchestration logic into a dedicated orchestrator service (e.g., `LeadIngestEngine`).

---

## 4. Automated Architecture Verification

All dependency direction rules are automatically verified in CI/CD via:
```bash
npm test
# Executes test/architecture.rules.test.js & test/architecture.contract.test.js
```
Any PR violating these dependency vectors fails the build immediately.
