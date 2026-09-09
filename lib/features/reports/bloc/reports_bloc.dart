import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';
import '../models/report_filter_state.dart';
import '../repository/reports_repository.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository _reportsRepository;
  StreamSubscription? _requirementsSub;

  ReportsBloc({ReportsRepository? reportsRepository})
      : _reportsRepository = reportsRepository ?? ReportsRepository(),
        super(ReportsInitial(config: ReportConfiguration.initial())) {
    on<LoadReportEvent>(_onLoadReport);
    on<UpdateDateRangeEvent>(_onUpdateDateRange);
    on<UpdateFiltersEvent>(_onUpdateFilters);
    on<ResetFiltersEvent>(_onResetFilters);
    on<ToggleSectionEvent>(_onToggleSection);
    on<UpdateKpiConfigEvent>(_onUpdateKpiConfig);
    on<ToggleKpiMetricEvent>(_onToggleKpiMetric);
    on<UpdateComparisonConfigEvent>(_onUpdateComparisonConfig);
    on<UpdateTrendConfigEvent>(_onUpdateTrendConfig);

    // Reactive subscription to local data changes
    _requirementsSub = RepositoryCoordinator().requirementsStream.listen((_) {
      add(const LoadReportEvent());
    });
  }

  @override
  Future<void> close() {
    _requirementsSub?.cancel();
    return super.close();
  }

  Future<void> _onLoadReport(
    LoadReportEvent event,
    Emitter<ReportsState> emit,
  ) async {
    ReportConfiguration config = state.config;
    ReportOverallData? prevData;

    if (state is ReportsLoaded) {
      prevData = (state as ReportsLoaded).data;
    }

    if (state is ReportsInitial) {
      config = await _reportsRepository.loadConfiguration();
    }

    emit(ReportsLoading(config: config, previousData: prevData));

    try {
      final data = await _reportsRepository.getReportData(config);
      emit(ReportsLoaded(config: config, data: data));
    } catch (e) {
      emit(ReportsError(config: config, message: e.toString(), previousData: prevData));
    }
  }

  Future<void> _onUpdateDateRange(
    UpdateDateRangeEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(dateRange: event.dateRange);
    await _reportsRepository.saveDateRangePreference(event.dateRange);
    await _recomputeWithConfig(updatedConfig, emit);
  }

  Future<void> _onUpdateFilters(
    UpdateFiltersEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(filters: event.filters);
    await _reportsRepository.saveFiltersPreference(event.filters);
    await _recomputeWithConfig(updatedConfig, emit);
  }

  Future<void> _onResetFilters(
    ResetFiltersEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(filters: const ReportFilterState.empty());
    await _reportsRepository.saveFiltersPreference(const ReportFilterState.empty());
    await _recomputeWithConfig(updatedConfig, emit);
  }

  Future<void> _onToggleSection(
    ToggleSectionEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(
      showLeadStatusPipeline: event.showPipeline,
      showConversionFunnel: event.showFunnel,
      showFollowupAnalysis: event.showFollowup,
      showTeamRanking: event.showTeamRanking,
      showBusinessInsights: event.showInsights,
      showGrowthComparison: event.showGrowth,
      showLeadSourceAnalysis: event.showLeadSource,
      showTrendAnalysis: event.showTrend,
    );
    final needsRecompute = (event.showGrowth == true && !state.config.showGrowthComparison) ||
        (event.showTrend == true && !state.config.showTrendAnalysis) ||
        (event.showLeadSource == true && !state.config.showLeadSourceAnalysis);

    await _reportsRepository.saveSectionVisibilities(
      showGrowthComparison: updatedConfig.showGrowthComparison,
      showLeadSourceAnalysis: updatedConfig.showLeadSourceAnalysis,
      showTrendAnalysis: updatedConfig.showTrendAnalysis,
      showLeadStatusPipeline: updatedConfig.showLeadStatusPipeline,
      showConversionFunnel: updatedConfig.showConversionFunnel,
      showFollowupAnalysis: updatedConfig.showFollowupAnalysis,
      showTeamRanking: updatedConfig.showTeamRanking,
      showBusinessInsights: updatedConfig.showBusinessInsights,
    );

    if (state is ReportsLoaded && !needsRecompute) {
      final currentData = (state as ReportsLoaded).data;
      emit(ReportsLoaded(config: updatedConfig, data: currentData));
    } else {
      await _recomputeWithConfig(updatedConfig, emit);
    }
  }

  Future<void> _onUpdateKpiConfig(
    UpdateKpiConfigEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(kpiConfigs: event.kpiConfigs);
    await _reportsRepository.saveKpiConfiguration(event.kpiConfigs);

    if (state is ReportsLoaded) {
      final currentData = (state as ReportsLoaded).data;
      emit(ReportsLoaded(config: updatedConfig, data: currentData));
    } else {
      await _recomputeWithConfig(updatedConfig, emit);
    }
  }

  Future<void> _onToggleKpiMetric(
    ToggleKpiMetricEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final configs = List<ReportKpiConfig>.from(state.config.kpiConfigs);
    final idx = configs.indexWhere((k) => k.type == event.kpiType);
    if (idx != -1) {
      final current = configs[idx];
      final newShowCount = event.showCount ?? current.showCount;
      final newShowPercentage = event.showPercentage ?? current.showPercentage;

      // Ensure at least one toggle remains enabled
      if (newShowCount || newShowPercentage) {
        configs[idx] = current.copyWith(
          showCount: newShowCount,
          showPercentage: newShowPercentage,
        );
        final updatedConfig = state.config.copyWith(kpiConfigs: configs);
        await _reportsRepository.saveKpiConfiguration(configs);

        if (state is ReportsLoaded) {
          final currentData = (state as ReportsLoaded).data;
          emit(ReportsLoaded(config: updatedConfig, data: currentData));
        } else {
          await _recomputeWithConfig(updatedConfig, emit);
        }
      }
    }
  }

  Future<void> _onUpdateComparisonConfig(
    UpdateComparisonConfigEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(
      comparisonPeriod: event.period,
      customComparisonStart: event.customStart,
      customComparisonEnd: event.customEnd,
    );
    await _recomputeWithConfig(updatedConfig, emit);
  }

  Future<void> _onUpdateTrendConfig(
    UpdateTrendConfigEvent event,
    Emitter<ReportsState> emit,
  ) async {
    final updatedConfig = state.config.copyWith(
      trendMetric: event.metric,
      trendGranularity: event.granularity,
    );
    await _recomputeWithConfig(updatedConfig, emit);
  }

  Future<void> _recomputeWithConfig(
    ReportConfiguration newConfig,
    Emitter<ReportsState> emit,
  ) async {
    ReportOverallData? prevData;
    if (state is ReportsLoaded) {
      prevData = (state as ReportsLoaded).data;
    }
    emit(ReportsLoading(config: newConfig, previousData: prevData));

    try {
      final data = await _reportsRepository.getReportData(newConfig);
      emit(ReportsLoaded(config: newConfig, data: data));
    } catch (e) {
      emit(ReportsError(config: newConfig, message: e.toString(), previousData: prevData));
    }
  }
}
