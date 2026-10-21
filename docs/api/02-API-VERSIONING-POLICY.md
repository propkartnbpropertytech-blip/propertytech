# 02 — PROPKART API VERSIONING POLICY (STEP 8.4)

## 1. Executive Summary

PropKart serves heterogeneous production clients including iOS and Android Flutter applications, web portals, third-party webhook ingestors, and internal administration consoles. Because mobile application update cycles are asynchronous and user-deferred, the API architecture enforces a **Zero-Breaking-Change Guarantee** across all minor and patch iterations.

---

## 2. URL Prefix & URI Structure

PropKart establishes two distinct top-level API gateways:

```text
/api/v1/          → Primary Authenticated Multi-Tenant CRM & Mobile API
/api/external/    → Public Webhook & Integration Gateway (Meta, Housing, 99acres)
```

### 2.1 Forward-Looking `/api/v2/` Gate
- Major breaking schema reorganizations (e.g., deprecation of legacy alias keys) will ONLY occur under a new URI prefix `/api/v2/`.
- The `/api/v1/` prefix is guaranteed to remain active and backward-compatible until all supported Flutter client versions deprecate `/v1` calls.

---

## 3. Backward Compatibility Mandates

1. **Envelope Preservation**: All `/api/v1/` endpoints MUST return the canonical envelope:
   ```json
   {
     "success": true,
     "data": { ... }
   }
   ```
2. **Key Retention**: Existing response fields must NEVER be removed or renamed in-place.
3. **Additive-Only Extensions**: New metrics, sub-metrics, or metadata must be added as new keys without altering existing field types or paths.
4. **Legacy Aliases Maintained**:
   - `counts.closed_deals` MUST equal `counts.deal_won`.
   - `counts.converted_clients` MUST reflect authoritative won lead count.
   - `counts.all_available_inventory` and `counts.global_available_inventory` MUST remain synchronized.
   - `counts.all_total_leads` and `counts.global_total_leads` MUST remain synchronized.
   - `counts.new_allocated` and `counts.new_leads_allocated` MUST mirror `leads_allocated`.
   - Dual-nested report objects (`data.kpis.metric` AND `data.metric`) MUST be preserved.

---

## 4. Client Version Negotiation & Header Contracts

- `X-Client-Version`: Recommended on mobile requests for telemetry and phased rollout tracking.
- `X-Request-Id`: Preserved or generated on every request to enable end-to-end tracing.
- `X-Degraded-Fallback`: Returned when non-critical analytics services operate in fallback mode, allowing Flutter BLoC states to display cached indicators without user interruption.

---

## 5. Deprecation Lifecycle

1. **Phase 1 (Observation)**: Telemetry logs track usage of legacy endpoints and fields.
2. **Phase 2 (Warning)**: Response headers include `X-API-Deprecation: date` without modifying payload bodies.
3. **Phase 3 (Sunsetting)**: Phased transition ONLY after Flutter app telemetry reports <0.1% traffic on deprecated fields over a 90-day window.
