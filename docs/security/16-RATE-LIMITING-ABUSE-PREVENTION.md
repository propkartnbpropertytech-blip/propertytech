# 16 — RATE LIMITING & ABUSE PREVENTION

## 1. Rate Limiting Strategy

PropKart enforces multi-dimensional rate limiting across different network and operational boundaries:

```text
Incoming Traffic
       │
       ├─► [Global IP Rate Limiter] ────── 300 req / 15 min per IP
       │
       ├─► [Auth Route Limiter] ────────── 10 req / 15 min per IP (Login, Reset, OTP)
       │
       ├─► [Account Lockout Guard] ─────── 5 failed logins triggers progressive delay
       │
       ├─► [Tenant KPI & Export Limiter] ─ 60 req / min per Organization
       │
       └─► [Captcha Challenge Guard] ───── Triggered on suspicious traffic or repeated attempts
```

---

## 2. Sensitive Endpoints & Policies

| Endpoint Category | Window | Max Attempts | Key Dimension | Action on Breach |
| :--- | :---: | :---: | :--- | :--- |
| `/api/v1/auth/login` | 15 min | 10 | IP address + email | HTTP 429 Too Many Requests + Captcha requirement |
| `/api/v1/auth/forgot-password` | 60 min | 5 | Email address | HTTP 429 Too Many Requests |
| `/api/v1/dashboard/kpis` | 1 min | 60 | `organization_id` | HTTP 429 Too Many Requests (Served from cache if available) |
| `/api/v1/sync/*` | 1 min | 120 | User ID + Device ID | Backoff header sent in HTTP 429 response |
| Media Uploads | 15 min | 30 | User ID | HTTP 429 Too Many Requests |

---

## 3. Account Lockout Architecture (`lockout.js`)

1. **Failure Tracking**: Tracks sequential failed login attempts in Redis / memory keyed by email and IP.
2. **Progressive Delays**:
   - 3 consecutive failures: 5-second artificial delay + Captcha challenge.
   - 5 consecutive failures: 15-minute temporary lockout of the IP/email combination.
3. **Reset on Success**: A successful authentication automatically resets the failed counter.

---

## 4. Captcha Hardening (`captcha.service.js`)

- Statistically verified via `test/captcha.hardening.test.js`.
- Generates stateless HMAC-signed Captcha IDs with embedded expiration timestamps.
- Consumed Captcha challenges cannot be replayed.
- Replay attacks and expired challenges are rejected with `400 BAD_REQUEST`.
