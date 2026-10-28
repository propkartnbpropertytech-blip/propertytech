# 09-EXECUTION-BATCHES.md — Step 15 Incremental Execution Batches

## 1. Phased Execution Architecture
To guarantee immediate regression detection and prevent multi-variable debugging, cleanup operations are executed in discrete, verifiable batches:

```text
BATCH 1: Backend Scratch Pruning
   ↓ (Verify: File system state)
BATCH 2: Flutter Temp Dump Pruning
   ↓ (Verify: File system state)
BATCH 3: Flutter Unused Import Remediation
   ↓ (Verify: flutter analyze)
BATCH 4: Flutter Unnecessary Import Remediation
   ↓ (Verify: flutter analyze)
BATCH 5: Flutter Safe Lint Micro-Cleanups
   ↓ (Verify: flutter analyze)
BATCH 6: Comprehensive Regression & Certification Run
   ↓ (Verify: 239 Backend Tests + 958 Flutter Tests + 13 AI Safety Tests)
```

---

## 2. Batch Details & Verification Gates

### Batch 1: Backend Scratch Pruning
- **Actions**: Remove `scratch_check_ids.py`, `scratch_fetch_health.py`, `scratch_health.html`.
- **Target Files**: 3
- **Verification Gate**: `node --import ./test/setup-env.js --test test/ai_agent.guardrails.test.js`

### Batch 2: Flutter Temp Dump Pruning
- **Actions**: Remove `analyze_errors.txt`, `flutter_01.log`.
- **Target Files**: 2
- **Verification Gate**: `git status` check in `c:/NB/propkart`

### Batch 3: Flutter Unused Import Remediation
- **Actions**: Execute `dart fix --apply --code=unused_import`
- **Target Files**: ~40 files in `lib/` and `test/`
- **Expected Fixes**: 59 unused imports removed
- **Verification Gate**: `flutter analyze --no-fatal-infos --no-fatal-warnings`

### Batch 4: Flutter Unnecessary Import Remediation
- **Actions**: Execute `dart fix --apply --code=unnecessary_import`
- **Target Files**: ~12 files in `lib/`
- **Expected Fixes**: 12 duplicate imports removed
- **Verification Gate**: `flutter analyze --no-fatal-infos --no-fatal-warnings`

### Batch 5: Flutter Safe Lint Micro-Cleanups
- **Actions**:
  - `dart fix --apply --code=dangling_library_doc_comments`
  - `dart fix --apply --code=unnecessary_brace_in_string_interps`
  - `dart fix --apply --code=unnecessary_to_list_in_spreads`
- **Verification Gate**: `flutter analyze --no-fatal-infos --no-fatal-warnings`

### Batch 6: Ecosystem Regression & Certification
- **Backend Tests**: `npm test` in `C:/NB/PropKart-Backend` (239 tests)
- **Flutter Tests**: `flutter test` in `c:/NB/propkart` (958 tests)
- **AI Safety Tests**: Both backend and frontend guardrails (13 tests)
- **Certification Gate**: Zero failures, zero skips, 100% pass rate.
