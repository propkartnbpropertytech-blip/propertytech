import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../integration/services/integration_service.dart';
import '../data/telecaller_repository.dart';

abstract class TelecallerDashboardEvent extends Equatable {
  const TelecallerDashboardEvent();
  @override
  List<Object?> get props => [];
}

class TelecallerDashboardRequested extends TelecallerDashboardEvent {}

class TelecallerAvailabilityChanged extends TelecallerDashboardEvent {
  final String status;
  const TelecallerAvailabilityChanged(this.status);
  @override
  List<Object?> get props => [status];
}

class TelecallerDashboardState extends Equatable {
  final bool loading;
  final String? error;
  final Map<String, dynamic> data;
  const TelecallerDashboardState({
    this.loading = false,
    this.error,
    this.data = const {},
  });
  TelecallerDashboardState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? data,
    bool clearError = false,
  }) {
    return TelecallerDashboardState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [loading, error, data];
}

class TelecallerDashboardBloc
    extends Bloc<TelecallerDashboardEvent, TelecallerDashboardState> {
  TelecallerDashboardBloc({TelecallerRepository? repository})
      : _repository = repository ?? TelecallerRepository(),
        super(const TelecallerDashboardState(loading: true)) {
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((_) {
      add(TelecallerDashboardRequested());
    });

    on<TelecallerDashboardRequested>(_onLoad);
    on<TelecallerAvailabilityChanged>(_onAvailability);
  }

  final TelecallerRepository _repository;
  StreamSubscription? _leadEventsSub;

  @override
  Future<void> close() {
    _leadEventsSub?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    TelecallerDashboardRequested event,
    Emitter<TelecallerDashboardState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final data = await _repository.dashboard();
      emit(state.copyWith(loading: false, data: data, clearError: true));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onAvailability(
    TelecallerAvailabilityChanged event,
    Emitter<TelecallerDashboardState> emit,
  ) async {
    try {
      await _repository.setAvailability(event.status);
      add(TelecallerDashboardRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
