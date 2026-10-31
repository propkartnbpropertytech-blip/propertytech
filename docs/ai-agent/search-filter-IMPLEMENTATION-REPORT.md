# AI AGENT IMPLEMENTATION REPORT

## 1. Task Summary
- **Task Title**: Search, follow-up filters, and persistent builders
- **Date & Timestamp**: 2026-10-30T18:50:00+05:30
- **Agent Role**: Full-stack engineer
- **Final Status**: COMPLETE for the requested search and filter behavior. Full Flutter regression still has unrelated widget failures.

## 2. File Change Audit
### Files Modified
- Backend property, global search, follow-up, builder, owner, client, and user list paths
- `src/services/audit.service.js` and `src/config/permissions.js`
- `src/config/ensureAdditiveSchema.js` and `package.json`
- Flutter property, directory, follow-up, telemetry, and header search paths

### Files Created
- `sql/migrations/93_persistent_builders.sql`
- `src/modules/followups/followupWindow.js`
- Flutter `SearchRequestGate`, directory field matchers, property server-query helper, and global results screen
- `test/search.filter.contract.test.js`
- `test/search_filter_contract_test.dart`
- `docs/ai-agent/search-filter-CHANGE-PLAN.md`

### Files Strictly NOT Changed
- Canonical KPI SQL, generated `*.g.dart`, historical migrations through 92, and `src/config/env.js`.

## 3. Architecture & Invariants Verification
- **Multi-Tenant Isolation**: Builder reads and writes use the caller organization. A builder id from another organization returns null. The client cannot supply `organization_id`.
- **Authoritative Persistence**: Builders are rows in `public.builders`. A new repository call reads the same row. PostgreSQL remains the search store. No search service was added.
- **Permissions**: `builders.read` stays on the common set, so Sales can read and Telecaller cannot. `builders.create`, `builders.update`, and `builders.delete` are admin extras. Routes call `requirePermission`.
- **Follow-up windows**: The Flutter chips use the same pending and calendar-day rules as `FollowupSyncEngine`. The API uses `Asia/Kolkata` for the calendar day because the server process is not the device clock. Canonical KPI SQL was not changed.
- **Telemetry**: Search audit rows keep module, result count, query length, and token count. The raw query is not stored.
- **Search ranking**: Exact phone tails and exact tokens add a rank of 3 before the existing prefix and trigram score. The trigram operator and GIN indexes were not changed.

## 4. Empirical Test Verification Matrix

| Test Suite | Scope | Total Tests | Passed | Failed | Skipped | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Targeted backend** | `test/search.filter.contract.test.js` | 8 | 8 | 0 | 0 | PASS |
| **Targeted Flutter** | `test/search_filter_contract_test.dart` | 5 | 5 | 0 | 0 | PASS |
| **Architecture and security** | architecture, RBAC, permissions, security hardening | 45 | 45 | 0 | 0 | PASS |
| **Backend regression** | `npm test` | 324 | 324 | 0 | 0 | PASS |
| **Flutter regression** | `flutter test --reporter compact` | 980 | 963 | 17 | 0 | FAIL, unrelated widget tests |

The 17 Flutter failures are mobile shell, requirements, properties, settings, telecaller, Super Admin dashboard, and login-screen tests. Their assertions are missing widgets or a pending timer. None is `search_filter_contract_test.dart`. The dedicated file passed 5/5 when run directly. The compact full-suite log did not print that filename.

## 5. Static Code Analysis & Linting
- **Command**: `flutter analyze --no-fatal-infos`
- **Result**: 1037 issues, exit code 1. 0 error diagnostics, 206 warnings, 831 infos. Warnings still fail the command. They are existing unused fields, dead code, and deprecations, not new error diagnostics.
- Backend `node --check` on the edited search, property, builder, follow-up, owner, user, and audit modules exited 0.

## 6. Measured Search Behavior
- Environment: local PostgreSQL from `.env.local`.
- Dataset at measurement time: 201 `public.properties` rows.
- Query: `search_document ILIKE '%west%' OR word_similarity('westt', search_document) >= 0.4`, `LIMIT 20`.
- Plan: sequential scan. `EXPLAIN ANALYZE` execution time 5.532 ms. Planning time 0.383 ms. 2 rows returned, 199 removed by the filter.
- Twenty repeats of the same query: P50 6.98 ms, P95 10.57 ms.
- No before-change sample was stored in this session, so this is not a speed improvement. The existing trigram index was left in place because this dataset is still faster as a sequential scan and changing the operator was not justified.

## 7. Design Decisions
- Property text search and structured filters share one parameterized `WHERE`, then `LIMIT`/`OFFSET`. The response keeps `properties` and adds `items`, `page_size`, `total`, and `total_pages`.
- A failed property server search clears the server page, keeps the cached list, and shows a stale message. It does not replace the cache with an empty list.
- Global search still returns a short suggestion list. `category` and `page` return one paged category plus totals for properties, requirements, owners, clients, and leads under the same role scope. `/search/results` is the paged view.
- Ordinary client, owner, and builder searches are capped at 50. User-list search defaults to 50 and accepts at most 200. The user tree asks for 200.
- Due today, Overdue, and Next 7 days are list chips. They can be cleared and show counts. They do not replace the existing Today, Due, and Future tabs when no chip is selected.
- The three builders already stored without `organization_id` stay unassigned. Tenant queries do not show them. They were not attached to an invented organization.

## 8. Remaining Risks
- The property screen requests one server page of 50 after filters. It does not yet ask the API for page 2, so a filtered set larger than 50 is not walked in the list UI. The API total is correct.
- Local property filters still run on the returned page. Furnishing matching in the app is stricter than the SQL `LIKE`.
- Follow-up chips use the device calendar. The follow-up API uses `Asia/Kolkata`. A device that is not set to IST can disagree with the API. KPI calculations were not changed to hide that difference.
- Header suggestions remain capped. The paged results screen is a separate route.
- Existing unassigned builder rows are visible to Super Admin and hidden from tenants.

## 9. Stop Condition
- [x] Requested search, filter, builder, and telemetry behavior is implemented.
- [x] Targeted acceptance tests passed.
- [x] Backend `npm test` passed 324/324.
- [ ] Full Flutter suite is not zero failures. The 17 failures are outside the new contract file.
- [x] Execution stopped at the task boundary.
