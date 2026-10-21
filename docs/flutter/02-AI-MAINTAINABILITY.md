# AI-Agent Maintainability & Codebase Structure Standard

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  
> **Audience:** Human Engineers & Autonomous AI Coding Agents  

---

## 1. The Context Window & Token Overflow Problem

In modern multi-agent and LLM-assisted software engineering, **large files represent a catastrophic failure mode**:
1. **Context Window Exhaustion:** A single 15,000-line file consumes ~60,000 to 90,000 tokens. Viewing, analyzing, or editing such files fills or overflows the context window, causing hallucinations, dropped context, and slow response latency.
2. **Diff & Patch Fragility:** Modifying a giant file using regex search/replace or hunk diffs frequently produces parse errors, indentation corruption, and unintended side effects across distant lines.
3. **Cognitive Overload:** Neither human engineers nor AI agents can safely reason about 25+ responsibilities bundled into a single file (UI rendering, direct HTTP, Isar queries, CSV export, PDF layout, WhatsApp launching, and dialog forms).

---

## 2. Hard & Soft File Size Standards

To ensure frictionless AI-agent maintenance and human developer velocity, PropKart enforces the following strict size tiers:

| Tier | Line Count | Status | Policy / Action |
| :--- | :---: | :---: | :--- |
| **Ideal Component** | `< 300 lines` | 🟢 **Compliant** | Default target for widgets, use cases, models, and repositories. |
| **Standard Screen** | `300 – 500 lines` | 🟢 **Compliant** | Acceptable for screen coordinators that compose child widgets. |
| **Complex Screen** | `500 – 1,000 lines` | 🟡 **Soft Limit** | Requires decomposition review. Permitted only if layout composition is dense. |
| **Legacy Monolith** | `1,000 – 2,500 lines` | 🟠 **Decomposition Queue** | Must be refactored before new features are added. |
| **Critical Monolith** | `> 2,500 lines` | 🔴 **Forbidden** | Immediate decomposition required. No new business logic permitted inline. |

---

## 3. Principles of AI-Friendly Architecture

### 3.1 Single Responsibility Principle (SRP)
Every file must have exactly **one reason to change**:
- A **Screen** only orchestrates layout and connects BLoC state to UI.
- A **Widget** only renders a specific visual section and emits callbacks.
- A **Use Case** only executes one business transaction.
- A **BLoC** only transforms incoming UI events into view states.
- A **Repository** only manages data sourcing (Local Isar vs Remote Dio).

### 3.2 Predictable Directory Hierarchy
An AI agent must be able to deduce the exact location of any component without sweeping the entire filesystem:

```text
lib/features/<feature_name>/
├── domain/
│   ├── models/            # Pure Dart entity definitions
│   └── usecases/          # Business transaction use cases
├── data/
│   ├── datasources/       # Remote (Dio) and Local (Isar) clients
│   ├── models/            # Serializers (fromJson, toIsar)
│   └── repositories/      # Repository implementations
└── presentation/
    ├── bloc/              # BLoC / Cubit, Events, States
    ├── screens/           # Top-level routable screens (<500 lines)
    ├── widgets/           # Feature-specific extracted widgets (<300 lines)
    └── dialogs/           # Feature modals and bottom sheets
```

### 3.3 Clear Barrel Exports & Public Interfaces
Features expose their capabilities via a top-level feature export or clearly designated domain interfaces. Internal widgets (e.g. `_RequirementTableRow`) must not be imported or manipulated by other features.

### 3.4 Explicit Typing & Immutability
- Always use strongly typed data transfer objects. Avoid `Map<String, dynamic>` in presentation layers.
- Prefer `const` constructors everywhere to assist both Flutter widget rebuilding optimizations and AI reasoning about immutable state.
