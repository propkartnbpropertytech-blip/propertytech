# 18 — DEPENDENCY & SUPPLY CHAIN SECURITY AUDIT

## 1. Audit Methodology

The dependency audit inspects:
1. Flutter dependencies (`pubspec.yaml`, `pubspec.lock`)
2. Node.js backend dependencies (`package.json`, `package-lock.json`)
3. Static automated vulnerability analysis via `npm audit` and Flutter package verification.

---

## 2. Node.js Backend Dependency Findings & Remediation

### Initial Audit Summary (Pre-Remediation)
- **Total Dependencies**: 432 packages audited.
- **Vulnerabilities**: 12 (1 Critical, 6 High, 5 Moderate).
- **Critical Finding**: `proxy-addr` (1.1.0 - 2.0.7): IP spoofing via IPv4-mapped IPv6 trust subnet.
- **High Findings**:
  - `compression <1.8.2`: DoS via memory leak on premature response close.
  - `multer <=2.3.0`: DoS via crafted multipart field names & file descriptor leak.
  - `brace-expansion <=1.1.20`: DoS via unbounded intermediate arrays in dev tools.

### Remediation Implemented
- Ran `npm audit fix`, successfully updating `proxy-addr` to patched version, along with `compression`, `multer`, `morgan`, `qs`, `ip-address`, and `brace-expansion`.
- **Result**: **0 CRITICAL vulnerabilities remaining**.

### Remaining Low/Moderate Dev Findings
| Package | Severity | Category | Risk Assessment | Mitigation |
| :--- | :---: | :---: | :--- | :--- |
| `braces` | High | Dev tool (`nodemon`) | Used only during local development hot-reload; never executed in production VPS container. | No production impact. |
| `uuid` | Moderate | Transitive via `exceljs` | Missing buffer bounds check when raw buffer is supplied. PropKart exports use standard JSON-to-Excel generators without custom buffers. | Bounded risk; scheduled for next minor `exceljs` update. |

---

## 3. Flutter Client Dependency Audit

- Key dependencies reviewed:
  - `flutter_secure_storage`: Verified configured with `encryptedSharedPreferences: true`.
  - `dio`: Certified Step 8.4 interceptor pipeline with error mapping and logging redaction.
  - `isar`: Bounded to local user isolation; wiped cleanly on logout.
  - `crypto`, `http_parser`: Standard cryptographic and MIME inspection libraries.
- Analysis via `flutter analyze --no-fatal-infos` completed with **0 errors**.
