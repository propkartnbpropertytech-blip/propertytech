# 05 — RESPONSE ENVELOPES, DTOS & PAYLOAD SANITIZATION

## 1. Authoritative Response Envelopes

To maintain a consistent API contract across Flutter mobile, web, and external consumers, all endpoints follow the standardized **Envelope Pattern**.

### 1.1 Single Resource Response
```json
{
  "success": true,
  "message": "Property retrieved successfully",
  "data": {
    "id": "c88ed9f1-5261-4e5f-8a34-e9fade752c70",
    "property_code": "PR-1042",
    "title": "3 BHK Luxury Apartment in Baner",
    "price": 12500000,
    "created_at": "2026-10-18T09:30:00.000Z"
  }
}
```

### 1.2 Paginated Collection Response
```json
{
  "success": true,
  "message": "Properties retrieved successfully",
  "data": {
    "properties": [ ... ],
    "count": 142,
    "page": 1,
    "limit": 25,
    "totalPages": 6
  }
}
```

> [!NOTE]
> Backward-compatible collection properties (e.g. `properties`, `requirements`, `site_visits`) retain their named root key within `data` to ensure zero breaking changes for existing Flutter models.

---

## 2. Sensitive Field Stripping & Data Sanitization

PropKart enforces strict database-to-API sanitization before sending any response to the client.

### 2.1 User & Credential Sanitization (`users.sanitize.js`)
The following fields are strictly excluded from all API responses:
- `password_hash`
- `mfa_secret`
- `mfa_temp_secret`
- `session_version`
- `reset_password_token`
- `reset_password_expires`
- `captcha_answer`

### 2.2 Inventory Attribution Masking (`tenant.js`)
When properties or leads are viewed by non-admin sales agents, creator identity and internal owner commission rates are masked:
- `creator.full_name`: Hidden or mapped to "Agent" if the agent is not in the same branch/team.
- `owner_mobile`: Masked for non-authorized team roles to prevent lead poaching.

---

## 3. Date & Time Format Standards

- All timestamps in API responses must be formatted as **ISO 8601 UTC** with trailing `Z` (e.g. `2026-10-20T12:00:00.000Z`).
- Date-only fields (e.g. `possession_date`, `visit_date`) are formatted as `YYYY-MM-DD`.
- Clients must never parse epoch integers or local timestamps without timezones.

---

## 4. DTO Validation Architecture (Request Schemas)

All API mutations must be validated against explicit Zod schemas in `src/security/validationSchemas.js` before reaching the controller:

```javascript
// Example Validation Middleware Application
router.post(
    "/",
    authenticate,
    validate(PropertyCreateSchema),
    PropertiesController.createProperty
);
```

### Key Validation Schemas:
- `PropertyCreateSchema` / `PropertyUpdateSchema`: Validates property types, configuration IDs, prices, positive numbers.
- `RequirementCreateSchema`: Validates buyer budget ranges, contact phone format (10-15 digits), category IDs.
- `FollowupCreateSchema`: Validates future followup dates, status transitions.
- `SiteVisitCreateSchema`: Validates visitor UUID, property UUID, scheduled date.
- `AuthLoginSchema`: Validates email format, password minimum length, CAPTCHA token.
