# 01 — Match engine remediation

## Cause

`MatchingService` scored a price within 15 percent as 20 and within 25 percent as 10. `PropertyRequirementMatcher` used 20 percent and 35 percent, and awarded 20 points when the requirement had no maximum. The settings screen described the Flutter bands.

## Fix

`src/modules/matching/canonicalBudgetScore.js` is the only band function. The service calls `scoreBudget`. Flutter `CanonicalBudgetScore.evaluate` uses the same boundaries, and the requirements screen calls it. The settings copy now says ±15% and ±25%. A missing maximum scores 0.

`clampMatchThreshold` and `assertMatchThreshold` are the threshold rules. Reads clamp into 10–100, with 60 when the stored value is not a number. Writes from 0, 1, or a non-number are rejected. Admin, Super Admin, and Broker may save the threshold.

## Tests

`test/match-engine/canonicalBudgetScore.test.js`: 17 passed.
`test/canonical_budget_score_test.dart`: 11 passed.

Location, BHK, and property-type scoring are still implemented in both layers. This fix covers the budget defect the audit named. It does not make every other match category a shared module.
