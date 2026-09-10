import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'sync_manager.dart';
import '../utils/app_logger.dart';

// --- Events ---
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class StartPeriodicSync extends SyncEvent {
  final Duration interval;

  const StartPeriodicSync([this.interval = const Duration(seconds: 9)]);

  @override
  List<Object?> get props => [interval];
}

class StopPeriodicSync extends SyncEvent {}

class TriggerDatabasePing extends SyncEvent {}

class _PeriodicTickEvent extends SyncEvent {}

// --- States ---
abstract class SyncBlocState extends Equatable {
  const SyncBlocState();

  @override
  List<Object?> get props => [];
}

class SyncBlocInitial extends SyncBlocState {}

class SyncBlocPinging extends SyncBlocState {
  final DateTime startedAt;

  const SyncBlocPinging({required this.startedAt});

  @override
  List<Object?> get props => [startedAt];
}

class SyncBlocSuccess extends SyncBlocState {
  final DateTime lastPingAt;
  final int recordsUpdated;

  const SyncBlocSuccess({
    required this.lastPingAt,
    this.recordsUpdated = 0,
  });

  @override
  List<Object?> get props => [lastPingAt, recordsUpdated];
}

class SyncBlocFailure extends SyncBlocState {
  final String error;
  final DateTime lastPingAt;

  const SyncBlocFailure({
    required this.error,
    required this.lastPingAt,
  });

  @override
  List<Object?> get props => [error, lastPingAt];
}

// --- BLoC ---
class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  final SyncManager _syncManager;
  Timer? _periodicTimer;
  Duration _currentInterval = const Duration(seconds: 9);

  SyncBloc({SyncManager? syncManager})
      : _syncManager = syncManager ?? SyncManager(),
        super(SyncBlocInitial()) {
    on<StartPeriodicSync>(_onStartPeriodicSync);
    on<StopPeriodicSync>(_onStopPeriodicSync);
    on<TriggerDatabasePing>(_onTriggerDatabasePing);
    on<_PeriodicTickEvent>(_onPeriodicTick);
  }

  void _onStartPeriodicSync(StartPeriodicSync event, Emitter<SyncBlocState> emit) {
    _currentInterval = event.interval;
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(_currentInterval, (_) {
      if (!isClosed) add(_PeriodicTickEvent());
    });
    AppLogger.sync("SyncBloc: Started periodic database ping (${_currentInterval.inSeconds}s interval)");
  }

  void _onStopPeriodicSync(StopPeriodicSync event, Emitter<SyncBlocState> emit) {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    AppLogger.sync("SyncBloc: Stopped periodic database ping");
  }

  Future<void> _onPeriodicTick(_PeriodicTickEvent event, Emitter<SyncBlocState> emit) async {
    await _executePing(emit);
  }

  Future<void> _onTriggerDatabasePing(TriggerDatabasePing event, Emitter<SyncBlocState> emit) async {
    await _executePing(emit);
  }

  Future<void> _executePing(Emitter<SyncBlocState> emit) async {
    final pingStart = DateTime.now();
    try {
      final updatedCount = await _syncManager.pingDatabase();
      emit(SyncBlocSuccess(
        lastPingAt: pingStart,
        recordsUpdated: updatedCount,
      ));
    } catch (e) {
      AppLogger.w("SyncBloc: Database ping error (continuing on local cache): $e");
      emit(SyncBlocFailure(
        error: e.toString(),
        lastPingAt: pingStart,
      ));
    }
  }

  @override
  Future<void> close() {
    _periodicTimer?.cancel();
    return super.close();
  }
}
