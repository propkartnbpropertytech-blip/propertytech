# Final recommendations

1. Restart the local API so it reads the new `SHEET_SYNC_TOKEN`, then set that same new value in production and in the Google Sheet script properties. Do not put the value back into git.

2. Move location and property-type scoring into the same shared contract as the budget score, and stop calculating a second match in Flutter.

3. Add a unique organization-and-phone rule, or an insert conflict path, so two ingest requests cannot create two people.

4. Reject requirement statuses outside the pipeline list in the database, and make the transition check use that list.

5. Open the sales report, property report, and one Broker login in the app and confirm the API returns 403 for a telecaller.

6. Do not treat the unused Flutter websocket as realtime until the API exposes a socket. HTTP delta sync is the path that runs today.
