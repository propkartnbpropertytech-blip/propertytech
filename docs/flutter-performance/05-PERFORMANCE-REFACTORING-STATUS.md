# PropKart — Performance Refactoring Status Ledger
**Step 7 Frontend Performance Engineering**

This ledger records all modified files, root causes addressed, specific technical changes made, and their verification status.

---

## 1. Refactoring Ledger

| ID | Priority | File Modified | Component / Area | Action Taken | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PRF-01** | **P1** | `lib/main.dart` | Startup Lifecycle | Deferred `PushNotificationService.initialize()` into `WidgetsBinding.instance.addPostFrameCallback`, removing non-critical network/FCM setup from the critical startup path before `runApp()`. | ✅ VERIFIED |
| **PRF-02** | **P1** | `lib/features/dashboard/bloc/dashboard_bloc.dart` | Dashboard Concurrency | Added 500ms debounce timer `_debouncedStreamRefresh()` for coordinator streams; added non-blocking `_droppable()` transformer for `RefreshDashboard` to drop concurrent duplicate refreshes; made `DashboardService` injectable. | ✅ VERIFIED |
| **PRF-03** | **P1** | `lib/features/dashboard/screens/dashboard_screen.dart` | Dashboard Navigation | Replaced unconditional `add(RefreshDashboard())` in `initState` with `if (state is! DashboardLoadedState) add(LoadDashboard())`, implementing stale-while-revalidate to prevent forced network fetches on screen push. | ✅ VERIFIED |
| **PRF-04** | **P1** | `lib/features/campaign/bloc/campaign_leads_bloc.dart` | Campaign State Computation | Precomputed `filterCounts` map and `dateFilteredLeads` list on state emission in `copyWith`; optimized `matchesDateFilter` with cached duration subtraction; replaced shallow props in `SyncLocalLeadsEvent` with deterministic content hashing (`_computeLeadsHash`). | ✅ VERIFIED |
| **PRF-05** | **P0** | `lib/features/properties/screens/property_search_screen.dart` | Viewport Virtualization | Replaced un-virtualized `Column` inside `SingleChildScrollView` with `CustomScrollView` and `SliverList.builder` (`SliverChildBuilderDelegate`), guaranteeing bounded viewport rendering for 1,000+ items. | ✅ VERIFIED |
| **PRF-06** | **P0** | `lib/features/properties/screens/property_search_screen.dart` | Build Purity & Memoization | Extracted RegEx matching, `.toLowerCase()`, word splitting, and `.sort()` out of `build()` into memoized `_getFilteredProperties()` cache; added 250ms debounced search controller listener with proper timer disposal. | ✅ VERIFIED |
| **PRF-07** | **P0** | `lib/features/campaign/screens/campaign_leads_screen.dart` | Not Interested Table Pass | Replaced 4 repeated `.where()` traversals over `notInterestedLeads` with a single linear $O(N)$ pass that computes sub-filter lists and counts simultaneously. | ✅ VERIFIED |
| **PRF-08** | **P2** | `lib/features/library/screens/agent_widgets.dart` | Media & Image Caching | Replaced raw `Image.network` with `CrmNetworkImage`, configuring logical decode cache bounds (`cacheLogicalWidth: 100`, `cacheLogicalHeight: 100`) and fallback error handling. | ✅ VERIFIED |
| **PRF-09** | **P2** | `lib/features/library/screens/library_widgets.dart` | Media & Image Caching | Replaced raw `Image.network` with `CrmNetworkImage`, configuring logical decode cache bounds (`cacheLogicalWidth: 104`, `cacheLogicalHeight: 104`) and disk caching. | ✅ VERIFIED |
| **PRF-10** | **P2** | `lib/features/library/screens/service_agent_library_screen.dart` | Media & Image Caching | Migrated 5 raw `Image.network` instances (detail modal, document preview, card avatar, mobile document card, data table avatar) to `CrmNetworkImage` with explicit size clamps. | ✅ VERIFIED |
| **PRF-11** | **P1** | `test/performance/campaign_leads_state_performance_test.dart` | Automated Guardrails | Implemented automated unit test benchmark verifying $O(1)$ precomputed state lookups and deterministic content hashing in `CampaignLeadsState`. | ✅ VERIFIED |
| **PRF-12** | **P1** | `test/performance/virtualized_list_test.dart` | Automated Guardrails | Implemented automated widget test verifying the bounded viewport rendering strategy invariant (bounded instantiated items vs unbounded `Column`). | ✅ VERIFIED |
| **PRF-13** | **P1** | `test/performance/dashboard_debounce_performance_test.dart` | Automated Guardrails | Implemented automated test verifying concurrency deduping and droppable transformer behavior in `DashboardBloc`. | ✅ VERIFIED |

---

## 2. Verification Summary
- **Analyzer Status**: `flutter analyze` completed with **0 compilation errors**.
- **Automated Performance Tests**: **3 / 3 test suites passing** (7 test cases).
- **Full Architecture & Core Regression Suite**: **102 / 102 tests passing (100%)**.
- **Zero Business Logic Drift**: KPI logic, authentication rules, local database schemas, and API contracts remain strictly preserved.
