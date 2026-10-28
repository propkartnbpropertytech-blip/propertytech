# 17 — AI VERIFICATION PROTOCOL & QUALITY GATES

## 1. Multi-Tier Verification Gates
Before presenting any task as complete, an AI coding agent must advance through five strict verification gates:

```text
[ Code Modification ]
          │
          ▼
Gate 1: Targeted Local Tests (Pass 100%)
          │
          ▼
Gate 2: Architecture Guardrails (Pass 100%)
          │
          ▼
Gate 3: Static Code Analysis (0 Errors)
          │
          ▼
Gate 4: Platform Regression Baseline (100% Pass, 0 Failures)
          │
          ▼
Gate 5: Git Diff Inspection (Zero Forbidden Files Changed)
          │
          ▼
[ Certified Completion ]
```

## 2. Gate Verification Checklist
- **Gate 1 (Targeted Tests):**
  - Execute specific test file covering the modified module.
- **Gate 2 (Architecture Guardrails):**
  - Run `node --import ./test/setup-env.js --test test/ai_agent.guardrails.test.js`.
  - Run `flutter test test/core/ai_agent_safety_test.dart`.
- **Gate 3 (Static Analysis):**
  - Run `flutter analyze --no-fatal-infos` in `c:/NB/propkart`.
  - Must report 0 errors.
- **Gate 4 (Regression Baseline):**
  - Backend baseline: 239/239 PASS.
  - Flutter baseline: 952/952 PASS.
  - Combined baseline: 1,191/1,191 PASS.
- **Gate 5 (Diff Inspection):**
  - Execute `git status` and `git diff --stat`.
  - Confirm zero modifications to generated files (`*.g.dart`), historical migrations, or unapproved files.
