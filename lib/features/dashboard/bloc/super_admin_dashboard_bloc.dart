import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/super_admin_platform_overview.dart';
import '../repository/super_admin_dashboard_repository.dart';

abstract class SuperAdminDashboardEvent extends Equatable {
  const SuperAdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadSuperAdminDashboard extends SuperAdminDashboardEvent {
  const LoadSuperAdminDashboard();
}

class RefreshSuperAdminDashboard extends SuperAdminDashboardEvent {
  const RefreshSuperAdminDashboard();
}

class SelectSuperAdminOrganization extends SuperAdminDashboardEvent {
  final String organizationId;

  const SelectSuperAdminOrganization(this.organizationId);

  @override
  List<Object?> get props => [organizationId];
}

abstract class SuperAdminDashboardState extends Equatable {
  const SuperAdminDashboardState();

  @override
  List<Object?> get props => [];
}

class SuperAdminDashboardInitial extends SuperAdminDashboardState {
  const SuperAdminDashboardInitial();
}

class SuperAdminDashboardLoading extends SuperAdminDashboardState {
  const SuperAdminDashboardLoading();
}

class SuperAdminDashboardLoaded extends SuperAdminDashboardState {
  final SuperAdminPlatformOverview overview;
  final String? selectedOrganizationId;
  final bool isRefreshing;

  const SuperAdminDashboardLoaded({
    required this.overview,
    this.selectedOrganizationId,
    this.isRefreshing = false,
  });

  SuperAdminDashboardLoaded copyWith({
    SuperAdminPlatformOverview? overview,
    String? selectedOrganizationId,
    bool? isRefreshing,
  }) {
    return SuperAdminDashboardLoaded(
      overview: overview ?? this.overview,
      selectedOrganizationId: selectedOrganizationId ?? this.selectedOrganizationId,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [overview, selectedOrganizationId, isRefreshing];
}

class SuperAdminDashboardError extends SuperAdminDashboardState {
  final String message;

  const SuperAdminDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class SuperAdminDashboardBloc extends Bloc<SuperAdminDashboardEvent, SuperAdminDashboardState> {
  final SuperAdminDashboardRepository repository;

  SuperAdminDashboardBloc({required this.repository}) : super(const SuperAdminDashboardInitial()) {
    on<LoadSuperAdminDashboard>(_onLoad);
    on<RefreshSuperAdminDashboard>(_onRefresh);
    on<SelectSuperAdminOrganization>(_onSelect);
  }

  Future<void> _onLoad(
    LoadSuperAdminDashboard event,
    Emitter<SuperAdminDashboardState> emit,
  ) async {
    emit(const SuperAdminDashboardLoading());
    await _emitFetch(emit, organizationId: null);
  }

  Future<void> _onRefresh(
    RefreshSuperAdminDashboard event,
    Emitter<SuperAdminDashboardState> emit,
  ) async {
    final current = state;
    final selectedId = current is SuperAdminDashboardLoaded ? current.selectedOrganizationId : null;
    if (current is SuperAdminDashboardLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _emitFetch(emit, organizationId: selectedId);
  }

  Future<void> _onSelect(
    SelectSuperAdminOrganization event,
    Emitter<SuperAdminDashboardState> emit,
  ) async {
    final current = state;
    if (current is SuperAdminDashboardLoaded) {
      emit(current.copyWith(
        selectedOrganizationId: event.organizationId,
        isRefreshing: true,
      ));
    } else {
      emit(const SuperAdminDashboardLoading());
    }
    await _emitFetch(emit, organizationId: event.organizationId);
  }

  Future<void> _emitFetch(
    Emitter<SuperAdminDashboardState> emit, {
    required String? organizationId,
  }) async {
    try {
      final overview = await repository.fetch(organizationId: organizationId);
      emit(SuperAdminDashboardLoaded(
        overview: overview,
        selectedOrganizationId: organizationId,
      ));
    } on SuperAdminDashboardLoadException catch (e) {
      emit(SuperAdminDashboardError(message: e.message));
    } catch (e) {
      emit(SuperAdminDashboardError(message: e.toString()));
    }
  }
}
