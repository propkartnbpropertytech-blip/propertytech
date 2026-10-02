# PropKart Mobile — Step 3.2 Implementation Report

**Shared Mobile Components and Screen Migration Foundation**

Branch: `local_setup` (not committed). Authoritative inputs: Step 2.6 Final Specification and the Decision Register. Technical contract produced: `docs/PROPKART_MOBILE_SCREEN_MIGRATION_CONTRACT.md`.

---

## 1. Objective

Standardize the technical contract every future mobile screen follows inside the new shell:

```text
Screen → MobileContent → MobileList/MobileCard → Search → Filter → Sort → Loading → Empty → Error → Offline → Sticky actions
```

To do that:
- Reuse the Step 3.0 components and fill only the real gaps.
- Settle K1 (double bottom padding) with one authoritative rule and pixel-level tests.
- Document the contract and a reusable checklist.

No role screens were migrated, no business logic was changed, and no product decisions were made.

## 2. Documents Read

- `docs/PROPKART_MOBILE_UX_AUDIT.md`
- `docs/PROPKART_MOBILE_UI_UX_MASTER_SPECIFICATION.md`
- `docs/PROPKART_MOBILE_UI_UX_STEP_2_5_VERIFICATION.md`
- `docs/PROPKART_MOBILE_UI_UX_FINAL_SPECIFICATION.md` (authoritative)
- `docs/PROPKART_MOBILE_UI_UX_DECISION_REGISTER.md` (authoritative). Applied: DR-001, DR-005, DR-016, DR-018, DR-019, DR-020, DR-021, DR-022, DR-023, DR-026, DR-027, DR-028, DR-030, SD-11, SD-12.
- `docs/PROPKART_MOBILE_UI_UX_STEP_2_7_SIGN_OFF.md`
- `docs/PROPKART_MOBILE_STEP_3_0_IMPLEMENTATION_REPORT.md`
- `docs/PROPKART_MOBILE_STEP_3_1_IMPLEMENTATION_REPORT.md`

## 3. Step 3.0/3.1 Baseline

- `MobileAppShell` is the default below 768. The old drawer and bottom bar are removed, and the flag is removed.
- The foundation components are in `lib/core/design_system/mobile/`.
- Analyzer: 1235 issues, 0 errors. `test/mobile`: 131 passing. Full suite: 267 passing, with 1 pre-existing failure (`telecaller_role_test`).
- Open known issue K1: double bottom padding inside the shell.

## 4. Existing Component Audit

| Contract need | Existing component | Gap found |
|---|---|---|
| Screen scaffold | None (only `MobileFormScaffold` for forms) | **Missing** |
| Shell awareness | `MobileShellScope.isInShell` | No title channel |
| Content padding | `MobileContent` | Read `viewPadding` (not zeroed by a `Scaffold` bottom bar or the keyboard), so a pushed page with a sticky bar could double the safe area |
| Shell clearance | `MobileAppShell` padding by `mobileNavClearance` | **K1:** `Scaffold(extendBody: true)` also raised the content `MediaQuery.padding.bottom` to the nav height, so screens using `SafeArea(bottom)`/padding reads (and `viewPadding` reads) got a second copy |
| Title | `MobileNavConfig.resolve()` | No custom or detail title |
| Back | `MobileSystemBackHandler`, shell Back, `MobileTopBar.backAction` (`maybePop` only) | No fallback for pushed pages without history |
| List | `MobileList<T>` (lazy, keyed, refresh, load-more, states) | No bottom safe area outside the shell |
| Card | `MobileCard` (generic slots) | None |
| Search | `MobileSearch` (idle/loading/results/empty/error, clear, filter badge) | No `typing` state; couldn't be used as a header above a list |
| Filter | `MobileFilterSheet` (caller sections, Reset, Apply) | None |
| Sort | `MobileSortSheet` | No Reset |
| Loading | `MobileLoadingState` (4 modes), `MobileSkeleton`, `MobileInlineLoader`, `MobileButtonLoader` | None |
| Empty / Error | `MobileEmptyState`, `MobileErrorState` (+`logTechnical`), `MobileRetryState` | None |
| Offline | `MobileDataStatus` (5 DR-021 states), banner, indicator, pending badge | No rule stopping direct-server writes from showing "Waiting to sync" |
| Sticky actions | `MobileStickyActionBar`, `MobileActionButton`, `MobileAction` | None |
| Forms | `MobileFormScaffold`, step header, progress, section, actions | None |
| Sheets / dialogs | `MobileSheet`, `MobileConfirmDialog` | None |

