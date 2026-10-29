# 20 — Root Cause Register

## BUG-001

Why it happened: the sheet connector was built to work before an environment token existed, so a constant was the default.

Why it was possible: the feed treats a missing organization as "all rows", and token auth set organization to null.

Why it was not caught: tests covered JWT login, not this token fallback. The guide published the same constant.

Boundary that failed: authentication and tenant scope on an export that does not use the normal user middleware.

What prevents recurrence: no default token, no default JWT secret, organization required, unit tests for the old token, a forged secret, a missing org, and an org mismatch.

## BUG-002

The match rule was implemented twice, once in SQL-backed Node and once in Dart, and the budget bands were not taken from one module.

## BUG-003 and BUG-004

Reports were gated in the widget tree. The route layer only checks that a session exists. Two screens were left as placeholders.

## BUG-005

Broker was added in the product UI and the control seed, and not added to the API permission map.

## BUG-006

`SKIP LOCKED` protects the lead. Capacity is a count of other leads, not a lock on the person.

## BUG-010

Two features shipped SQL files with the same number. Startup order follows the additive list, not the number alone. 82 replaces `fn_sync_leads_to_requirements` and leaves the 81 preserve trigger in place. Both have not been proven together on the local database.
