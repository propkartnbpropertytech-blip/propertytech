# 06 — CONTINUOUS INTEGRATION (CI) SPECIFICATION

## 1. CI Pipeline Architecture
PropKart enforces automated pull request and branch validation through GitHub Actions:
- **Backend Pipeline (`.github/workflows/backend-ci.yml`):**
  - Triggered on PRs to `main` and pushes to `main`.
  - Runs in clean Ubuntu runner with Node 22.
  - Enforces dependency lockfile verification (`npm ci`).
  - Executes security audits (`npm audit --omit=dev --audit-level=high`).
  - Scans for accidental secret commits (`git grep -I -nE`).
  - Executes all 239+ automated tests (`npm test` and `npm run test:all`).
  - Builds production Docker image to guarantee container build reproducibility.

- **Flutter Pipeline (`.github/workflows/flutter-ci.yml`):**
  - Triggered on PRs affecting `lib/`, `test/`, `pubspec.yaml`.
  - Installs pinned Flutter SDK (3.38.3+).
  - Fetches pinned dependencies (`flutter pub get`).
  - Runs static analysis (`flutter analyze --no-fatal-infos`).
  - Executes entire frontend test suite (952 tests) via `flutter test`.
  - Dry-runs release build (`flutter build web --dry-run`).

## 2. Merge Gate Invariants
No pull request can merge into `main` unless:
1. All CI jobs report status `SUCCESS` (0 test failures, 0 skipped/quarantined tests).
2. Secret scanner returns 0 matching leak patterns.
3. Static code analysis reports 0 errors.
4. Dependency vulnerability check reports 0 Critical and 0 High vulnerabilities.
