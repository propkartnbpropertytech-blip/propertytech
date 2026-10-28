# 20 — SUPPLY-CHAIN SECURITY & DEPENDENCY AUDIT STANDARD

## 1. Dependency Locking
To eliminate build non-determinism and dependency tampering:
- **Node.js:** Pinned strictly via `package-lock.json` (`lockfileVersion: 3`). Installations use `npm ci` rather than `npm install`.
- **Flutter:** Pinned strictly via `pubspec.lock`. Installations use `flutter pub get` with exact lockfile resolution.

## 2. Automated Vulnerability Scanning
- **CI Dependency Audit:**
  - Every pull request executes `npm audit --omit=dev --audit-level=high`.
  - Zero high or critical vulnerabilities are tolerated in production dependencies.
- **Base Image Vulnerability Scanning:**
  - Pinned Debian base `node:22-bookworm-slim` is refreshed on monthly security cadences.

## 3. Package Integrity & Supply-Chain Hardening
- Direct external script execution (`curl | bash`) is forbidden in all Dockerfiles and deployment pipelines.
- Transitive dependencies are audited regularly via `npm ls` and automated Dependabot / Renovate updates.
