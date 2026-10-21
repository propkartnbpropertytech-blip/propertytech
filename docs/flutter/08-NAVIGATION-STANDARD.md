# Routing & Navigation Standard

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  
> **Library:** `go_router: ^12.1.3`  

---

## 1. Declarative Routing Architecture

PropKart uses `go_router` for all web and mobile navigation. All routes are centrally defined in `lib/core/navigation/app_router.dart` and organized hierarchically:

```text
/ (AppShell)
├── /dashboard
├── /requirements
│   ├── /requirements/add
│   └── /requirements/:id
├── /properties
│   ├── /properties/add
│   └── /properties/:id
├── /campaign
│   └── /campaign/connections
├── /telecaller
│   └── /telecaller/callbacks
├── /sales
└── /admin
```

---

## 2. Navigation Rules & Constraints

### 2.1 Zero Business Logic in Routes
Route builders and redirects must remain strictly declarative:
- **Permitted in `redirect`:** Checking session state (e.g. redirecting unauthenticated users to `/login`) or checking user role guards (e.g. redirecting non-admins from `/admin`).
- **Prohibited in `redirect`:** Calling APIs, initializing repositories, writing to Isar, or computing analytics.

### 2.2 Deep Linking & URL Parameter Standards
- Use **Path Parameters** for resource identity: `/requirements/:id` or `/properties/:id`.
- Use **Query Parameters** for filter/view state: `/requirements?status=active&telecaller=14`.
- Use `state.extra` only for complex transient objects that cannot be serialized into a clean URL (e.g. initial form pre-fill DTOs), while ensuring the target screen handles null `extra` gracefully if accessed via direct URL.

### 2.3 Navigation Execution from BLoC vs UI
- UI widgets navigate using `context.go(path)` or `context.push(path)`.
- When an action triggers asynchronous operations (e.g. form submission), the UI should listen to the BLoC via `BlocListener` and navigate only upon receiving a success state, rather than navigating unconditionally.
