# PropKart — Frontend Performance Standards & Invariants
**Step 7 Frontend Performance Engineering**

This document establishes the mandatory performance standards, architecture guardrails, and coding invariants for the PropKart Flutter application. All existing features and future contributions must adhere to these standards.

---

## 1. Startup & Initialization Standards
- **Critical Path Budget**: The code path executed before `runApp()` must strictly complete in $< 500\text{ ms}$.
- **Only Essential Offline Engines on Critical Path**:
  - `WidgetsFlutterBinding.ensureInitialized()`
  - `ApiConstants.assertConfig()`
  - Platform media player hook (e.g. `initWindowsVideoPlayer()`)
  - Local SQLite/Isar database initialization (`IsarService().initialize()`)
- **Mandatory Deferral to Post-Frame**:
  - All non-blocking services (Push notifications, Firebase Cloud Messaging, Sentry logging, `PerformanceLogger`, background sync daemon) **MUST** be deferred to `WidgetsBinding.instance.addPostFrameCallback((_) async { ... })`.
  - **Rule**: Never `await` external device token registration or remote HTTP network calls before the first frame is painted.

---

## 2. Rendering & Viewport Standards
- **Bounded Rendering Invariant**:
  - Any list or table capable of holding $> 20$ elements **MUST** use a virtualized rendering strategy (`ListView.builder`, `GridView.builder`, `CustomScrollView` with `SliverList.builder`, or explicit page-sized chunks).
  - **Forbidden**: `SingleChildScrollView` wrapping a `Column(children: list.map(...).toList())` or un-paginated `Table` widget for dynamic collections.
  - **Invariant**: The number of active rendered item elements in the tree must be strictly bounded by the viewport size ($\approx 4\text{ to }12$ items) regardless of whether the dataset contains 50 items or 5,000 items.
- **Scroll Jank Prevention**:
  - Item builders in virtualized lists must never perform synchronous I/O, heavy parsing, or un-memoized object transformations.

---

## 3. UI Build Method Purity
- **Zero Heavy Computations inside `build()`**:
  - RegEx evaluations, sorting (`list.sort(...)`), multiple string `.toLowerCase()` passes, and word splitting are **strictly prohibited** inside `build()`.
  - Filtering and sorting must be memoized or triggered by user input events, cached until source data or query parameters change.
- **No State Mutation during `build()`**:
  - State variables (e.g. filter chips, active tab values) must never be updated inside `build()`. All mutations must occur inside event handlers or controller callbacks.
- **Debounced Text Input**:
  - Any search or filter `TextEditingController` that recalculates dynamic collections must debounce input with a minimum delay of $250\text{ ms}$ and cancel any pending timers on `dispose()`.

---

## 4. BLoC & State Management Standards
- **Deterministic State Identity**:
  - Do **NOT** use raw timestamps (e.g. `DateTime.now().millisecondsSinceEpoch`) in `Equatable` props to force widget rebuilds.
  - State and event identity must rely on deterministic properties or content hashing (e.g. `_computeLeadsHash(leads)` combining IDs and update timestamps).
- **Precomputed State Querying**:
  - Derived calculations (e.g. category counts, date filter tallies, pre-filtered lists) that are accessed repeatedly during build frames must be precomputed once upon state emission in the BLoC or state constructor.
  - UI getters and count methods must execute in $O(1)$ time.
- **Stream Listener Storm Prevention**:
  - When a BLoC subscribes to local database or coordinator change streams (`dashboardStream`, `requirementsStream`, `propertiesStream`), it **MUST** debounce emissions (e.g., $500\text{ ms}$) to prevent back-to-back refresh cascades during batch operations.
- **Droppable Concurrency for Network Refreshes**:
  - High-cost remote refresh events (e.g. `RefreshDashboard`) must use a droppable event transformer so that duplicate concurrent events dispatched while a fetch is already in flight are safely dropped.

---

## 5. Media & Network Image Standards
- **Mandatory `CrmNetworkImage` Usage**:
  - All network images displayed across screens, avatars, document cards, and data tables must use `CrmNetworkImage` instead of raw `Image.network`.
- **Decode Cache Clamping**:
  - Always specify `cacheLogicalWidth` and `cacheLogicalHeight` matching the widget's on-screen layout bounds (e.g. 36px for table avatars, 52px for cards, 80px for detail dialogs).
  - This ensures images are decoded into memory at display size rather than raw 4K/1080p sensor resolution.
- **CDN Transformation Variants**:
  - Use appropriate `CrmImageVariant` (`thumbnail`, `preview`, `fullscreen`) to leverage server-side Cloudinary compression and auto-formatting (WebP/AVIF).