`lib/core/design_system/widgets/` contains desktop/shared widgets (`CRMDataTable`, `crm_error_state.dart`, skeletons, drawers). None duplicates a mobile component, and none was changed.

## 5. Components Reused

`MobileContent`, `MobileShellScope`, `MobileList`, `MobileListItem`, `MobileCard`, `MobileSearch`, `MobileFilterSheet`, `MobileSortSheet`, `MobileSheet`, `MobileConfirmDialog`, `MobileLoadingState` (with skeleton, inline and button loaders), `MobileEmptyState`, `MobileErrorState`, `MobileRetryState`, `MobileDataStatus`, `MobileOfflineBanner`, `MobileSyncIndicator`, `MobilePendingSyncBadge`, `MobileStickyActionBar`, `MobileActionButton`, `MobileForm*`, `MobileTopBar`, `MobileIconAction`, `MobileSystemBackHandler`, and GoRouter.

## 6. Components Added

| Added | Where | Purpose |
|---|---|---|
| `MobileScreenScaffold` | `mobile_screen.dart` (new) | Layout-only page frame |
| `MobileShellTitle` | `mobile_screen.dart` | Screen-supplied title in the shell top bar |
| `MobileBackNavigation.back` | `mobile_screen.dart` | Pop, or fall back through GoRouter |
| `MobileTitleController` | `mobile_layout.dart` | Owner-safe title override, carried by `MobileShellScope` |
| `MobileWriteChannel`, `MobileDataStatusRules.forWrite` | `mobile_offline.dart` | DR-021 write-state mapping |
| `MobileSearchStatus.typing`, `MobileSearch.showResultsBody` | `mobile_search.dart` | Typing state; header-only field |
| `MobileSortSheet.show(resetValue:)` | `mobile_sheets.dart` | Reset to the caller's default |

There are no V2 or duplicate components.

## 7. MobileScreenScaffold

Its slots are `title`, `banner` (pinned), `header` (pinned), `body`, `bottomAction`, `floatingAction`, `scrollable`, `onRefresh`, `padding`, `centered`, `controller`, `actions`, `showBack`, `onBack`, and `backFallback`.

Behavior:
- Inside the shell: no top bar and no bottom nav; `title` becomes `MobileShellTitle`.
- Outside the shell: draws `MobileTopBar` with Back (`MobileBackNavigation`).
- `scrollable: true` wraps the body in `MobileContent`; `false` is for self-scrolling bodies such as `MobileList`.
- It fetches no data and has no knowledge of roles, records, KPIs, or statuses.

## 8. MobileShellScope

This remains the single shell-awareness mechanism (`isInShell`). It now also carries an optional `MobileTitleController` (`titleControllerOf`, which does not create a dependency).

`MobileAppShell` became a `StatefulWidget` to own that controller. Its public API is unchanged.

## 9. Bottom Clearance / K1

**Rule:** the shell owns the bottom-nav clearance, and screens never add it.

Implementation, in `MobileAppShell` only:
- The content is padded once by `CRMBreakpoints.mobileNavClearance`.
- The content's `MediaQuery` has bottom `padding` and `viewPadding` removed.

Consequences:
- `SafeArea(bottom)` in existing screens no longer adds a second copy, and neither do reads of padding or view padding.
- `MobileContent` and `MobileList` add only their 16px inset in the shell. Outside the shell they add the bottom safe area from `MediaQuery.padding`.

This is a shell-level fix: no existing screen file was edited. Its visible effect is that existing screens inside the mobile shell lose the extra blank band above the bottom nav.

Verification (pixel-exact, `test/mobile/mobile_foundation_step32_test.dart`, 34px bottom inset, 800px height):

