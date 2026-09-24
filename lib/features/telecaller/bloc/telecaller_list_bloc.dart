import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/security/role_guard.dart';
import '../../integration/services/integration_service.dart';
import '../data/telecaller_repository.dart';

abstract class TelecallerListEvent extends Equatable {
  const TelecallerListEvent();
  @override
  List<Object?> get props => [];
}

class TelecallerCallbacksRequested extends TelecallerListEvent {
  final String? search;
  final String? from;
  final String? to;
  final String? source;
  const TelecallerCallbacksRequested({this.search, this.from, this.to, this.source});
  @override
  List<Object?> get props => [search, from, to, source];
}

class TelecallerCnrRequested extends TelecallerListEvent {
  final String? search;
  final String? from;
  final String? to;
  final String? source;
  const TelecallerCnrRequested({this.search, this.from, this.to, this.source});
  @override
  List<Object?> get props => [search, from, to, source];
}

class TelecallerLeadRemoved extends TelecallerListEvent {
  final String leadId;
  const TelecallerLeadRemoved(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class TelecallerListState extends Equatable {
  final bool loading;
  final String? error;
  final List<dynamic> items;
  const TelecallerListState({
    this.loading = false,
    this.error,
    this.items = const [],
  });
  @override
  List<Object?> get props => [loading, error, items];
}

class TelecallerCallbacksBloc extends Bloc<TelecallerListEvent, TelecallerListState> {
  TelecallerCallbacksBloc({TelecallerRepository? repository})
      : _repository = repository ?? TelecallerRepository(),
        super(const TelecallerListState(loading: true)) {
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((_) {
      add(const TelecallerCallbacksRequested());
    });

    on<TelecallerCallbacksRequested>((event, emit) async {
      emit(TelecallerListState(loading: true, items: state.items));
      try {
        final items = _keptForCurrentTelecaller(await _repository.callbacks(
          search: event.search,
          from: event.from,
          to: event.to,
          source: event.source,
        ));
        emit(TelecallerListState(items: items));
      } catch (e) {
        emit(TelecallerListState(error: e.toString(), items: state.items));
      }
    });

    on<TelecallerLeadRemoved>((event, emit) {
      final filtered = state.items.where((raw) {
        final id = (raw is Map ? (raw['lead_id'] ?? raw['id']) : null)?.toString();
        return id != event.leadId;
      }).toList();
      emit(TelecallerListState(items: filtered, loading: false));
    });
  }

  final TelecallerRepository _repository;
  StreamSubscription? _leadEventsSub;

  @override
  Future<void> close() {
    _leadEventsSub?.cancel();
    return super.close();
  }
}

class TelecallerCnrBloc extends Bloc<TelecallerListEvent, TelecallerListState> {
  TelecallerCnrBloc({TelecallerRepository? repository})
      : _repository = repository ?? TelecallerRepository(),
        super(const TelecallerListState(loading: true)) {
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((_) {
      add(const TelecallerCnrRequested());
    });

    on<TelecallerCnrRequested>((event, emit) async {
      emit(TelecallerListState(loading: true, items: state.items));
      try {
        final items = _keptForCurrentTelecaller(await _repository.cnr(
          search: event.search,
          from: event.from,
          to: event.to,
          source: event.source,
        ));
        emit(TelecallerListState(items: items));
      } catch (e) {
        emit(TelecallerListState(error: e.toString(), items: state.items));
      }
    });

    on<TelecallerLeadRemoved>((event, emit) {
      final filtered = state.items.where((raw) {
        final id = (raw is Map ? (raw['id'] ?? raw['lead_id']) : null)?.toString();
        return id != event.leadId;
      }).toList();
      emit(TelecallerListState(items: filtered, loading: false));
    });
  }

  final TelecallerRepository _repository;
  StreamSubscription? _leadEventsSub;

  @override
  Future<void> close() {
    _leadEventsSub?.cancel();
    return super.close();
  }
}

List<dynamic> _keptForCurrentTelecaller(List<dynamic> items) {
  if (!RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) return items;
  final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
  if (myId == null || myId.isEmpty) return items;
  return items.where((raw) {
    if (raw is! Map) return true;
    final id = (raw['lead_id'] ?? raw['campaign_lead_id'] ?? raw['campaignLeadId'] ?? raw['id'])
        ?.toString();
    if (id == null || id.isEmpty) return true;
    final local = IntegrationService().getLeadById(id);
    if (local == null) return true;
    final assigned = local.assignedTelecallerId?.trim().toLowerCase();
    if (assigned == null || assigned.isEmpty) return true;
    return assigned == myId;
  }).toList();
}
