# 04-DUPLICATE-CODE-AUDIT.md — PropKart Duplicate Code & Redundancy Forensic Audit

## 1. Executive Summary
This forensic audit analyzed both the Flutter client and Backend service to detect:
1. Duplicate business logic or redundant algorithms.
2. Parallel implementations of identical formatting, parsing, or validation logic.
3. Overlapping utility functions across feature modules.
4. Platform-conditional implementations (e.g. Web vs Mobile) to ensure they are architectural abstractions rather than accidental duplications.

---

## 2. Cross-Subsystem Audit Findings

### A. Number & Currency Formatting (`lib/core/utils/`)
- **Candidates**:
  - `budget_formatter.dart`: Compact human-readable abbreviation (`Cr`, `Lakh`, e.g., "1.25 Cr").
  - `currency.dart`: Full standard Indian currency formatting (`NumberFormat.currency(locale: 'en_IN', symbol: '₹')`).
  - `formatters.dart`: Flutter `TextInputFormatter` subclasses for numeric input fields.
- **Forensic Assessment**:
  - Each module fulfills a distinct architectural responsibility.
  - `formatters.dart` directly imports and delegates to `currency.dart` rather than reimplementing Indian rupee formatting.
  - **Verdict**: **No Duplication**. Clean architectural delegation.

### B. Platform-Specific Conditional Imports (`lib/core/utils/`)
- **Candidates**:
  - `file_downloader.dart` + `file_downloader_web.dart` + `file_downloader_mobile.dart` + `file_downloader_stub.dart`
  - `seo_helper.dart` + `seo_helper_web.dart` + `seo_helper_stub.dart`
- **Forensic Assessment**:
  - These files employ standard Dart conditional compilation syntax (`if (dart.library.html) ... if (dart.library.io) ...`).
  - Web implementation interacts with the browser DOM (`dart:html` / `web`), while Mobile interacts with the native filesystem (`dart:io` / `path_provider`).
  - Merging these files into a single compilation unit would crash mobile builds on Android/iOS due to missing `dart:html`.
  - **Verdict**: **Architectural Necessity**. Must remain preserved.

### C. Backend Request Validation & Sanitization
- **Candidates**:
  - `src/security/validateRequest.js` (Zod schema-based request validation)
  - `src/security/sanitize.js` (Prototype pollution and SQL parameter sanitization)
  - `src/middleware/validate.middleware.js` (Legacy `express-validator` adapter)
- **Forensic Assessment**:
  - `validateRequest.js` handles schema validation for API endpoints.
  - `sanitize.js` executes deep recursive object sanitization and metacharacter stripping.
  - `validate.middleware.js` is legacy code retained for backwards compatibility.
  - **Verdict**: **No Active Conflict**. Zero overlapping execution paths.

### D. Redis Connection vs Cache Abstraction
- **Candidates**:
  - `src/config/redis.js` (Connection lifecycle, retry strategies, event listeners)
  - `src/services/cache.service.js` (Higher-level caching, single-flight stampede protection, payload ceiling, tenant namespacing)
- **Forensic Assessment**:
  - `src/config/redis.js` is low-level infrastructure; `cache.service.js` is an enterprise service layer.
  - **Verdict**: **Strict Clean Architecture**. No duplication.
