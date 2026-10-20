# DEFERRED PERFORMANCE FINDINGS

This document records performance-related findings discovered during remediation phases that are intentionally deferred because they lie outside the strictly scoped boundary of the current remediation step.

---

## Step 7 Findings (Transitions & Animation Scope)

### 1. `dialogs.dart` — Duplicate `CurvedAnimation` Allocations in Modal Transitions
- **File:** `lib/core/design_system/widgets/dialogs.dart` (lines 75–85, 290–300)
- **Observation:** In `showConfirmDialog` and `showExitAppDialog`, the `transitionBuilder` instantiates two independent `CurvedAnimation` objects wrapping the same parent `anim`:
  ```dart
  FadeTransition(
    opacity: CurvedAnimation(parent: anim, curve: CRMMotion.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: anim, curve: CRMMotion.easeOut),
      ),
      child: child,
    ),
  );
  ```
- **Impact:** Minor heap allocation churn during modal dialog popups.
- **Recommended Action:** In a future UI refactoring phase, instantiate a single shared `final curved = CurvedAnimation(...)` and reuse it for both opacity and scale tweens.

### 2. `splash.dart` — Unmatched Hero Tag
- **File:** `lib/splash.dart` (line 417)
- **Observation:** The splash screen logo is wrapped with `Hero(tag: 'app_logo', child: ...)`. However, no destination route (neither `/get-started` nor `/dashboard`) contains a corresponding `Hero` with tag `'app_logo'`.
- **Impact:** Negligible. Flutter simply skips Hero animation flight when no matching tag exists on the pushed route.
- **Recommended Action:** Remove the redundant `Hero` wrapper or introduce matching tags on landing/auth screens if cross-route logo flight is desired.

---

## Step 8 Findings (Dart I/O & Logging Persistence Scope)

### 1. `PerformanceLogger.readLogFile()` Diagnostic Reading on Main Isolate
- **File:** `lib/core/storage/performance_logger.dart`
- **Observation:** `readLogFile()` performs `await _logFile!.readAsLines()` on the main isolate. Because Step 8 enforces a 1 MB file cap with `.old` rotation, file reading typically takes $< 5$ ms. Furthermore, this method is strictly an administrative/diagnostic capability and is never invoked during UI rendering, animation flight, or list scrolling.
- **Impact:** Negligible during normal CRM operations.
- **Recommended Action:** If telemetry export or diagnostic viewer tools are built in the future that process large rotated logs, wrap `readAsLines()` or JSON parsing in `compute()` or `Isolate.run()` to keep administrative exports off the UI isolate.

---

## Step 9 Findings (Mascot Ticker & Redundant Library Fetch Scope)

### 1. `RentalLibraryScreen` & `ResaleLibraryScreen` Widget State Search Filtering
- **File:** `lib/features/library/screens/rental_library_screen.dart`, `lib/features/library/screens/resale_library_screen.dart`
- **Observation:** Master property dropdown entities are now cached with TTL and deduplicated via `LibraryRepository`. However, search query filtering and local pagination logic inside these screens operate directly within `StatefulWidget` state (`setState`).
- **Impact:** Negligible for current library dataset sizes (< 1,000 items).
- **Recommended Action:** If library document volume expands beyond 5,000 entities in future releases, offload query filtering to an isolate or leverage an indexed Isar full-text search query.

### 2. `ServiceAgentLibraryScreen` Offline Mutation Queuing
- **File:** `lib/features/library/screens/service_agent_library_screen.dart`
- **Observation:** `LibraryRepository` handles in-flight request deduplication, in-memory caching, and automatic invalidation on mutations for service agent documents. When offline, new document uploads or approvals throw a network exception.
- **Impact:** Expected online transactional behavior for administrative document approvals.
- **Recommended Action:** If complete offline-first document drafting and delayed write queuing are desired for service agents in the future, extend the `SyncManager` write queue architecture to support service agent document mutations.

