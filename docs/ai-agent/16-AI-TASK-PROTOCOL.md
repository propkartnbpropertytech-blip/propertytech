# 16 — AI TASK LIFECYCLE & EXECUTION PROTOCOL

## 1. The 8-Stage Mandatory Lifecycle
Every coding agent operating on PropKart must follow this lifecycle sequentially:

```text
1. DISCOVER ──> 2. UNDERSTAND ──> 3. PLAN ──> 4. IMPLEMENT ──> 5. TEST ──> 6. VERIFY ──> 7. REPORT ──> 8. STOP
```

### Stage 1: DISCOVER
- Inspect repository structure and identify target feature modules.
- Read `AGENTS.md` and `docs/ai-agent/project-manifest.json`.

### Stage 2: UNDERSTAND
- Identify existing contracts, schemas, and layer responsibilities.
- Locate the authoritative data source and existing test files.

### Stage 3: PLAN
- Complete a structured change plan using `templates/CHANGE-PLAN.md`.
- Declare files allowed to change and files strictly forbidden to touch.

### Stage 4: IMPLEMENT
- Apply the Minimum Correct Change.
- Maintain existing comments, formatting, and docstrings.
- Never perform unrelated refactoring.

### Stage 5: TEST
- Execute the targeted unit test suite for the modified code immediately.
- Fix any local errors or assertions before proceeding.

### Stage 6: VERIFY
- Run full platform regression suites (`npm test` and `flutter test`).
- Run static analysis (`flutter analyze --no-fatal-infos`).
- Verify zero regressions.

### Stage 7: REPORT
- Produce an implementation report using `templates/IMPLEMENTATION-REPORT.md`.
- Detail exact measured test counts and evidence.

### Stage 8: STOP
- Halt execution cleanly. Do not proceed to unprompted subsequent phases.
