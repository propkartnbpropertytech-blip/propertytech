# PROPKART FLUTTER PERFORMANCE ROOT CAUSES & BOTTLENECK INVENTORY
## Deep-Dive Architectural Investigation (Phase 7.0)

```text
STATUS: ROOT CAUSES IDENTIFIED & RANKED
GOAL: TARGETED, SURGICAL OPTIMIZATION
```

---

## 1. RANKED BOTTLENECK MATRIX

| ID | Severity | File / Module | Root Cause Description | Architectural Remediation |
|---|---|---|---|---|
| **RC-01** | **P0** | `lib/features/properties/screens/property_search_screen.dart` | Unbounded `Column` inside `SingleChildScrollView` renders 1,000+ property cards simultaneously without viewport recycling. | Virtualize cards using `ListView.builder` or `SliverList` with lazy recycling. |
| **RC-02** | **P0** | `lib/features/properties/screens/property_search_screen.dart` | Heavy string matching, RegEx parsing, lowercasing, and sorting executed directly inside `build()` on every frame. | Move filtering and sorting out of `build()` to trigger only on query/tab/dataset changes. |
| **RC-03** | **P0** | `lib/features/campaign/screens/campaign_leads_screen.dart` | Monolithic `Table` widget with hundreds of unpaginated `TableRow` widgets in Not Interested view. | Apply virtualized pagination to not-interested table. |
| **RC-04** | **P1** | `lib/features/campaign/bloc/campaign_leads_bloc.dart` | `CampaignLeadsState` getters `dateFilteredLeads` and `countForFilter` scan entire lead list for every filter on every frame ($6 \times N$ operations). | Pre-compute filtered lists and filter count maps during state emission. |
| **RC-05** | **P1** | `lib/features/dashboard/bloc/dashboard_bloc.dart` | Three un-debounced stream listeners (`dashboardStream`, `requirementsStream`, `propertiesStream`) trigger sequential forced remote refresh storms. | Add debounce/throttle transformer (500ms) to collapse refresh cascades. |
| **RC-06** | **P1** | `lib/features/dashboard/screens/dashboard_screen.dart` | `initState` forces remote `RefreshDashboard()` on every tab switch / navigation even if data was just loaded. | Implement stale-while-revalidate pattern; don't force refresh if cached data is fresh. |
| **RC-07** | **P1** | `lib/main.dart` | `PushNotificationService.initialize()` is awaited sequentially in `bootstrap()` before `runApp()`, blocking first frame. | Move `PushNotificationService.initialize()` into post-frame deferred callback. |
| **RC-08** | **P2** | `lib/features/library/screens/service_agent_library_screen.dart` | Raw `Image.network` calls without disk caching or dimension decode clamps causes high RAM usage on image galleries. | Replace with `CrmNetworkImage` with explicit `cacheLogicalWidth` / `thumbnail` variant. |
| **RC-09** | **P2** | `lib/features/campaign/bloc/campaign_leads_bloc.dart` | `SyncLocalLeadsEvent` equatable props only checks `[leads.length, first.id]`, potentially dropping valid state emissions. | Include deterministic list state hash/timestamp in props. |
| **RC-10** | **P2** | `lib/features/properties/screens/property_search_screen.dart` | Search input `onSubmitted` and search button call empty `setState(() {})` without debounced text controller listener. | Add clean 250ms debounced search controller listener with cancellation on dispose. |

---

## 2. DETAILED ROOT CAUSE ANALYSES

### RC-01 & RC-02: Non-Virtualized Property Search Screen
- **Symptom**: Scrolling or typing a search query in `PropertySearchScreen` stutters and drops frames.
- **Investigation**: In `property_search_screen.dart`:
  ```dart
  SingleChildScrollView(
    child: Column(
      children: filteredProps.map((p) => _buildHousingCard(p, ...)).toList(),
    ),
  )
  ```
  And in the `build()` method before rendering, lines 384–500 run:
  ```dart
  final filteredProps = allProps.where((p) {
    // RegEx match, 12 .toLowerCase() calls, word splitting, etc.
  }).toList();
  filteredProps.sort(...);
  ```
- **Consequence**: If 1,000 properties are cached, Flutter instantiates all 1,000 housing card widgets, with images, buttons, and text layouts, into the element tree simultaneously.
- **Fix**:
  1. Virtualize using `ListView.builder` or sliver-based viewport.
  2. Compute `_filteredProps` only when `_searchController.text`, `_activeCategoryTab`, `_activeListingTab`, `_activeBhkFilter`, or property dataset actually changes.

---

### RC-04: Dynamic Date Scanning in CampaignLeadsState
- **Symptom**: High CPU utilization on campaign leads screen whenever filters or tab bars re-render.
- **Investigation**: In `campaign_leads_bloc.dart`:
  ```dart
  List<IntegrationLeadModel> get dateFilteredLeads => ...;
  int countForFilter(CampaignDateFilter filter, {String? section}) => ...;
  ```
  Every time a date chip or count badge builds, it evaluates `matchesDateFilter` on all leads. For 5,000 leads and 6 filter chips, that is 30,000 date comparisons every build!
- **Fix**: Pre-compute `filterCounts` map (e.g. `Map<CampaignDateFilter, int>`) and `dateFilteredLeads` when emitting `CampaignLeadsState`. Lookups in UI then become instant $O(1)$.

---

### RC-05 & RC-06: Dashboard Cascade Refresh Storms
- **Symptom**: Lag and repeated network requests to `/api/v1/dashboard/data` and `/api/v1/dashboard/kpis`.
- **Investigation**:
  `DashboardBloc` listens to 3 streams from `RepositoryCoordinator`. During sync, all 3 streams emit within a 100ms window. Because `on<RefreshDashboard>` uses sequential transformer, it executes 3 remote roundtrips in a row. Furthermore, `DashboardScreen.initState` forces another `RefreshDashboard()`.
- **Fix**:
  1. Apply a 500ms debounce to stream listeners in `DashboardBloc`.
  2. In `DashboardScreen`, check if data was loaded within the last 60 seconds before forcing a remote refresh.

---

### RC-07: Blocking Startup Push Notification Init
- **Symptom**: App startup delayed by Firebase/OS notification initialization.
- **Investigation**: `lib/main.dart` awaits `PushNotificationService.initialize()` before `runApp()`.
- **Fix**: Push notification initialization is not required to render the login or splash screen. Defer it to `WidgetsBinding.instance.addPostFrameCallback`.
