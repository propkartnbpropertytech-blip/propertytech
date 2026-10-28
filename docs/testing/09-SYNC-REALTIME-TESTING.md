# 09 — Sync Engine & Realtime Communication Testing Standard

## 1. Scope & Architecture

PropKart provides offline-first mobility for field real estate agents combined with instant realtime synchronization for telecallers, managers, and admin consoles. This document defines the testing standards for the **Isar Offline Sync Engine**, **Durable Outbox Queue**, and **Phoenix WebSocket Realtime Subsystem**.

---

## 2. Sync Engine State Machine Verification

The Flutter Sync Engine operates as a formal finite state machine (FSM). All state transitions are verified by automated BLoC and service unit tests:

```
  ┌──────────────┐
  │     IDLE     │◄─────────────────────────────┐
  └──────┬───────┘                              │
         │ (Item Enqueued / Network Online)     │
         ▼                                      │
  ┌──────────────┐                              │
  │   SYNCING    │                              │
  └──────┬───────┘                              │
         │                                      │
    ┌────┴────────────────────────┬─────────────┴──────────┐
    ▼                             ▼                        ▼
┌──────────────┐          ┌──────────────┐         ┌──────────────┐
│    SYNCED    │          │   CONFLICT   │         │    ERROR     │
└──────────────┘          └──────┬───────┘         └──────┬───────┘
                                 │                        │
                                 ▼ (Resolution)           ▼ (Backoff Retry)
                          ┌──────────────┐         ┌──────────────┐
                          │   RESOLVED   │         │    RETRY     │
                          └──────────────┘         └──────────────┘
```

### Invariants Verified by Tests:
1. **FIFO Execution Order:** Items in the local outbox must be synchronized in strict chronological order based on `enqueued_at` timestamps.
2. **Atomic Batching:** Batches of updates are dispatched with a batch ID; failure of an atomic transaction causes the entire batch to revert to retry status.
3. **Network Flapping Resilience:** Rapid transitions between online, offline, and cellular states must not cause duplicate sync requests or race conditions.

---

## 3. Conflict Resolution Testing

When an entity is modified offline by an agent while simultaneously updated on the server (e.g., lead stage updated by telecaller), the sync engine applies strict conflict resolution rules:

### 3.1 Last-Write-Wins (LWW) with Monotonic Vector Timestamps
- Used for non-financial editable fields (notes, comments, client contact preference).
- Test verifies that if `clientTimestamp > serverUpdatedAt`, client update wins; otherwise server state is retained and client local cache updated.

### 3.2 Server-Authoritative Priority
- Used for critical business fields: `assigned_agent_id`, `lead_stage`, `payment_status`, and `contract_terms`.
- If a client attempts an offline overwrite of an already-advanced lead stage, the server rejects the field mutation, logs a conflict event in the audit trail, and instructs the client to adopt server state.

```dart
test('SyncEngine resolves lead stage conflict using server-authoritative rule', () async {
  final localChange = LocalLeadUpdate(
    leadId: 'lead-99',
    stage: 'SITE_VISIT_SCHEDULED',
    clientTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  final serverCurrentState = ServerLead(
    leadId: 'lead-99',
    stage: 'DEAL_LOST', // Advanced by manager
    serverUpdatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
  );

  final outcome = await syncEngine.resolveConflict(localChange, serverCurrentState);
  expect(outcome.acceptedStage, equals('DEAL_LOST'));
  expect(outcome.conflictLogged, isTrue);
});
```

---

## 4. Phoenix Realtime WebSocket Channel Testing

The backend distributes live updates across subscribed clients via Phoenix WebSocket channels.

### 4.1 Topic Authorization & Tenant Scoping
- Every channel topic is structured as `tenant:{tenant_id}:{resource}` (e.g., `tenant:tenant_alpha:leads`).
- Tests verify:
  1. A socket connection authorized as Tenant A is rejected with `403 Forbidden` if it attempts to join `tenant:tenant_beta:leads`.
  2. Events broadcast on Tenant A's channel are never delivered to sockets subscribed to Tenant B.

```javascript
describe('Phoenix Channel Realtime Authorization', () => {
  it('strictly rejects join attempt to cross-tenant lead topic', async () => {
    const socket = await connectTestSocket(tenantAUserToken);
    
    assert.rejects(
      () => socket.joinTopic('tenant:tenant_beta:leads'),
      /Unauthorized topic access/
    );
  });
});
```

### 4.2 Heartbeat & Reconnection Backoff
- Tests verify client socket sends regular heartbeat pings (`interval = 30s`).
- Disconnection triggers exponential backoff reconnection (`1s, 2s, 4s, 8s, up to max 30s`) with randomized jitter to prevent the "thundering herd" problem on the backend socket gateway.
