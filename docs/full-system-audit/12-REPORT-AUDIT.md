# 12 — Report Audit

| Report | Finding | Status |
| :--- | :--- | :--- |
| KPI dashboard | Backed by the canonical repository | NOT TESTABLE |
| Sales report screen | Placeholder UI | FAIL |
| Property report screen | Coming-soon UI | FAIL |
| Telecaller report | Code exists | NOT TESTABLE |
| Live Excel / Google Sheet | Auth and organization scope fixed and unit-tested. File bytes were not downloaded | PARTIAL |
| PDF property share | Image fetch is gated by the share config | NOT TESTABLE |

Report routes that only call `authenticate` can be called by any signed-in role even when the drawer hides the screen. That was read from the route table and not called live.

Filters, timezone, totals, empty files, and large files were not checked.
