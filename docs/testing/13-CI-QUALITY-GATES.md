# 13 — Continuous Integration Quality Gates & Release Criteria

## 1. Pipeline Overview & Gate Architecture

Every commit, pull request, and release candidate in the PropKart ecosystem is evaluated against an uncompromising 6-stage continuous integration pipeline. A failure at any gate halts the pipeline immediately and blocks deployment.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PropKart CI Pipeline                            │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
  ┌──────────────────────────────┐ ▼
  │ Gate 1: Static Analysis      │ ──► ESLint, Prettier, flutter analyze (0 warnings)
  └──────────────────────────────┘
                                   │
  ┌──────────────────────────────┐ ▼
  │ Gate 2: Security & Secrets   │ ──► npm audit, GitGuardian secret scan (0 CVEs)
  └──────────────────────────────┘
                                   │
  ┌──────────────────────────────┐ ▼
  │ Gate 3: Unit Test Suites     │ ──► Node.js unit, Flutter BLoC/Service (100% pass)
  └──────────────────────────────┘
                                   │
  ┌──────────────────────────────┐ ▼
  │ Gate 4: Component & UI Matrix│ ──► 13-Viewport Responsive Matrix (0 overflows)
  └──────────────────────────────┘
                                   │
  ┌──────────────────────────────┐ ▼
  │ Gate 5: Integration & Contract│ ──► DB RLS, Redis Failover, Canonical Envelopes
  └──────────────────────────────┘
                                   │
  ┌──────────────────────────────┐ ▼
  │ Gate 6: Build Verification   │ ──► flutter build apk, Docker container build
  └──────────────────────────────┘
                                   │
                                   ▼
                       [ RELEASE CANDIDATE CERTIFIED ]
```

---

## 2. Gate Criteria & Enforcement Standards

### Gate 1: Static Code Analysis & Linting
- **Backend:** `npm run lint` must pass with zero errors and zero warnings.
- **Frontend:** `flutter analyze` must pass with zero issues.
- **Formatting:** Code formatting must conform to Prettier (backend) and `dart format` (frontend).

### Gate 2: Security & Dependency Verification
- **Vulnerability Scanning:** `npm audit --audit-level=high` must find 0 high or critical vulnerabilities.
- **Secret Detection:** Scan commits for hardcoded API keys, JWT secrets, database connection strings, or private certificates.

### Gate 3: Unit Testing Gate
- **Backend:** Primary test suite (`npm test`) must achieve 100% pass rate.
- **Frontend:** Pure unit tests (models, bloc logic, math utilities) must pass with 0 failures and 0 skips.

### Gate 4: Component & Viewport Matrix Gate
- All Flutter screens must execute against the 13-step viewport matrix (320px to 1280px) and text scale 1.0x to 1.3x.
- `tester.takeException()` must be strictly `null` across all viewports (zero `RenderFlex` overflows permitted).
- Accessibility touch targets must meet or exceed 48x48 logical pixels.

### Gate 5: Integration & API Contract Gate
- Secondary backend suites (`api/`, `security/`, `kpi/`, `sync/`) must pass 100%.
- Canonical API envelopes verified on all routes.
- Multi-tenant Row-Level Security verified with cross-tenant isolation checks.
- Redis failover resilience validated under simulated cache disconnect.

### Gate 6: Build Verification Gate
- Frontend must cleanly compile: `flutter build apk --debug`.
- Backend must cleanly compile Docker production image: `docker build -t propkart-backend:rc .`.

---

## 3. Pull Request & Branch Protection Rules

1. **Branch Protection:** Direct pushes to `main`, `master`, and `release/*` are strictly blocked.
2. **Review Requirements:** Minimum 1 peer review and approval from a QA Architect or Lead Engineer.
3. **Status Checks:** All 6 CI quality gates must report `SUCCESS` before merge buttons are unlocked.
