# Implementation Report — Support New UI (Step 2)

## Summary
Support page restyled on `New_UI` to match `support.html`, with existing SupportService / RBAC / IssueDetailsDrawer preserved. **Not pushed.**

## Files
- `lib/features/support/screens/support_screen.dart`
- `lib/features/support/widgets/support_ui/support_tokens.dart`
- `lib/features/support/widgets/support_ui/support_widgets.dart`
- Change plan + this report under `docs/ai-agent/`

## UX mapping
| HTML | Flutter |
|---|---|
| Hero + Raise a ticket | SuHeroBanner (scrolls to form; RBAC gated) |
| KPI strip | Clickable SuKpiStrip filters |
| WhatsApp / Call / Email | SuContactWays + url_launcher |
| Raise ticket form | Inline form → SupportNavigationRegistry + SupportService.createIssue |
| My tickets | Styled list → IssueDetailsDrawer |
| Quick answers FAQ | SuFaqSection |

## Packages
Existing only: `url_launcher`, `image_picker`, Cloudinary uploader.

## Verification
- flutter analyze (scoped)
- flutter test test/support/role_based_support_issue_reporting_test.dart
