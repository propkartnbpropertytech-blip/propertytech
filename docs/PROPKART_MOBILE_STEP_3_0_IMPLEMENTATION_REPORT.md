# PropKart Mobile — Step 3.0 Implementation Report

Controlled mobile implementation foundation. Branch: `local_setup`. Not committed.

---

## 1. Objective

Build the reusable mobile foundation (shell chrome, navigation config, More infrastructure, shared components, state/offline presentation, form primitives, accessibility baseline) for widths `< 768`, without implementing role screens, without changing business logic, and without resolving any pending product decision. Step 3.1 is not started.

## 2. Documents Used

| Document | Use |
|---|---|
| `docs/PROPKART_MOBILE_UI_UX_FINAL_SPECIFICATION.md` (Step 2.6) | Breakpoints, tab sets, component specs, state copy |
| `docs/PROPKART_MOBILE_UI_UX_DECISION_REGISTER.md` (Step 2.6) | DR / PD / RV / SD / FB identifiers |
| `docs/PROPKART_MOBILE_UI_UX_STEP_2_7_SIGN_OFF.md` | Authorization (AUTHORIZED WITH CONDITIONS), pending PDs, release gates |
| `docs/PROPKART_MOBILE_UI_UX_STEP_2_5_VERIFICATION.md` | Verified current-code facts |
| `docs/PROPKART_MOBILE_UX_AUDIT.md` | Baseline of existing shell behavior |

## 3. Files Added

`lib/core/design_system/mobile/`

| File | Contents |
|---|---|
| `mobile.dart` | Barrel export |
| `mobile_layout.dart` | `MobileLayout` (constants, width classes, padding), `MobileWidthClass`, `MobileShellScope`, `MobileShellSwitch`, `MobileContent` |
| `mobile_touch.dart` | `MobileIconAction`, `MobileTapTarget` (48×48, semantics, tooltip) |
| `mobile_top_bar.dart` | `MobileTopBar` (56px, title header, role-control slot, actions, `backAction`) |
| `mobile_bottom_nav.dart` | `MobileNavItem`, `MobileBottomNav` (64px, ≤5 items, badges, selected semantics, optional center slot) |
| `mobile_states.dart` | `MobileLoadingMode`, `MobileLoadingState`, `MobileSkeleton`, `MobileInlineLoader`, `MobileButtonLoader`, `MobileEmptyState`, `MobileErrorState` (+ `logTechnical`), `MobileRetryState` |
| `mobile_offline.dart` | `MobileDataStatus`, `MobileDataStatusCopy`, `MobileOfflineBanner`, `MobileSyncIndicator`, `MobilePendingSyncBadge` |
| `mobile_card.dart` | `MobileCard` |
| `mobile_list.dart` | `MobileList<T>`, `MobileListItem`, `MobileSectionHeader` |
| `mobile_search.dart` | `MobileSearchStatus`, `MobileSearch` |
| `mobile_sheets.dart` | `MobileSheet`, `MobileOption`, `MobileFilterSection`, `MobileFilterSheet`, `MobileSortSheet`, `MobileSortOptions`, `MobileConfirmDialog` |
| `mobile_actions.dart` | `MobileAction`, `MobileStickyActionBar`, `MobileActionButton` |
| `mobile_form.dart` | `MobileFormScaffold`, `MobileFormStepHeader`, `MobileFormProgress`, `MobileFormSection`, `MobileFormActions` |

`lib/features/shell/mobile/`

| File | Contents |
|---|---|
| `mobile_shell_flags.dart` | `MobileShellFlags.enabled` (`--dart-define=PROPKART_MOBILE_SHELL`, default `false`) |
| `mobile_nav_config.dart` | `MobileNavConfig.tabsForRole`, `indexForLocation`, `moreForRole`; `MobileMoreEntry`, `MobileMoreSection` |
| `mobile_app_shell.dart` | `MobileAppShell` (top bar + routed body + bottom nav + clearance) |
| `more_screen.dart` | `MoreScreen` (route widget), `MobileMoreView` (pure, testable) |

