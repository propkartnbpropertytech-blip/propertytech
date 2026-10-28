# 21 — AI AGENT SELF-TESTING & EXECUTION GUIDE

## 1. How AI Agents Execute Tests

### A. Backend Node.js Environment (`C:/NB/PropKart-Backend`)
- **Fast Single Test File Execution:**
  ```powershell
  Set-Location "C:\NB\PropKart-Backend"
  node --import ./test/setup-env.js --test test/your_target.test.js
  ```
- **Run with Force Exit (Prevents dangling timers):**
  ```powershell
  node --import ./test/setup-env.js --test --test-force-exit test/your_target.test.js
  ```
- **Primary Full Suite (239 tests):**
  ```powershell
  npm test
  ```
- **AI Agent Guardrails Test:**
  ```powershell
  node --import ./test/setup-env.js --test test/ai_agent.guardrails.test.js
  ```

### B. Flutter Client Environment (`c:/NB/propkart`)
- **Fast Single Test File Execution:**
  ```powershell
  Set-Location "c:\NB\propkart"
  flutter test test/core/your_target_test.dart
  ```
- **Run AI Agent Safety Suite:**
  ```powershell
  flutter test test/core/ai_agent_safety_test.dart
  ```
- **Run Full Regression Suite (952 tests):**
  ```powershell
  flutter test
  ```
- **Run Static Analysis (Must be 0 errors):**
  ```powershell
  flutter analyze --no-fatal-infos
  ```

## 2. Test Failure Triage Protocol
When a test fails:
1. Read the exact failure message, expected value, and actual value.
2. Inspect the stack trace to determine which function threw the assertion.
3. Check if the database was left in an unexpected state.
4. Modify the implementation code to fix the root cause.
5. Re-run the test to confirm it passes cleanly.
