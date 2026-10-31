import 'package:flutter/widgets.dart';

import 'permission_matrix_service.dart';
import 'role_guard.dart';

/// Shows [child] only when the signed-in user may use [actionKey] (Role Drill-down toggle of their
/// role). Super Admin always sees [child]. Rebuilds when the permission matrix syncs.
class AdminActionGate extends StatelessWidget {
  final String actionKey;
  final Widget child;
  final Widget fallback;

  const AdminActionGate({
    super.key,
    required this.actionKey,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PermissionMatrixService.instance,
      builder: (context, _) => RoleGuard.canAction(actionKey) ? child : fallback,
    );
  }
}

/// Rebuilds [builder] with whether [actionKey] is allowed, for widgets that disable instead of hide.
class AdminActionBuilder extends StatelessWidget {
  final String actionKey;
  final Widget Function(BuildContext context, bool allowed) builder;

  const AdminActionBuilder({super.key, required this.actionKey, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PermissionMatrixService.instance,
      builder: (context, _) => builder(context, RoleGuard.canAction(actionKey)),
    );
  }
}
