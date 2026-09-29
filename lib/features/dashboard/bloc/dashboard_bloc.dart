import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../models/dashboard_summary.dart';
import '../models/kpi_models.dart';
import '../repository/dashboard_repository.dart';
import '../services/dashboard_service.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final KpiFilterParams? initialFilters;

  const LoadDashboard({this.initialFilters});

  @override
  List<Object?> get props => [initialFilters];
}

class RefreshDashboard extends DashboardEvent {}

class LoadDashboardKpis extends DashboardEvent {
  final KpiFilterParams filters;

  const LoadDashboardKpis({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class UpdateKpiFilter extends DashboardEvent {
  final String? businessType;
  final String? dateFilter;
  final String? startDate;
  final String? endDate;
  final String? leadType;

  const UpdateKpiFilter({
    this.businessType,
    this.dateFilter,
    this.startDate,
    this.endDate,
    this.leadType,
  });

  @override
  List<Object?> get props => [businessType, dateFilter, startDate, endDate, leadType];
}

class ToggleKpiConfig extends DashboardEvent {
  final String kpiKey;
  final bool isEnabled;

  const ToggleKpiConfig({
    required this.kpiKey,
    required this.isEnabled,
  });

  @override
  List<Object?> get props => [kpiKey, isEnabled];
}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoadedState extends DashboardState {
  final DashboardData data;
  final DashboardKpisResponse? kpis;
  final KpiFilterParams kpiFilters;
  final bool isKpiLoading;

  const DashboardLoadedState({
    required this.data,
    this.kpis,
    this.kpiFilters = const KpiFilterParams(),
    this.isKpiLoading = false,
  });

  DashboardLoadedState copyWith({
    DashboardData? data,
    DashboardKpisResponse? kpis,
    KpiFilterParams? kpiFilters,
    bool? isKpiLoading,
  }) {
    return DashboardLoadedState(
      data: data ?? this.data,
      kpis: kpis ?? this.kpis,
      kpiFilters: kpiFilters ?? this.kpiFilters,
      isKpiLoading: isKpiLoading ?? this.isKpiLoading,
    );
  }

  @override
  List<Object?> get props => [data, kpis, kpiFilters, isKpiLoading];
}

class DashboardRefreshing extends DashboardState {
  final DashboardData data;
  final DashboardKpisResponse? kpis;
  final KpiFilterParams kpiFilters;

  const DashboardRefreshing({
    required this.data,
    this.kpis,
    this.kpiFilters = const KpiFilterParams(),
  });

  @override
  List<Object?> get props => [data, kpis, kpiFilters];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _dashboardRepository;
  final DashboardService _dashboardService = DashboardService();
  StreamSubscription? _dashboardSubscription;

  DashboardBloc({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard, transformer: _sequential());
    on<RefreshDashboard>(_onRefreshDashboard, transformer: _sequential());
    on<LoadDashboardKpis>(_onLoadDashboardKpis, transformer: _sequential());
    on<UpdateKpiFilter>(_onUpdateKpiFilter, transformer: _sequential());
    on<ToggleKpiConfig>(_onToggleKpiConfig, transformer: _sequential());

    _dashboardSubscription = RepositoryCoordinator().dashboardStream.listen((_) {
      add(const LoadDashboard());
    });
  }

  EventTransformer<E> _sequential<E>() {
    return (events, mapper) => events.asyncExpand(mapper);
  }

  @override
  Future<void> close() {
    _dashboardSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    KpiFilterParams currentFilters = const KpiFilterParams();
    DashboardKpisResponse? existingKpis;

    if (currentState is DashboardLoadedState) {
      currentFilters = event.initialFilters ?? currentState.kpiFilters;
      existingKpis = currentState.kpis;
    } else if (currentState is DashboardRefreshing) {
      currentFilters = event.initialFilters ?? currentState.kpiFilters;
      existingKpis = currentState.kpis;
    } else {
      currentFilters = event.initialFilters ?? const KpiFilterParams();
      emit(DashboardLoading());
    }

    try {
      final futures = await Future.wait([
        _dashboardRepository.getDashboardData(),
        _dashboardService.getDashboardKpis(currentFilters),
      ]);

      final data = futures[0] as DashboardData;
      final kpis = futures[1] as DashboardKpisResponse;

      emit(DashboardLoadedState(
        data: data,
        kpis: kpis,
        kpiFilters: currentFilters,
        isKpiLoading: false,
      ));
    } catch (e) {
      if (currentState is DashboardLoadedState) {
        emit(currentState.copyWith(isKpiLoading: false));
      } else if (currentState is DashboardRefreshing) {
        emit(DashboardLoadedState(
          data: currentState.data,
          kpis: currentState.kpis ?? existingKpis,
          kpiFilters: currentState.kpiFilters,
          isKpiLoading: false,
        ));
      } else {
        emit(DashboardError(message: e.toString()));
      }
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    KpiFilterParams currentFilters = const KpiFilterParams();
    DashboardKpisResponse? existingKpis;

    if (currentState is DashboardLoadedState) {
      currentFilters = currentState.kpiFilters;
      existingKpis = currentState.kpis;
      emit(DashboardRefreshing(
        data: currentState.data,
        kpis: existingKpis,
        kpiFilters: currentFilters,
      ));
    } else {
      emit(DashboardLoading());
    }

    try {
      final futures = await Future.wait([
        _dashboardRepository.getDashboardData(forceRefresh: true),
        _dashboardService.getDashboardKpis(currentFilters),
      ]);

      final data = futures[0] as DashboardData;
      final kpis = futures[1] as DashboardKpisResponse;

      emit(DashboardLoadedState(
        data: data,
        kpis: kpis,
        kpiFilters: currentFilters,
        isKpiLoading: false,
      ));
    } catch (e) {
      if (currentState is DashboardLoadedState) {
        emit(DashboardLoadedState(
          data: currentState.data,
          kpis: currentState.kpis,
          kpiFilters: currentState.kpiFilters,
          isKpiLoading: false,
        ));
      } else {
        emit(DashboardError(message: e.toString()));
      }
    }
  }

  Future<void> _onLoadDashboardKpis(
    LoadDashboardKpis event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is DashboardLoadedState) {
      // Retain existing data and KPI counts while marking loading - ZERO flickering
      emit(currentState.copyWith(
        kpiFilters: event.filters,
        isKpiLoading: true,
      ));

      try {
        final kpis = await _dashboardService.getDashboardKpis(event.filters);
        emit(currentState.copyWith(
          kpis: kpis,
          kpiFilters: event.filters,
          isKpiLoading: false,
        ));
      } catch (_) {
        emit(currentState.copyWith(isKpiLoading: false));
      }
    } else if (currentState is DashboardRefreshing) {
      emit(DashboardLoadedState(
        data: currentState.data,
        kpis: currentState.kpis,
        kpiFilters: event.filters,
        isKpiLoading: true,
      ));
      try {
        final kpis = await _dashboardService.getDashboardKpis(event.filters);
        emit(DashboardLoadedState(
          data: currentState.data,
          kpis: kpis,
          kpiFilters: event.filters,
          isKpiLoading: false,
        ));
      } catch (_) {
        emit(DashboardLoadedState(
          data: currentState.data,
          kpis: currentState.kpis,
          kpiFilters: event.filters,
          isKpiLoading: false,
        ));
      }
    }
  }

  Future<void> _onUpdateKpiFilter(
    UpdateKpiFilter event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    KpiFilterParams current = const KpiFilterParams();
    if (currentState is DashboardLoadedState) {
      current = currentState.kpiFilters;
    } else if (currentState is DashboardRefreshing) {
      current = currentState.kpiFilters;
    }

    final updated = current.copyWith(
      businessType: event.businessType,
      dateFilter: event.dateFilter,
      startDate: event.startDate,
      endDate: event.endDate,
      leadType: event.leadType,
    );

    add(LoadDashboardKpis(filters: updated));
  }

  Future<void> _onToggleKpiConfig(
    ToggleKpiConfig event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoadedState) return;

    final existingKpis = currentState.kpis;
    if (existingKpis == null) return;

    final updatedConfig = existingKpis.config.map((c) {
      if (c.kpiKey == event.kpiKey) {
        return c.copyWith(isEnabled: event.isEnabled);
      }
      return c;
    }).toList();

    final optimisticKpis = DashboardKpisResponse(
      config: updatedConfig,
      counts: existingKpis.counts,
      filters: existingKpis.filters,
    );

    emit(currentState.copyWith(kpis: optimisticKpis));

    // Persist to backend
    final payload = updatedConfig.map((c) => c.toJson()).toList();
    final ok = await _dashboardService.updateKpiConfig(payload);
    if (!ok) {
      // Revert if failed
      emit(currentState.copyWith(kpis: existingKpis));
    } else {
      // Refetch KPIs to reflect any enabled/disabled changes
      add(LoadDashboardKpis(filters: currentState.kpiFilters));
    }
  }
}
