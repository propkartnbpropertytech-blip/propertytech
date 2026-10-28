# 20 — AI DOCUMENTATION GOVERNANCE & CONSISTENCY STANDARD

## 1. Single Source of Truth
To prevent architectural drift and conflicting documentation:
- High-level platform axioms and architectural laws reside exclusively in [`PROPKART_MASTER_ENGINEERING_RULEBOOK.md`](file:///c:/NB/propkart/PROPKART_MASTER_ENGINEERING_RULEBOOK.md).
- AI agent operational rules, lifecycle protocols, and navigation reside in `AGENTS.md` and `docs/ai-agent/`.
- Domain-specific specifications reside in designated directories (`docs/kpi/`, `docs/sync/`, `docs/security/`, `docs/devops/`).

## 2. Documentation Integrity Principles
1. **Preserve Existing Docstrings:** Do not remove existing docstrings or explanatory comments when refactoring adjacent code.
2. **Never Silently Rewrite History:** Historical audit reports (e.g. `STEP-1-PERFORMANCE-REMEDIATION.md`) are immutable historical records. Document evolutions in subsequent sequential reports.
3. **Keep Code and Docs Synchronized:** If an API endpoint, migration, or environment variable is added or modified, update the corresponding documentation file in the same task.
4. **Use Clickable Relative Links:** All markdown references to repository files must use valid markdown links so engineers and agents can navigate effortlessly.
