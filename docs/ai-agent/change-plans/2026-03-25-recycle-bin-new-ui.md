# Change Plan — Recycle Bin New UI (Step 1)

## 1. Task Metadata
- **Task Title**: Implement New_UI Recycle Bin page from HTML prototype
- **Target Subsystem**: Flutter Presentation — Properties / Recycle Bin
- **Requester**: UI/UX page-by-page New_UI rollout (first page: Recycle Bin)
- **Assigned Agent Role**: UI Implement Engineer + UX Engineer

## 2. Objective & Scope
- **Primary Objective**: Restyle Recycle Bin to match `C:/NB/UI by shubhangi/Propkart/recycle-bin.html` while preserving restore / permanent-delete / empty-bin / RBAC / sync behavior.
- **Non-Goals**: Sidebar/shell redesign, other pages, backend/API/schema changes, new packages unless required.
- **Architecture Layer**: Flutter Presentation only
- **Authoritative Source**: Existing PropertiesService / RequirementsService bin endpoints (PostgreSQL)

## 3. Scope Boundaries
### Files Allowed to Change
- `lib/features/properties/screens/recycle_bin_screen.dart`
- `lib/features/properties/widgets/recycle_bin/**` (new UI building blocks)
- `docs/ai-agent/change-plans/2026-03-25-recycle-bin-new-ui.md`
- Additive tests under `test/` if needed for UI helpers

### Forbidden
- Generated `*.g.dart`, backend, migrations, unrelated feature screens, `pubspec.lock` unless a dep is approved

## 4. Strategy
1. Extract overflow-safe Recycle Bin UI widgets (banner, tools, item row, sidebar, lead-kind cards).
2. Rebuild screen layout: header → banner → filters/search → lead kinds → list + sidebar.
3. Keep service calls, permissions (`page.recycle_bin.*`), sync refresh, search-link deep linking.
4. Map HTML "Leads" → Requirements; preserve Not Interested as a third lead-kind card.
5. Verify with analyze + recycle_bin source tests; avoid RenderFlex overflow via Wrap/Flexible/ellipsis.

## 5. Verification
- `flutter test test/requirements/recycle_bin_source_test.dart`
- `flutter analyze --no-fatal-infos` (scoped / project)
- Manual layout check: phone + desktop widths
