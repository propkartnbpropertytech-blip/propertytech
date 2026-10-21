# AI-Agent Maintainability & Codebase Architecture Standard

> **Document Version:** 1.0.0  
> **Status:** Authoritative Standard  
> **Target:** PropKart Backend Engine (`PropKart-Backend`)  
> **Audience:** Core Engineering Team, Autonomous AI Coding Agents, Software Architects  

---

## 1. Executive Summary & Philosophy

In modern software engineering, codebases are increasingly analyzed, maintained, refactored, and audited by both senior software engineers and autonomous AI coding agents (such as DeepMind Antigravity, Claude, and GPT-4). An architecture that is optimized for AI-agent maintainability is simultaneously an architecture that is exceptionally clean, robust, and readable for human software engineers.

PropKart’s Step 5 transformation institutes **AI-Agent Maintainability** as a first-class architectural invariant.

---

## 2. The Core Problem: Monolithic Files in LLM Contexts

Monolithic files exceeding 1,000 to 5,000 lines create compounding failure modes for AI agents:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       MONOLITH FAILURE MODES IN LLMs                        │
├────────────────────────┬────────────────────────────────────────────────────┤
│ Failure Mode           │ Mechanism & Impact                                 │
├────────────────────────┼────────────────────────────────────────────────────┤
│ Context Window Bloat   │ Large files consume tens of thousands of tokens,   │
│                        │ pushing out architecture rules and test baselines. │
├────────────────────────┼────────────────────────────────────────────────────┤
│ Lost Attention & Hallu │ High token distance between definitions and usages │
│                        │ triggers hallucinations and subtly broken edits.   │
├────────────────────────┼────────────────────────────────────────────────────┤
│ Truncated Diff Edits   │ Large replacement chunks fail diff matching and    │
│                        │ introduce syntax corruption during patching.       │
├────────────────────────┼────────────────────────────────────────────────────┤
│ Hidden Side-Effects    │ Deeply coupled state across 4,000 lines causes     │
│                        │ localized fixes to trigger silent regressions.    │
└────────────────────────┴────────────────────────────────────────────────────┘
```

---

## 3. Mandatory AI-Agent Maintainability Rules

### Rule 1: File Size Thresholds & Complexity Ceilings
- **Strict Target:** Every source file should remain under **500 lines**.
- **Hard Ceiling:** No file may exceed **800 lines** without an architectural exception and modular decoupling plan.
- **Single Responsibility:** A single file must represent exactly one logical role (e.g. transport handling, business orchestration, or SQL access).

### Rule 2: Predictable Feature Directory Structure
Every backend capability is organized as a discrete feature module under `src/modules/<feature>/`:

```text
src/modules/<feature>/
  ├── <feature>.routes.js       # HTTP URL routes, HTTP methods, route-level middleware
  ├── <feature>.schemas.js      # Zod validation schemas for input contracts
  ├── <feature>.controller.js   # HTTP transport, params parsing, status codes, response envelopes
  ├── <feature>.service.js      # Pure business rules, domain orchestration, transaction boundaries
  ├── <feature>.repository.js   # Authoritative PostgreSQL / Supabase queries
  └── <feature>.sanitize.js     # Mass-assignment allowlists & field stripping (optional)
```

### Rule 3: Deterministic Function Signatures & Explicit Types
- Static class methods and exported functions must accept explicit, destructured parameter objects:
  ```javascript
  // ✅ AI-FRIENDLY: Clear parameter schema, self-documenting, extensible
  static async getRequirementsForExport({ orgId, role, userId }) { ... }

  // ❌ ANTI-PATTERN: Positional arguments with invisible ordering requirements
  static async getRequirementsForExport(a, b, c, d, e) { ... }
  ```
- Methods must never mutate caller arguments.
- Pure utility functions (date calculation, string parsing, math) must live in standalone, stateless helper files (e.g., `kpi.definitions.js`).

### Rule 4: Clean Layer Boundary Enforcement
An AI agent modifying a controller must never have to parse or reason about raw SQL statements. An AI agent optimizing database queries must never have to inspect HTTP header formatting or cookie sessions:

```text
[ HTTP Transport ]   Controller  → Inspects req, delegates to Service, returns res
                           ↓
[ Domain Engine ]    Service     → Enforces business invariants, delegates to Repo
                           ↓
[ Persistence ]      Repository  → Executes raw SQL / Supabase queries via dbPool
```

### Rule 5: Zero Implicit State & Zero Global Leakage
- No module-level mutable state (`let globalCounter = 0;`).
- All dependencies must be explicitly imported at the top of the file using standard ES modules (`import { ... } from "..."`).
- No circular dependencies (`A -> B -> A`).

---

## 4. AI-Agent Refactoring Protocol

When an autonomous agent refactors or extends backend code in PropKart, it must adhere to the following sequence:

1. **Scan Before Edit:** Measure file line count and locate boundary layers.
2. **Feature Extraction:** If a service exceeds 800 lines, extract pure sub-domains into distinct service files (e.g., `campaignColumns.service.js` extracted from `integrations.service.js`).
3. **Re-Export Compatibility:** Always re-export extracted methods from the parent facade to prevent breaking external callers.
4. **Immediate Test Verification:** Run targeted test suites after every extraction wave before modifying subsequent modules.

---

## 5. Verification & Architectural Testing

AI-Agent maintainability is enforced continuously via automated architectural tests in `test/architecture.rules.test.js` and `test/architecture.contract.test.js`.
