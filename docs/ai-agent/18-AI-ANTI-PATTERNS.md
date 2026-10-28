# 18 — AI CODING ANTI-PATTERNS CATALOG

## 1. Catalog of Prohibited AI Anti-Patterns

| # | Anti-Pattern | Description | Correct Alternative |
| :--- | :--- | :--- | :--- |
| **1** | **Blind Grep-and-Replace** | Mass replacing strings across files without understanding context. | Read context, trace dependencies, apply targeted edits. |
| **2** | **Opportunistic Refactoring** | Rewriting clean, working adjacent code ("while I'm here"). | Strictly limit changes to the declared scope. |
| **3** | **Duplicate Service Creation** | Authoring a new service when an authoritative service exists. | Inspect existing modules; extend existing service. |
| **4** | **Duplicate KPI Calculation** | Computing KPI metrics in UI or ad-hoc SQL. | Query `CanonicalKpiRepository` exclusively. |
| **5** | **Direct Database from UI** | Calling database or network drivers directly from widgets. | Dispatch BLoC events; delegate through domain use cases. |
| **6** | **Manual Edits to Generated Code**| Editing `isar_collections.g.dart` directly. | Modify source schema and run `build_runner`. |
| **7** | **Hardcoded Tenant IDs** | Using hardcoded UUIDs for `organization_id`. | Extract from verified JWT token context. |
| **8** | **Hardcoded Secrets / Tokens** | Placing API keys or passwords in source code. | Inject via environment variables (`process.env`). |
| **9** | **Silent Exception Swallowing** | Using empty `catch (_) {}` blocks that hide errors. | Log sanitized error with correlation ID. |
| **10**| **Test Assertion Weakening** | Changing `assert.equal(a, 10)` to `assert.ok(true)`. | Fix root cause of regression; never weaken tests. |
| **11**| **Deleting Tests to Pass CI** | Deleting failing test files instead of resolving bugs. | Strictly forbidden; failing tests indicate real bugs. |
| **12**| **Fake Mocks Hiding Bugs** | Mocking entire repositories to bypass integration checks. | Use real test harness and isolated database transactions. |
| **13**| **Ad-Hoc API Envelopes** | Returning raw arrays or unstandardized JSON payloads. | Always return standard `{ success, data, error, meta }`. |
| **14**| **Destructive SQL Migrations** | Running `DROP TABLE` or `DROP COLUMN` in production. | Write purely additive migrations with default values. |
| **15**| **Bypassing Stop Conditions** | Proceeding to next step without user instruction. | Halt immediately upon task completion. |
