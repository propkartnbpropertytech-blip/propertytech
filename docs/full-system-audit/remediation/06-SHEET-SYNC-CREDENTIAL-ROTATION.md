# 06 — Sheet sync credential rotation

## Local

`.env.local` is gitignored. `SHEET_SYNC_TOKEN` was replaced with a new 64-character random value. The value was not printed.

In the same process, the old published token was rejected and the new token was accepted.

The setup guide and the Google Sheet connector now use the placeholders `SET_SHEET_SYNC_TOKEN` and `SET_ORGANIZATION_UUID`. The only remaining copy of the old token in the current tree is the negative test that asserts it is rejected.

## Not done

The running Docker API was not recreated, so a process started before this rotation still has its previous environment. Production, CI secrets, and the live Google Sheet script were not changed from this machine. Set the new token there and restart the API before using the sheet connector.

`.env.local.example` documents the variable with an empty value.