`test/mobile/`

| File | Contents |
|---|---|
| `mobile_test_utils.dart` | Width list, iOS variant helper, surface sizing |
| `mobile_layout_test.dart` | Breakpoints, width bands, shell switch at 13 widths, content max width |
| `mobile_nav_config_test.dart` | Role tabs, permission filtering, More filtering, location matching |
| `mobile_components_test.dart` | Nav semantics, touch targets, top bar, app shell widths, states, offline, list/card, search, sheets, dialog, actions, forms, More view, labeled tap targets |

`docs/PROPKART_MOBILE_STEP_3_0_IMPLEMENTATION_REPORT.md` (this file).

## 4. Files Modified

| File | Change |
|---|---|
| `lib/core/design_system/widgets/app_shell.dart` | +5 imports; flag-gated early return `if (MobileShellFlags.enabled && isMobile) return _buildMobileShell(...)`; new `_buildMobileShell`; the existing inline sync-overlay `ValueListenableBuilder` moved verbatim into `_buildSyncOverlay()` and called from both branches. Existing ≥768 tree and existing <768 tree unchanged. |
| `lib/core/navigation/app_router.dart` | +1 import; `GoRoute('/more')` inside the existing `ShellRoute` using `crmFadeSlidePage`. |

## 5. Files Deleted

None from the repository. During the session a concurrently running agent wrote a second, conflicting set of files into `lib/core/design_system/mobile/` and an empty `lib/features/more/`; with the user's approval those uncommitted files were removed and the overwritten foundation files were restored to a single design. No tracked file was deleted.

## 6. Packages Added

None. `pubspec.yaml` unchanged. No dependency was required (sheets, badges, radio groups, semantics all come from Flutter 3.47.1).

## 7. Shell Architecture

```
GoRouter ShellRoute
└── CRMAppShell (existing)
    ├── width ≥ 768 ............ existing tree (sidebar + ModernTopBar)        [unchanged]
    ├── width < 768, flag off .. existing mobile tree (drawer + CustomBottomNavBar) [unchanged, default]
    └── width < 768, flag on ... _buildMobileShell
        └── MobileSystemBackHandler (existing)
            └── Stack
                ├── TelecallerShiftGateOverlay (existing, unchanged)
                │   └── MobileAppShell
                │       ├── MobileTopBar(title, roleControl, [notifications])
                │       ├── MobileShellScope → Padding(bottom: mobileNavClearance) → routed child
                │       └── MobileBottomNav(MobileNavConfig.tabsForRole(role))
                ├── existing notifications panel (when open)
                └── existing blocking sync overlay (PD-05 interim default)
```

Rationale for the flag: today's `<768` branch carries the drawer (full destination list), global search, quick actions and notifications. Replacing it before Step 3.1 moves those destinations would regress mobile users. The flag keeps current behavior as default while the new shell is fully mountable and testable.

`MobileAppShell` owns layout only. Auth, routing, session expiry (`/get-started?from=`), shift init (`TelecallerShiftManager.instance.init`), notifications fetch, and sync remain in `CRMAppShell` and are reused unchanged.

## 8. Breakpoint Implementation

- Mobile shell condition: `width < CRMBreakpoints.tablet` (768) via `MobileLayout.isMobileShell`, matching `CRMAppShell`'s existing `isMobile`.
- Width bands (`MobileWidthClass`): `compact < 360`, `phone 360–479`, `phablet 480–767`, `shell ≥ 768` — derived from `CRMBreakpoints.phone/phablet/tablet`.
- Horizontal padding: 12 below 360, otherwise 16.
- Content max width: 560 (`MobileLayout.contentMaxWidth`).
- No 600/700/900/1050/1100 breakpoints introduced.
- `MobileShellSwitch` runs exactly one builder; 767 → mobile, 768 → existing.

## 9. Navigation Foundation

