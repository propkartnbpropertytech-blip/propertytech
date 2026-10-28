# 12 — Flaky Test Policy & Zero-Tolerance Protocol

## 1. Definition & Objectives

A **flaky test** is any automated test that produces inconsistent outcomes (passing in one run, failing in another) without any modification to the underlying production code or test logic.

Flaky tests erode engineer trust in continuous integration, mask real regression defects, and delay production releases. PropKart enforces a **Zero-Tolerance Policy** against test flakiness.

---

## 2. Common Root Causes & Prevention Guidelines

### 2.1 Arbitrary Delays vs. Event-Driven Pumping
- **Forbidden:** Using arbitrary sleep functions (`await new Promise(r => setTimeout(r, 500))` or `await Future.delayed(Duration(milliseconds: 500))`).
- **Standard:** Use event-driven await patterns or Flutter's explicit pump cycle:
  - `await tester.pumpAndSettle()` for animations and microtasks.
  - If a widget contains an infinite animation (e.g. continuous shimmer or pulsing spinner), pump explicitly with a finite duration:
    ```dart
    await tester.pump(const Duration(milliseconds: 300));
    ```

### 2.2 Parallel CPU Contention in Microbenchmarks
- High-concurrency test runners can throttle CPU execution times, causing microsecond-level benchmarks to fail intermittently.
- **Guideline:** Set realistic upper bounds for benchmark assertions (e.g., `< 35ms` for 1,000 items, `< 120ms` for 5,000 items) that account for low-tier CI runner environments.

### 2.3 Network & External Dependencies
- Tests must never access live internet services, external CDNs, or real third-party endpoints.
- Flutter runtime font fetching must remain disabled:
  ```dart
  GoogleFonts.config.allowRuntimeFetching = false;
  ```

### 2.4 OS Platform & Typography Rendering Discrepancies
- Text measurement and line-wrapping can differ between macOS, Linux, and Windows test runners.
- **Guideline:** Use deterministic platform variants in Flutter widget suites:
  ```dart
  TargetPlatformVariant.only(TargetPlatform.iOS);
  ```

---

## 3. The PropKart Flaky Test Protocol

If a test fails intermittently in CI or local full-suite execution, the following 4-step protocol is immediately triggered:

```
  ┌─────────────────┐
  │ 1. Identification│ ──► Detected via CI retry failure or intermittent run
  └────────┬────────┘
           ▼
  ┌─────────────────┐
  │ 2. Quarantine   │ ──► Moved to .quarantine suite; issue logged with HIGH priority
  └────────┬────────┘
           ▼
  ┌─────────────────┐
  │ 3. RCA & Fix    │ ──► Root Cause Analysis diagnosed; 24-hour SLA to submit fix
  └────────┬────────┘
           ▼
  ┌─────────────────┐
  │ 4. Reintegration│ ──► Run 100 consecutive executions without a single failure
  └─────────────────┘
```

### 3.1 Strict Quarantine Invariants:
1. **Never Skip Silently:** Disabling a test by commenting it out, deleting it, or marking `test.skip` without an associated Jira/GitHub tracking ticket is strictly forbidden.
2. **24-Hour SLA:** Quarantined tests must be resolved within 24 hours. If unresolved, the underlying code feature must be reviewed for potential architectural race conditions.
3. **Verification Criterion:** Before a quarantined test is restored to the primary suite, it must run **100 consecutive times** in CI without a single failure:
   ```bash
   for i in {1..100}; do npm test -- test/path/to/test.js || break; done
   ```
