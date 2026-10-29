# 10 — Security regression

| Check | Result |
| :--- | :--- |
| Old published sheet token | Rejected when `SHEET_SYNC_TOKEN` is set. Covered by `test/sync.auth.scope.test.js` and by the rotation script |
| JWT signed with the old fallback secret | Rejected |
| JWT signed with the application secret | Accepted |
| Sheet feed without an organization | 400 |
| Sheet query organization that disagrees with the JWT organization | 403 |
| Report query organization that disagrees with Admin or Broker | 403 |
| Report user with no organization | 400 |
| Broker platform permissions | Denied by the permission map |
| Export without an organization id | 400, and the query is not run |
| Sheet and export 500 bodies | No longer include the driver message |
| Current tree search for the old token | Only the negative test remains |

Production `SHEET_SYNC_TOKEN`, CI secrets, and the Google Sheet script were not updated from this session.
