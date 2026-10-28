# 11 — Test Data Management & Fixture Standards

## 1. Core Principles

Test data in PropKart is governed by four strict architectural rules:
1. **Zero Production Data in Test Suites:** Production dumps or real customer data must never be imported into automated test suites. All data is generated synthetically.
2. **Deterministic Isolation:** Test cases must never rely on records inserted by prior tests. Each test or test suite generates its own self-contained fixtures.
3. **Traceable Test Identity:** All generated entities use deterministic IDs or clearly tagged prefixes (e.g., `test-step11-*` or email domains `@propkart.test`) to allow surgical cleanup and auditing.
4. **Idempotent Cleanup:** Any test suite modifying persistent storage must restore the state to clean baseline upon completion.

---

## 2. Test Fixture Factories (Backend)

Backend tests utilize centralized factory builders located in `test/factories/` that instantiate valid domain entities with sensible defaults:

```javascript
// Example: Factory for creating test leads
export function buildTestLead(overrides = {}) {
  const uniqueId = crypto.randomUUID();
  return {
    id: `test-lead-${uniqueId}`,
    tenantId: overrides.tenantId || 'test-tenant-alpha',
    contactName: overrides.contactName || 'Test Customer',
    contactEmail: overrides.contactEmail || `lead.${uniqueId.slice(0, 8)}@propkart.test`,
    contactPhone: overrides.contactPhone || '+919800000001',
    stage: overrides.stage || 'NEW_LEAD',
    source: overrides.source || 'CAMPAIGN_FACEBOOK',
    budgetMin: overrides.budgetMin ?? 5000000,
    budgetMax: overrides.budgetMax ?? 10000000,
    assignedAgentId: overrides.assignedAgentId || null,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    ...overrides,
  };
}
```

### Factory Guarantees:
- Output is always schema-valid according to database constraints and API validation schemas.
- Foreign key dependencies (e.g., `tenantId`, `campaignId`) can be injected or resolved via chained factory helpers (`createTenantWithUsers()`).

---

## 3. Flutter Client Mock Fixtures

On the Flutter client, deterministic fixtures are maintained under `test/fixtures/`:

```dart
class TestFixtures {
  static LeadModel createLead({
    String id = 'test-lead-001',
    String tenantId = 'test-tenant-001',
    String name = 'Test Client',
    String stage = 'PROSPECT',
  }) {
    return LeadModel(
      id: id,
      tenantId: tenantId,
      name: name,
      stage: stage,
      phone: '+919800000000',
      budgetMin: 5000000,
      budgetMax: 12000000,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  static RequirementModel createRequirement({
    String id = 'test-req-001',
    String tenantId = 'test-tenant-001',
    double budgetMin = 4000000,
    double budgetMax = 8000000,
  }) {
    return RequirementModel(
      id: id,
      tenantId: tenantId,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      preferredLocations: const ['Indiranagar', 'Koramangala'],
      propertyType: 'COMMERCIAL_OFFICE',
    );
  }
}
```

---

## 4. Teardown & Lifecycle Hooks

### 4.1 Database Cleanup Strategy
When integration tests run without transaction rollbacks, teardown is performed using deterministic cleanup queries:

```javascript
after(async () => {
  await dbClient.query(`
    DELETE FROM leads WHERE id LIKE 'test-lead-%';
    DELETE FROM requirements WHERE id LIKE 'test-req-%';
    DELETE FROM properties WHERE id LIKE 'test-prop-%';
    DELETE FROM tenants WHERE id LIKE 'test-tenant-%';
  `);
});
```

### 4.2 Redis Cache Invalidation Hook
Tests touching Redis invalidate test namespaces:
```javascript
afterEach(async () => {
  const keys = await redisClient.keys('kpi:test-*');
  if (keys.length > 0) {
    await redisClient.del(keys);
  }
});
```

### 4.3 Flutter Resource Disposal
Every Flutter widget test lifecycle must terminate with teardown disposing BLoCs, Streams, and Notifiers:
```dart
tearDown(() async {
  testBloc.close();
  AppNotifierService.dismissToast();
});
```
