# 11 — DATABASE RESTORATION & INTEGRITY VERIFICATION RUNBOOK

## 1. Scope & Security Guardrails
**STRICT WARNING:** Database restore into a live production database while traffic is being served is strictly prohibited. Restores are permitted only during emergency disaster recovery windows or when synchronizing local/staging development databases.

The backend enforces programmatic guardrails:
- `SnapshotService.restoreSnapshotToLocal` verifies `APP_ENV !== "production"`. Any execution in production triggers an immediate HTTP 403 / application exception.

## 2. Pre-Restore Safety Procedure
Before executing any database restore:
1. **Create Safety Dump:**
   ```bash
   node -e "import('./src/services/snapshot.service.js').then(s => s.SnapshotService.createLocalSafetyBackup({ id: 'manual-pre-restore' }))"
   ```
2. **Verify Checksum of Target Dump:**
   Compute SHA-256 of the backup file to guarantee it is not corrupted:
   ```bash
   node -e "import('./src/services/snapshot.service.js').then(async s => console.log(await s.SnapshotService.computeFileSha256(process.argv[1])))" /path/to/dumpfile.dump
   ```

## 3. Database Restoration Execution Steps
1. **Stop Incoming HTTP Traffic:**
   ```bash
   docker compose stop backend
   ```
2. **Execute Database Restore via pg_restore:**
   ```bash
   pg_restore --clean --if-exists --no-owner --no-privileges -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" "/path/to/backup.dump"
   ```
3. **Execute Additive Schema Synchronization:**
   ```bash
   node -e "import('./src/config/ensureAdditiveSchema.js').then(s => s.ensureAdditiveSchema())"
   ```
4. **Restart Backend Service:**
   ```bash
   docker compose start backend
   ```
5. **Run Post-Restore Smoke Verification:**
   ```bash
   node scripts/smoke_test.js
   ```
