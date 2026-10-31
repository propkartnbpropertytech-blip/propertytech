import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/security/permission_matrix_service.dart';
import '../../../core/security/role_guard.dart';
import '../widgets/reports_subshell_nav.dart';

class ReportsShell extends StatelessWidget {
  final Widget child;

  const ReportsShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final actionKey = ReportsSubshellNav.actionKeyForPath(location);

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: Column(
        children: [
          // Persistent Subshell Navigation
          ReportsSubshellNav(currentPath: location),

          // Child Screen Content
          Expanded(
            child: ListenableBuilder(
              listenable: PermissionMatrixService.instance,
              builder: (context, _) => actionKey == null || RoleGuard.canAction(actionKey)
                  ? child
                  : const _ReportDisabledNotice(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDisabledNotice extends StatelessWidget {
  const _ReportDisabledNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 40, color: CRMColors.textSecondaryOf(context)),
            const SizedBox(height: 12),
            Text(
              'This report has been disabled by Super Admin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: CRMColors.textSecondaryOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}
