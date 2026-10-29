# 14 — Integration Audit

| Integration | Where | Proven |
| :--- | :--- | :--- |
| PostgreSQL | `pg` pool and PostgREST | Local API was healthy earlier on port 5001 |
| Redis | `ioredis` | Not stopped on purpose |
| Google Sheet live connector | `docs/GOOGLE_SHEET_LIVE_CONNECTOR.js` | Token placeholder and organization id added. Not run inside Google |
| Excel workbook | `exceljs` on the live feed | Not downloaded |
| Mail | mailer module, portal URL commit `75dbab6` | Not sent |
| Push / device tokens | notifications and device token tables | Not sent |
| Hostinger deploy | `.github/workflows/deploy.yml` | Workflow file is on `main` but observed runs were zero-job failures. Production VPS was not shown to be updated |

No payment gateway, SMS, or map provider was verified beyond references in code. If one is configured only in production env, it was not called.
