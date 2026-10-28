# 21 — PRODUCTION ACCESS CONTROL & BASTION SPECIFICATION

## 1. Principle of Least Privilege
Direct administrative access to production infrastructure is strictly regulated:
- **Zero Shared Accounts:** All engineer access uses individual SSH public keys.
- **Root Login Disabled:** `PermitRootLogin no` configured in `/etc/ssh/sshd_config`. Deployments use a dedicated unprivileged `deploy` user with scoped `sudo` privileges.
- **SSH Key Authentication Only:** Password authentication over SSH is disabled (`PasswordAuthentication no`).
- **Network Port Hardening:** Only ports 80 (HTTP redirect) and 443 (HTTPS) are exposed to the public internet. Port 5432 (PostgreSQL) and Port 6379 (Redis) are bound to `127.0.0.1` and Docker bridge networks only.

## 2. Production Database Access Rules
- Engineers never query production databases with write credentials during normal operations.
- Emergency read-only access uses read replicas or time-bound access tokens.
- All administrative SQL executions must be submitted via peer-reviewed migration scripts or audited scripts with change tickets.

## 3. Audit Logging of Administrative Operations
- All SSH sessions, `sudo` commands, and Docker operations are logged to the VPS system journal (`journald`) and forwarded to centralized SIEM / CloudWatch.
- Application-level administrative actions (user role alterations, settings updates) are written to `public.audit_logs`.
