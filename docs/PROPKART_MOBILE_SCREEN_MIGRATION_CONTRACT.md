# PropKart Mobile — Screen Migration Contract

Technical contract for every screen migrated into the mobile shell in Step 3.3 and later. Authority order:
1. Step 2.6 Final Specification and the Decision Register.
2. This contract.
3. The Step 3.0, 3.1 and 3.2 implementation reports.

All components live in `lib/core/design_system/mobile/`. Import them through the barrel `mobile.dart`.

---

## 1. Purpose

This contract gives every migrated screen the same structure, states, and behavior below 768px. Desktop and tablet stay unchanged.

A migration changes **presentation only**. Routes, APIs, BLoCs/providers, repositories, permissions, statuses, KPIs, and form fields stay exactly as they are (see §30).

## 2. Shell boundary

| Width | Shell | Source |
|---|---|---|
| < 768 | `MobileAppShell` (top bar, content, bottom nav) | `MobileLayout.isMobileShell(width)` |
| ≥ 768 | Existing `CRMAppShell` (ModernSidebar + ModernTopBar) | unchanged |

Rules:
- Breakpoints come only from `CRMBreakpoints` (DR-001): below 360, 360–479, 480–767, and 768 and up (`MobileWidthClass`). Do not add new breakpoints.
- A screen that renders differently on mobile branches with `MobileShellSwitch` or `MobileLayout.isMobileShell`, so exactly one layout builds.
- The desktop branch keeps its current code path untouched.

## 3. Screen scaffold

Use `MobileScreenScaffold`. It is layout only: it does not fetch data and knows nothing about roles, records, or statuses.

```text
MobileScreenScaffold
 ├── banner        optional, pinned   (MobileOfflineBanner / MobileSyncIndicator)
 ├── header        optional, pinned   (MobileSearch showResultsBody:false, chips)
 ├── body          scrolls            (MobileContent via scrollable:true, or MobileList with scrollable:false)
 ├── floatingAction optional
 └── bottomAction  optional           (MobileStickyActionBar / MobileFormActions)
```

| Parameter | Use |
|---|---|
| `title` | Inside the shell it becomes a `MobileShellTitle` (§4); outside, the top-bar title |
| `scrollable` | `true` wraps `body` in `MobileContent`; set `false` when `body` scrolls itself (`MobileList`, `MobileSearch` with body) |
| `onRefresh` | Pull-to-refresh for a `MobileContent` body (lists pass `onRefresh` to `MobileList`) |
| `padding`, `centered`, `controller` | Forwarded to `MobileContent` |
| `actions`, `showBack`, `onBack`, `backFallback` | Top bar, outside the shell only |

Inside the shell the scaffold draws **no** top bar and **no** bottom nav (the shell owns both). Outside the shell it draws a `MobileTopBar` with Back.

## 4. Title rules

| Location | Title source |
|---|---|
| Root tab | `MobileNavConfig.resolve()` returns the tab label. Do not pass `title` |
| More-owned page | `resolve()` returns the More entry label. Do not pass `title` |
| Secondary or detail page in the shell | `MobileScreenScaffold(title: …)` or `MobileShellTitle(title: …)`; overrides the shell title while mounted |
| Pushed full-screen page (outside the shell) | `MobileScreenScaffold(title: …)` draws its own top bar |
| Unknown route | "PropKart" |

Mechanics:
- The override goes through `MobileTitleController`, which `MobileAppShell` provides via `MobileShellScope`.
- The latest claim wins, and a page that is leaving can't clear the incoming page's title.
- Desktop titles are not affected.

## 5. Back rules

There is one navigation stack: GoRouter plus the existing `Navigator`s. Never create a nested `Navigator` for a screen.

| Trigger | Behavior |
|---|---|
| System back (<768) | `MobileSystemBackHandler` closes search, then the notifications panel. If a route can pop, it pops. A More-owned route falls back to `/more`. Any other non-home route goes to `/dashboard`. On Home it shows the exit confirmation |
| Shell top-bar Back | `canPop ? pop : go(resolve().backFallback)` |
| Scaffold Back (outside shell) | `MobileBackNavigation.back(context, fallback:)`: `Navigator.maybePop()` if it can pop, otherwise `GoRouter.go(fallback)` |
| Sheets / dialogs | Close with `Navigator.pop`; system back closes them first |

Unsaved-changes interception on forms uses `PopScope`. Verify it against `MobileSystemBackHandler` per screen in that screen's phase.

## 6. Content padding

`MobileContent` and `MobileList` own page padding:
- Horizontal: 12px below 360, 16px from 360 (`MobileLayout.horizontalPaddingOf`).
- Vertical: 16px.
- Content is centered at a 560px max width from 430 to 767.

