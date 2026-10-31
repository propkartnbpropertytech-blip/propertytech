# AI AGENT IMPLEMENTATION REPORT

## 1. Task Summary
- **Task Title**: AI Search in the AppShell
- **Date & Timestamp**: 2026-10-31T11:24:00+05:30
- **Agent Role**: Full-stack architect
- **Final Status**: PARTIAL (feature tests pass; full Flutter suite still has 17 pre-existing failures)

## 2. File Change Audit
### Files Modified
- `C:\NB\propkart\lib\core\design_system\widgets\app_shell.dart` — debounced AI search, panel, stale cache
- `C:\NB\propkart\lib\features\shell\widgets\top_bar.dart` — AI Search field and compact button
- `C:\NB\propkart\lib\features\shell\mobile\mobile_app_shell.dart` — compact tooltip “AI Search”
- `C:\NB\propkart\lib\core\design_system\mobile\mobile_top_bar.dart` — placeholder and sparkle
- `C:\NB\propkart\lib\features\owners\screens\owners_screen.dart` — open from a search result
- `C:\NB\propkart\lib\features\clients\screens\clients_screen.dart` — open from a search result
- `C:\NB\propkart\lib\core\navigation\app_router.dart` — pass `search` into clients and owners
- `C:\NB\PropKart-Backend\src\modules\search\search.repository.js` — filters before pagination
- `C:\NB\PropKart-Backend\src\modules\search\search.service.js` — interpret, search, safe telemetry
- `C:\NB\PropKart-Backend\src\modules\search\search.controller.js` — `POST /search/ai`
- `C:\NB\PropKart-Backend\src\modules\search\search.routes.js` — same permission as keyword search
- `C:\NB\PropKart-Backend\src\services\audit.service.js` — keep a precomputed query length when no raw text is stored
- `C:\NB\PropKart-Backend\.env.example` — optional provider settings
- `C:\NB\PropKart-Backend\package.json` — register `test/ai.search.test.js`

### Files Created
- `C:\NB\PropKart-Backend\src\modules\search\aiSearchIntent.js`
- `C:\NB\PropKart-Backend\src\modules\search\aiProvider.js`
- `C:\NB\PropKart-Backend\src\modules\search\aiSearchFilters.js`
- `C:\NB\PropKart-Backend\test\ai.search.test.js`
- `C:\NB\propkart\lib\features\search\ai_search_session.dart`
- `C:\NB\propkart\lib\features\search\services\ai_search_service.dart`
- `C:\NB\propkart\lib\features\search\widgets\ai_search_field.dart`
- `C:\NB\propkart\lib\features\search\widgets\ai_search_panel.dart`
- `C:\NB\propkart\test\search\ai_search_test.dart`
- `C:\NB\propkart\docs\ai-agent\ai-search-CHANGE-PLAN.md`

### Files Strictly NOT Changed
- `canonicalKpi.repository.js`, `*.g.dart`, historical migrations, `src/config/env.js`, builders, and the allocation engine.

## 3. Architecture & Invariants Verification
- **Multi-Tenant Isolation**: Search still uses `organizationScope(req.user)`. `organization_id` from a model or request body is rejected and is not a SQL parameter.
- **Layer Purity**: The panel does not import Dio. The controller does not import the pool. The provider adapter is server-only.
- **Authoritative Persistence**: Rows come from the existing PostgreSQL search. The model may return only an allowlisted intent.
- **Provider**: No approved provider was configured. Missing `AI_SEARCH_PROVIDER`, `AI_SEARCH_API_KEY`, `AI_SEARCH_BASE_URL`, or `AI_SEARCH_MODEL` keeps the built-in parser. A timeout, HTTP 429, or malformed JSON falls back to that parser. The request body is the query plus the schema, never CRM rows.
- **Privacy**: Search telemetry stores `query_length`, `token_count`, `filter_count`, `result_count`, and `source`. Raw query text is not written.
- **Cache**: The shell keeps the last successful grouped result and marks it stale when a later request fails. No new Redis cache.
- **Motion**: The control has no pulse. Reduced-motion users get the same static treatment.

## 4. Empirical Test Verification Matrix

| Test Suite | Scope | Total Tests | Passed | Failed | Skipped | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Targeted backend** | `test/ai.search.test.js` | 9 | 9 | 0 | 0 | PASS |
| **Targeted Flutter** | `test/search/ai_search_test.dart` and `test/search_filter_contract_test.dart` | 8 | 8 | 0 | 0 | PASS |
| **Backend guardrails** | AI-agent, architecture contract, architecture rules, security hardening | 31 | 31 | 0 | 0 | PASS |
| **Backend regression** | `npm test` | 334 | 334 | 0 | 0 | PASS |
| **Flutter regression** | `flutter test --reporter compact` | 983 | 966 | 17 | 0 | FAIL, pre-existing |
| **Static analysis** | `flutter analyze --no-fatal-infos` | 1035 issues | 0 errors | 204 warnings | 831 infos | exit 1, warnings already fatal |

The 17 Flutter failures are the same screens as the previous baseline: Super Admin dashboard overview, mobile shell shift gate, sales and admin requirements/properties layouts, settings, lead allocation, telecaller calling queue, and the login timer. `ai_search_test.dart` and `search_filter_contract_test.dart` are not in that list. `test/core/ai_agent_safety_test.dart` ran inside the full Flutter suite and did not fail.

## 5. Latency
Five repeats on the local Admin tenant, no provider call:

- Keyword `gota`: 24 properties, samples 32.2, 32.4, 32.4, 32.5, 68.1 ms, median 32.4 ms.
- AI sentence `available property in gota`: 11 properties, samples 17.4, 19.4, 19.9, 20.8, 73.3 ms, median 19.9 ms.

These are different queries. The second also requires status Available, which is why it returns 11 instead of 24. No speedup is claimed.

## 6. Stop Condition & Final Certification
- [x] AppShell shows AI Search and opens the panel, including the compact control.
- [x] Natural-language intents are allowlisted. A model cannot set the tenant or SQL.
- [x] Keyword search still runs when the provider is absent or fails.
- [ ] Full Flutter regression is not 0 failures. The 17 failures above are outside this diff.
- [x] Execution stopped at the task boundary.

## 7. Follow-up: one shape, a close control, and interpreted recovery
The live panel mixed a pill field (radius 24) with a 12px card, and the shell wrapped that card in a second surface. The field and the suggestions panel now both use `CRMBorderRadius.input` (12). The shell no longer adds a second Material around the panel. The panel header has a Close button that hides the overlay and drops focus, so the suggestions do not stay open. Filter chips use the same close icon and remain removable.

The empty result in the screenshot was the keyword fallback. `POST /search/ai` had failed, and `GET /search` then required every leftover word (`under`, `rentals`, `35000`) to match the row, so the Satellite 2 BHK rent was hidden and the “keyword matches” banner was shown. `GET /search?interpret=1` now runs the same interpreter as `POST /search/ai`. The client uses that call when the POST fails, and it no longer replaces a failed interpretation with a raw-token search. A successful interpretation does not show the keyword banner. If both calls fail, the panel shows the error or offline state and keeps the last saved result.

Checked after this change: the new backend case “interprets a natural language query through the normal search call” passed, and `flutter test test/search/ai_search_test.dart` passed (3 tests). The full suites from section 4 were not run again.
