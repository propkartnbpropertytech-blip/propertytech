import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../design_system/widgets/dialogs.dart';

/// Intercepts the mobile system back button inside the signed-in app:
/// pop one route at a time, then return to [homeLocation], then confirm before exit.
/// Does not log the user out or change session timeout.
class MobileSystemBackHandler extends StatefulWidget {
  final Widget child;
  final Future<bool> Function()? onBeforeBack;
  final String homeLocation;

  const MobileSystemBackHandler({
    super.key,
    required this.child,
    this.onBeforeBack,
    this.homeLocation = '/dashboard',
  });

  @override
  State<MobileSystemBackHandler> createState() => _MobileSystemBackHandlerState();
}

class _MobileSystemBackHandlerState extends State<MobileSystemBackHandler> {
  bool _isHandlingBack = false;

  bool _isHomeLocation(String location) {
    final home = widget.homeLocation;
    if (location == home) return true;
    if (home == '/dashboard' && location.startsWith('/dashboard')) return true;
    return false;
  }

  Future<void> _handleBack() async {
    if (_isHandlingBack || !mounted) return;
    _isHandlingBack = true;
    try {
      if (widget.onBeforeBack != null) {
        final handled = await widget.onBeforeBack!();
        if (handled) return;
      }

      if (context.canPop()) {
        context.pop();
        return;
      }

      final location = GoRouterState.of(context).matchedLocation;
      if (!_isHomeLocation(location)) {
        context.go(widget.homeLocation);
        return;
      }

      final shouldExit = await CRMDialogs.showExitAppDialog(context);
      if (shouldExit == true && mounted) {
        await SystemNavigator.pop();
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return PopScope(
      canPop: !isMobile,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !isMobile) return;
        await _handleBack();
      },
      child: widget.child,
    );
  }
}
