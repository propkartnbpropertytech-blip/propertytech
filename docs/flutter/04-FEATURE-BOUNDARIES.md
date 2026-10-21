# Feature Boundaries & Module Architecture

> **Document Version:** 1.0.0  
> **Date:** October 2026  
> **Target:** PropKart Flutter Frontend (`c:\NB\propkart\lib`)  

---

## 1. Domain-Driven Feature Decomposition

PropKart structures all application capabilities into distinct **Feature Modules** under `lib/features/`, supported by a foundation layer in `lib/core/`:

```text
lib/
├── core/                         # Cross-cutting horizontal capabilities
│   ├── design_system/            # Theme, typography, tokens, atomic UI components
│   ├── network/                  # DioClient, interceptors, auth token refresh
│   ├── storage/                  # Isar schema instances, local store adapters
│   ├── sync/                     # SyncManager, RepositoryCoordinator
│   └── utils/                    # Formatters, date helpers, validators
│
└── features/                     # Vertical business capability domains
    ├── admin/                    # System health, staff roster, allocation rules
    ├── auth/                     # Login, session verification, user role state
    ├── campaign/                 # Meta/Google Ads leads, lead reclassification
    ├── dashboard/                # Operational KPIs, analytics charts, inventory demand
    ├── integration/              # Webhook connectors, third-party ingestion
    ├── properties/               # Property inventory, cards, share PDF, media
    ├── reports/                  # Export pipelines, Excel/PDF reporting
    ├── requirements/             # Buyer/tenant requirements, matching engine
    ├── sales/                    # Sales pipeline, lead follow-ups, deal closing
    └── telecaller/               # Telecaller calling queue, callbacks, dispositions
```

---

## 2. Feature Encapsulation Rules

### 2.1 Public vs. Private Feature Surface
Each feature maintains a strict separation between public contracts and internal implementations:
1. **Public Surface:**
   - Domain Entity Models (e.g. `RequirementModel`, `PropertyModel`, `IntegrationLeadModel`).
   - Feature Public Routable Screens (e.g. `RequirementsScreen`, `CampaignLeadsScreen`).
   - Feature Public Events / Use Cases where cross-domain triggering is necessary.
2. **Private Surface (Forbidden to external features):**
   - Internal child widgets (e.g. `_RequirementTableRow`, `_CampaignCellRenderer`).
   - Internal BLoCs / Cubits managing local screen states.
   - Internal Data Sources & HTTP payload mappers.

### 2.2 Prohibited Cross-Feature Coupling

```text
❌ BAD: features/sales/screens/lead_detail.dart imports features/requirements/presentation/widgets/requirement_action_dialogs.dart
✅ GOOD: features/sales navigates via GoRouter to '/requirements/:id' or uses a shared Core dialog.

❌ BAD: features/properties directly queries isar.requirementModels
✅ GOOD: features/properties uses MatchCriteriaManager or calls RequirementsRepository via DI.
```

---

## 3. Dependency Injection & Service Locator Guidelines

- Cross-cutting repositories and services are registered in the dependency container (e.g., `GetIt` or top-level `MultiRepositoryProvider`).
- Screens retrieve dependencies via `context.read<T>()` or constructor injection.
- Direct instantiation of repositories or services inside widget `initState` or build methods is strictly forbidden.
