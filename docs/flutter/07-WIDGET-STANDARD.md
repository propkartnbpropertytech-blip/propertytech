# Presentation & Widget Composition Standard

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  

---

## 1. Container (Smart) vs. Presentational (Dumb) Components

To maintain clean separation of concerns, PropKart divides UI components into two distinct tiers:

```text
┌────────────────────────────────────────────────────────┐
│             CONTAINER SCREEN (Smart / Coordinator)      │
│  • Binds to Route arguments and BLoC lifecycle         │
│  • Injects BlocProvider / BlocConsumer                 │
│  • Dispatches domain events                            │
│  • Delegates visual rendering to child widgets         │
└───────────────────────────┬────────────────────────────┘
                            │ passes props & callbacks
                            ▼
┌────────────────────────────────────────────────────────┐
│           PRESENTATIONAL WIDGETS (Dumb / Pure)         │
│  • Stateless or minimal ephemeral state                │
│  • Reusable & independently testable                   │
│  • Strict const constructors                           │
│  • Emits callbacks (onChanged, onSubmitted, onAction)  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Widget Guidelines & Anti-Patterns

### 2.1 File Size & Extraction
- **Rule:** A single presentation widget file should rarely exceed **300 lines**.
- When a `build()` method exceeds 80 lines or contains deeply nested ternary trees, extract the sub-sections into private or standalone widget classes.

### 2.2 Rebuild Optimization & Const Constructors
- Prefer `const` constructors on all stateless widgets and subtrees without dynamic values.
- Never place heavy business calculations (e.g. sorting thousands of leads or computing aggregate KPI metrics) inside a `build()` method. All filtering and metric aggregations must occur in BLoCs or ViewModels before reaching the widget tree.

### 2.3 Virtualization Standards
- Monolithic screens previously constructed large lists using `SingleChildScrollView` with inline `Column(children: items.map(...).toList())`, causing all 5,000 items to allocate in memory and render simultaneously.
- All lists and tables exceeding 20 items must utilize virtualized renderers: `ListView.builder()`, `CustomScrollView` with `SliverList`, or `PaginatedDataTable`.

### 2.4 Responsive Layout Breakpoints
Widgets must adapt gracefully across PropKart's supported form factors:
- **Desktop / Web:** `width >= 1100 px` (Multi-column tables, persistent sidebar, expanded filter bars)
- **Tablet:** `768 px <= width < 1100 px` (Collapsible drawers, 2-column grids)
- **Mobile:** `width < 768 px` (Bottom navigation, swipeable cards, modal bottom sheet filters)