Do not add another horizontal page inset inside them. Cards and rows rely on this padding.

## 7. Bottom navigation clearance (K1)

**The shell owns the bottom-nav clearance. A screen never adds it.**

`MobileAppShell` does two things:
1. Pads its content once by `CRMBreakpoints.mobileNavClearance` (76 plus the bottom safe area; 0 while the keyboard is open).
2. Gives its content a `MediaQuery` with **bottom `padding` and `viewPadding` removed**.

As a result, inside the shell:
- `MobileContent` and `MobileList` add only their 16px bottom inset.
- A legacy `SafeArea(bottom)` or a `MediaQuery.padding.bottom`/`viewPadding.bottom` read resolves to 0, so existing screens do not double the space.
- `MobileStickyActionBar` sits directly above the bottom nav with no extra inset.

`MobileShellScope.isInShell(context)` is the **only** shell-awareness check. Never hard-code `76`, `64`, or nav heights in a screen.

This is verified by `test/mobile/mobile_foundation_step32_test.dart` (group "K1 bottom clearance"), which measures in pixels.

## 8. Safe-area rules

| Layer | Owns |
|---|---|
| Shell | Bottom-nav clearance and the bottom safe area for everything routed inside it; top safe area via the top bar |
| Screen | Nothing at the bottom while in the shell |
| Screen outside the shell (pushed full-screen page) | Bottom safe area via `MobileContent`/`MobileList`, which read `MediaQuery.padding`. `Scaffold` zeroes that padding when a bottom bar is present or the keyboard is open, so it never doubles |
| Sticky action bar | Its own bottom safe area outside the shell (via `viewPadding`); dropped while typing |
| Sheets (`MobileSheet`) | Their own safe area and keyboard insets |
| Full-screen media, system UI overlays | Their own `SafeArea` as needed |

A screen may use `SafeArea` for modal content, full-screen media, or system UI. It must **not** use it to make room for the bottom nav.

## 9. Search

There are two search surfaces, and they stay separate (DR-018):
- **Global search:** the shell top bar → existing `CRMAppShell` engine and overlay. Do not touch it.
- **Screen search:** `MobileSearch`, fed by the screen's existing source and existing debounce (`debounce:` parameter). No new backend, no global debounce change, no recent searches.

Statuses: `idle`, `typing` (debounce pending; previous results stay), `loading`, `results`, `empty`, `error`. Clear emits `''`.

Modes:
- `showResultsBody: true` (default) is the full-screen search with its own results, empty, and error body.
- `showResultsBody: false` renders only the 48px field row (Back, field, Clear, Filters with an active-count badge), for use as a `MobileScreenScaffold.header` above the screen's own `MobileList`.

## 10. Filter

`MobileFilterSheet.show(context, sections:, initialSelection:)` returns `Map<String, Set<String>>` on Apply and `null` when dismissed. Reset clears the selection inside the sheet.

The screen supplies every `MobileFilterSection` and `MobileOption` from filters it **already supports**. The foundation knows no categories, BHK, price, status, or source values. Do not invent filters or change backend filter support. Show active counts with `MobileSearch.activeFilterCount`.

## 11. Sort

`MobileSortSheet.show(context, options:, selected:, resetValue:)`:
- Selecting an option applies it immediately and returns its value.
- Reset (only when `resetValue` is given) returns the screen's existing default.
- Dismissing returns `null`.

Options are only the sort keys the screen already has. Server-side and existing property sorting stay unchanged.

## 12. List

Use `MobileList<T>` with `items`, `itemBuilder`, `keyOf` (stable, unique id), `onRefresh`, `onLoadMore`/`hasMore`/`isLoadingMore`, `isLoading`, `hasError`/`onRetry`, `emptyState`, and `header`.

Behavior:
- Rows are built lazily (`ListView.separated`) and wrapped in `ValueKey(keyOf(item))`.
- Initial load with no items shows `MobileLoadingState`; an error with no items shows `MobileErrorState`; no items shows `emptyState`.
- `onLoadMore` is a **UI hook** only. It fires near the end while `hasMore && !isLoadingMore`. It does not imply server pagination (SD-11), and the campaign 5000 request stays as is (DR-020).

## 13. Cards

`MobileCard` stays generic: `leading`, `title`, `subtitle`, `metadata`, `status`, `trailing`, `footer`, `selected`, `onTap`, `onLongPress`, `semanticLabel`.

Record-specific cards (lead, property, visit) are composed in their screen phase from `MobileCard` slots. Do not fork the component. Status chips use the presentation labels from Final Spec §9 (DR-019); backend values are not changed.

## 14. Loading

