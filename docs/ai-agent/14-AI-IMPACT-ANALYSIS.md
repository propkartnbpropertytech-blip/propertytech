# 14 — AI IMPACT ANALYSIS & DEPENDENCY TRACING PROTOCOL

## 1. Impact Tracing Model
Before introducing a modification to any backend service or Flutter module, the AI agent must trace the downstream impact across seven distinct dimensions:

```text
Target File Modification
       │
       ├── 1. Direct Imports & Consumers (Which files import this symbol?)
       ├── 2. API Contract Impact (Does this change query parameters or JSON fields?)
       ├── 3. Database Persistence Impact (Does this affect table columns or constraints?)
       ├── 4. KPI Semantics Impact (Does this alter canonical status counts?)
       ├── 5. Multi-Tenant Isolation (Is organization_id correctly preserved?)
       ├── 6. Test Suite Coverage (Which tests protect this behavior?)
       └── 7. Telemetry & Observability (Are latency metrics and error logs maintained?)
```

## 2. Practical Dependency Discovery Commands
To trace dependencies safely without relying on guesswork:

- **Trace Consumers in Backend:**
  ```powershell
  Select-String -Path "src/**/*.js" -Pattern "FunctionNameOrClass"
  ```
- **Trace Consumers in Flutter:**
  ```powershell
  Select-String -Path "lib/**/*.dart" -Pattern "WidgetOrUseCaseName"
  ```
- **Find Associated Tests:**
  ```powershell
  Get-ChildItem -Path "test" -Filter "*feature_name*.js"
  ```

## 3. High-Blast-Radius Components
Changes to the following core components carry platform-wide blast radius and require maximum caution:
1. `src/config/dbPool.js` & `src/config/env.js`: Affects all database connections.
2. `src/modules/dashboard/kpi/canonicalKpi.repository.js`: Affects all executive and sales KPI counts.
3. `lib/core/api/dio_client.dart` & `logging_interceptor.dart`: Affects all network requests.
4. `lib/core/network/sync_engine.dart`: Affects all offline-online synchronization.