`MobileNavConfig.tabsForRole(role, {canView})` returns frozen tabs, each filtered by `PermissionMatrixService.instance.canViewRoute(role, route)` (injectable for tests):

| Role | Tabs (routes) |
|---|---|
| Telecaller | Home `/dashboard`, Queue `/campaign/leads`, Callbacks `/telecaller/callbacks`, CNR `/telecaller/cnr`, More `/more` |
| Sales | Home, Leads `/requirements`, Properties `/properties`, More |
| Admin | Home, Leads, Properties, Reports `/reports/leads/overall-business-insight` (matches `/reports/*`), More |
| Super Admin | Same as Admin; extras in More |

- `MobileBottomNav`: 64px + bottom safe area, 24px icons, 12px labels, ≥48×48 cells, badges announced as "N new", `selected` + `inMutuallyExclusiveGroup` semantics, max 5 visible items.
- Center slot: parameter only; no global "+" action is wired.
- `indexForLocation`: exact or `prefix/` match; unknown routes select nothing.
- Hidden while the keyboard is open.

## 10. More Foundation

- Route `/more` → `MoreScreen` inside the shell route. `MoreScreen` reads identity from `AuthBloc` (fallback `RoleGuard.currentUser`), builds sections with `MobileNavConfig.moreForRole`, and navigates with `context.go`.
- `MobileMoreView` (pure): profile header, optional Shift slot, sections of `MobileListItem` rows.
- Telecaller: Shift slot hosts the existing `TelecallerAvailabilityToggle(compact: true)`; Work (All leads, Properties, Library, Messages); Account (Profile, Settings, Recycle bin).
- Sales: Work (Library, Messages); Account (Profile, Settings, Recycle bin).
- Admin / Super Admin: Operations (Calling queue, Campaign connections, Lead allocation, Callbacks, CNR); Team (Employees, Messages, Super admin metrics — Super Admin only); Workspace (Library, Recycle bin, Audit logs, Settings); Account (Profile).
- Each entry filtered by `canViewRoute`; empty sections dropped. Admin's Callbacks/CNR/Audit logs appear only if the permission matrix grants them.
- No Clients / Owners / Builders destinations.
- `/more` is not in `RoleGuard.allowedPostLoginPaths`; left unchanged (it is never a post-login landing target).

## 11. Shared Components

| Area | Components | Notes |
|---|---|---|
| Layout | `MobileContent`, `MobileShellScope` | Bottom clearance applied once (by the shell); `MobileContent` adds bottom safe area only outside the shell |
| Touch | `MobileIconAction`, `MobileTapTarget` | ≥48×48 hit area independent of icon size |
| Cards / lists | `MobileCard`, `MobileList<T>`, `MobileListItem`, `MobileSectionHeader` | `ListView.separated` builder, `KeyedSubtree(ValueKey(keyOf(item)))`, loading/error/empty, `onRefresh`, `onLoadMore` UI hook |
| Search | `MobileSearch` | 48px field, 48px clear, caller debounce, idle/loading/results/empty/error, filter action with active count, no recent-search store |
| Sheets | `MobileSheet`, `MobileFilterSheet`, `MobileSortSheet`, `MobileConfirmDialog` | max 85% height, grabber, 48px close, keyboard insets, safe area; filter definitions supplied by callers |
| Actions | `MobileStickyActionBar`, `MobileActionButton` | 48px buttons, inline loader, disabled while loading |
| Forms | `MobileFormScaffold`, `MobileFormStepHeader`, `MobileFormProgress`, `MobileFormSection`, `MobileFormActions` | Layout only; fields/validation/payloads stay in feature forms |

Existing `CRMEmptyState` / `CRMErrorState` were not modified; they lack secondary actions, semantics headers, and configurable retry copy, so `Mobile*` variants were added instead.

Media foundation: deferred (optional in scope).

## 12. Shift Integration

