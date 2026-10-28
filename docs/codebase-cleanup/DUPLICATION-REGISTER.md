# DUPLICATION-REGISTER.md — PropKart Duplication & Redundancy Register

## 1. Register Overview
This register catalogs all subsystem code modules audited for structural duplication and redundancy across PropKart.

---

## 2. Redundancy & Duplication Matrix

| Evaluated Module Group | Files Involved | Pattern Detected | Classification | Action | Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Currency & Number Formatting** | `budget_formatter.dart`<br>`currency.dart`<br>`formatters.dart` | Similar formatting domain | **Architectural Specialization** | **Preserve All** | Distinct functional scopes (Compact display vs full INR currency vs TextInputFormatter). Direct delegation verified. |
| **Platform File Downloader** | `file_downloader_web.dart`<br>`file_downloader_mobile.dart`<br>`file_downloader_stub.dart` | Platform-specific file download | **Conditional Compilation** | **Preserve All** | Required by Dart compiler to prevent `dart:html` resolution errors on iOS/Android. |
| **SEO Meta Helpers** | `seo_helper_web.dart`<br>`seo_helper_stub.dart` | Platform-specific head tags | **Conditional Compilation** | **Preserve All** | Web updates DOM `<head>` elements; stub provides no-op on native platforms. |
| **Backend Validation** | `validateRequest.js`<br>`validate.middleware.js` | Request body validation | **Historical Evolution** | **Preserve Both** | `validateRequest.js` (Zod) is active standard; `validate.middleware.js` retained as harmless non-interfering legacy fallback. |
| **Error Response Serialization** | `apiResponse.js`<br>`errors.js` | HTTP payload envelopes | **Architectural Separation** | **Preserve Both** | `apiResponse.js` formats successful envelopes (`{ success: true, data }`); `errors.js` formats error envelopes (`{ success: false, error }`). |

---

## 3. Governance Conclusion
No unwarranted structural duplication exists that compromises maintainability. All detected parallel structures represent intentional platform adaptations, layer boundaries, or architectural delegations.
