# 15 — CONTAINER RESOURCE LIMITS & QUOTAS SPECIFICATION

## 1. Resource Allocation Matrix
To prevent noisy-neighbor starvation and system memory exhaustion, PropKart enforces explicit CPU and memory constraints across all containers in `docker-compose.prod.yml`:

| Service | CPU Reservation | CPU Limit | Memory Reservation | Memory Limit | Log Rotation Policy |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`backend`** | `0.50` CPU | `2.00` CPUs | `512MB` | `1024MB` | `max-size: "20m"`, `max-file: "5"` |
| **`redis`** | `0.25` CPU | `1.00` CPU | `256MB` | `512MB` | `max-size: "10m"`, `max-file: "3"` |
| **`db`** | `1.00` CPU | `2.00` CPUs | `1024MB` | `2048MB` | `max-size: "20m"`, `max-file: "5"` |

## 2. Memory OOM Mitigation
- Node.js runtime memory is bounded via `--max-old-space-size=800` inside a 1024MB container limit, guaranteeing that garbage collection kicks in before the Linux kernel OOM-killer intervenes.
- Redis is configured with `maxmemory 512mb` and `maxmemory-policy allkeys-lru`, ensuring cache data is evicted gracefully rather than hitting OS memory boundaries.

## 3. Log Rotation Guardrails
Uncapped Docker container stdout/stderr logging can exhaust host disk space. Every container service specifies JSON-file log driver options:
- `max-size: "20m"`
- `max-file: "5"`
Guarantees container logs never consume more than 100MB per service on disk.
