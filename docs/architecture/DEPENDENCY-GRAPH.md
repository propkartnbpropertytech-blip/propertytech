# PROPKART — SYSTEM DEPENDENCY GRAPH & VIOLATIONS MAP
**Version:** 1.0.0  
**Status:** CANONICAL DEPENDENCY GRAPH (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** End-to-End System Flow & Visual Violation Registry  

---

## 1. Target End-to-End Dependency Flow

In the target architecture, dependencies flow strictly downward and inward. No layer may skip intermediate tiers or point upward.

```mermaid
graph TD
    subgraph Client_Platform ["Flutter Client (lib/)"]
        UI["Flutter UI (Screens & Atomic Widgets)"]
        State["Presentation State (BLoC / Cubit)"]
        UseCase["Application Layer (Use Cases & Facades)"]
        Domain["Domain Layer (Entities & Repository Interfaces)"]
        RepoImpl["Data Repositories Implementation"]
        DataSources["DataSources (Remote Dio Client & Local Isar DAO)"]
    end

    subgraph Transport ["Network Boundary"]
        HTTP["HTTP / REST (TLS Encrypted JSON)"]
    end

    subgraph Server_Platform ["Node.js / Express Backend (src/)"]
        Router["Express Routers (/api/v1/*)"]
        Controller["Controllers (Request Parsing & Response Envelope)"]
        Service["Domain Services (Business Logic & Transactions)"]
        BackendRepo["Backend Repositories (Data Access Layer)"]
    end

    subgraph Data_Stores ["Infrastructure & Persistence"]
        Postgres[("PostgreSQL 16 (Authoritative Database)")]
        RedisStore[("Redis (Cache-Aside & Security Store)")]
        CloudinaryCDN["Cloudinary / S3 (Media CDN)"]
        ThirdParty["External Services (Meta Graph API / Housing)"]
    end

    UI --> State
    State --> UseCase
    UseCase --> Domain
    RepoImpl -.->|"Implements"| Domain
    UseCase --> RepoImpl
    RepoImpl --> DataSources
    DataSources --> HTTP

    HTTP --> Router
    Router --> Controller
    Controller --> Service
    Service --> BackendRepo
    Service --> RedisStore
    Service --> ThirdParty
    BackendRepo --> Postgres
    DataSources -.->|"Media URLs"| CloudinaryCDN
```

---

## 2. Current Architecture Flow with Active Violations

The current implementation contains multiple severe architectural violations where components skip layers, invert dependency flow, or bypass isolation boundaries entirely:

```mermaid
graph TD
    subgraph Current_Flutter ["Flutter Client (Current Implementation)"]
        Screen["Screen Widgets (e.g. requirements_screen.dart: 15.9k lines)"]
        BLoC["BLoC (e.g. lead_allocation_monitor_bloc.dart: 2.3k lines)"]
        SyncMgr["core/network/sync_manager.dart"]
        DioClient["core/api/dio_client.dart"]
        IsarDB["core/storage/isar_service.dart"]
        FeatureA["Feature: Requirements"]
        FeatureB["Feature: Properties"]
    end

    subgraph Current_Backend ["Backend Service (Current Implementation)"]
        AppJS["src/app.js (/diagnostics/crud)"]
        FatControllers["Controllers (e.g. auth.controller.js: 1.2k lines)"]
        FatServices["Services (e.g. kpi.service.js: 5.5k lines)"]
        BackendRepos["Partial Repositories (properties.repository.js)"]
        SupaClient["@supabase/supabase-js (service_role)"]
        PGPool["pg.Pool (dbPool.js)"]
    end

    subgraph Current_DB ["PostgreSQL 16"]
        DBTables[("Postgres Tables (leads, properties, etc.)")]
        Triggers["Bi-Directional Triggers (leads <-> requirements)"]
    end

    %% CRITICAL VIOLATIONS (RED ARROWS)
    Screen ==>|"VIOLATION 1: Direct Dio HTTP Call from Widget"| DioClient
    Screen ==>|"VIOLATION 2: Direct Isar DB Call from Widget"| IsarDB
    BLoC ==>|"VIOLATION 3: UI Screen embedded inside BLoC file"| Screen
    SyncMgr ==>|"VIOLATION 4: Core importing 15+ Feature modules"| FeatureA
    SyncMgr ==>|"VIOLATION 4: Core importing 15+ Feature modules"| FeatureB
    FeatureA ==>|"VIOLATION 5: Direct Cross-Feature Internal Coupling"| FeatureB

    AppJS ==>|"VIOLATION 6: Direct raw DB queries in app.js"| SupaClient
    FatControllers ==>|"VIOLATION 7: Direct DB queries bypassing Service"| SupaClient
    FatServices ==>|"VIOLATION 8: 5,000+ lines of raw SQL in Service"| PGPool
    FatServices ==>|"VIOLATION 9: Direct Supabase Client bypassing Repo"| SupaClient
    DBTables ==>|"VIOLATION 10: Recursive DB triggers syncing tables"| Triggers

    %% Standard Flow (Gray/Normal)
    Screen --> BLoC
    DioClient --> AppJS
    FatControllers --> FatServices
    FatServices --> BackendRepos
    BackendRepos --> PGPool
    PGPool --> DBTables
    SupaClient --> DBTables

    classDef violation stroke:#FF0000,stroke-width:3px,color:#FF0000;
    class Screen,BLoC,SyncMgr,AppJS,FatControllers,FatServices,Triggers violation;
```

---

## 3. Cataloged Violation Details

| Violation ID | Component From | Component To | Description & Risk | Target Layer Resolution |
| :--- | :--- | :--- | :--- | :--- |
| **VIO-01** | `requirements_screen.dart` | `DioClient` | Widget executes direct HTTP requests (`DioClient.dio.get`). Prevents offline queuing, unit testing, and breaks UI responsiveness. | Must call `RequirementsBloc` -> `RequirementsRepository`. |
| **VIO-02** | `requirements_screen.dart` | `LocalRepositories` | Widget queries local Isar database directly within `setState`. Couples UI to local schema. | Must read from `RequirementsRepository` abstraction. |
| **VIO-03** | `lead_allocation_monitor_bloc.dart` | `LeadAllocationMonitorScreen` | The entire 2,050-line UI screen is embedded inside the BLoC file. Impossible to test BLoC headlessly. | Extract UI into `presentation/screens/`. BLoC file contains state machine only. |
| **VIO-04** | `core/network/sync_manager.dart` | `features/*/models & services` | Core infrastructure imports 15 feature directories. Severe architectural inversion. | Invert dependency: Features register `SyncParticipant` interfaces with core. |
| **VIO-05** | `features/requirements/` | `features/properties/` | Requirements screen directly imports `PropertiesRepository` and `PropertiesService` internal files. | Mediate access via `PropertiesFacade`. |
| **VIO-06** | `src/app.js` | `@supabase/supabase-js` | Diagnostic endpoint (`/diagnostics/crud`) executes direct database mutations inside application root bootstrap file. | Relocate logic to `health.controller.js` and `health.service.js`. |
| **VIO-07** | `src/modules/auth/auth.controller.js` | PostgreSQL | Controller performs password hashing, token creation, and database writes directly. | Move logic to `auth.service.js` and `users.repository.js`. |
| **VIO-08** | `src/modules/dashboard/kpi.service.js` | `pg.Pool` | Domain service builds 5,000+ lines of raw SQL string concatenations. | Move SQL compositions to `kpi.repository.js`. Service computes business metrics. |
| **VIO-09** | Backend Application | `@supabase/supabase-js` & `pg.Pool` | Split database drivers causing duplicate connection overhead and inconsistent transactions. | Deprecate Supabase client in backend; unify on `pg.Pool` with `timedQuery`. |
| **VIO-10** | PostgreSQL `leads` | PostgreSQL `requirements` | Bi-directional triggers automatically mutate sibling tables, creating circular lock risks and hidden side-effects. | Transition table synchronization to the backend application service layer. |
