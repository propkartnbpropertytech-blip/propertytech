# 03 — PROPKART API RESPONSE STANDARD (STEP 8.4)

## 1. Primary Objective

Establishes the uniform structure, type contracts, envelope standards, and serialization invariants across all PropKart HTTP responses.

---

## 2. Standard Success Envelope

Every successful API response in PropKart MUST adhere strictly to the top-level envelope:

```json
{
  "success": true,
  "data": { ... }
}
```

### 2.1 Metadata & Informational Fields (Optional Top-Level)
For mutations or state changes, an optional `message` field may accompany the envelope:
```json
{
  "success": true,
  "message": "Resource created successfully.",
  "data": { ... }
}
```

---

## 3. Standard Collection & Pagination Envelope

When endpoints return paginated collections (such as inventory listings, leads, or drilldowns), the data block MUST encapsulate both the items array and bounded pagination metadata:

```json
{
  "success": true,
  "data": {
    "items": [ ... ],
    "pagination": {
      "page": 1,
      "limit": 25,
      "total": 142,
      "totalPages": 6,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

*Note: For legacy compatibility with existing Flutter screens, domain-named keys like `"properties"`, `"leads"`, or `"records"` are supported alongside `"items"`.*

---

## 4. Nullability, Zero-Values & Invariants

1. **Numeric Metrics**: KPI counts and aggregations must NEVER return `null` or `NaN`. Missing or zero metrics must return `0`.
2. **Collections & Arrays**: If no matching records exist, endpoints must return empty arrays `[]`, NEVER `null`.
3. **Filter Metadata**: Endpoints accepting filters must echo the normalized active filters in `data.filters` or `data.date_range`.
4. **Dates**: All timestamps in responses must be serialized in ISO-8601 UTC format (`YYYY-MM-DDTHH:mm:ss.sssZ`).

---

## 5. Header Invariants

All responses emit the following standard HTTP headers:
- `X-Request-Id`: Sanitized correlation ID string (UUIDv4 or whitelisted client token).
- `X-Correlation-Id`: Identical to `X-Request-Id` for multi-standard tracing compatibility.
- `Content-Type`: `application/json; charset=utf-8`.
- `X-Content-Type-Options`: `nosniff`.
