import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import 'data/telecaller_repository.dart';

class TelecallerHeartbeatService with WidgetsBindingObserver {
  TelecallerHeartbeatService._();
  static final TelecallerHeartbeatService instance = TelecallerHeartbeatService._();

  final TelecallerRepository _repository = TelecallerRepository();
  Timer? _timer;
  bool _started = false;

  void start(AuthState authState) {
    final role = authState is Authenticated ? authState.user.role : '';
    if (role.toLowerCase() != 'telecaller') {
      stop();
      return;
    }
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _beat());
    _beat();
  }

  Future<void> _beat() async {
    try {
      await _repository.heartbeat();
    } catch (_) {}
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _beat();
    }
  }
}