| Case | Expected bottom of content | Result |
|---|---|---|
| Shell content `MediaQuery` | padding 0, viewPadding 0 | PASS |
| `MobileContent` in shell | 800 − 110 (clearance) − 16 | PASS |
| Legacy `SafeArea(bottom)` in shell | 800 − 110 | PASS |
| `MobileContent` outside shell | 800 − 34 − 16 | PASS |
| `MobileList` outside / inside shell | list bottom padding 16 + 34 / 16 | PASS |
| Sticky action in shell | button bottom 800 − 110 − 12 | PASS |
| Sticky action outside shell | button bottom 800 − 34 − 12; body ends 16 above the bar | PASS |
| Keyboard (300) in shell | nav hidden; button bottom 800 − 300 − 12 | PASS |

**K1: PASS.**

## 10. Safe Area Contract

The shell owns the bottom-nav clearance and the bottom safe area for routed content. A screen owns a safe area only for:
- pushed full-screen pages (through `MobileContent`/`MobileList`),
- sticky bars outside the shell,
- sheets,
- full-screen media,
- system UI.

It never adds one to make room for the nav. Details are in Contract §8.

## 11. Screen Title Contract

| Location | Title |
|---|---|
| Root tab | from `resolve()` |
| More-owned page | from `resolve()` |
| Secondary or detail page | `MobileScreenScaffold(title:)` / `MobileShellTitle` |
| Pushed page | its own top bar |
| Unknown | "PropKart" |

The latest claim wins, a stale release is ignored, and claims after the shell is disposed are ignored. Desktop titles are untouched. No existing screen titles were changed.

## 12. Back Navigation Contract

One stack (GoRouter plus the existing Navigators):
- System back goes through `MobileSystemBackHandler`.
- Shell Back is `pop`, or the `resolve()` fallback.
- Scaffold Back uses `MobileBackNavigation.back`: `maybePop` (respecting `PopScope`), otherwise `GoRouter.go(fallback)`.

Tested: popping a pushed route, and the GoRouter fallback with no history.

## 13. List/Card Contract

- `MobileList`: lazy and keyed, with refresh, a load-more UI hook (no server paging), and the loading, empty and error states.
- Tested: 10,000 items build fewer than 60 rows, keys are stable, load-more is gated while in flight, and the footer and refresh are wired.
- `MobileCard` stays generic (selection semantics tested).
- DR-020's 5000-row campaign request is unchanged.

## 14. Search Contract

`MobileSearch` statuses: `idle`, `typing`, `loading`, `results`, `empty`, `error`. Clear emits `''`. The filter action shows an announced active count. Header-only mode is available.

The global search engine, debounce values, and backend are untouched, and there is no recent-search persistence.

## 15. Filter/Sort Contract

- Filter: the caller supplies sections and options. Select, Reset and Apply are tested; the result is `{'a': {'x'}}`.
- Sort: the caller supplies options. Selecting applies immediately, Reset returns `resetValue`, and dismissing returns `null` (tested).
- No new keys, filters, or server behavior.

## 16. Loading Contract

The four modes (initial, refreshing, loading more, action) map to the existing components. All are tested, including at 1.3× text scale in the width matrix.

## 17. Empty/Error Contract

- Empty: the caller supplies the copy; the primary and secondary actions are tested.
- Error: friendly copy only, retry tested. `logTechnical` keeps details out of the UI.
- A source guard asserts the foundation contains no `e.toString()`, `'$e'`, or `${e}`.

## 18. Offline Contract

The DR-021 five-state model (`MobileDataStatus`) is reused; there is no new enum. Every state is labelled and announced (tested).

`MobileDataStatusRules.forWrite` gives:
- outbox, in progress → `pendingWrite`;
- direct server, in progress → `directOperation`;
- failed → `failedWrite`;
- idle → none.

The test asserts that direct-server writes never produce `pendingWrite` ("Waiting to sync"), satisfying the campaign-outcome rule (SD-12). `SyncManager`, the outbox, and realtime are unchanged.

## 19. Sticky Action Contract

- One primary action and an optional secondary, 48px tall.
- Loading is announced as "…, in progress" and is inert; disabled actions are inert with `enabled=false` semantics.
- Safe-area and keyboard behavior are covered by the K1 tests.

## 20. Form Contract

The existing `MobileFormScaffold`, step header, progress, section, and actions already support multi-step forms, validation (`formKey`), keyboard-safe scrolling, sticky Next/Save, Back, and draft text. No change was needed, and no form fields were touched.

## 21. Sheet/Dialog Contract

