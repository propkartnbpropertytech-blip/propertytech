# 11-CONSOLIDATION-PLAN.md — PropKart Module Consolidation & Architectural Refinement Plan

## 1. Governance Principles
Under the **Master Engineering Rulebook** and **Zero-Behavior-Change Cleanup Mandate**:
1. Consolidation is permitted **ONLY** when two or more components perform identical logic with identical invariants and identical consumer expectations.
2. Consolidation is **FORBIDDEN** if it introduces conditional platform coupling (e.g. breaking Flutter Web/Mobile split) or merges distinct architectural layers (e.g. merging presentation with data).

---

## 2. Evaluation of Consolidation Proposals

### Proposal 1: Merging Number & Currency Formatters
- **Files**: `budget_formatter.dart`, `currency.dart`, `formatters.dart`
- **Assessment**:
  - `budget_formatter.dart` is presentation-oriented for compact KPI badges (`"2.5 Cr"`, `"15 Lakh"`).
  - `currency.dart` handles authoritative rupee currency formatting (`"₹2,50,000"`).
  - `formatters.dart` is a widget-layer input validator (`TextInputFormatter`).
- **Verdict**: **REJECTED**. Merging these would violate the Single Responsibility Principle and couple UI input filtering with string presentation.

### Proposal 2: Merging Conditional Platform Adapters
- **Files**: `file_downloader_web.dart` + `file_downloader_mobile.dart`
- **Assessment**:
  - Flutter multi-platform compilation requires separating `dart:html` from `dart:io`.
  - Merging them into a single file causes compile-time symbol errors on Android and iOS.
- **Verdict**: **REJECTED**. Conditional compilation files must remain separate.

### Proposal 3: Consolidation of Legacy Middleware in Backend
- **Files**: `src/middleware/validate.middleware.js` vs `src/security/validateRequest.js`
- **Assessment**:
  - Modern routes use `src/security/validateRequest.js` (Zod schemas).
  - `validate.middleware.js` is legacy code from early sprint experiments.
- **Verdict**: **PRESERVED IN ISOLATION**. No active routes consume `validate.middleware.js`. Retained without modification to eliminate any risk of breaking older external test harnesses.

---

## 3. Consolidation Summary
The PropKart architecture is already heavily consolidated from the systematic transformations executed in Steps 1 through 14. Further forced consolidations would violate architectural layer boundaries.
