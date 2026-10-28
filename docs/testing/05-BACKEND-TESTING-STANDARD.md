# 05 — Backend Testing Standard & Quality Guidelines

## 1. Overview & Framework Architecture

The PropKart Backend (Node.js) test infrastructure is built directly on the Node.js native test runner (`node:test`) and native assertion module (`node:assert/strict`). This removes external test runner bloat, guarantees zero native-module compilation flakiness, and delivers blazing execution performance (all 303 backend tests complete in under 26 seconds total).

### Core Testing Pillars:
1. **Deterministic Test Isolation:** Every test file must execute independently without depending on shared mutable global state or test execution ordering.
2. **Canonical Envelope Enforcement:** Every API endpoint test must assert against the standard PropKart response envelope: `{ success: boolean, data?: any, error?: { code, message, details }, meta?: any }`.
3. **Multi-Tenant Scoping By Default:** All database queries and service tests must explicitly assert tenant boundaries (`tenant_id`), ensuring cross-tenant leakage is impossible.
4. **Resilience & Fail-Open Verification:** Caching layers (Redis) must be tested for graceful degradation (fail-open to PostgreSQL on cache timeout or connection drop).

---

## 2. Directory Layout & Test Suite Hierarchy

```
PropKart-Backend/test/
├── api/                       # API route & controller integration tests
│   ├── auth.test.js           # Authentication, refresh tokens, cookie security
│   ├── campaign_leads.test.js # Campaign leads ingestion & assignments
│   ├── kpi.test.js            # KPI query routes & parameter validation
│   ├── properties.test.js     # Property catalog CRUD & filtering
│   ├── requirements.test.js   # Client requirements CRUD & matching
│   └── users.upload.test.js   # Bulk user CSV upload & validation
├── kpi/                       # Core KPI computation & aggregation tests
│   ├── canonical_kpi.test.js  # CanonicalKpiRepository math & cache tests
│   └── kpi_service.test.js    # KPI business logic & period comparisons
├── reports.kpi.test.js        # KPI reporting exports & summaries
├── security/                  # RBAC, tenant isolation, and security regression
│   ├── tenant_isolation.test.js # Cross-tenant read/write prevention
│   └── rbac_guard.test.js     # Role privilege boundaries (Admin, Manager, Agent)
├── sync/                      # Realtime sync & outbox processing
│   ├── outbox_processor.test.js # Durable outbox state machine & retries
│   └── phoenix_channel.test.js  # Realtime event broadcasting
└── telecaller_boundary_verification.test.js # Telecaller role boundary constraints
```

---

## 3. Test Categories & Implementation Patterns

### 3.1 Unit Testing (Services & Math Calculations)
- Pure logic tests for KPI calculations, commission formulas, date window calculations, and CSV parsing.
- Uses `node:test` (`describe`, `it`) with strict assertions (`assert.deepStrictEqual`, `assert.strictEqual`).
- Stubs external dependencies via lightweight factory injection or ES module mocking.

```javascript
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { calculateLeadConversionRate } from '../src/services/kpi_math.js';

describe('KPI Math Service - calculateLeadConversionRate', () => {
  it('correctly calculates conversion percentage to 2 decimal places', () => {
    const rate = calculateLeadConversionRate(45, 300);
    assert.strictEqual(rate, 15.0);
  });

  it('safely handles zero total leads without division by zero', () => {
    const rate = calculateLeadConversionRate(0, 0);
    assert.strictEqual(rate, 0.0);
  });
});
```

### 3.2 Integration Testing (API Routes & Envelopes)
- Routes are tested using `supertest` or lightweight HTTP client against the initialized Express/Koa application.
- All requests must include valid JWT headers or session cookies representing specific roles (`SuperAdmin`, `TenantAdmin`, `Agent`, `Telecaller`).
- Responses must conform to the unified API envelope:

```javascript
describe('GET /api/v1/requirements', () => {
  it('returns canonical envelope with pagination metadata', async () => {
    const res = await request(app)
      .get('/api/v1/requirements?page=1&limit=20')
      .set('Authorization', `Bearer ${testAgentToken}`)
      .set('X-Tenant-ID', tenantAId);

    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.success, true);
    assert.ok(Array.isArray(res.body.data.items));
    assert.strictEqual(res.body.meta.page, 1);
    assert.strictEqual(res.body.meta.limit, 20);
    assert.strictEqual(typeof res.body.meta.total, 'number');
  });
});
```

### 3.3 Database & Transaction Testing
- Every test performing writes against the database must either:
  1. Wrap the test in an explicit database transaction (`BEGIN ... ROLLBACK`) to prevent persistent state pollution.
  2. Or clean up created records using deterministically prefixed UUIDs (`test-step11-*`) in `afterEach()`.
- Explicit verification that `soft_deleted_at IS NOT NULL` records are excluded by default queries.

---

## 4. Mocking Guidelines & Best Practices

1. **Redis Cache Mocking:**
   - Use in-memory Redis simulators (e.g., `ioredis-mock` or lightweight `Map`-backed stubs) for unit and standard integration runs.
   - For cache failover tests, simulate connection errors (`ECONNREFUSED`, timeout) and assert that the service executes the fallback PostgreSQL query transparently.
2. **External Webhooks & Third-Party APIs:**
   - Telephony gateways, email services (SendGrid/SES), and SMS providers must NEVER be hit during automated test execution.
   - Use mock adapters injected via environment or dependency injection container.
3. **Database Client Mocking:**
   - Prefer running against a real local test PostgreSQL database for repository integration tests.
   - For fast controller unit tests, mock the database query builder or repository interfaces.

---

## 5. Execution Commands & CI Targets

```bash
# Execute primary backend test suite (207 tests)
npm test

# Execute secondary specialized suites (API, security, KPI, upload)
node --test test/api/*.test.js test/security/*.test.js test/kpi/*.test.js test/reports.kpi.test.js test/campaign_connections.test.js test/telecaller_boundary_verification.test.js test/users.upload.test.js

# Execute single test file with verbose output
node --test --test-reporter spec test/security/tenant_isolation.test.js
```