- Bottom sheet: filters, sort, lightweight actions, outcome selection.
- `MobileConfirmDialog`: destructive or critical confirmation.
- Full page: complex forms, details, workflows, large lists.

The conversion happens per screen (DR-030). Nothing was converted in this step.

## 22. Table Migration Contract

Each row becomes a `MobileCard`:
- primary column → `title`,
- secondary column → `subtitle`,
- key columns → `metadata`,
- status → `status`,
- actions → `trailing` / detail page.

Column sort becomes `MobileSortSheet`, and column filters become `MobileFilterSheet`. The data source, pagination, and sort order are unchanged, and the desktop table remains. None of the roughly 44 tables were converted.

## 23. Accessibility

- New and changed components meet 48×48 and labeling: `androidTapTargetGuideline` and `labeledTapTargetGuideline` pass on the scaffold chrome (top bar, header search, filter, sticky actions).
- Titles are headers, selection and disabled states are exposed, and badges are announced.
- Text is not clamped; layouts were tested at 1.0 and 1.3 across all widths.

## 24. Keyboard

- The shell hides the nav and drops the clearance; the shell `Scaffold` resizes the content (nested scaffolds don't get a double inset).
- Sticky actions sit directly above the keyboard (tested).
- Drag dismisses the keyboard. There is no global keyboard manager.

## 25. Media

Plug points are defined: thumbnail in `MobileCard.leading`, gallery in a card footer or detail section, video using the existing player in the detail page, and full-screen media as a pushed page. Nothing is implemented, and upload, storage, compression, and APIs are unchanged.

## 26. Responsive Behavior

Bands: `compact` (below 360), `phone` (360–479), `phablet` (480–767), and `shell` (768 and up), all from `CRMBreakpoints`. No new breakpoints.

The full screen pattern was tested at 320, 360, 390, 412, 430, 480, 600, 767 (in the shell) and 768 (outside the shell), each at text scale 1.0 and 1.3. The pattern is a banner, a header search, a list of cards, and sticky actions. Checks:
- no overflow;
- exactly one top bar;
- a bottom nav only below 768;
- the list ends above the sticky bar;
- the sticky bar ends above the nav.

## 27. Tests

| Command | Result |
|---|---|
| `flutter analyze` | 1235 issues, 0 errors (baseline 1235; **0 new**). Mobile files: **No issues found** |
| `flutter test test/mobile` | **184 passed** (131 existing + 53 new), 0 failed |
| `flutter test` | **320 passed, 1 failed**. The failure is the pre-existing `test/security/telecaller_role_test.dart` case ("Telecaller is recognized as having Admin privileges but cannot manage employees"). **Not fixed; not claimed fixed** |

New test file: `test/mobile/mobile_foundation_step32_test.dart`. Groups:
- K1 bottom clearance (9)
- Shell separation (3)
- Title contract (3)
- Back contract (2)
- Loading/empty/error (4)
- Offline (3)
- List contract (4)
- Search contract (3)
- Filter and sort (2)
- Sticky actions (1)
- Widths, text scale and accessibility (19)

All permissions are injected (`canView`). No test calls `setPermission()` or a backend mutation. `test/security/permission_matrix_test.dart` was not modified.

## 28. Files Added

- `lib/core/design_system/mobile/mobile_screen.dart`
- `test/mobile/mobile_foundation_step32_test.dart`
- `docs/PROPKART_MOBILE_SCREEN_MIGRATION_CONTRACT.md`
- `docs/PROPKART_MOBILE_STEP_3_2_IMPLEMENTATION_REPORT.md`

## 29. Files Modified

| File | Change |
|---|---|
| `lib/core/design_system/mobile/mobile_layout.dart` | `MobileShellScope.titleController`, `MobileTitleController`; `MobileContent` reads `MediaQuery.padding` |
| `lib/core/design_system/mobile/mobile_list.dart` | Bottom safe area outside the shell |
| `lib/core/design_system/mobile/mobile_search.dart` | `typing` status; `showResultsBody`; field extracted (formatting) |
| `lib/core/design_system/mobile/mobile_sheets.dart` | `MobileSortSheet` Reset (`resetValue`); `dart format` |
| `lib/core/design_system/mobile/mobile_offline.dart` | `MobileWriteChannel`, `MobileDataStatusRules.forWrite` |
| `lib/core/design_system/mobile/mobile.dart` | Exports `mobile_screen.dart` |
| `lib/features/shell/mobile/mobile_app_shell.dart` | Stateful; title controller; content `MediaQuery` bottom padding/viewPadding removed (K1) |

Not touched by this step: `crm_donut_chart.dart`, `dashboard_screen.dart`, and `properties_screen.dart`. These are pre-existing external working-tree changes, with diffs identical to the end of Step 3.1. `app_shell.dart` and `app_router.dart` were not changed in Step 3.2.

## 30. Files Deleted

None.

## 31. Packages Added

None.

## 32. Business Logic Safety

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

Business logic, backend, and database files touched: **0**.

## 33. Pending Product Decisions

| PD | Status |
|---|---|
| PD-01 Telecaller landing | PENDING |
| PD-02 Sales landing | PENDING |
| PD-03 Sales Visits | PENDING |
| PD-04 KPI-04 presentation | PENDING |
| PD-05 Sync overlay | PENDING (blocking overlay kept) |
| PD-06 Queue start-call | PENDING |

Also not decided: Meta/Housing More entries and quick-action permission filtering (Step 3.1 K2/K4), and Sales Visits.

## 34. Known Issues

- **K1 resolved at the shell level.** Existing screens inside the mobile shell now lose the duplicated blank space above the bottom nav. This is visible but intended. Screens that relied on `MediaQuery.padding.bottom` for something other than nav clearance (none identified) should be checked in their phase.
- **Title transition.** While a GoRouter page transition runs, the outgoing page's custom title can stay for one transition (about 300ms) when the incoming page sets none. Cosmetic.
- **Form back interception.** `PopScope`-based unsaved-changes handling must be verified against `MobileSystemBackHandler` per form in its phase.
- Pre-existing `telecaller_role_test` failure (unchanged; not fixed).
- `test/security/permission_matrix_test.dart` still triggers backend permission sync (left unmodified as instructed).
- Step 3.1 known issues K2–K7 still apply: Meta/Housing shortcuts, no hide-on-scroll, quick actions not filtered, search overlay offset, theme/logout location, `/more` after session expiry.
- No device or emulator QA yet.

## 35. Deferred Screen Work

Recorded, not fixed:
- **Step 3.3 (Telecaller):** Home, Queue (campaign leads: lazy rendering of the 5000-row request, outcome sheets DR-005/006/014, no "Waiting to sync" for outcomes), Callbacks, CNR; PD-01 and PD-06 are dependencies.
- **Step 3.4 (Sales):** Home (SD-10 field mapping), Leads, Properties; PD-02 and PD-03 are dependencies.
- **Step 3.5 (Admin):** Home (PD-04), Reports/KPI drilldowns, Allocation, Employees, Campaign Connections, Audit Logs.
- **Later phases:** Property and Lead detail and wizards (forms via `MobileFormScaffold`), Library, Recycle Bin, Messages, Settings; per-screen table-to-card and dialog-to-sheet conversions (DR-030); raw error cleanup (DR-026 / FB-11); semantics on untouched screens (FB-12).

## 36. Step 3.2 Status

**COMPLETE WITH CONDITIONS.**

All foundation requirements are met and tested:
- The scaffold exists; K1 is defined and tested; the safe-area, keyboard, title, and back contracts are defined.
- The state model is standardized; list and card are lazy and stable; accessibility checks pass.
- Desktop is unaffected, and there are no business-logic changes.
- The contract document and checklist exist.

Conditions:
- Device QA of the K1 shell change on real screens.
- Pending PDs.
- Release gates RV-01, RV-11, and RV-20 (from Step 2.7).

## 37. Recommendation for Step 3.3

Start the Telecaller mobile experience on this contract:
- Queue first (campaign leads) using `MobileScreenScaffold` + `MobileSearch(showResultsBody: false)` + `MobileList` + `MobileCard`, with outcome sheets via `MobileSheet`. Use `MobileDataStatusRules.forWrite(directServer)` for outcomes.
- Then Callbacks, CNR, and Home (respecting PD-01 and PD-06).
- Apply the migration checklist (Contract §29) per screen.
- Keep the 5000 request (DR-020) and verify RV-01 and RV-11 before release.
