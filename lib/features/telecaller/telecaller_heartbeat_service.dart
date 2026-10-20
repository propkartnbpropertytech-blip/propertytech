import 'package:flutter/widgets.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import 'services/telecaller_shift_manager.dart';

/// Consolidated Telecaller Heartbeat Service.
///
/// Eliminates the duplicate independent 30-second heartbeat timer by delegating
/// heartbeat lifecycle to the authoritative [TelecallerShiftManager].
class TelecallerHeartbeatService with WidgetsBindingObserver {
  TelecallerHeartbeatService._();
  static final TelecallerHeartbeatService instance = TelecallerHeartbeatService._();

  bool _started = false;

  bool get isRunning => _started && TelecallerShiftManager.instance.isHeartbeatActive;

  void start(AuthState authState) {
    final role = authState is Authenticated ? authState.user.role : '';
    if (role.toLowerCase() != 'telecaller') {
      stop();
      return;
    }
    if (_started) return;
    _started = true;
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // Ensure shift manager is initialized with user ID if authenticated
    if (authState is Authenticated) {
      TelecallerShiftManager.instance.init(authState.user.id);
    }
  }

  void stop() {
    if (_started) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    }
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      TelecallerShiftManager.instance.resumeFromBackground();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      TelecallerShiftManager.instance.pauseForBackground();
    }
  }
}