| Situation | Component |
|---|---|
| Initial (no data yet) | `MobileLoadingState(mode: initial)` (skeletons) or `MobileList(isLoading: true)` |
| Refreshing with data shown | `RefreshIndicator` via `onRefresh`; optional `MobileLoadingState(mode: refreshing)` |
| Loading more | `MobileList(isLoadingMore: true)` footer (`MobileInlineLoader`) |
| Action in progress | `MobileAction(loading: true)` (`MobileButtonLoader`, label "…, in progress", inert) |

No other spinners or skeleton systems.

## 15. Empty

`MobileEmptyState(icon, title, description, actionLabel/onAction, secondaryActionLabel/onSecondaryAction)`. The **screen supplies all copy** from Final Spec copy. The foundation invents no business copy.

## 16. Error

- `MobileErrorState(title, message, onRetry)` for full-area errors; `MobileRetryState` for inline retry.
- Never put `$e`, `e.toString()`, exception messages, or stack traces in UI (DR-026).
- Log technical details separately with `MobileErrorState.logTechnical(error, stackTrace)` (debug only).
- API 403 uses the permission state from DR-016; router redirects are unchanged.

## 17. Offline

DR-021 state model (`MobileDataStatus`):

| State | Meaning | UI |
|---|---|---|
| `cachedRead` | Showing Isar cache while offline | `MobileOfflineBanner(hasCache: true, lastUpdated:)` |
| `syncing` | Sync run in progress | `MobileSyncIndicator` |
| `pendingWrite` | Write queued in the **existing outbox** | `MobilePendingSyncBadge` ("Waiting to sync") |
| `directOperation` | Direct server call in flight | `MobileSyncIndicator` ("Saving…") |
| `failedWrite` | Write failed | `MobileSyncIndicator(onRetry:)` |

Derive write states with `MobileDataStatusRules.forWrite(channel, inProgress:, failed:)`:
- `MobileWriteChannel.directServer` (for example campaign outcomes, SD-12) can **never** produce `pendingWrite`.
- Never show "Waiting to sync" for campaign outcomes.

The foundation only displays states the screen already knows. `SyncManager`, the outbox, and realtime are unchanged. The blocking sync overlay stays in place until PD-05 is decided. Realtime is not relied on (DR-022): use pull-to-refresh or refetch on focus.

## 18. Sticky actions

`MobileStickyActionBar(primary:, secondary:)` with `MobileAction(label, onPressed, icon, loading, enabled)`:
- Exactly one primary action, plus an optional secondary.
- Buttons are 48px tall.
- Disabled and loading actions are inert and announced.
- Place it in `MobileScreenScaffold.bottomAction` so it stays above the keyboard and above the shell nav.

Do not attach business actions in the foundation.

## 19. Forms

Use `MobileFormScaffold(stepHeader, progress, children, actions, formKey, controller)` with:
- `MobileFormStepHeader` and `MobileFormProgress` for multi-step forms.
- `MobileFormSection` for field groups.
- `MobileFormActions(onBack, onNext, nextLabel, saving, canProceed, draftStatus)` for sticky Back and Next/Save with draft indication.

Validation stays in the existing `Form`/validators. Fields, field order semantics, and payloads are **not** changed by a migration. The keyboard is dismissed on drag, and fields scroll into view through the resized body.

## 20. Sheets

Use a bottom sheet (`MobileSheet.show` / `MobileFilterSheet` / `MobileSortSheet`) for:
- filters and sort,
- lightweight actions (2–6 choices),
- outcome selection (DR-005; the outcome semantics are unchanged).

Sheets have a grabber, a header title, a 48px Close button, a scrollable body, sticky actions, and handle safe area and keyboard insets.

## 21. Dialogs

| Case | Use |
|---|---|
| Simple action | Bottom sheet |
| Destructive or critical confirmation | `MobileConfirmDialog.show(…, destructive:)`; the title names the affected object |
| Complex workflow | Full-screen page (`MobileScreenScaffold` / `MobileFormScaffold`) |
| Large data list | Full-screen page with `MobileList` |

Convert dialogs only on the screen being migrated (DR-030). There is no global conversion.

## 22. Tables

Desktop `DataTable` / `CRMDataTable` becomes a card or list representation on mobile:
- Each row becomes one `MobileCard`. The primary column is the `title`, the secondary identifying column is the `subtitle`, 2–4 key columns go in `metadata`, the status column goes in `status`, and row actions go in `trailing` (overflow sheet) or the detail page.
- Column sorting becomes `MobileSortSheet` with the same keys, and column filters become `MobileFilterSheet` with the same values.
- Same data source, pagination, and sort order. Only the presentation changes.
- The desktop table remains for ≥768.

Convert tables per screen in its phase (DR-030); about 44 tables remain.

## 23. Accessibility

