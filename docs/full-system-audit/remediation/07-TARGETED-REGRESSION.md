# 07 — Targeted regression

| Suite | Result |
| :--- | :--- |
| Canonical budget score (Node) | 17 passed |
| Canonical budget score (Flutter) | 11 passed |
| Report organization and `reports.read` | passed |
| Broker permission set | passed |
| Telecaller and sales isolation | passed |
| Sheet sync auth | 5 passed |
| Telecaller row lock | passed, including a live lock timeout |
| Requirement status after migrations 81 and 82 | passed, rolled back |

These runs used `node --import ./test/setup-env.js --test` and `flutter test test/canonical_budget_score_test.dart`.