- `TelecallerShiftGateOverlay` wraps the whole `MobileAppShell`, mirroring its placement in the existing shell. The overlay widget is unchanged.
- `TelecallerAvailabilityToggle(compact: true)` is placed in `MobileTopBar.roleControl` for telecallers and in the More Shift slot. The toggle is unchanged.
- `TelecallerShiftManager.instance.init(userId)` still runs in `CRMAppShell.build` before the branch.
- No shift timers, states, idle logic or break rules touched.

## 13. Accessibility

- All icon actions and nav cells: ≥48×48, `Semantics(button)`, labels, badge counts announced.
- Bottom nav: `selected` state exposed; `androidTapTargetGuideline` test passes.
- Top bar title, section headers, state titles, sheet titles: `Semantics(header)`.
- Loading/offline/sync states: `liveRegion`.
- Text scale not clamped; titles ellipsize; no fixed-height text containers.
- `labeledTapTargetGuideline` passes for the app shell.

## 14. Offline/Error/Loading Foundation

- Loading modes: initial (skeletons), refreshing (2px linear bar), loadingMore (inline spinner), action (button spinner).
- Error: fixed user copy ("Something went wrong." / "Please try again."), retry, `MobileErrorState.logTechnical` (debug-only `debugPrint`); exceptions never rendered — tested.
- Offline states (DR-021): cached read, syncing, pending write, direct operation, failed write, with frozen copy.
- Presentation only. The existing blocking sync overlay is retained in both shells (PD-05 pending). Sync engine, outbox and campaign outcome behavior untouched.

## 15. Routing Changes

- Added `/more` inside the existing `ShellRoute`.
- No other routes added, removed, or renamed. Redirects, auth guard, and `/get-started?from=` session-expiry path unchanged.

## 16. Test Results

| Command | Result |
|---|---|
| `flutter analyze` (full) | 1237 issues, 0 errors — identical to the pre-change baseline (1237). New files: 0 issues. |
| `flutter analyze test/mobile lib/core/design_system/mobile lib/features/shell/mobile` | No issues found |
| `flutter test test/mobile` | 75 / 75 passed |
| `flutter test` (full) | 211 passed, 1 failed — `test/security/telecaller_role_test.dart` ("Telecaller is recognized as having Admin privileges but cannot manage employees"). Pre-existing: the test imports only `role_guard.dart`, which this step did not modify. |

## 17. Width Verification

| Width | Expected | Result |
|---|---|---|
| 320, 360, 390, 412, 430, 480, 600, 700 | Mobile shell; no overflow | PASS (`MobileShellSwitch`, `MobileAppShell`, `MobileContent`) |
| 767 | Mobile shell only | PASS |
| 768 | Existing shell only | PASS |
| 800, 1024, 1280 | Existing shell only | PASS |

Never both, never neither — asserted at every width.

## 18. Role Verification

| Role | Tabs | More | Result |
|---|---|---|---|
| Telecaller | Home, Queue, Callbacks, CNR, More | Shift slot + Work + Account | PASS |
| Sales | Home, Leads, Properties, More | Work + Account | PASS |
| Admin | Home, Leads, Properties, Reports, More | Operations, Team, Workspace, Account (permission-filtered) | PASS |
| Super Admin | Same as Admin | Adds Super admin metrics; never filtered | PASS |

## 19. Permission Verification

- Every tab and More entry produced under the default matrix satisfies `canViewRoute(role, route)` for all four roles (tested).
- Revoking a route hides its tab (tested with injected visibility: Telecaller without `/campaign*` loses Queue).
- Super Admin unfiltered.
- No new permission keys, no matrix edits, no backend permission sync calls from the mobile code.

## 20. Business Logic Verification

| Area | Changed |
|---|---|
| KPI | NO |
| Database | NO |
| APIs | NO |
| RBAC | NO |
| Allocation | NO |
| Matching | NO |
| Sync | NO |
| Realtime | NO |
| Shift | NO |
| Statuses | NO |
| Forms | NO |

## 21. Step 2.6 Compliance

