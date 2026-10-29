# 11 — KPI Audit

## Authority

`CanonicalKpiRepository` runs the SQL. Redis key prefix `propkart:kpi:`. TTL is about 60 seconds for today and 300 seconds otherwise. Redis failure falls open to an in-memory map. Flutter `kpi_rulebook.dart` names metrics. It does not calculate them.

## Invalidation

Property, requirement, and lead mutations call `invalidateOnMutation` with the organization id. The requirement service does this after reassert, using the fresh row.

## Not done

No KPI was counted in SQL and compared with the API, Redis, and the dashboard. Today, week, month, year, custom range, empty, and large data were not run. Status: `NOT TESTABLE`.

Client-side authoritative KPI math was not found in the rulebook. That does not prove every widget avoids a local count.
