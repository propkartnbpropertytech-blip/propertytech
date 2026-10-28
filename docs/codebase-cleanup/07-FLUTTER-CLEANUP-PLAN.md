# 07-FLUTTER-CLEANUP-PLAN.md — PropKart Flutter Client Cleanup Execution Plan

## 1. Scope & Governance
- **Repository**: `c:/NB/propkart`
- **Guiding Law**: Zero-Behavior-Change.
- **Invariants**:
  - Isar presentation database remains local-first UI cache.
  - Durable outbox and 10-state offline sync engine remain untouched.
  - Phoenix realtime channels remain intact.
  - Codegen artifact `lib/core/storage/isar_collections.g.dart` remains strictly frozen.
  - Presentation purity guardrails (no Dio in screens, no Isar in modular widgets) remain enforced.
  - All 958 verified Flutter tests must remain 100% PASS.

---

## 2. Planned Operations

### Batch F1: Temporary Build Log Pruning
1. Delete `c:/NB/propkart/analyze_errors.txt` (Confidence 4)
2. Delete `c:/NB/propkart/flutter_01.log` (Confidence 4)

### Batch F2: Automated Dead Import Pruning
1. Apply Dart SDK automated unused import remediation:
   `dart fix --apply --code=unused_import` (Prunes 59 unreferenced import directives)
2. Apply Dart SDK automated unnecessary duplicate import remediation:
   `dart fix --apply --code=unnecessary_import` (Prunes 12 redundant duplicate imports)

### Batch F3: Automated Safe Formatting & Micro-Cleanups
1. Clean dangling doc comments:
   `dart fix --apply --code=dangling_library_doc_comments`
2. Clean unnecessary string interpolation braces:
   `dart fix --apply --code=unnecessary_brace_in_string_interps`
3. Clean unnecessary list spread copies:
   `dart fix --apply --code=unnecessary_to_list_in_spreads`

### Batch F4: Architectural Preservation
1. Preserve all BLoC classes, states, and events.
2. Preserve all Isar collection models and repository interfaces.
3. Preserve all CRM design system tokens and modular widgets.

---

## 3. Post-Cleanup Verification Sequence
1. Run Flutter AI Safety Test:
   `flutter test test/core/ai_agent_safety_test.dart`
2. Run Flutter Static Analysis:
   `flutter analyze --no-fatal-infos --no-fatal-warnings`
3. Run Full Flutter Test Suite:
   `flutter test` (Expect 958/958 PASS)
