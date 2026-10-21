# PROPKART — DATABASE ACCESS STRATEGY & DRIVER ARCHITECTURE
**Version:** 1.0.0  
**Status:** CANONICAL DATABASE ENGINEERING SPECIFICATION (STEP 2)  
**Date:** October 20, 2026  
**Scope:** PostgreSQL Drivers, Transaction Boundaries, Supabase vs pg.Pool Convergence  

---

## 1. Executive Summary & Driver Landscape

In PropKart, database operations currently utilize two distinct client drivers:
1. **`dbPool` (`pg.Pool` in `src/config/dbPool.js`):** Native Node-Postgres connection pool using the binary PostgreSQL protocol (`pgwire`).
2. **`supabase` (`@supabase/supabase-js` in `src/config/supabase.js`):** REST API client interacting with PostgreSQL via PostgREST HTTP endpoints using the service role key.

```
========================================================================================================================
                                DATABASE DRIVER COMPARISON MATRIX
========================================================================================================================
  Feature                        Native dbPool (pg.Pool)                Supabase JS Client (PostgREST)
------------------------------------------------------------------------------------------------------------------------
  Protocol                       Binary PostgreSQL Protocol (Socket)    HTTP/1.1 REST JSON Over Head
  Latency Overhead               Minimal (~0.1 ms socket latency)       HTTP Serialization (~5–15 ms)
  ACID Multi-Table Transactions  Native (`BEGIN ... COMMIT / ROLLBACK`) NOT SUPPORTED across REST calls
  Row Locking (`SKIP LOCKED`)    Full Support (`FOR UPDATE SKIP LOCKED`) NOT SUPPORTED via REST
  Connection Pool Control        Explicit (size, timeouts, drains)      Managed by external PostgREST server
  Complex Joins & Aggregations   Full SQL Syntax                        PostgREST Resource Embedding syntax
  Primary Use Case               Transactions, Ingestion, Ledgers       Single-table CRUD, Auth, Storage
========================================================================================================================
```

---

## 2. The Danger of Driver Fragmentation & Mixed Boundaries

### 2.1 The Distributed Atomicity Hazard
When an API endpoint performs a multi-step mutation (e.g. `leadIngestEngine` creating a lead, logging an assignment history record, and scheduling an initial callback):
- If Step 1 uses `supabase.from('leads').insert()`,
- And Step 2 uses `dbPool.query('INSERT INTO lead_assignment_history ...')`,
- And Step 2 fails:
**Step 1 CANNOT BE ROLLED BACK.** The database is left in a corrupted, half-applied state with orphan leads lacking audit history.

### 2.2 The Permanent Transaction Rule
> **RULE:** Any business operation touching more than one table, or requiring row-level locking, MUST use `withTransaction` from `src/config/dbPool.js`. Mixing Supabase REST calls with native SQL in the same business flow is strictly prohibited.

---

## 3. Transaction Engineering Standards (`withTransaction`)

PropKart provides a hardened transaction wrapper supporting automatic commit, rollback, and nested savepoints:

```javascript
import { withTransaction } from "../config/dbPool.js";

export async function transferLead(leadId, fromTelecallerId, toTelecallerId, reason, adminId) {
  return await withTransaction(async (client) => {
    // 1. Lock the lead row to prevent concurrent reassignment
    const leadRes = await client.query(
      `SELECT id, organization_id, stage FROM public.leads 
       WHERE id = $1 FOR UPDATE`,
      [leadId]
    );
    if (leadRes.rows.length === 0) {
      throw new NotFoundError("Lead does not exist");
    }

    // 2. Update lead assignment
    await client.query(
      `UPDATE public.leads 
       SET assigned_telecaller_id = $1, telecaller_assigned_at = NOW(), updated_at = NOW() 
       WHERE id = $2`,
      [toTelecallerId, leadId]
    );

    // 3. Append immutable audit ledger
    await client.query(
      `INSERT INTO public.lead_assignment_history 
       (lead_id, organization_id, from_telecaller_id, to_telecaller_id, assignment_type, reason, assigned_by) 
       VALUES ($1, $2, $3, $4, 'MANUAL_REASSIGN', $5, $6)`,
      [leadId, leadRes.rows[0].organization_id, fromTelecallerId, toTelecallerId, reason, adminId]
    );

    return { success: true };
  });
}
```

### 3.1 Benefits of `withTransaction`
- Automatic `BEGIN` and `COMMIT`.
- Automatic `ROLLBACK` on any thrown error or unhandled promise rejection.
- Automatic release of connection socket back to pool, preventing connection leaks.
- Supports nested savepoints via `withSavepoint(client, name, fn)`.

---

## 4. Architectural Convergence Roadmap

To eliminate driver fragmentation across the codebase:
1. **Repository Layer Decoupling:** All data access must reside inside dedicated repositories (`DashboardRepository`, `RequirementsRepository`, `LeadsRepository`). Controllers must never invoke SQL or Supabase directly.
2. **Gradual Migration to `dbPool`:** Because `dbPool` provides native binary speeds, statement timeouts, and complete transaction control, new repositories must be authored exclusively on `dbPool`.
3. **Supabase Client Scoping:** Restrict `@supabase/supabase-js` solely to:
   - Supabase Auth session token verification (if needed).
   - Supabase S3-compatible Object Storage for image uploads.
