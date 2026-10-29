# 21 — Permanent Fix Register

| ID | Fix | Layer | Test | Live retest |
| :--- | :--- | :--- | :--- | :--- |
| BUG-001 | Remove the built-in sync token and the JWT fallback secret. Require one organization on feed, user list, and Excel. Ignore a query organization that disagrees with the JWT. Replace the published token in the guide and connector with placeholders | `src/modules/sync/sync.controller.js` | `test/sync.auth.scope.test.js`, 5 passed | Excel file not downloaded. API process not restarted in this step |
| Requirement status (previous cycle) | Snapshot plus AFTER preserve trigger, repository reassert, Flutter resolve of Assigned versus a chosen pipeline status | Migration 81, requirements repository and service, Flutter requirement model | `test/requirement.status.persistence.test.js` passed before `b0393a5`. Local SQL proof, rolled back | User confirmed the local UI. Not repeated in this audit |

No other bug in the register was changed. Changing them without a failing test and a traced write would be a patch.

## Operational follow-up for BUG-001

Set a new `SHEET_SYNC_TOKEN` on the local API and on production. Put that value and the organization UUID into the Google Sheet script. The old token must be treated as public.
