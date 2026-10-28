# 12 — FILE OWNERSHIP & EDITABILITY CLASSIFICATION

## 1. Classification Matrix
To prevent accidental corruption of generated files, historical database records, or critical environment guardrails, every file in the PropKart ecosystem is classified into one of eight categories:

| Classification | Meaning & Intent | AI Agent Permissions | Examples |
| :--- | :--- | :--- | :--- |
| **`AUTHORITATIVE`** | Core application source code containing business logic. | **Editable** (Subject to change plan & tests). | `src/modules/**/*.service.js`, `lib/features/**/bloc/*.dart` |
| **`GENERATED`** | Output of automated code generators (`build_runner`). | **STRICTLY READ-ONLY**. Edit source schema only. | `lib/core/storage/isar_collections.g.dart` |
| **`MIGRATION`** | Historical SQL migrations already applied to environments. | **READ-ONLY**. Create *new* sequential migration instead. | `sql/migrations/01_*.sql` through `60_*.sql` |
| **`CONFIGURATION`**| Environment definitions and container setups. | **Strictly Regulated**. Only change with explicit scope. | `src/config/env.js`, `Dockerfile`, `docker-compose.prod.yml` |
| **`TEST`** | Automated verification suites protecting contracts. | **Additive Only**. Never delete assertions to hide bugs. | `test/**/*.test.js`, `test/**/*.dart` |
| **`DOCUMENTATION`**| Specifications, runbooks, and agent context files. | **Editable / Additive**. Must keep synchronized with code. | `docs/**/*.md`, `AGENTS.md` |
| **`LEGACY`** | Undecoupled legacy code scheduled for later cleanup. | **Do NOT Refactor Opportunistically**. | Old monolith helper files |
| **`DO NOT EDIT`** | Pinned lockfiles, git internals, compiled binaries. | **FORBIDDEN TO TOUCH**. | `.git/*`, `.dart_tool/*`, `pubspec.lock` (unless updating deps) |

## 2. Generated Code Protection Protocols
- **Isar Generator:**
  - Source file: `lib/core/storage/isar_collections.dart`.
  - Generated output: `lib/core/storage/isar_collections.g.dart`.
  - Manual edits to `*.g.dart` will be overwritten during CI builds or developer checkouts. If schema updates are needed, modify `isar_collections.dart` and execute:
    ```powershell
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## 3. Database Migration Integrity
- Never modify an existing migration file in `sql/migrations/` that has already been executed on production.
- Any change to tables, columns, or indexes must be introduced as a new, sequentially numbered migration file (e.g. `61_*.sql`) and registered in `src/config/ensureAdditiveSchema.js`.
