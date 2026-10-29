# 09 — End-to-end verification

The full click path from ingestion through won was not executed in the UI.

What was executed in PostgreSQL, then rolled back:

- A linked requirement and lead already existed.
- Setting the requirement to Follow-up and updating the lead to stage `SALES` left the requirement on Follow-up.
- The same check for Interested left the requirement on Interested.
- Both preserve triggers are present on the database that also has migration 82's sync function.

Allocation of a live lead was not run. The capacity proof locked a telecaller row from a second session and rolled back.

Report screens call the report API. They were not opened in a browser.
