# 15 — AI ARCHITECTURE GUARDRAILS & AUTOMATED ENFORCEMENT

## 1. Overview of Automated Guardrails
To prevent AI coding agents from degrading architectural integrity over time, PropKart maintains automated test suites that fail immediately if forbidden dependencies or layer breaches are introduced:
- **Backend Guardrails:** `test/architecture.rules.test.js` and `test/ai_agent.guardrails.test.js`.
- **Flutter Guardrails:** `test/core/flutter_architecture_rules_test.dart` and `test/core/ai_agent_safety_test.dart`.

## 2. Hard Enforced Architectural Rules

### Rule 1: Route Purity (Backend)
- **Constraint:** Route files (`src/modules/**/*.routes.js`) must ONLY bind middleware and controller functions.
- **Enforcement:** Automated AST / regex scan checks that zero route files import `dbPool` or `supabase`.

### Rule 2: Controller Decoupling (Backend)
- **Constraint:** Controllers must handle HTTP unwrapping and delegate to services. They must not execute raw SQL queries.
- **Enforcement:** Controllers outside documented legacy exemptions are prohibited from importing `dbPool.query`.

### Rule 3: Service Protocol Independence (Backend)
- **Constraint:** Domain services must remain protocol-agnostic. They must not accept Express `req` or `res` objects or call `res.status().json()`.
- **Enforcement:** Automated regex scans detect Express response manipulation inside service files.

### Rule 4: Presentation Framework Isolation (Flutter)
- **Constraint:** Presentation screens and widgets must not import `DioClient`, `package:dio`, or `isar_collections.dart`.
- **Enforcement:** Automated file inspection fails CI if presentation code imports network or database drivers directly.

### Rule 5: BLoC State Machine Purity (Flutter)
- **Constraint:** BLoCs must be pure reactive event-to-state processors. They must not declare UI widgets (`StatelessWidget`, `StatefulWidget`).
- **Enforcement:** Automated AST checks fail if BLoC files contain UI widget subclasses.
