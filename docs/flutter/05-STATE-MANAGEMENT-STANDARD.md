# State Management Standard: BLoC & Cubit Architecture

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  
> **Library:** `flutter_bloc: ^8.1.3`  

---

## 1. Core State Management Philosophy

PropKart uses `flutter_bloc` as its official state management solution.
State transitions must be predictable, immutable, and testable without UI dependencies.

```text
User Interaction (Tap / Filter / Input)
   │
   ▼
UI Widget dispatches BlocEvent
   │
   ▼
BLoC receives Event in on<Event>() handler
   │
   ▼
BLoC invokes Domain Use Case
   │
   ▼
BLoC emits new immutable BlocState (with copyWith)
   │
   ▼
BlocBuilder / BlocConsumer selectively rebuilds targeted widget subtree
```

---

## 2. The Flicker-Free Caching Standard

To deliver optimal UX on high-latency mobile networks or offline operations, PropKart enforces the **Flicker-Free State Pattern**:

```dart
// ❌ WRONG: Flashes a full-screen loading skeleton every time the user refreshes
emit(RequirementsLoading());
final items = await useCase.execute();
emit(RequirementsLoaded(items: items));

// ✅ CORRECT: Retains cached items during background revalidation
if (state is RequirementsLoaded) {
  emit((state as RequirementsLoaded).copyWith(isSilentRefreshing: true));
} else {
  emit(RequirementsLoading()); // Only on very first cold load
}
final items = await useCase.execute();
emit(RequirementsLoaded(items: items, isSilentRefreshing: false));
```

This prevents table and card flicker, preserving user scroll positions and active selections.

---

## 3. Strict Rules for BLoC & Cubit Implementations

1. **Zero UI References:** Never import `package:flutter/material.dart` or pass `BuildContext` into a BLoC or Cubit.
2. **Zero Direct Network / Storage Access:** Never call `dio.get()` or `isar.writeTxn()` inside a BLoC handler. All external operations must be encapsulated in a Use Case or Repository.
3. **Immutability:** All state classes must extend `Equatable` or implement `operator ==` and `hashCode`. Never mutate state collections in place (e.g. `state.items.add(x)` is forbidden; use `[...state.items, x]`).
4. **Scoped Rebuilds:** Never wrap the entire screen `Scaffold` in a single monolithic `BlocBuilder`. Wrap only the specific child widgets that consume that piece of state (e.g. `RequirementSummaryBar`, `RequirementTable`).
5. **No God BLoCs:** If a BLoC handles more than 8 distinct event types or spans multiple screen lifecycles, decompose it into focused BLoCs or Cubits (e.g., separating `LeadAllocationMonitorBloc` into polling management and queue manipulation).
