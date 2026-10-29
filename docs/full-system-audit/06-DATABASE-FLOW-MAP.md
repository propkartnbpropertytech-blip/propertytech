# 06 — Database Flow Map

PostgreSQL is the business authority. Isar is a device cache. Redis is a TTL cache.

## Writes that were inspected

| Action | Tables | Transaction note |
| :--- | :--- | :--- |
| Requirement status | `requirements`, `leads` via sync triggers | Trigger depth above 1 skips nested sync. Preserve trigger runs after the forward sync |
| Allocation | `leads`, allocation history, availability | One SQL transaction. Node code around the RPC is not the lock boundary |
| Organization delete | many child tables, then users and organizations | Explicit cascade in `subscriptions.service.js`, commit inside the method |
| KPI read | canonical SQL | Redis key `propkart:kpi:...`. Miss falls open to memory, then SQL |

## Integrity notes

- Lead `stage` is constrained. Requirement `status` is not.
- Two files share the number 80, and two share 81. Additive startup lists one of each plus `82_reallocated_campaign_requirement_status.sql`. Running an older `live_schema` script can install a narrower allocation check. That script is not in the additive list.
- Service role access bypasses RLS. Tenant scope has to be enforced in the service.

## Failure behavior

Database-down, pool exhaustion, and constraint errors were not injected. The API returns the service error message on the sheet feed, including the driver message. That is a leak risk on 500 responses and was not load-tested.
