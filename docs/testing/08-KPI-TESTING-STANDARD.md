# 08 — KPI Testing Standard & Calculation Integrity

## 1. Executive Summary & Architectural Invariants

Key Performance Indicators (KPIs) govern business operations, agent performance tracking, pipeline valuation, and executive dashboards across the PropKart platform.

### Core Architectural Invariants:
1. **PostgreSQL as Authoritative Source:** Redis is purely an acceleration tier. Under no circumstances may Redis contain aggregated metrics that cannot be deterministically computed from PostgreSQL rows.
2. **Deterministic Cache Key Hashing:** All Redis cache keys must follow the canonical format:
   ```
   kpi:{tenantId}:{metricName}:{window}:{filterHash}
   ```
3. **Single-Flight Lock (Stampede Protection):** When a cache miss occurs under high concurrency, exactly one worker must compute the aggregate from PostgreSQL while other requests wait or return slightly stale data.
4. **Fail-Open Resilience:** If Redis disconnects, times out (> 100ms), or errors, `KpiService` must fall back to PostgreSQL and log a warning without failing the user request.

---

## 2. Tested KPI Metrics & Math Formulas

The following KPI calculations are covered by automated unit and integration tests:

| Metric | Formula | Test Assertions |
|:---|:---|:---|
| **Lead Conversion Rate** | $\frac{\text{Closed Won Leads}}{\text{Total Created Leads}} \times 100$ | Zero divisor protection ($0/0 = 0.0\%$), decimal precision to 2 digits. |
| **Average Deal Value** | $\frac{\sum \text{Closed Deal Values}}{\text{Number of Closed Deals}}$ | Proper handling of null deal values, multi-currency conversion. |
| **Pipeline Funnel Velocity** | $\text{Days elapsed between Stage } i \text{ and Stage } i+1$ | Date boundary calculations, non-monotonic stage changes handling. |
| **Telecaller Connect Rate** | $\frac{\text{Answered Calls}}{\text{Total Call Attempts}} \times 100$ | Filtering out calls < 15 seconds as unassisted drops. |
| **Demand-Supply Ratio** | $\frac{\text{Active Client Requirements}}{\text{Available Property Units}}$ | Regional grouping (micromarket level) and budget band categorization. |

---

## 3. Redis Cache & Failover Testing

### 3.1 Cache Hit / Miss Verification
Tests verify:
1. First request computes from DB and sets Redis with configured TTL (e.g., 300 seconds).
2. Second request retrieves from Redis without calling PostgreSQL query pool.
3. Invalidation event (e.g., new lead created or stage change) purges or updates the relevant Redis keys.

```javascript
describe('CanonicalKpiRepository - Caching & Invalidation', () => {
  it('serves cached aggregate on second request without database hit', async () => {
    const dbSpy = mock.method(dbClient, 'query');
    
    // First call: Cache miss -> DB hit
    const result1 = await canonicalKpiRepo.getLeadFunnelMetrics(tenantId, '30d');
    assert.strictEqual(dbSpy.mock.callCount(), 1);

    // Second call: Cache hit -> 0 additional DB hits
    const result2 = await canonicalKpiRepo.getLeadFunnelMetrics(tenantId, '30d');
    assert.strictEqual(dbSpy.mock.callCount(), 1);
    assert.deepStrictEqual(result1, result2);
  });
});
```

### 3.2 Fail-Open Verification (Redis Disconnect)
Tests simulate Redis failure:
```javascript
it('falls back to PostgreSQL gracefully when Redis encounters ECONNREFUSED', async () => {
  mockRedis.simulateFailure(new Error('connect ECONNREFUSED 127.0.0.1:6379'));
  
  const result = await kpiService.getDashboardSummary(tenantId);
  assert.ok(result);
  assert.strictEqual(result.source, 'POSTGRES_FALLBACK');
  assert.strictEqual(result.success, true);
});
```

---

## 4. Time Window & Boundary Testing

Automated tests cover all supported temporal aggregation windows:
- **TODAY:** Current UTC day (`00:00:00.000` to now).
- **YESTERDAY:** Previous complete calendar day.
- **THIS_WEEK / LAST_WEEK:** ISO week boundaries (Monday 00:00:00 to Sunday 23:59:59).
- **MTD (Month-To-Date):** 1st day of current month to current timestamp.
- **QTD (Quarter-To-Date):** Standard calendar quarters (Q1: Jan-Mar, Q2: Apr-Jun, etc.).
- **YTD (Year-To-Date):** Jan 1 of current year to now.
- **Boundary Edge Cases:**
  - Leap year February 29 date math.
  - Month boundaries (March 31 -> April 30 transitions).
  - Timezone conversion (UTC stored in DB vs. Asia/Kolkata presentation on client).

---

## 5. Flutter Client KPI Zero-Flicker Verification

On the Flutter application, KPI displays must adhere to zero-flicker loading:
- When a user pulls to refresh or selects a new time window filter, the UI retains existing KPI cards while displaying a subtle inline loading spinner or progress bar.
- Empty states are strictly distinguished from loading states: an empty state is only displayed when the response returns with zero records, never during intermediate loading.
