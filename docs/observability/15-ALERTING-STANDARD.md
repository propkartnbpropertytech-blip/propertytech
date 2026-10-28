# 15 — Alerting Standard

## 1. Alerting Philosophy & Signal Quality

PropKart enforces the Google SRE alerting principle: **Alert on symptoms that directly affect users, not on internal noise.** Alerts must be actionable, deduplicated, and clearly categorized by urgency.

## 2. Alert Escalation Matrix

| Alert Name | Severity | Condition Threshold | Evaluation Window | Target Route | Actionable Runbook |
|:---|:---:|:---|:---:|:---|:---|
| **ApiHigh5xxErrorRate** | P0 (Critical) | 5xx error rate > 2.0% | 2 minutes | PagerDuty + Slack `#alerts-critical` | Check Sentry top issues, examine DB pool, check recent deployment. |
| **PostgreSqlPoolExhausted** | P0 (Critical) | Pool waiting clients > 5 | 1 minute | PagerDuty + Slack `#alerts-critical` | Inspect active long-running transactions; execute `pg_stat_activity` query kill. |
| **DatabaseDown** | P0 (Critical) | Readiness probe fails DB `SELECT 1` | 30 seconds | PagerDuty + SMS | Check PostgreSQL container/instance status, verify disk space. |
| **ApiHighLatencyP95** | P1 (High) | P95 latency > 500 ms | 5 minutes | Slack `#alerts-ops` | Check slow query logs, review Redis hit ratio, check CPU utilization. |
| **RedisCircuitOpen** | P1 (High) | Redis connection down | 2 minutes | Slack `#alerts-ops` | Restart Redis instance; database handles fail-open gracefully. |
| **SyncFailureRateSpike** | P1 (High) | Mobile sync failure rate > 5.0% | 5 minutes | Slack `#alerts-sync` | Inspect delta endpoint latency, check schema version mismatches. |
| **SentryNewExceptionSpike** | P2 (Medium) | > 50 novel unhandled errors/hr | 15 minutes | Slack `#alerts-sentry` | Triage bug in Sentry dashboard, assign engineer for investigation. |
| **DiskSpaceLow** | P2 (Medium) | Disk usage > 85% on DB/server | 10 minutes | Slack `#alerts-ops` | Prune old database snapshots, rotate audit logs, expand EBS volume. |

## 3. Pager Routing & On-Call Playbook

- **P0 Incidents**: Triggers automated voice calls and SMS to the Primary On-Call Engineer. If unacknowledged within 5 minutes, escalates to Secondary On-Call and Engineering Lead.
- **P1 Incidents**: Dispatches high-priority Slack notifications to `#alerts-ops`. If unresolved within 30 minutes, escalates to P0.
- **Silence & Inhibit Rules**: If `DatabaseDown` fires, subordinate latency and 5xx alerts are inhibited to prevent alert fatigue.
