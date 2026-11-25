# Change Plan: Library + Employees New_UI

## 1. Task Metadata
- **Task Title**: Implement Library hub + Employees list New_UI from HTML prototypes with working actions
- **Target Subsystem**: Flutter Presentation (Library, Users/Employees)
- **Assigned Agent Role**: Frontend Engineer

## 2. Objective & Scope
- Match `library.html` hub and `employees.html` list visually.
- Every visible button must call an existing working path (navigate, BLoC event, Dio, or url_launcher). No decorative dead controls.
- **Non-Goals**: Full rewrite of rental/resale/service vault internals; inventing document persistence APIs; employee detail page redesign; push.

## 3. Files Allowed to Change
- `lib/features/library/screens/library_main_screen.dart`
- `lib/features/library/widgets/library_hub_*` (new tokens/widgets)
- `lib/features/users/screens/users_screen.dart` (layout chrome only; keep dialogs/BLoC)
- `lib/features/users/widgets/employees_*` (new tokens/widgets)

## 4. Action wiring (must remain live)
### Library hub
| Control | Wire to |
|---|---|
| Open vault / folder row / Open vault → | `context.go` rental/resale/service-agent library |
| Upload | Dialog → vault route with `?upload=1` (vault opens existing upload dialog) |
| Request documents | Dialog → WhatsApp `url_launcher` checklist |

### Employees
| Control | Wire to |
|---|---|
| Add Employee / Add administrator | `_showAddEditUserDialog` (+ Admin role when possible) |
| Edit / Delete / Login toggle | Existing dialogs + `ToggleUserStatusRequested` |
| Open profile / side panel CTAs | `_openEmployeePage` / `tel:` / edit dialog |
| Lead allocation rules | `context.go('/admin/lead-allocation')` if permitted |
| Password requests Reset | `_showResetPasswordDialog` |
| KPI / role / login chips | Drive `_selectedRoleId` / `_selectedStatus` + `_triggerFetch` |
| Show login-off banner | Set status filter Inactive |

## 5. Verification
- `flutter analyze` on touched files
- Manual: each header/table/side action fires existing path
