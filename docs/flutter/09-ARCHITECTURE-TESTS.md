# PROPKART FLUTTER ARCHITECTURE TEST STANDARD & SUITE
## Step 6 Architectural Governance & Invariant Enforcement

```text
STATUS: ACTIVE & ENFORCED
VERSION: 1.0.0
TEST LOCATION: test/core/flutter_architecture_rules_test.dart
EXECUTION: flutter test test/core/flutter_architecture_rules_test.dart
```

---

## 1. PURPOSE & ARCHITECTURAL OBJECTIVE

The Flutter Architecture Test Suite ensures that the architectural standards established during Step 6 cannot be degraded by future feature work, refactoring, or AI-agent code edits.

Like backend architecture tests in Step 5, these automated rules run as standard Dart/Flutter unit tests, validating:
1. Layer boundaries (`Presentation` -> `BLoC` -> `Domain` -> `Repository` -> `Data Source`).
2. Absence of direct database schema imports in presentation UI.
3. Absence of direct HTTP/Dio clients inside UI screens.
4. Purity of BLoC business logic (zero widget definitions inside BLoC files).
5. Monolith size ceilings to prevent file inflation.

---

## 2. AUTOMATED RULES MATRIX

| Rule ID | Name | Target Scope | Enforcement Logic | Failure Consequence |
|---|---|---|---|---|
| **RULE-FL-01** | Isar Isolation in Presentation | Extracted screens & widgets | Rejects direct `isar_collections.dart` imports | Build & Test Failure |
| **RULE-FL-02** | Dio Client Presentation Decoupling | Restructured Monolith Screens | Prohibits `dio_client.dart` or `package:dio/dio.dart` | Build & Test Failure |
| **RULE-FL-03** | Pure BLoC Logic Separation | `lib/features/*/bloc/` | Prohibits `extends StatelessWidget` or `StatefulWidget` in BLoCs | Build & Test Failure |
| **RULE-FL-04** | Monolith Size Ceiling | `lead_allocation_monitor_bloc.dart` | Maximum line count < 350 lines (currently 248 lines) | Build & Test Failure |
| **RULE-FL-05** | Requirements Domain Decoupling | `features/requirements/` | Verifies existence of Use Cases & extracted widgets | Build & Test Failure |
| **RULE-FL-06** | Campaign Domain Decoupling | `features/campaign/` | Verifies existence of Use Cases & extracted dialogs | Build & Test Failure |
| **RULE-FL-07** | Screen Decoupling Verification | `features/admin/` | Verifies `LeadAllocationMonitorScreen` extracted to `screens/` | Build & Test Failure |

---

## 3. RULE IMPLEMENTATION SPECIFICATION

### 3.1 RULE-FL-01: Isar Isolation
```dart
test('Extracted presentation widgets and use-cases do NOT import isar_collections.dart directly', () {
  final extractedFiles = [
    'lib/features/requirements/widgets/requirement_summary_bar.dart',
    'lib/features/requirements/widgets/requirement_filter_bar.dart',
    'lib/features/requirements/widgets/requirement_action_dialogs.dart',
    'lib/features/campaign/widgets/campaign_column_settings_dialog.dart',
    'lib/features/campaign/widgets/lead_reclassify_dialog.dart',
    'lib/features/admin/screens/lead_allocation_monitor_screen.dart',
    'lib/features/requirements/domain/usecases/load_requirements_usecase.dart',
    'lib/features/requirements/domain/usecases/update_requirement_status_usecase.dart',
    'lib/features/campaign/domain/usecases/reclassify_campaign_lead_usecase.dart',
  ];
  // Validates 0 direct references to isar_collections.dart
});
```

### 3.2 RULE-FL-02: Dio Client Decoupling
```dart
test('Primary restructured screens do NOT import dio_client.dart directly', () {
  final targetedScreens = [
    'lib/features/requirements/screens/requirements_screen.dart',
    'lib/features/campaign/screens/campaign_leads_screen.dart',
    'lib/features/admin/screens/lead_allocation_monitor_screen.dart',
  ];
  // Validates 0 direct imports of dio_client.dart or package:dio/dio.dart
});
```
*Note: In `requirements_screen.dart`, all 17 direct Dio calls were migrated to `RequirementsRepository` and `RequirementsService` delegation methods.*

### 3.3 RULE-FL-03: Pure BLoC Separation
```dart
test('BLoC files do NOT declare Widget subclasses (StatelessWidget/StatefulWidget)', () {
  for (final file in blocFiles) {
    expect(file.contains('extends StatelessWidget'), isFalse);
    expect(file.contains('extends StatefulWidget'), isFalse);
  }
});
```
*Ensures that UI classes (such as the 2,050 line widget formerly in `lead_allocation_monitor_bloc.dart`) are never hosted inside BLoC files.*

### 3.4 RULE-FL-04: Line Count Ceilings
```dart
test('Lead Allocation Monitor BLoC size ceiling (< 350 lines)', () {
  final lineCount = blocFile.readAsLinesSync().length;
  expect(lineCount, lessThan(350));
});
```

---

## 4. VERIFICATION COMMANDS

To execute the architecture suite independently:
```powershell
flutter test test/core/flutter_architecture_rules_test.dart
```

To execute the complete regression suite:
```powershell
flutter test test/core/flutter_architecture_rules_test.dart test/campaign/ test/requirements/ test/bloc/
```

Expected result:
```text
00:00 +7: All tests passed!
```
