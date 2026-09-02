import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import '../models/dashboard_summary.dart';
import '../repository/dashboard_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class RefreshDashboard extends DashboardEvent {}

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

  const DashboardLoadedState({required this.data});

  @override
  List<Object?> get props => [data];
}

class DashboardRefreshing extends DashboardState {
  final DashboardData data;

  const DashboardRefreshing({required this.data});

  @override
  List<Object?> get props => [data];
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
  StreamSubscription? _dashboardSubscription;

  DashboardBloc({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard, transformer: _sequential());
    on<RefreshDashboard>(_onRefreshDashboard, transformer: _sequential());

    _dashboardSubscription = RepositoryCoordinator().dashboardStream.listen((_) {
      add(LoadDashboard());
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
    if (currentState is! DashboardLoadedState && currentState is! DashboardRefreshing) {
      emit(DashboardLoading());
    }
    try {
      final data = await _dashboardRepository.getDashboardData();
      emit(DashboardLoadedState(data: data));
    } catch (e) {
      if (currentState is DashboardLoadedState) {
        emit(DashboardLoadedState(data: currentState.data));
      } else if (currentState is DashboardRefreshing) {
        emit(DashboardLoadedState(data: currentState.data));
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
    if (currentState is DashboardLoadedState) {
      emit(DashboardRefreshing(data: currentState.data));
    } else {
      emit(DashboardLoading());
    }

    try {
      final data = await _dashboardRepository.getDashboardData();
      emit(DashboardLoadedState(data: data));
    } catch (e) {
      if (currentState is DashboardLoadedState) {
        emit(DashboardLoadedState(data: currentState.data));
      } else {
        emit(DashboardError(message: e.toString()));
      }
    }
  }
}
