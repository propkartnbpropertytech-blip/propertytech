# 14 — End-to-End Critical Business Flows & Journey Verification

## 1. Overview & Strategy

While unit and component tests provide high-density coverage of isolated modules, End-to-End (E2E) critical flow tests verify that all architectural components—API gateways, databases, Redis caches, durable outboxes, Phoenix sockets, and Flutter client state machines—operate harmoniously across essential business workflows.

---

## 2. The 5 Core Critical Business Journeys

### Journey 1: Lead Ingestion to Field Agent Assignment
- **Actors:** Campaign Webhook, Telecaller, Sales Manager, Field Agent.
- **Workflow:**
  1. Incoming lead ingested via webhook (`POST /api/v1/campaigns/{id}/leads`).
  2. Database persists lead with `stage = 'NEW_LEAD'`; outbox event published.
  3. Telecaller picks up lead from queue, performs qualification call, sets `stage = 'QUALIFIED'`.
  4. Sales Manager assigns lead to Field Agent in Bangalore East territory.
  5. Field Agent receives instant Phoenix push notification and sees lead in their active mobile pipeline.
- **Verification Assertions:**
  - Audit trail contains 3 chronological events: `LEAD_INGESTED`, `LEAD_QUALIFIED`, `LEAD_ASSIGNED`.
  - Field agent query immediately returns the assigned lead.
  - Telecaller boundary prevents viewing leads once assigned away.

---

### Journey 2: Client Requirement Matching to Property Shortlist
- **Actors:** Field Agent, Prospective Buyer, Property Catalog.
- **Workflow:**
  1. Agent registers new client requirement (Budget: 1.5 Cr – 2.2 Cr, 3 BHK, Whitefield).
  2. System executes `RequirementFilterEngine` and ranks matching inventory properties.
  3. Agent selects top 3 matching properties and generates a client property booklet.
  4. Agent schedules a site visit for Saturday 10:00 AM.
- **Verification Assertions:**
  - `RequirementFilterEngine` matches properties strictly within the budget tolerance and micromarket filter.
  - Site visit appointment record created with foreign key linkage to both Requirement and Property.
  - Calendar event synced to agent's local offline Isar store.

---

### Journey 3: Offline Site Visit Completion & Deal Closing
- **Actors:** Field Agent (Offline), Sales Manager, Finance/Admin.
- **Workflow:**
  1. Field Agent enters basement parking of commercial property (device loses cellular connectivity).
  2. Agent marks site visit as completed, records client feedback, and enqueues negotiated offer in Isar outbox.
  3. Agent exits basement; device re-establishes 5G connection.
  4. Sync Engine automatically flushes local outbox in chronological sequence.
  5. Server accepts update, updates stage to `DEAL_WON`, and triggers commission calculation.
- **Verification Assertions:**
  - Zero data loss during offline duration.
  - Outbox transitions: `PENDING` -> `SYNCING` -> `SYNCED`.
  - Commission KPI recalculated and cached in Redis.

---

### Journey 4: Telecaller High-Velocity Dialing Session
- **Actors:** Telecaller, Dialing Campaign Engine.
- **Workflow:**
  1. Telecaller starts dialing session for "Sarjapur Luxury Villas" campaign.
  2. Next lead claimed atomically using `SELECT ... FOR UPDATE SKIP LOCKED`.
  3. Call initiated; call duration recorded (2m 14s).
  4. Telecaller marks outcome as `INTERESTED - SCHEDULE CALLBACK`.
  5. Next lead immediately rendered without dashboard screen reload.
- **Verification Assertions:**
  - Lock prevents double-assignment across multiple telecallers.
  - Connect rate KPI incremented accurately.
  - Next call loaded within < 100ms.

---

### Journey 5: Bulk User Ingestion & Roster Provisioning
- **Actors:** Tenant Admin.
- **Workflow:**
  1. Tenant Admin uploads CSV containing 50 new agent accounts.
  2. Pre-validation checks emails, phones, and role validity.
  3. Database batch-inserts users and assigns default permissions.
  4. Durable outbox creates 50 welcome email tasks.
- **Verification Assertions:**
  - Transaction atomicity: invalid row in CSV rejects batch or reports surgical row-level errors.
  - Audit log records bulk upload event with user count and file hash.
  - Zero cross-tenant user assignment.
