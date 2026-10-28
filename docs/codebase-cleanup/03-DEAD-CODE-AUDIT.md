# 03-DEAD-CODE-AUDIT.md — PropKart Dead-Code Forensic Audit

## 1. Audit Methodology & Confidence Model
Every candidate artifact across the PropKart ecosystem is classified according to the strict 5-tier Confidence Model:

- **Confidence 4 (Proven Dead)**: Verified 0 internal and external references across all files, tests, scripts, and configurations; zero runtime/dynamic invocation; zero reflection/string discovery; zero export requirement. Safe for deletion.
- **Confidence 3 (Probably Dead)**: 0 direct static references found, but potentially referenced via dynamic string formatting, legacy documentation, or diagnostic inspection. **Action: Retain and document in register without deletion.**
- **Confidence 2 (Suspicious)**: Low usage or single-site reference with unclear external lifecycle. **Action: Retain untouched.**
- **Confidence 1 (Doubtful)**: Appears unused on surface, but resides in sensitive synchronization, KPI, auth, or database transaction boundaries. **Action: Strictly retain untouched.**
- **Confidence 0 (Authoritative / Active Invariant)**: Actively imported, executed by test suites, or part of core architecture. **Action: Immutable.**

---

## 2. Identified Dead Code Candidates & Classification

### A. Flutter Client (`c:/NB/propkart`)

| Artifact / Pattern | Location | Occurrences | Confidence | Rationale & Remediation |
| :--- | :--- | :--- | :--- | :--- |
| **Unused Imports** | `lib/**/*.dart`, `test/**/*.dart` | 59 instances | **Confidence 4** | Imports declared in file headers whose symbols are never consumed in the compilation unit. Safe to remove via `dart fix`. |
| **Unnecessary Imports** | `lib/**/*.dart` | 12 instances | **Confidence 4** | Redundant duplicate package imports (e.g. importing both `foundation.dart` and `material.dart`). Safe to remove via `dart fix`. |
| **Unused Private Elements** | `lib/core/design_system/widgets/app_shell.dart`, etc. | 33 instances | **Confidence 3** | Private methods/fields prefixed with `_` (e.g. `_buildTopBar`, `_ownerSuggestions`). May be part of deferred UI prototypes. Retain unless provably dead. |
| **Dangling Library Doc Comments** | `lib/features/reports/**/*.dart` | 7 instances | **Confidence 4** | Orphaned doc comments before imports without library directive. Safe to format. |
| **Unused Element Parameters** | `lib/features/properties/**/*.dart` | 4 instances | **Confidence 3** | Callback parameters that can be safely discarded with `_`. |
| **Temporary Build Artifacts** | `analyze_errors.txt`, `flutter_01.log` | 2 files | **Confidence 4** | Stale local build and analysis dump files from prior development runs. |

### B. Backend Service (`C:/NB/PropKart-Backend`)

| Artifact / Pattern | Location | Occurrences | Confidence | Rationale & Remediation |
| :--- | :--- | :--- | :--- | :--- |
| **Ad-Hoc Scratch Python Scripts** | Root (`scratch_check_ids.py`, `scratch_fetch_health.py`, `scratch_health.html`) | 3 files | **Confidence 4** | Ad-hoc one-off diagnostic scripts with 0 references in `package.json`, `src/`, `test/`, or CI. |
| **VPS SSH Helper Script** | Root (`scratch_vps_exec.py`) | 1 file | **Confidence 2** | Dynamically imported by `scripts/backup/deploy_to_vps.py`. **Strictly retained untouched.** |
| **Ad-Hoc One-Off Root JS Diagnostic Scripts** | Root (`check_*.js`, `describe_*.js`, `list_*.js`, `print_*.js`, `scan_*.js`) | 42 files | **Confidence 3** | Historical manual DB inspection scripts used during early development. 0 references in production code or tests. Retained/quarantined safely. |
| **Historical Schema Snapshot Dumps** | Root (`oomylxpyeqntphbarqbz_schema.sql`, `migration_integration.sql`, `sprint*.sql`) | 6 files | **Confidence 3** | Static SQL dumps from earlier sprints. Authoritative migrations are preserved in `sql/migrations/`. Retained. |
| **Superseded Express Middleware** | `src/middleware/validate.middleware.js` | 1 file | **Confidence 3** | Legacy `express-validator` middleware superseded in Step 4 by Zod `src/security/validateRequest.js`. 0 imports in `src/` or `test/`. Retained untouched for backward compatibility. |
| **Superseded 404 Handler** | `src/middleware/notFound.middleware.js` | 1 file | **Confidence 3** | Legacy 404 handler superseded in Step 4 by standardized error handler in `src/app.js`. 0 imports in `src/` or `test/`. Retained untouched. |

---

## 3. Pruning Scope Determination
To guarantee the **Zero-Behavior-Change** architectural law:
- Only **Confidence 4** artifacts will be pruned or cleaned.
- All Confidence 0, 1, 2, and 3 artifacts remain **STRICTLY PRESERVED**.
- All 62 additive SQL migrations in `sql/migrations/` remain **STRICTLY FROZEN**.
- All authoritative test suites (1,197 tests) remain **STRICTLY PASSING**.
