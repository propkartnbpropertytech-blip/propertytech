# 04 — Flutter Testing Standard & Quality Guidelines

## 1. Overview & Principles

The PropKart Flutter application enforces an observable-behavior testing philosophy:
1. **Test Observable Behavior, Not Implementation Details:** Tests must verify what the user sees, inputs, or experiences, rather than asserting private variables or internal helper invocations.
2. **Zero Network Flakiness:** All tests run with mocked HTTP clients or repository interfaces. Google Fonts runtime fetching is disabled (`GoogleFonts.config.allowRuntimeFetching = false`).
3. **Deterministic Viewports:** All mobile adaptation tests use `TargetPlatformVariant.only(TargetPlatform.iOS)` and explicit surface sizing via `tester.view.physicalSize`.

---

## 2. Testing Layers & Conventions

### 2.1 BLoC & Cubit Unit Tests
- Must verify exact state progression: `Initial → Loading → Loaded (with data) / Error`.
- Must test zero-flicker state transitions: soft-refresh events must keep previous data visible (`state.previousData != null`) while updating loading flags (`isKpiLoading: true`).
- Errors must emit structured error states containing human-readable error messages and previous data retention.

```dart
// Example: Zero-flicker test pattern
blocTest<DashboardBloc, DashboardState>(
  'retains cached KPIs during background refresh without flashing blank screens',
  build: () => DashboardBloc(repository: mockRepo),
  seed: () => DashboardLoadedState(data: initialData, isKpiLoading: false),
  act: (bloc) => bloc.add(const RefreshDashboardEvent()),
  expect: () => [
    DashboardLoadedState(data: initialData, isKpiLoading: true),
    DashboardLoadedState(data: updatedData, isKpiLoading: false),
  ],
);
```

### 2.2 Widget & Component Tests
- Every interactive element (button, switch, tab, icon) must meet the **minimum 48x48 logical pixels** accessibility touch target requirement.
- Overflows must be caught and forbidden:
  ```dart
  expect(tester.takeException(), isNull);
  ```
- All screens must be tested across the standardized **13-step viewport matrix**:
  ```dart
  const kStep30Widths = <double>[
    320, 360, 390, 412, 430, 480, 600, 700, 767, 768, 800, 1024, 1280,
  ];
  ```

### 2.3 Provider Scoping Standard
When pumping any top-level or operational screen, the test must supply all required BLoCs within a `MultiBlocProvider` wrapper to prevent `ProviderNotFoundException`:

```dart
Widget wrapScreen(Widget screen) {
  return wrapWithRouter(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
        BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
        BlocProvider<DashboardBloc>.value(value: MockDashboardBloc()),
        BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
        BlocProvider<PropertiesBloc>.value(value: MockPropertiesBloc()),
        BlocProvider<CampaignLeadsBloc>.value(value: TestCampaignLeadsBloc()),
      ],
      child: screen,
    ),
  );
}
```

---

## 3. Mocking & Fixtures Rules

1. **Use Concrete Test Doubles Where Practical:** Prefer simple test stubs (e.g. `TestCampaignLeadsBloc`) implementing the interface over complex, brittle mockito verification chains.
2. **Never Assert Mock Calls Alone:** A test that only asserts `verify(mock.method()).called(1)` without asserting the resulting UI or state change is classified as a low-value test and rejected.
3. **Always Clean Up In TDown:** Tear down mocks, controllers, and services in `tearDown()`:
   ```dart
   tearDown(() async {
     AppNotifierService.dismissToast();
     AuditTelemetryService.instance.dispose();
   });
   ```
