import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:propkart/features/requirements/repository/requirements_repository.dart';
import '../data/telecaller_repository.dart';

abstract class TelecallerLeadsEvent extends Equatable {
  const TelecallerLeadsEvent();
  @override
  List<Object?> get props => [];
}

class TelecallerLeadsRequested extends TelecallerLeadsEvent {}

class TelecallerStartCallRequested extends TelecallerLeadsEvent {
  final String leadId;
  const TelecallerStartCallRequested(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class TelecallerOutcomeRequested extends TelecallerLeadsEvent {
  final String leadId;
  final String outcome;
  final String? remarks;
  final String? salesUserId;
  final String? callbackAt;
  const TelecallerOutcomeRequested({
    required this.leadId,
    required this.outcome,
    this.remarks,
    this.salesUserId,
    this.callbackAt,
  });
  @override
  List<Object?> get props => [leadId, outcome, remarks, salesUserId, callbackAt];
}

class TelecallerLeadsState extends Equatable {
  final bool loading;
  final String? error;
  final String? info;
  final List<dynamic> leads;
  final List<dynamic> oldUntouchedLeads;
  const TelecallerLeadsState({
    this.loading = false,
    this.error,
    this.info,
    this.leads = const [],
    this.oldUntouchedLeads = const [],
  });
  TelecallerLeadsState copyWith({
    bool? loading,
    String? error,
    String? info,
    List<dynamic>? leads,
    List<dynamic>? oldUntouchedLeads,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return TelecallerLeadsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      info: clearInfo ? null : (info ?? this.info),
      leads: leads ?? this.leads,
      oldUntouchedLeads: oldUntouchedLeads ?? this.oldUntouchedLeads,
    );
  }

  @override
  List<Object?> get props => [loading, error, info, leads, oldUntouchedLeads];
}

class TelecallerLeadsBloc extends Bloc<TelecallerLeadsEvent, TelecallerLeadsState> {
  TelecallerLeadsBloc({TelecallerRepository? repository})
      : _repository = repository ?? TelecallerRepository(),
        super(const TelecallerLeadsState(loading: true)) {
    on<TelecallerLeadsRequested>(_onLoad);
    on<TelecallerStartCallRequested>(_onStart);
    on<TelecallerOutcomeRequested>(_onOutcome);
  }

  final TelecallerRepository _repository;

  Future<void> _onLoad(
    TelecallerLeadsRequested event,
    Emitter<TelecallerLeadsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    try {
      final results = await Future.wait([
        _repository.myLeads(isOldUntouched: false),
        _repository.myLeads(isOldUntouched: true),
      ]);
      emit(state.copyWith(
        loading: false,
        leads: results[0],
        oldUntouchedLeads: results[1],
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString(), clearInfo: true));
    }
  }

  Future<void> _onStart(
    TelecallerStartCallRequested event,
    Emitter<TelecallerLeadsState> emit,
  ) async {
    try {
      await _repository.startCall(event.leadId);
      emit(state.copyWith(info: 'Call authorized', clearError: true));
      add(TelecallerLeadsRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString(), clearInfo: true));
    }
  }

  Future<void> _onOutcome(
    TelecallerOutcomeRequested event,
    Emitter<TelecallerLeadsState> emit,
  ) async {
    try {
      await _repository.recordOutcome(
        event.leadId,
        outcome: event.outcome,
        remarks: event.remarks,
        salesUserId: event.salesUserId,
        callbackAt: event.callbackAt,
      );
      emit(state.copyWith(info: 'Outcome saved: ${event.outcome}', clearError: true));
      if (event.outcome == 'PICKED_UP') {
        unawaited(RequirementsRepository().getRequirements(refreshFromServer: true));
      }
      add(TelecallerLeadsRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString(), clearInfo: true));
    }
  }
}
