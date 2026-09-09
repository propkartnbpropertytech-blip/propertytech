import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../design_system/widgets/dialogs.dart';

/// Intercepts the mobile system back button inside the signed-in app:
/// any page → Dashboard (home), then a confirm dialog to close the app.
/// Does not log the user out or change session timeout.
class MobileSystemBackHandler extends StatefulWidget {
  final Widget child;
  final Future<bool> Function()? onBeforeBack;

  const MobileSystemBackHandler({
    super.key,
    required this.child,
    this.onBeforeBack,
  });

  @override
  State<MobileSystemBackHandler> createState() => _MobileSystemBackHandlerState();
}

class _MobileSystemBackHandlerState extends State<MobileSystemBackHandler> {
  bool _isHandlingBack = false;

  bool _isHomeLocation(String location) {
    return location == '/dashboard' || location.startsWith('/dashboard');
  }

  Future<void> _handleBack() async {
    if (_isHandlingBack || !mounted) return;
    _isHandlingBack = true;
    try {
      if (widget.onBeforeBack != null) {
        final handled = await widget.onBeforeBack!();
        if (handled) return;
      }

      final location = GoRouterState.of(context).matchedLocation;
      if (!_isHomeLocation(location)) {
        context.go('/dashboard');
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
