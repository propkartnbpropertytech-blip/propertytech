# Implementation Report: Library + Employees New_UI

## Summary
Restyled Library hub (`library.html`) and Employees list (`employees.html`) with New_UI chrome. Every visible control is wired to an existing working path (vault navigation + upload dialog, WhatsApp request, UsersBloc CRUD, lead-allocation route). No push.

## Files
- `lib/features/library/screens/library_main_screen.dart` (rewrite)
- `lib/features/library/widgets/library_hub/*` (new)
- `lib/features/users/screens/users_screen.dart` (chrome + wiring; dialogs/BLoC preserved)
- `lib/features/users/widgets/employees_ui/*` (new)
- Change plan under `docs/ai-agent/change-plans/`

## Action wiring
### Library
- Open vault / folder / Open vault → → `/rental-library` | `/resale-library` | `/service-agent-library`
- Upload → dialog → vault with `autoOpenUpload: true` (existing rental/resale dialog); service opens vault + snackbar to use Add agent
- Request documents → WhatsApp via `url_launcher`

### Employees
- Add Employee / Add administrator → `_showAddEditUserDialog`
- Edit / Remove / Login toggle → existing dialogs + `ToggleUserStatusRequested`
- Call / Open profile → `tel:` / `/users/:id`
- Lead allocation rules → `/admin/lead-allocation` when permitted
- KPI + role/login chips → `_selectedRoleId` / `_selectedStatus` + `_triggerFetch`
- Login-off banner Show them → Inactive filter
- Password requests tab → unchanged `_showResetPasswordDialog`

## Verification
- `flutter analyze` on touched Library + Employees paths: **No issues found**
