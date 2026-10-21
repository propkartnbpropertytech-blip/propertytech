# Flutter Layering & Dependency Direction Standard

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  
> **Reference Architecture:** Clean Architecture & BLoC Pattern  

---

## 1. Unidirectional Dependency Flow

PropKart enforces a strict unidirectional dependency architecture across all Flutter feature modules. Dependencies may only point **downward** toward lower layers:

```text
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   Screens, Modular Widgets, Modals & Dialogs           │
└───────────────────────────┬────────────────────────────┘
                            │ depends on / dispatches events
                            ▼
┌────────────────────────────────────────────────────────┐
│                 STATE MANAGEMENT LAYER                 │
│   BLoC / Cubit (Events, States, Transformers)          │
└───────────────────────────┬────────────────────────────┘
                            │ calls
                            ▼
┌────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                      │
│   Use Cases (Single Business Operations), Entities     │
└───────────────────────────┬────────────────────────────┘
                            │ calls contracts (Abstract Repos)
                            ▼
┌────────────────────────────────────────────────────────┐
│                   DATA ACCESS LAYER                    │
│   Repositories (Offline-first coordinator, cache logic)│
└───────────────────────────┬────────────────────────────┘
                            │ queries
                            ▼
┌────────────────────────────────────────────────────────┐
│                   DATA SOURCES LAYER                   │
│   LocalDataSource (Isar / IndexedDB)                   │
│   RemoteDataSource (Dio REST API / Supabase Realtime)  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Layer Responsibilities & Constraints

| Layer | Permitted Actions | Prohibited Actions (Architecture Violations) |
| :--- | :--- | :--- |
| **Presentation (Screens & Widgets)** | • Render UI based on BLoC state<br>• Dispatch BLoC events / call Cubit methods<br>• Trigger routing/navigation<br>• Simple local ephemeral state (`AnimationController`, `TextEditingController`) | ❌ Direct `Dio` HTTP calls<br>❌ Direct `Isar` or `Supabase` database queries<br>❌ Business validation & filtering calculations<br>❌ Parsing JSON responses |
| **State Management (BLoC / Cubit)** | • Receive UI events<br>• Execute Use Cases<br>• Map domain entities to view states<br>• Retain flicker-free cache states | ❌ Direct database queries or mutations<br>❌ Importing `package:flutter` UI widgets (except Flutter foundation/types)<br>❌ Navigating directly (must emit state/events or rely on router listeners) |
| **Domain (Use Cases)** | • Encapsulate a single business operation (e.g. `UpdateRequirementStatusUseCase`)<br>• Orchestrate multiple repositories if needed<br>• Pure Dart business rules & validation | ❌ Platform/UI dependencies<br>❌ Direct HTTP or raw database serialization |
| **Data (Repositories)** | • Coordinate offline caching (read Isar first, then network revalidate)<br>• Handle optimistic UI rollback<br>• Translate DTOs to Domain Entities<br>• Map exceptions to Domain Failures | ❌ Emitting Flutter UI widgets<br>❌ Storing ephemeral UI state (e.g. active tab index) |
| **Data Sources** | • Raw HTTP calls via Dio<br>• Raw CRUD queries against Isar / Supabase<br>• Local storage key/value operations | ❌ Business decision making<br>❌ Presentation dependencies |

---

## 3. Strict Boundary Violation Matrix

```text
┌───────────────────────────────────┬─────────────┬───────────────────────────────────────────────────────────┐
│ Detected Pattern                  │ Status      │ Remediation                                               │
├───────────────────────────────────┼─────────────┼───────────────────────────────────────────────────────────┤
│ `Screen -> DioClient.get()`       │ 🔴 CRITICAL │ Move API call to RemoteDataSource & trigger via BLoC      │
│ `Widget -> isar.writeTxn(...)`    │ 🔴 CRITICAL │ Delegate mutation to Repository via Use Case              │
│ `BLoC -> isar.collection...`      │ 🔴 CRITICAL │ Access storage exclusively through Repository contract    │
│ `BLoC -> Widget / BuildContext`   │ 🔴 CRITICAL │ Remove UI references; emit pure state objects             │
│ `Repository -> BuildContext`      │ 🔴 CRITICAL │ Repositories must remain 100% agnostic of Flutter UI      │
│ `Feature A -> Feature B (private)`│ 🟠 HIGH     │ Communicate via public models or shared event buses       │
└───────────────────────────────────┴─────────────┴───────────────────────────────────────────────────────────┘
```

---

## 4. Error Propagation Standard

Errors must propagate gracefully through the layers without unhandled crashes:

```text
DioException / IsarError (Data Source)
   ↓
Catches raw error and translates to ServerFailure / StorageFailure (Repository)
   ↓
Emits FailureState(errorMessage: failure.message) (BLoC)
   ↓
Renders user-friendly banner, toast, or retry button (UI Presentation)
```
