# 10 — DATABASE BACKUP & DATA RETENTION STANDARD

## 1. Backup Strategy Overview
PropKart implements a multi-layered database protection policy:

```text
[ PostgreSQL Production Database ]
                 │
                 ├── 1. Continuous WAL Archiving (Point-in-Time Recovery)
                 │
                 ├── 2. Automated Daily Snapshot (Custom pg_dump with SHA-256)
                 │      (Stored in backups/snapshots/)
                 │
                 └── 3. Pre-Restore Safety Backups
                        (Created automatically before any schema/data reload)
```

## 2. Backup Execution Standards
1. **Format:** Compressed custom archive (`pg_dump --format=custom --compress=9`).
2. **Integrity Validation:** Every snapshot calculates and stores a 64-character SHA-256 cryptographic checksum alongside the dump file.
3. **Storage Isolation:** Backups are written to isolated volumes outside container root layers, with automated mirroring to off-site object storage.

## 3. Retention Policies
- **Daily Snapshots:** Retained for 30 days.
- **Weekly Snapshots:** Retained for 12 weeks.
- **Monthly Snapshots:** Retained for 12 months.
- **Pre-Restore Safety Backups:** Retained indefinitely in `backups/snapshots/safety_backups/`.
