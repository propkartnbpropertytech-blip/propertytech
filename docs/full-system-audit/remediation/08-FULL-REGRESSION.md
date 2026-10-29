# 08 — Full regression

`npm test` after the remediation:

```text
tests 273
pass 272
fail 1
```

The failure is the same Windows libuv crash in `test/rbac.team.isolation.test.js` seen at baseline. The cases inside that file passed before the runner closed its handles. No new assertion failure was reported.

`npm run test:coverage` and `npm run lint` are not defined. There is no ESLint config.

Flutter `flutter test test/canonical_budget_score_test.dart`: 11 passed.

The full `flutter test` suite was not re-run. Baseline `flutter analyze --no-fatal-infos` reported 1043 issues and no analyzer errors. A second analyze of the changed Dart files was started after the edits.
