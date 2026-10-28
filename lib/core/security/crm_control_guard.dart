import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'access_control_bloc.dart';

/// Declarative widget that conditionally renders its child based on dynamic PBAC permissions.
/// Defaults to Option A: Completely Hidden (SizedBox.shrink) when permission is denied.
class CrmControlGuard extends StatelessWidget {
  final String? controlKey;
  final List<String>? controlKeys;
  final bool matchAll;
  final Widget child;
  final Widget fallback;

  const CrmControlGuard({
    super.key,
    this.controlKey,
    this.controlKeys,
    this.matchAll = false,
    required this.child,
    this.fallback = const SizedBox.shrink(), // Option A: Hidden
  }) : assert(
          controlKey != null || controlKeys != null,
          'Must provide either controlKey or controlKeys',
        );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccessControlBloc, AccessControlState>(
      builder: (context, state) {
        if (state is AccessControlLoaded) {
          bool allowed = false;
          if (controlKey != null) {
            allowed = state.can(controlKey!);
          } else if (controlKeys != null) {
            allowed = matchAll
                ? state.canAll(controlKeys!)
                : state.canAny(controlKeys!);
          }

          if (allowed) {
            return child;
          }
        }
        return fallback;
      },
    );
  }
}

/// Convenience extension on BuildContext for quick programmatic permission checks
extension AccessControlContextX on BuildContext {
  bool can(String controlKey) {
    final state = watch<AccessControlBloc>().state;
    if (state is AccessControlLoaded) {
      return state.can(controlKey);
    }
    return false;
  }

  bool canAny(List<String> controlKeys) {
    final state = watch<AccessControlBloc>().state;
    if (state is AccessControlLoaded) {
      return state.canAny(controlKeys);
    }
    return false;
  }
}
