# PROPKART — MASTER ARCHITECTURE RULES & CONSTITUTION
**Version:** 1.0.0  
**Status:** PERMANENT ENGINEERING CONSTITUTION  
**Date:** October 19, 2026  
**Scope:** Universal Engineering Governance for PropKart Platform  

---

## The Twenty Canonical Engineering Commandments

These twenty rules constitute the permanent architectural constitution of PropKart. Every future pull request, refactor, and AI agent prompt execution must comply with these commandments. Violations must be flagged as blockers during code review and automated linting gates.

---

### RULE 1: No Giant Mixed-Responsibility Files
Files exceeding 800 lines (backend) or 1,000 lines (frontend) are strict architectural violations. Files must adhere to the Single Responsibility Principle (SRP). Screens must only compose UI; state machines must only manage state; use cases must only execute business actions; repositories must only coordinate data.

### RULE 2: No Business Logic Inside UI Widgets
Flutter widgets and screens must NEVER contain mathematical calculations, filtering algorithms, KPI derivations, date offset logic, or business validation rules. UI widgets must only bind to state and dispatch user intent.

### RULE 3: No Direct Server Database Access from UI
The Flutter client must NEVER query server PostgreSQL or Supabase tables directly. All interactions with server data must be mediated through the Node.js/Express REST API.

### RULE 4: No Random or Ad-Hoc API Calls
HTTP requests must never be executed directly within UI widgets or BLoC classes. All network communication must pass through typed Remote DataSources and domain Repository contracts using centralized endpoint constants.

### RULE 5: Zero Duplicated Business Rules
Every business rule, validation constraint, and lifecycle state transition must have exactly ONE canonical owner across the platform. Client-side rules are strictly optimistic previews, never independent authorities.

### RULE 6: Zero Duplicated KPI Calculations
The backend Domain KPI Service (`src/modules/dashboard/kpi.service.js`) is the sole canonical source of KPI formulations and counts. The Flutter client must NEVER recalculate or count metrics independently from server response payloads.

### RULE 7: No Random or Direct Redis Access
Cache storage must be accessed exclusively through the centralized `CacheService` abstraction. Direct Redis commands scattered across controllers or services are strictly forbidden.

### RULE 8: No Circular Dependencies
Circular module imports (`A` $\rightarrow$ `B` $\rightarrow$ `A`) are forbidden across both frontend and backend. Dependencies must flow strictly inward: Presentation $\rightarrow$ Application $\rightarrow$ Domain $\leftarrow$ Data.

### RULE 9: No Hidden Global State
Global mutable variables, unmanaged static singletons holding business state, and implicit ambient context are prohibited. State must be explicitly injected via BLoC, dependency injection, or constructor parameters.

### RULE 10: Strict Cross-Feature Isolation
Features must never import the private UI widgets, screens, local databases, or internal models of other features. Cross-feature communication must take place exclusively through exported Public Facades or asynchronous Domain Events.

### RULE 11: Every Feature Has an Explicit Bounded Owner
Every feature module in `lib/features/` and `src/modules/` must have an explicit owner, a documented domain boundary, and an isolated unit test suite.

### RULE 12: Every Data Domain Has One Canonical Source of Truth
PostgreSQL is the single authoritative source of business truth. Client-side storage (Isar, SharedPreferences) and server caching (Redis/Memory) are non-authoritative read projections or transient staging buffers.

### RULE 13: Every Backend Endpoint Has Single-Tier Controller Responsibility
Controllers only parse requests, call domain services, and return typed HTTP status responses. Controllers must never construct SQL queries, mutate database records directly, or calculate business metrics.

### RULE 14: Every Database Query Has a Defined Repository Owner
Domain services must never execute raw SQL query strings directly. All database access must be encapsulated inside typed Repository classes within the data layer.

### RULE 15: Every Cache Has an Explicit Justification & Invalidation Policy
Caching must never be used to mask bad database query design or poor indexing. Every cache entry must have a defined TTL, an explicit invalidation trigger on mutation, and a cache-miss fallback path.

### RULE 16: Every Sync Operation Has Defined Ownership & Server-Wins Precedence
Offline mutations buffered in the client Outbox queue are non-authoritative proposals. The backend synchronization service is the final arbiter of conflict resolution, enforcing a strict server-wins timestamp policy.

### RULE 17: Every Critical Business Rule Must Be Testable in Isolation
Business logic, matching algorithms, and allocation rules must reside in pure, framework-agnostic classes that can be unit tested without starting Flutter UI rendering or booting live database connections.

### RULE 18: New Code Must Follow the Target Architecture Before Migration
New features, endpoints, or screens must be implemented strictly according to the Target Clean Architecture. Technical debt in legacy files must never be accepted as justification for violating rules in new code.

### RULE 19: Do Not Solve Architecture Problems with Arbitrary Caching
Performance bottlenecks caused by unindexed database scans, N+1 query loops, or bloated JSON payloads must be fixed at the source, not papered over with in-memory caching.

### RULE 20: Do Not Solve Database Problems with Frontend Workarounds
Missing relational constraints, dirty data, or lack of pagination must be resolved in PostgreSQL and the backend API, never worked around with fragile filtering loops on the client device.
