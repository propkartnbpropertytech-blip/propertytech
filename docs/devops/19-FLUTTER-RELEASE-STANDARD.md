# 19 — FLUTTER CLIENT BUILD & RELEASE MANAGEMENT STANDARD

## 1. Multi-Platform Build Pipeline
PropKart Flutter client targets Web and Android platforms:
- **Web Release:**
  - Build command: `flutter build web --release --pwa-strategy=offline-first --base-href="/"`.
  - Artifacts: Deployed to Nginx web root `/var/www/propkart-web` with Brotli and gzip compression.
  - Service worker caches core UI assets for immediate offline loading.
- **Android Release:**
  - Build command: `flutter build appbundle --release`.
  - ProGuard / R8 code shrinking and obfuscation enabled in `android/app/build.gradle`.
  - Version code incremented sequentially based on CI build counter.

## 2. Frontend Configuration & Flavor Isolation
- Frontend environment is injected at build time via `--dart-define`:
  - `API_BASE_URL`: Production API endpoint (`https://api-propkart.nbpropertytech.com/api/v1`).
  - `SENTRY_DSN`: Client-side error telemetry DSN.
  - `APP_ENV`: `production`.
- Zero credentials or database connection strings are compiled into the client binary.

## 3. Offline-First Resilience Validation
Prior to releasing any Flutter build:
- Verify Isar local storage schema migrations (`isar.migration.dart`).
- Validate Durable Outbox and Offline Sync state machine against offline-online network transitions.
- All 952 Flutter tests must pass with 0 errors.
