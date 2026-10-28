# 13 — AI CHANGE SAFETY & CHANGE MINIMIZATION STANDARD

## 1. The Principle of "Minimum Correct Change"
AI coding agents naturally tend toward over-engineering, uncontrolled refactoring, and rewriting functional code. In PropKart, agents must adhere to the **Minimum Correct Change** doctrine:
- The optimal implementation touches the **fewest files and fewest lines of code** required to satisfy the user request correctly and completely.
- Modifying 1 file cleanly is infinitely superior to rewriting 10 files with speculative abstractions.

## 2. Change Scope Boundaries
Before editing, every AI agent must establish a strict boundary:

```text
Target Files (Allowed to Change)
  ├─ Specific controller / service
  └─ Corresponding test suite

Protected Files (Forbidden to Change)
  ├─ Authentication / RBAC boundaries
  ├─ CanonicalKpiRepository
  ├─ Database migrations
  ├─ Environment guardrails
  └─ Unrelated feature modules
```

## 3. Unexpected Scope Expansion Protocol
If an agent begins implementing a change and discovers that an unpredicted dependency requires modifying files outside the declared scope:
1. **DO NOT** silently edit the unexpected files.
2. **HALT** the implementation immediately.
3. Document the technical reason why the scope must expand in the execution report.
4. Request explicit authorization from the user before proceeding.
