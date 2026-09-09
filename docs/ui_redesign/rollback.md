# Rollback Instructions

## Instant restore on the redesign branch

```bash
git log --oneline
git revert <sha>
# or hard reset only if you know the tip is unpushed and safe:
# git reset --hard <good-sha>
```

## Return to last committed `main`

```bash
git switch main
```

## Tag

- `ui-pre-redesign` → `69ba9339f93c0836c8bcaf5a991c50533a1892e0`

**Important:** When the tag was created, most of `lib/core` and `lib/features` existed only in the working tree (untracked). Prefer reverting commits on `redesign/apple-inspired-ui` to undo UI work. Checking out the tag alone will not restore a pre-redesign CRM tree that was never committed.

## Partial file restore

```bash
git checkout HEAD~1 -- path/to/file.dart
```

## Branch policy

- Redesign lives on `redesign/apple-inspired-ui`
- Do not merge to `main` until light/dark + mobile/desktop smoke QA passes
- Never force-push `main`
- Keep `ui-pre-redesign` until redesign is validated
