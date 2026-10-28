# 02 — ARCHITECTURE CONTEXT MAP & LAYER RESPONSIBILITIES

## 1. Full-Stack End-to-End Layer Flow

```text
[ Flutter Client ]
  ├── Presentation (Screens & Modular Widgets)
  │      ↓
  ├── State Management (BLoC / Cubit Reactive State Machine)
  │      ↓
  ├── Domain Use Cases (Business logic & Orchestration)
  │      ↓
  ├── Repositories (Data abstractions & Cache coordination)
  │      ↓
  └── Data Sources (Dio HTTP Client, Isar Offline Store, WebSockets)
         │
         │ (HTTP / JSON / WSS)
         ▼
[ Express Backend ]
  ├── Routes (HTTP verbs, route binding, rate limiting, validation schemas)
  │      ↓
  ├── Controllers (Request unwrapping, tenant context extraction, response formatting)
  │      ↓
  ├── Domain Services (Transactional coordination, validation, business rules)
  │      ↓
  └── Repositories (SQL query composition, parameter binding, RLS filtering)
         │
         ├───────────────────────────────┐
         ▼                               ▼
[ PostgreSQL 16 ]               [ Redis 7 Cache ]
Authoritative Store             Transient Cache-Aside & Mutexes
```

## 2. Layer Specifications & Directional Dependencies

### A. Frontend Layers (`c:/NB/propkart/lib/`)
1. **Presentation (`lib/features/**/screens/`, `lib/features/**/widgets/`):**
   - **Responsibility:** UI rendering, user event capturing, responsive layout adaptations.
   - **Allowed:** BLoC event dispatching, state observation via `BlocBuilder`/`BlocConsumer`.
   - **Forbidden:** Direct HTTP calls (`DioClient`), direct local DB queries (`isar_collections.dart`), raw KPI mathematics.
2. **State Management (`lib/features/**/bloc/`):**
   - **Responsibility:** Pure reactive state machine; maps incoming UI events to immutable UI states.
   - **Allowed:** Calling domain use cases and repositories; handling errors.
   - **Forbidden:** Subclassing `Widget` (`StatelessWidget`, `StatefulWidget`), importing `BuildContext` or `package:flutter/material.dart`.
3. **Domain Use Cases (`lib/features/**/domain/usecases/`):**
   - **Responsibility:** Encapsulating single business operations (e.g. `LoadRequirementsUseCase`, `ReclassifyCampaignLeadUseCase`).
   - **Allowed:** Interfacing with repository interfaces.
   - **Forbidden:** UI framework dependencies, database-specific drivers.
4. **Data Repositories (`lib/core/api/`, `lib/core/storage/`):**
   - **Responsibility:** Coordinating remote API retrieval and local Isar persistence (offline-first read-through/write-through).
   - **Allowed:** Dio HTTP client, Isar collections, local cache mappings.

### B. Backend Layers (`C:/NB/PropKart-Backend/src/`)
1. **Routes (`src/modules/**/*.routes.js`):**
   - **Responsibility:** URL routing, middleware binding (`authMiddleware`, `requireRole`, `correlationId`).
   - **Forbidden:** Direct database imports (`dbPool`, `supabase`), raw SQL execution.
2. **Controllers (`src/modules/**/*.controller.js`):**
   - **Responsibility:** Unwrapping Express request headers, query, and body; formatting responses into standard envelopes.
   - **Forbidden:** Direct database queries (`dbPool.query`), Redis commands.
3. **Services (`src/modules/**/*.service.js`):**
   - **Responsibility:** Core domain business logic, multi-table transactions, cache-aside coordination.
   - **Forbidden:** Express `req` and `res` objects (must remain protocol-agnostic).
4. **Repositories (`src/modules/**/*.repository.js`):**
   - **Responsibility:** Authoritative SQL queries, parameterized statements, multi-tenant `organization_id` filtering.
