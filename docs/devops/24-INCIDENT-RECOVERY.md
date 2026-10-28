# 24 — PRODUCTION INCIDENT MANAGEMENT & POST-MORTEM RUNBOOK

## 1. Incident Severity Classification

| Severity | Definition | Target Response | Target Resolution |
| :--- | :--- | :--- | :--- |
| **SEV-1 (Critical)** | Complete API outage, database unavailability, persistent data corruption, or catastrophic auth failure. | < 5 minutes | < 30 minutes |
| **SEV-2 (High)** | Degradation of major core flow (e.g. leads queue failing, site visit booking failing, Redis outage with slow DB queries). | < 15 minutes | < 2 hours |
| **SEV-3 (Medium)** | Minor non-blocking feature degradation (e.g. report export delay, non-critical integration webhook retry). | < 1 hour | < 8 hours |
| **SEV-4 (Low)** | Cosmestic UI issue, minor telemetry warning, non-impacting log anomaly. | Next business day | Next sprint |

## 2. SEV-1 Incident Command Workflow
1. **Declare Incident:** Notify engineering leadership via incident war-room.
2. **Designate Incident Commander (IC):** One engineer coordinates triage, communication, and mitigation.
3. **Stabilize (Mitigation First):**
   - If caused by recent release: Trigger rollback runbook (`18-ROLLBACK-RUNBOOK.md`).
   - If caused by resource exhaustion: Scale resources or restart offending container.
   - If caused by external integration: Enable circuit-breaker or decouple worker.
4. **Preserve Forensics:** Capture container logs, database metrics, and error stack traces before restarting instances.
5. **Verify Recovery:** Run `node scripts/smoke_test.js` to certify operational restoration.

## 3. Blameless Post-Mortem Standard
Within 48 hours of any SEV-1 or SEV-2 incident, a formal blameless post-mortem document must be produced detailing:
- Timeline of events (detection, acknowledgment, mitigation, resolution).
- Root Cause Analysis (RCA) utilizing the 5 Whys methodology.
- Action items with assigned owners and due dates to prevent recurrence.
