# 08 — RELEASE MANAGEMENT & VERSIONING STANDARD

## 1. Semantic Versioning (SemVer 2.0)
PropKart components follow strict Semantic Versioning: `MAJOR.MINOR.PATCH`.
- **MAJOR (`vX.0.0`):** Breaking architectural changes, incompatible API modifications, or major database overhaul.
- **MINOR (`v1.X.0`):** Backward-compatible new features, new migrations, new API endpoints.
- **PATCH (`v1.1.X`):** Backward-compatible bug fixes, performance improvements, security patches.

## 2. Release Artifact Management
1. **Docker Container Images:**
   - Tagged with git commit SHA (`propkart-backend:${GITHUB_SHA}`) and release version tag (`propkart-backend:v1.1.2`).
   - `latest` tag always mirrors the certified production deployment commit.
2. **Flutter Web / Mobile Builds:**
   - Web artifacts compiled via `flutter build web --release --pwa-strategy=offline-first`.
   - Android artifacts compiled with deterministic signing and version codes derived from git commit count.

## 3. Production Release Cadence
- Production deployments occur strictly within designated maintenance / deployment windows.
- Every release must have an associated Git release tag, automated changelog, and certified smoke test run.
