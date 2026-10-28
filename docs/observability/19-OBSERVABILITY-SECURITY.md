# 19 — Observability Security & Access Control Standard

## 1. Security Architecture for Telemetry

Telemetry pipelines possess broad visibility into platform execution and must therefore be secured against unauthorized interrogation, credential theft, and tenant isolation bypasses.

## 2. Access Controls & Endpoint Security

| Endpoint | Access Level | Authentication Protocol | Rate Limiting |
|:---|:---:|:---|:---:|
| `GET /health/liveness` | Public (Cluster Internal) | None (Protected by Ingress / Network Policy) | None (Cluster probe) |
| `GET /health/readiness` | Cluster Internal | None (Internal health probe network) | 60 req/min |
| `GET /health/metrics` | Admin Only | JWT with scope `health_admin` or role `Super Admin` | 30 req/min |
| `GET /metrics` | Scraper Only | Basic Auth / Internal VPC Network Firewall | 120 req/min |
| `GET /health/portal` | Health Admin Only | Encrypted Session Cookie (`health_portal_session`) | 10 req/min |

## 3. Defense-in-Depth Protections

1. **Information Leakage Prevention**:
   - Error envelopes returned to external callers omit internal database table names, SQL query strings, stack traces, and local filesystem paths.
   - Internal diagnostics (e.g. detailed Postgres error codes) are restricted to server-side Winston logs.
2. **Tenant Boundary Defense**:
   - Traces and telemetry records include `tenantId` (organization UUID) to allow filtering, but never cross tenant scopes.
   - Realtime telemetry on Phoenix channels enforces JWT tenant verification before topic join.
3. **No Dynamic Code Evaluation**:
   - Metrics queries and log search utilities are strictly parameterized and do not execute dynamic `eval()` or unvalidated SQL interpolation.
