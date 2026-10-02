# PropKart Mobile — Step 3.1 Implementation Report

**Mobile Shell + Navigation**

Branch: `local_setup` (not committed). Authoritative inputs: Step 2.6 Final Specification and the Decision Register.

---

## 1. Objective

Make the new `MobileAppShell` the default shell for widths below 768px. It provides a top bar, routed content, bottom navigation, More, global search, notifications, and quick actions. Widths of 768px and above keep the existing shell (ModernSidebar plus ModernTopBar) unchanged.

All features of the old mobile shell move into the new shell. The `PROPKART_MOBILE_SHELL` flag is removed, and so is the old mobile-only branch (drawer, `CustomBottomNavBar`, `PersistentTabController`).

Out of scope, and not done: role screens (Home, Queue, Callbacks, CNR, Leads, Properties, Admin, Reports, KPI, detail views, wizards), Step 3.2, and any business-logic change.

## 2. Documents Read

| Document | Used for |
|---|---|
| `docs/PROPKART_MOBILE_UX_AUDIT.md` | Old mobile chrome inventory (drawer, top bar, bottom bar, overlays) |
| `docs/PROPKART_MOBILE_UI_UX_MASTER_SPECIFICATION.md` | Shell anatomy, 48px targets, More pattern |
| `docs/PROPKART_MOBILE_UI_UX_STEP_2_5_VERIFICATION.md` | RV items (RV-16 drawer, RV-18 bell on 360) |
| `docs/PROPKART_MOBILE_UI_UX_FINAL_SPECIFICATION.md` | Authoritative frozen tabs and More lists, back rules |
| `docs/PROPKART_MOBILE_UI_UX_DECISION_REGISTER.md` | Authoritative DRs (e.g. DR-017 Sync diagnostics for admins); PD-01…PD-06 left open |
| `docs/PROPKART_MOBILE_UI_UX_STEP_2_7_SIGN_OFF.md` | Release gates RV-01 / RV-11 / RV-20 |
| `docs/PROPKART_MOBILE_STEP_3_0_IMPLEMENTATION_REPORT.md` | Baseline components and flag-gated shell |

## 3. Step 3.0 Baseline

- Mobile design-system components in `lib/core/design_system/mobile/` (layout, touch, top bar, bottom nav, states, offline, card, list, search, sheets, actions, form).
- `MobileAppShell`, `MoreScreen`, and `MobileNavConfig` sat behind `--dart-define=PROPKART_MOBILE_SHELL` (default off), so the default behavior below 768px was still the old drawer and bottom-bar shell.
- `/more` route registered inside the `ShellRoute`.
- Analyzer baseline: 1237 issues, 0 errors. `test/mobile`: 75 component tests passing.
- Pre-existing failure: `test/security/telecaller_role_test.dart` ("Telecaller is recognized as having Admin privileges but cannot manage employees").

## 4. Existing Mobile Features Inventory

These are everything the old <768 shell provided, all located in `lib/core/design_system/widgets/app_shell.dart` (`CRMAppShell`) and `lib/features/shell/widgets/top_bar.dart` (`ModernTopBar`, `isMobile` branch).

