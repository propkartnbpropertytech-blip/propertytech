# Component Inventory

| Component | Path | Notes |
|-----------|------|-------|
| CRMButton | widgets/buttons.dart | Press scale + primary glow |
| CRMCard / CRMKPICard | widgets/cards.dart | Elevated option, thin borders |
| CRMTextField | widgets/inputs.dart | Theme-aware |
| CRMDialogs | widgets/dialogs.dart | Glass blur dialogs |
| CRMStatusChip | widgets/crm_status_chips.dart | Soft semantic pills |
| CRMEmptyState | widgets/empty_state.dart | |
| CRMErrorState | widgets/crm_error_state.dart | |
| CRMNoInternet | widgets/crm_no_internet.dart | |
| CRMPermissionDenied | widgets/crm_permission_denied.dart | |
| CRMSkeleton* | widgets/skeletons.dart | Dark-mode aware |
| CRMGlassSurface | widgets/crm_glass_surface.dart | NEW |
| CRMAppShell | widgets/app_shell.dart | Glass top bar, soft sidebar |
| CRMDataTable | widgets/data_table.dart + crm_data_table.dart | Soft chrome |
| Form suite | widgets/form/* | Currency, date, phone, pickers… |
| PremiumButton/TextField | theme/app_theme.dart | Auth; CRM-backed |

## Screens restyled

Auth: Splash, Login  
Shell: CRMAppShell  
Dashboard (+ StatusPieChartPainter)  
Properties, Add/Edit Property, Detail, Recycle Bin  
Requirements, Add/Edit Requirement, Share, Public Detail  
Clients, Owners, Builders, Users  
Profile, Settings, Audit Logs, Sync Debug  

## Unrouted (left alone)

Home prototype, Pipeline Kanban
