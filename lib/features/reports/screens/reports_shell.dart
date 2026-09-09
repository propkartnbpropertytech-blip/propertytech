import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
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

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: Column(
        children: [
          // Persistent Subshell Navigation
          ReportsSubshellNav(currentPath: location),

          // Child Screen Content
          Expanded(child: child),
        ],
      ),
    );
  }
}
