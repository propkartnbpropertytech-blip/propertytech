# DELETION-REGISTER.md — PropKart Step 15 Deletion & Retention Register

## 1. Register Overview
This register documents every item evaluated for deletion or structural pruning during Step 15.
In strict alignment with the **Zero-Behavior-Change** mandate, only artifacts proven to be **Confidence 4 (Proven Dead)** with zero production, testing, deployment, or documentation dependencies are modified or deleted.

---

## 2. Deletion & Modification Register

| Item / Path | Category | Classification | Action Taken | Rationale & Safety Justification |
| :--- | :--- | :--- | :--- | :--- |
| `c:/NB/propkart/lib/**/*.dart` (59 unused imports) | Code Syntax | **Confidence 4** | **Removed** | 59 unreferenced import directives flagged by static analyzer. Zero symbol usage in compiling files. |
| `c:/NB/propkart/lib/**/*.dart` (12 unnecessary imports) | Code Syntax | **Confidence 4** | **Removed** | 12 duplicate namespace imports already exposed by parent package exports. |
| `c:/NB/propkart/analyze_errors.txt` | Temporary Artifact | **Confidence 4** | **Deleted** | Stale local analysis output dump from earlier terminal session. Zero runtime dependencies. |
| `c:/NB/propkart/flutter_01.log` | Temporary Artifact | **Confidence 4** | **Deleted** | Historical local crash/run log from earlier manual debug session. Zero runtime dependencies. |
| `C:/NB/PropKart-Backend/scratch_check_ids.py` | Diagnostic Scratch | **Confidence 4** | **Deleted** | One-off scratch script for debugging ID formats. 0 references across entire repository. |
| `C:/NB/PropKart-Backend/scratch_fetch_health.py` | Diagnostic Scratch | **Confidence 4** | **Deleted** | One-off health polling scratch script. 0 references across entire repository. |
| `C:/NB/PropKart-Backend/scratch_health.html` | Diagnostic Scratch | **Confidence 4** | **Deleted** | Ad-hoc HTML file containing health curl output. 0 references across entire repository. |
| `C:/NB/PropKart-Backend/scratch_vps_exec.py` | Operational Helper | **Confidence 2** | **RETAINED** | Imported dynamically by `scripts/backup/deploy_to_vps.py`. Preserved to prevent breaking backup pipeline. |
| `C:/NB/PropKart-Backend/vps.txt` | Credentials Artifact | **Confidence 3** | **RETAINED** | Contains host connection info. Retained for administrative continuity while warning logged. |
| `C:/NB/PropKart-Backend/src/middleware/notFound.middleware.js` | Legacy Middleware | **Confidence 3** | **RETAINED** | Superseded by `app.js` inline 404 handler, but retained untouched to prevent regression in older entrypoints. |
| `C:/NB/PropKart-Backend/src/middleware/validate.middleware.js` | Legacy Middleware | **Confidence 3** | **RETAINED** | Superseded by Zod validation in `src/security/validateRequest.js`, but retained untouched for backward compatibility. |
| `C:/NB/PropKart-Backend/sql/migrations/*.sql` (62 files) | Database Schema | **Confidence 0** | **STRICTLY FROZEN** | Authoritative database migrations. Deletion strictly prohibited by Master Engineering Rulebook. |
| `c:/NB/propkart/lib/core/storage/isar_collections.g.dart` | Generated Code | **Confidence 0** | **STRICTLY FROZEN** | Build runner codegen artifact for Isar database. Manual deletion or modification strictly prohibited. |

---

## 3. Verification Safeguards
1. **Immediate Pre/Post Testing**: Full test suites run after every batch of deletions.
2. **Rollback Guarantee**: All operations are tracked under git version control and can be reverted instantly if any regression occurs.
3. **Guardrail Tests**: AI safety guardrails (`test/ai_agent.guardrails.test.js` and `test/core/ai_agent_safety_test.dart`) ensure 0 core architectural violations.