| Requirement | Status |
|---|---|
| `<768` mobile shell, `≥768` existing shell | PASS |
| Width bands 360/480/768 only | PASS |
| Frozen tab sets per role, permission-filtered | PASS |
| Super Admin extras in More | PASS |
| No global center "+" (slot only) | PASS |
| No Clients/Owners/Builders nav | PASS |
| 48×48 touch targets, semantics | PASS |
| Content max width 560, nav clearance via `CRMBreakpoints.mobileNavClearance` | PASS |
| Offline/state copy per DR-021 | PASS |
| Blocking sync overlay retained (PD-05) | PASS |
| Shift gate hosted unchanged | PASS |
| No packages added | PASS |
| 12,795-line campaign screen untouched | PASS |

Pending product decisions (all remain **PENDING**, interim defaults preserved):

| PD | Topic | Interim default kept |
|---|---|---|
| PD-01 | Telecaller default landing | `/dashboard` |
| PD-02 | Sales default landing | `/dashboard` |
| PD-03 | Sales Visits data source | No Visits tab |
| PD-04 | KPI-04 presentation | Two cards per KPI config (no Home layout built) |
| PD-05 | Sync overlay | Blocking overlay kept |
| PD-06 | Start-call from Queue | `tel:` only (no call action built) |

Release gates (not build blockers; must pass before release):

| Gate | Topic | Step 3.0 impact |
|---|---|---|
| RV-01 | Idle auto-break while dialer is foreground | Not exercised (no calling screens built) |
| RV-11 | `tel:` resolution on Android 11+ | Not exercised (no Call actions built) |
| RV-20 | Visible elements under shift overlays | Overlay hosted on mobile shell; parity must be documented on device before release |

## 22. Known Issues

1. Mobile shell is behind `PROPKART_MOBILE_SHELL` (default off); default `<768` behavior is still the existing shell.
2. With the flag on, global search and quick actions are not yet reachable from the mobile shell (Step 3.1).
3. Mobile shell title uses the active tab label (or "PropKart"); per-screen titles are Step 3.1+.
4. Pre-existing failing test `test/security/telecaller_role_test.dart` (unrelated to this step).
5. `/more` not in `RoleGuard.allowedPostLoginPaths` (intentional; not a landing route).
6. Sync diagnostics has no route (pushed via `MaterialPageRoute` from Settings), so it is not listed in More.
7. Existing screens still contain their own mobile padding/bottom spacing; double clearance is possible when they render inside the flagged shell until migrated.
8. Running permission-matrix tests that call `setPermission` triggers the existing backend sync (`PATCH /super-admin/feature-permissions/role`) against the configured API; mobile tests avoid this by injecting visibility.

## 23. Deferred Work

- Step 3.1: enable the mobile shell by default; move search, notifications, quick actions into mobile chrome; remove drawer dependency below 768.
- Role screens (Home, Queue, Callbacks, CNR, Leads, Properties, Reports) on the new primitives.
- Media foundation (thumbnail, gallery viewer).
- Per-screen titles and back behavior inside the mobile shell.
- RV-01 / RV-11 / RV-20 device verification.
- All six PDs await human sign-off.

## 24. Step 3.0 Completion Status

**COMPLETE WITH CONDITIONS**

Conditions:
- Mobile shell is mounted below 768 behind a build flag (default off) to avoid regressing current mobile navigation before Step 3.1.
- One pre-existing, unrelated unit test fails.
- PD-01…PD-06 pending; RV-01, RV-11, RV-20 open as release gates.

## 25. Recommendation for Step 3.1

1. Build Step 3.1 (Mobile Shell + Navigation) on `MobileAppShell` / `MobileNavConfig` with the flag on in dev builds.
2. Move global search into `MobileSearch` reachable from the top bar; move notifications and quick actions into the mobile chrome; then flip the default and delete the `<768` drawer branch.
3. Strip per-screen bottom-nav padding as each screen adopts `MobileContent`.
4. Fix or update the failing `telecaller_role_test.dart` separately (RBAC owner).
5. Do not start role screens until PD-01/PD-02 landing decisions are signed off or explicitly deferred.
