# PROPKART FLUTTER KPI PERFORMANCE ARCHITECTURE
## Step 8.5 Rendering Optimization, Rebuild Suppression & Memory Discipline

**Document Version:** 1.0.0  
**Status:** Certified Architecture  
**Scope:** UI Rendering Performance, In-Flight Request Deduplication & Memory Management  

---

## 1. Zero-Flicker State Transitions

A primary visual regression in dashboard applications occurs when changing a filter (e.g. from "Weekly" to "Monthly"): if the entire state resets to a blank `LoadingState`, the UI unmounts all widgets, shows a large spinner, and causes noticeable visual jitter.

In PropKart Step 8.5:
1. **Preserved Presentation State:**
   When `LoadDashboardKpis` or `UpdateKpiFilter` is received, `DashboardBloc` retains `currentState.data` and `currentState.kpis`, emitting:
   ```dart
   emit(currentState.copyWith(
     kpiFilters: event.filters,
     isKpiLoading: true,
   ));
   ```
2. **Subtle Loading Indication:**
   KPI cards continue rendering the previous authoritative figures with a subtle, non-blocking progress indicator in the corner until fresh network results arrive.
3. **No Widget Tree Teardown:**
   The widget tree remains stable; only the text nodes update when the new `DashboardLoadedState` arrives with `isKpiLoading: false`.

---

## 2. In-Flight Request Deduplication

When multiple UI components (e.g. Dashboard screen, Navigation Shell, and Background Refresh) concurrently request dashboard data, redundant HTTP network requests are eliminated at the service layer:

```dart
/// Shared across every [DashboardService] instance so parallel callers
/// hit the network once.
static Future<Map<String, dynamic>>? _inFlight;

Future<Map<String, dynamic>> getDashboardData() {
  return _inFlight ??= _fetch().whenComplete(() {
    _inFlight = null;
  });
}
```

Any subsequent call arriving while an HTTP request is in-flight attaches to the identical active Future, preventing server thundering herd and reducing mobile radio wakeups.

---

## 3. Rebuild Suppression via `buildWhen`

Every KPI widget tree utilizes granular `buildWhen` predicates to avoid full-screen repainting:

```dart
BlocBuilder<DashboardBloc, DashboardState>(
  buildWhen: (previous, current) {
    if (previous is DashboardLoadedState && current is DashboardLoadedState) {
      return previous.kpis != current.kpis ||
             previous.isKpiLoading != current.isKpiLoading;
    }
    return previous.runtimeType != current.runtimeType;
  },
  builder: (context, state) {
    // Renders only when KPI data or loading flag changes
  },
);
```

---

## 4. RepaintBoundaries & List Virtualization

1. **Repaint Boundaries:**
   High-frequency interactive widgets (such as charts, maps in `InventoryDemandAnalyticsSection`, and pipeline funnel bars) are isolated using `RepaintBoundary` widgets. This ensures animations and hover states do not trigger rasterization of the surrounding KPI cards.
2. **Virtualization:**
   All drill-down modals (`_InventoryDrilldownDialog`, `_LeadsDrilldownDialog`, `_SiteVisitsDrilldownDialog`, `PipelineStageDrilldownDialog`) render records using `ListView.builder` with fixed item extents or lightweight tiles, guaranteeing constant $O(1)$ memory usage regardless of result set size.
