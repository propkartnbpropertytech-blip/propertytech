import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../api/dio_client.dart';

// ── Events ─────────────────────────────────────────────────────────────
abstract class AccessControlEvent extends Equatable {
  const AccessControlEvent();
  @override
  List<Object?> get props => [];
}

class LoadAccessControlsEvent extends AccessControlEvent {
  const LoadAccessControlsEvent();
}

class RefreshAccessControlsEvent extends AccessControlEvent {
  const RefreshAccessControlsEvent();
}

class ClearAccessControlsEvent extends AccessControlEvent {
  const ClearAccessControlsEvent();
}

// ── States ─────────────────────────────────────────────────────────────
abstract class AccessControlState extends Equatable {
  const AccessControlState();
  @override
  List<Object?> get props => [];
}

class AccessControlInitial extends AccessControlState {
  const AccessControlInitial();
}

class AccessControlLoading extends AccessControlState {
  const AccessControlLoading();
}

class AccessControlLoaded extends AccessControlState {
  final Set<String> controls;
  final bool isSuperAdmin;
  final String role;
  final DateTime updatedAt;

  const AccessControlLoaded({
    required this.controls,
    required this.isSuperAdmin,
    required this.role,
    required this.updatedAt,
  });

  bool can(String controlKey) {
    if (isSuperAdmin) return true;
    if (controls.contains('*')) return true;
    return controls.contains(controlKey);
  }

  bool canAny(List<String> keys) {
    if (isSuperAdmin) return true;
    return keys.any(can);
  }

  bool canAll(List<String> keys) {
    if (isSuperAdmin) return true;
    return keys.every(can);
  }

  @override
  List<Object?> get props => [controls, isSuperAdmin, role, updatedAt];
}

class AccessControlError extends AccessControlState {
  final String message;
  const AccessControlError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ───────────────────────────────────────────────────────────────
class AccessControlBloc extends Bloc<AccessControlEvent, AccessControlState> {
  static AccessControlBloc? _instance;
  static AccessControlBloc get instance => _instance ??= AccessControlBloc();

  AccessControlBloc() : super(const AccessControlInitial()) {
    on<LoadAccessControlsEvent>(_onLoadAccessControls);
    on<RefreshAccessControlsEvent>(_onLoadAccessControls);
    on<ClearAccessControlsEvent>(_onClearAccessControls);
  }

  Future<void> _onLoadAccessControls(
    AccessControlEvent event,
    Emitter<AccessControlState> emit,
  ) async {
    try {
      final res = await DioClient.dio.get('/permissions/my-controls');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'] as Map<String, dynamic>? ?? {};
        final rawControls = data['controls'] as List<dynamic>? ?? [];
        final controls = rawControls.map((c) => c.toString()).toSet();
        final isSuperAdmin = data['isSuperAdmin'] == true;
        final role = data['role']?.toString() ?? 'Sales';

        emit(AccessControlLoaded(
          controls: controls,
          isSuperAdmin: isSuperAdmin,
          role: role,
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('[AccessControlBloc] Error loading controls: $e');
      // If error occurs, fall back to safe empty state or maintain previous state
      if (state is! AccessControlLoaded) {
        emit(AccessControlError(e.toString()));
      }
    }
  }

  void _onClearAccessControls(
    ClearAccessControlsEvent event,
    Emitter<AccessControlState> emit,
  ) {
    emit(const AccessControlInitial());
  }

  /// Synchronous helper to query permissions when Bloc instance is available
  bool can(String controlKey) {
    final s = state;
    if (s is AccessControlLoaded) {
      return s.can(controlKey);
    }
    return false;
  }
}