| # | Feature | Old location / implementation | Disposition in 3.1 |
|---|---|---|---|
| F1 | Global search | `ModernTopBar` search icon or field. Below 600px it expands inline; 600–767px uses a field anchored by `_searchLayerLink`. Engine: `CRMAppShell._onSearchChanged` (500ms debounce) → `_performSearch` → `_showSearchOverlay` | Rehomed (§5) |
| F2 | Notifications bell + badge + panel | `ModernTopBar.onNotificationsTap` → `_notificationsPanelOpen=true; _fetchNotifications()`; `_buildNotificationsPanel` | Rehomed (§6) |
| F3 | Quick actions | Center "+" of `CustomBottomNavBar` → `_showQuickActionsBottomSheet()` | Rehomed (§7) |
| F4 | Team messages icon + unread dot | `ModernTopBar` messages icon, `_unreadTeamMessagesCount`, `context.go('/messages')` | Rehomed: top-bar overflow and More → Messages, both badged |
| F5 | Drawer destinations | `Drawer(ModernSidebar)` opened from the top-bar menu | Replaced by role tabs and More (§9, §10, §14) |
| F6 | Profile menu (avatar) | `ModernTopBar._showUserDropdown`: Default theme (admin), Dark mode, Settings, Logout | Reachable via More → Profile (Logout) and More → Settings (Dark mode, themes) |
| F7 | Bottom navigation | `CustomBottomNavBar`: Dashboard, Properties, Leads, Profile, "+"; not role- or permission-filtered; `PersistentTabController` sync | Replaced by role-filtered `MobileBottomNav` (§9) |
| F8 | Hide-on-scroll bottom bar | `NotificationListener` + `_isBottomBarVisible` | Not carried over (Known issue K3) |
| F9 | Telecaller availability toggle | `TelecallerAvailabilityToggle(compact: true)` in top bar | Kept in the top bar, and also in More → Shift (§12) |
| F10 | Shift gate overlays | `TelecallerShiftGateOverlay` wrapping the shell body | Wraps `MobileAppShell`, unmodified (§12) |
| F11 | Blocking sync overlay | `ValueListenableBuilder(SyncManager().isSyncing)` | Shared `_buildSyncOverlay()`, unmodified (§13) |
| F12 | System back | `MobileSystemBackHandler` (closes search/panel, pop, go home, exit confirm) | Reused and extended for More-owned routes (§11) |
| F13 | Session handling | Router redirect to `/get-started?from=`; `_handleLogout` | Unchanged; Logout via Profile |
| F14 | Sync diagnostics (admin) | Settings → `SyncDebugScreen` (`MaterialPageRoute`) | Also in More → Workspace → Sync diagnostics (DR-017) |

## 5. Search Migration