Applies to every migrated screen (DR-027, DR-028):
- 48×48 minimum targets (`MobileLayout.minTouchTarget`, `MobileIconAction`, `MobileTapTarget`).
- Semantic labels on every tappable; badges announced as "N new".
- Selected and disabled states exposed. Page and sheet titles are headers.
- Live regions for loading, offline, sync, and draft status.
- Text is never clamped. Layouts tolerate a 1.3× text scale, with long text ellipsized rather than clipped.

## 24. Keyboard

- The shell hides the bottom nav and drops its clearance while the keyboard is open.
- The shell's `Scaffold` resizes the content, so nested scaffolds see no double inset.
- `MobileStickyActionBar` / `MobileFormActions` in `bottomAction` sit directly above the keyboard.
- Scroll views use `keyboardDismissBehavior: onDrag`, and focused fields scroll into view through the resized viewport.
- There is no global keyboard manager.

## 25. Media

These plug points are defined; full implementations come in the media phase:

| Need | Plug point |
|---|---|
| Thumbnail | `MobileCard.leading` (fixed square, `ClipRRect`, cached image widget the screen already uses) |
| Gallery | Horizontal list inside a card `footer` or a detail section |
| Video | Existing player widget inside the detail page |
| Full-screen media | A pushed full-screen page (outside the shell) that owns its `SafeArea` and back |

Upload limits, storage, compression, and backend APIs are unchanged.

## 26. Responsive behavior

| Band | Width | Behavior |
|---|---|---|
| `compact` | < 360 | 12px page padding; Telecaller Search moves to the top-bar overflow below 412 |
| `phone` | 360–479 | 16px page padding |
| `phablet` | 480–767 | 16px padding; content centered at a 560px max from 430 |
| `shell` | ≥ 768 | Existing desktop/tablet shell; mobile components are not used by the shell |

There is no new orientation behavior.

## 27. Performance

- Lists build lazily with stable keys. Do not wrap long lists in `Column` or `SingleChildScrollView`.
- The shell fetches no business data. Screens keep their existing BLoC/repository fetches; do not add duplicate fetches on rebuild.
- `MobileShellBadges` and `MobileShellScope` are read-only `InheritedWidget`s; avoid `setState` in build.
- The campaign 5000-row request is unchanged (DR-020); render it lazily.

## 28. Testing requirements

For each migrated screen:
- Widget tests at 320, 360, 390, 412, 430, 480, 600, and 767, plus a ≥768 regression check.
- No overflow, exactly one top bar, no double nav, and sticky actions not overlapping content or the nav.
- K1: no duplicate bottom clearance inside the shell.
- Loading, empty, error, and offline states rendered.
- `androidTapTargetGuideline` and `labeledTapTargetGuideline` pass, plus a text scale of 1.3.
- Permissions are injected (for example `canView`), never `setPermission()`. Tests send no PATCH/POST/DELETE to the backend.
- `flutter analyze` adds no new issues; `flutter test test/mobile` and the relevant feature tests pass.

Use `test/mobile/mobile_test_utils.dart` (`testMobile`, `setSurface`, `wrap`).

## 29. Migration checklist

Copy this list into each screen's phase report:

```text
□ Screen identified
□ Desktop behavior understood
□ Existing route preserved
□ Existing API preserved
□ Existing BLoC/provider preserved
□ Existing repository preserved
□ Existing business logic preserved
□ Mobile title defined
□ Mobile back behavior defined
□ MobileContent used
□ No duplicate bottom-nav clearance
□ Search converted if applicable
□ Filters converted if applicable
□ Sort converted if applicable
□ Table converted to card/list if applicable
□ Dialog converted where appropriate
□ Loading state
□ Empty state
□ Error state
□ Offline state
□ Sticky actions
□ Accessibility
□ 48×48 targets
□ Keyboard behavior
□ 320–767 verification
□ >=768 regression
□ flutter analyze
□ relevant tests
```

## 30. Forbidden changes

A screen migration must not change:
- KPI definitions, KPI SQL, or the database schema/relationships.
- API contracts or response semantics.
- RBAC, permission definitions, route permissions, or router redirects (DR-016, DR-023).
- Lead allocation, the match engine, or campaign business logic.
- Lead/property statuses or outcome semantics (DR-005, DR-006, DR-014, DR-019).
- Telecaller shift logic, timers, break, the 9-hour lockout, or the 30-second heartbeat.
- `SyncManager`, the outbox, or realtime (DR-021, DR-022).
- Form business fields or payloads.
- Desktop/tablet UI at ≥768.
- Pending product decisions PD-01…PD-06, Meta/Housing More entries, quick-action permission filtering, or Sales Visits.
- Dependencies (no new packages without approval).

If a migration needs any of these: **STOP**, identify the DR/PD/RV/SD/FB item, and report it.
