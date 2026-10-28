# 17 — Incident Diagnostics Standard

## 1. Fast Forensic Diagnostics Workflow

When production anomalies, elevated error rates, or database pool contention occur, on-call engineers follow a deterministic 5-step triage framework to answer:
> What failed, when, for which tenant/user, in which layer, and what is the blast radius?

```text
Incident Detected (Alert / Sentry / Prometheus)
      │
      ▼
Step 1: Check Liveness & Readiness (/health/liveness, /health/readiness)
      │ If 503 DOWN -> Check PostgreSQL pool / connection sockets
      │ If 200 DEGRADED -> Check Redis reachability
      ▼
Step 2: Inspect In-Memory Metrics (/health/metrics or /metrics)
      │ Check P95/P99 latency distribution
      │ Identify high-error normalized routes (e.g. /api/v1/leads/:id)
      ▼
Step 3: Correlate via Sentry & Winston Logs
      │ Filter Sentry by environment: production and recent release
      │ Extract requestId and correlationId from failing transaction
      ▼
Step 4: Trace Lifecycle across DB & Services
      │ Search Winston structured logs for correlationId
      │ Check if slow query alert (> 500ms) was logged for matching statement
      ▼
Step 5: Remediate, Verify & Document Post-Mortem
```

## 2. Quick Diagnostic Commands

### Health & Metrics Probes:
```bash
# Check process liveness (zero I/O)
curl -i http://localhost:5001/health/liveness

# Check dependency readiness (PostgreSQL & Redis)
curl -i http://localhost:5001/health/readiness

# Fetch structured JSON metrics
curl -s http://localhost:5001/health/metrics | jq .
```

### PostgreSQL Pool Diagnostics:
```sql
-- Check active and blocked queries in PostgreSQL
SELECT pid, usename, client_addr, state, query_start, wait_event_type, wait_event, query 
FROM pg_stat_activity 
WHERE state != 'idle' 
ORDER BY query_start ASC;

-- Check lock contention
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS current_statement_in_blocking_process
FROM  pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```