| Field | Value |
|---|---|
| Old location | `ModernTopBar` (mobile branch): search icon below 600px, inline field at 600–767px |
| Old implementation | `CRMAppShell._searchController`, `_searchFocusNode`, `_onSearchChanged` (500ms debounce), `_performSearch` (Isar + repositories, fuzzy), `_showSearchOverlay` / `_hideSearchOverlay`, `_searchLayerLink` |
| New mobile entry point | Top-bar **Search** action (48×48, label "Search"). For Telecaller below 412px it moves into **More actions → Search** so the availability toggle fits without shrinking targets. Tapping it replaces the top bar with `MobileSearchBar` (Close-search back button 48×48, 48px field, Clear 48×48) |
| Existing service/route reused | Same controller, focus node, `_onSearchChanged`, `_performSearch` (on submit), `_hideSearchOverlay`, `_searchLayerLink`, and overlay. `/search` was **not** used: it is the public `PropertySearchScreen` outside the shell (homeLocation `/get-started`), not the CRM global search |
| Test result | PASS. Reachable at all 8 mobile widths × 4 roles; field drives `onChanged`; Clear/Close callbacks; overlay anchor (`CompositedTransformTarget` with the shell's `LayerLink`) present |

Details:
- No new API, algorithm, or recent-search persistence.
- Search mode is tied to the route where it was opened (`_mobileSearchLocation`), so navigating from a result closes it without a `setState` during build.
- System Back closes search first.
- Desktop search (`ModernTopBar` ≥768) is untouched.

## 6. Notification Migration

| Field | Value |
|---|---|
| Old location | `ModernTopBar` bell (mobile branch) |
| Old implementation | `onNotificationsTap` → `setState(_notificationsPanelOpen = true); _fetchNotifications()`; panel `_buildNotificationsPanel(context)`; badge from `_unreadNotificationsCount` (25s poll + `NotificationCenter` stream) |
| New mobile entry point | Top-bar **Notifications** action, always direct (never in overflow), 48×48, badge announced as "Notifications, N new" |
| Existing service/route reused | Same `_notificationsPanelOpen`, `_fetchNotifications`, `_buildNotificationsPanel`, `_unreadNotificationsCount`. No new service |
| Test result | PASS. Tappable at every width and role; badge semantics verified |

## 7. Quick Action Migration

| Field | Value |
|---|---|
| Old location | Circular "+" in `CustomBottomNavBar` (index 2) |
| Old implementation | `_showQuickActionsBottomSheet()`: Add New Property `/properties?action=add`, Add New Lead `/requirements?action=add`, Schedule Site Visit `/dashboard` |
| New mobile entry point | Top bar **More actions** (⋮) sheet → **Quick actions**. The sheet closes first, then the existing bottom sheet opens. No global center "+" (frozen tabs have none) |
| Existing service/route reused | `_showQuickActionsBottomSheet()`, unchanged, passed as `onQuickActions` |
| Test result | PASS. Reachable at all 8 widths × 4 roles |

## 8. Top Bar

The 56px bar (`MobileTopBar`) contains, from left to right:
- Back, shown only on secondary routes.
- Title: a semantic header, one line with ellipsis.
- Role control: the Telecaller `TelecallerAvailabilityToggle(compact: true)`, wrapped in `Flexible` + `FittedBox(scaleDown)`.
- Search.
- Notifications.
- More actions (⋮), badged with unread team messages.

The overflow sheet ("More actions") lists Search (only when collapsed), Quick actions, and Messages (badged). Targets are never shrunk; the Telecaller rule below 412px moves Search into the overflow instead.

Titles come from `MobileNavConfig.resolve()`:
- Root tabs use the tab label.
- More-owned routes use the More entry label.
- Anything else uses "PropKart".

Overflow check: no `RenderFlex` overflow at 320/360/390/412/430/480/600/767 for any role (including Telecaller with a 145px toggle stand-in).

## 9. Bottom Navigation

Frozen tabs, permission-filtered (`MobileNavConfig.tabsForRole`):

| Role | Tabs |
|---|---|
| Telecaller | Home, Queue, Callbacks, CNR, More |
| Sales | Home, Leads, Properties, More |
| Admin | Home, Leads, Properties, Reports, More |
| Super Admin | Home, Leads, Properties, Reports, More |

Behavior:
- No Visits, Clients, Owners, Builders, or Pipeline tabs, and no center action.
- More is always shown.
- Queue (`/campaign/leads`) also counts `/telecaller/leads` as its own route and stays visible if either is permitted, matching the sidebar's "My Calling Leads" rule.
- Reports matches any `/reports*`.
- Routes owned by More highlight the More tab. Tapping a tab calls `context.go(route)` only when not already there.
- The bar hides while the keyboard is open.
- Each cell is at least 48px with semantics: button, selected, in a mutually exclusive group, and label including "N new".

## 10. More

Frozen lists (`MobileNavConfig.moreForRole`), permission-filtered. Empty sections are dropped.

- **Telecaller**
  - Shift: availability toggle
  - Work: All leads, Properties, Library, Messages
  - Account: Profile, Settings, Recycle bin
- **Sales**
  - Work: Library, Messages
  - Account: Profile, Settings, Recycle bin
- **Admin / Super Admin**
  - Operations: Calling queue, Campaign connections, Lead allocation, Callbacks, CNR
  - Team: Employees, Messages, Super admin metrics (Super Admin only)
  - Workspace: Library, Recycle bin, Audit logs, Settings, Sync diagnostics (DR-017)
  - Account: Profile

Behavior:
- Route rows call `context.go(route)`. Sync diagnostics pushes the existing `SyncDebugScreen` exactly as Settings does.
- The Messages row is badged from `MobileShellBadges`, an InheritedWidget that carries the shell's existing counts, so there is no extra fetch.
- Super Admin gets no Telecaller- or Sales-only rows (no "All leads", no Queue tab).

## 11. Back Navigation

The existing `MobileSystemBackHandler` and GoRouter are reused; there is no second navigation stack.

Top-bar Back, shown on secondary routes, calls `onBack(fallback)`: `context.canPop() ? pop() : go(fallback)`.

System Back runs `onBeforeBack` in order:
1. Close search (overlay plus search mode).
2. Close the notifications panel.
3. If nothing can pop and the route is More-owned, `go('/more')`.
4. Otherwise the handler's existing logic runs: pop, then go to `/dashboard` from other root tabs, then the exit-confirm dialog on Home. Nothing exits unexpectedly.

Fallbacks:
- Root tabs: none (no Back shown).
- More-owned routes: `/more`.
- Unknown routes: `/dashboard`.

## 12. Shift Integration

- `TelecallerShiftGateOverlay` wraps the whole `MobileAppShell` (top bar, content, bottom nav), unmodified. This matches the old coverage, where it wrapped the top bar, content and bottom bar.
- `TelecallerAvailabilityToggle(compact: true)` stays in the top bar and also appears in More → Shift. Same widget, no new state.
- No change to shift logic, timers, break, the 9-hour lockout, the 30-second heartbeat, or `TelecallerShiftManager.init`.

## 13. Sync Overlay

The blocking sync overlay (PD-05 still pending) is the same `ValueListenableBuilder(SyncManager().isSyncing)` code, moved verbatim into `_buildSyncOverlay()` in Step 3.0. It is stacked above the mobile shell, the shift gate, and the notifications panel. `SyncManager` is not modified.

## 14. Old Drawer Removal

The following were removed from `app_shell.dart`:
- `drawer: isMobile ? Drawer(ModernSidebar…)`.
- The mobile `openDrawer` branch of `onToggleSidebar`.
- The mobile `NotificationListener` hide-on-scroll and padding branch.
- The `Positioned(CustomBottomNavBar)` block.
- `showBottomNav` / `navClearance` / `keyboardOpen` locals.
- The tab-sync post-frame block.
- `_tabController`, `_previousIndex`, `_isBottomBarVisible`, and their init, listener and dispose.
- `_getTabRouteIndex` / `_getTabRoutePath`.
- The `CustomBottomNavBar` class.
- The `persistent_bottom_nav_bar_v2` import.

The developer flag was removed too: `lib/features/shell/mobile/mobile_shell_flags.dart` is deleted, and the branch is now `if (MobileLayout.isMobileShell(size.width)) return _buildMobileShell(...)`.

Kept for desktop: `ModernSidebar` and `ModernTopBar`. `top_bar.dart` and `sidebar.dart` are untouched; their `isMobile` paths are now unreachable from `CRMAppShell` but still compile.

Note: the private `_buildTopBar` method in `app_shell.dart` (which contains an `openDrawer()` call) was already unreferenced at HEAD before Step 3.1 and remains unreferenced. It was left untouched.

## 15. Desktop/Tablet Preservation

- The ≥768 tree is unchanged except for removing branches that only ran when `isMobile` was true: the drawer, the mobile scroll listener, and the bottom bar. `ModernSidebar` with resizer, `ModernTopBar`, and the desktop search/notifications/profile still behave as before.
- `onToggleSidebar` keeps only the desktop collapse/expand body.
- The switch is verified at 768/800/1024/1280 (`isMobileShell == false`), plus source checks that `ModernSidebar(` and `ModernTopBar(` remain.

## 16. Permission Verification

- Default visibility is `MobileNavAccess.canOpen(role, route)`. It applies the same `RoleGuard` gates as `ModernSidebar` and `sanitizeRedirectPath` (`canManageEmployees`, `canAccessCampaign`, `canViewAuditLogs`, `canViewReports`, `isAdmin`), on top of `RoleGuard.canViewPage` → `PermissionMatrixService.canViewRoute`.
- No permission definitions, matrix data, route permissions, or RBAC code were changed.
- Tests inject visibility (`canView`) and reset the matrix to defaults with mocked `SharedPreferences`. No Step 3.1 test calls `setPermission()` or sends PATCH/POST/DELETE.
- Existing tests with backend sync: `test/security/permission_matrix_test.dart` (7 call sites of `setPermission`/sync) still triggers `PATCH /super-admin/feature-permissions/role`. Per the instructions it was not modified.
- Result: **PASS**. Revoked routes hide tabs and More rows. Sales cannot open `/users` or `/admin/lead-allocation`. Audit logs are Super Admin only (matches the sidebar and `RoleGuard`).

## 17. Accessibility Verification

- Every tappable has a label and passes `labeledTapTargetGuideline` and `androidTapTargetGuideline` (48×48) for all 4 roles at 360px.
- The top-bar title is a semantic header.
- Bottom-nav cells expose selected state.
- Badges are announced ("Notifications, 3 new", "More actions, 1 new", "Messages, 2 new").
- Text is single-line with ellipsis, so nothing clips.
- The search field has a "Search" text-field label; Close search and Clear search are 48×48.
- No new orientation behavior.

## 18. Width Verification

| Width | Shell | Result |
|---|---|---|
| 320×800 | Mobile | PASS. 4 roles; Telecaller Search in overflow |
| 360×800 | Mobile | PASS. 4 roles; a11y guidelines |
| 390×844 | Mobile | PASS. 4 roles; Telecaller Search in overflow |
| 412×915 | Mobile | PASS. 4 roles; Telecaller Search direct |
| 430×932 | Mobile | PASS |
| 480×900 | Mobile | PASS |
| 600×900 | Mobile | PASS. Overlay anchors to `MobileSearchBar` via `LayerLink` |
| 767×900 | Mobile | PASS |
| 768 | Existing | PASS (switch) |
| 1024 | Existing | PASS (switch) |
| 1280 | Existing | PASS (switch) |

Widget tests run at 800px height. Bars are height-independent.

## 19. Role Verification

| Role | Tabs | More | Search / Notifications / Quick actions | Result |
|---|---|---|---|---|
| Telecaller | Home, Queue, Callbacks, CNR, More | Shift; Work; Account | Search in overflow below 412px | PASS |
| Sales | Home, Leads, Properties, More | Work; Account | Direct | PASS |
| Admin | Home, Leads, Properties, Reports, More | Operations; Team; Workspace; Account (no SA metrics; Audit logs hidden by gate) | Direct | PASS |
| Super Admin | Same as Admin | Same as Admin plus Super admin metrics and Audit logs; no Telecaller/Sales rows | Direct | PASS |

## 20. Test Results

| Command | Result |
|---|---|
| `flutter analyze` | 1235 issues, **0 errors**. Baseline was 1237; 0 new, and 2 fewer because dead mobile code was removed |
| `flutter test test/mobile` | **131 passed**, 0 failed |
| `flutter test` | **267 passed, 1 failed**. The failure is the pre-existing `test/security/telecaller_role_test.dart` case |
| `flutter test test/security/telecaller_role_test.dart` | 5 passed, 1 failed (same case: `Expected: true, Actual: false`). It only imports `role_guard.dart`, which is unchanged. **Not fixed; not claimed fixed** |

New Step 3.1 tests (`test/mobile/mobile_shell_step31_test.dart`) cover:
- The <768 vs ≥768 switch.
- No flag, old drawer, or bottom bar in `CRMAppShell`.
- Shift gate, notifications panel, sync overlay and back handler inside the mobile shell.
- No overflow, no `Drawer`, and Search/Notifications/Quick actions/Messages reachable for 4 roles × 8 widths.
- Search mode.
- Root versus More-owned back behavior.
- `resolve()`.
- More per role, Sync diagnostics, and More badges.
- Injected permission hiding and `RoleGuard`-gate parity.
- Accessibility guidelines.
- `MobileShellBadges`.

Step 3.0 tests were updated to the new `MobileAppShell` / `MobileMoreView` APIs and to the Queue visibility rule.

## 21. Files Added

- `test/mobile/mobile_shell_step31_test.dart`
- `docs/PROPKART_MOBILE_STEP_3_1_IMPLEMENTATION_REPORT.md`

## 22. Files Modified

| File | Change |
|---|---|
| `lib/core/design_system/widgets/app_shell.dart` | Mobile shell is the default below 768; flag removed; search mode, back, overflow, and badge wiring; old mobile drawer, bottom bar, tab controller and scroll-hide code removed; unused imports removed |
| `lib/core/design_system/mobile/mobile_top_bar.dart` | `MobileSearchBar` added; role control made overflow-safe; shared bar frame |
| `lib/features/shell/mobile/mobile_app_shell.dart` | Rewritten: role/location-driven chrome, overflow sheet, Back, `MobileShellBadges` |
| `lib/features/shell/mobile/mobile_nav_config.dart` | `MobileNavAccess`, Queue alias, Sync diagnostics entry, `MobileLocationInfo` / `resolve()` |
| `lib/features/shell/mobile/more_screen.dart` | Entry-based `onOpen`, Sync diagnostics push, Messages badge |
| `test/mobile/mobile_components_test.dart` | Updated to new APIs |
| `test/mobile/mobile_nav_config_test.dart` | Queue revocation semantics updated; alias test added |

The step-3 files under `lib/core/design_system/mobile/`, `lib/features/shell/mobile/` and `test/mobile/` are untracked (new since Step 3.0).

Not part of Step 3.1 and not touched by this step: working-tree changes in `crm_donut_chart.dart`, `dashboard_screen.dart`, and `properties_screen.dart` (chart painters switched from gradient shaders to solid colors). They were made outside this step and are left as found.

## 23. Files Deleted

- `lib/features/shell/mobile/mobile_shell_flags.dart`

## 24. Packages Added

None. `persistent_bottom_nav_bar_v2` is now unused in `lib/` but was intentionally left in `pubspec.yaml`; removing a dependency is outside this step's scope.

## 25. Business Logic Safety Verification

| Area | Changed? |
|---|---|
| KPI | NO |
| Database | NO |
| API | NO |
| RBAC | NO |
| Allocation | NO |
| Matching | NO |
| Sync | NO |
| Realtime | NO |
| Shift | NO |
| Statuses | NO |
| Forms | NO |

Routes were not renamed or removed and route permissions are unchanged. Session expiry still redirects to `/get-started?from=`. No new data fetches: the shell reads only identity, role, permission, and the existing notification and message counters.

## 26. Product Decisions Still Pending

PD-01, PD-02, PD-03, PD-04, PD-05 (the blocking sync overlay is kept as-is), and PD-06 are all unresolved and not changed by this step.

## 27. Release Gates Still Pending

RV-01, RV-11, and RV-20. RV-16 (drawer) and RV-18 (bell at 360px) are superseded by this step: there is no drawer below 768, and the bell is a direct 48×48 action at every width.

## 28. Known Issues

- **K1 Double bottom padding.** The shell pads content by `CRMBreakpoints.mobileNavClearance` (76 + safe area), the same value the old shell used. Because `Scaffold.extendBody` is set, existing screens that also apply `SafeArea(bottom)` or their own bottom padding may get extra space. This is the same as the old shell; no screen changes were made. Revisit per screen in Step 3.2+.
- **K2 Meta / Housing drawer shortcuts** (`/campaign/meta`, `/campaign/housing`) are not in the frozen More list. They remain reachable through Calling queue (source filter) and by URL.
- **K3 Hide-on-scroll** of the bottom bar was not carried over; the new bar is always visible except while the keyboard is open.
- **K4 Quick actions are not permission-gated.** This is the same as before (shown to all roles); the sheet is reused unchanged.
- **K5 Mobile search overlay offset.** Below 600px the existing overlay sits at a fixed `70 + topPadding + 8`, about 22px below the 56px bar. Cosmetic; `_showSearchOverlay` was intentionally not modified.
- **K6 Dark mode, default theme, and Logout** moved from the avatar menu to More → Settings and More → Profile (they existed in both places before).
- **K7 `/more` after session expiry.** `/more` is not in `RoleGuard.allowedPostLoginPaths`, so `/get-started?from=/more` returns to `/dashboard` after login. RBAC and redirect lists were not changed.
- **K8 Pre-existing test failure** in `test/security/telecaller_role_test.dart` (not caused by this step; not fixed).
- **K9** `test/security/permission_matrix_test.dart` still calls `setPermission`, which triggers backend permission sync. Left unmodified by instruction.
- **K10** The full `CRMAppShell` (blocs, services, timers) is verified through `MobileAppShell` widget tests and source checks, not end to end. A device pass is still needed (see §29).

## 29. Step 3.1 Status

**COMPLETE WITH CONDITIONS.**

All Step 3.1 requirements are implemented and tested:
- The mobile shell is the default below 768, and the flag is removed.
- Old mobile features are rehomed and the old mobile branch is removed.
- The desktop/tablet shell is preserved.
- Permissions pass, the shift code is unchanged, and no business logic changed.

Conditions:
- A device or emulator QA pass for each role on a real backend (search overlay, notifications panel, shift overlays, sync overlay) before release.
- Known issues K1–K7.
- Pending PDs and release gates.

## 30. Recommendation for Step 3.2

- Build shared mobile screen scaffolding on top of `MobileShellScope` and `MobileContent`, and resolve K1 per screen (drop redundant bottom insets when `MobileShellScope.isInShell`).
- Define the screen-migration contract: list, card, filter, sort, empty/error/loading, and sticky actions using the Step 3.0 components.
- Decide whether Meta and Housing need More entries (K2) and whether quick actions should be permission-filtered (K4). Both are product decisions.
- Optionally align the mobile search overlay offset with the 56px bar (K5).
- Do not start role screens until Step 3.2 is approved.
