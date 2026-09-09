import 'package:equatable/equatable.dart';
import '../models/report_configuration.dart';
import '../models/report_date_range.dart';
import '../models/report_filter_state.dart';
import '../models/report_kpi_type.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportEvent extends ReportsEvent {
  final bool forceRefresh;

  const LoadReportEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class UpdateDateRangeEvent extends ReportsEvent {
  final ReportDateRange dateRange;

  const UpdateDateRangeEvent(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class UpdateFiltersEvent extends ReportsEvent {
  final ReportFilterState filters;

  const UpdateFiltersEvent(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ResetFiltersEvent extends ReportsEvent {}

class ToggleSectionEvent extends ReportsEvent {
  final bool? showPipeline;
  final bool? showFunnel;
  final bool? showFollowup;
  final bool? showTeamRanking;
  final bool? showInsights;
  final bool? showGrowth;
  final bool? showLeadSource;
  final bool? showTrend;

  const ToggleSectionEvent({
    this.showPipeline,
    this.showFunnel,
    this.showFollowup,
    this.showTeamRanking,
    this.showInsights,
    this.showGrowth,
    this.showLeadSource,
    this.showTrend,
  });

  @override
  List<Object?> get props => [
        showPipeline,
        showFunnel,
        showFollowup,
        showTeamRanking,
        showInsights,
        showGrowth,
        showLeadSource,
        showTrend,
      ];
}

class UpdateKpiConfigEvent extends ReportsEvent {
  final List<ReportKpiConfig> kpiConfigs;

  const UpdateKpiConfigEvent(this.kpiConfigs);

  @override
  List<Object?> get props => [kpiConfigs];
}

class ToggleKpiMetricEvent extends ReportsEvent {
  final ReportKpiType kpiType;
  final bool? showCount;
  final bool? showPercentage;

  const ToggleKpiMetricEvent({
    required this.kpiType,
    this.showCount,
    this.showPercentage,
  });

  @override
  List<Object?> get props => [kpiType, showCount, showPercentage];
}

class UpdateComparisonConfigEvent extends ReportsEvent {
  final GrowthComparisonPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;

  const UpdateComparisonConfigEvent({
    required this.period,
    this.customStart,
    this.customEnd,
  });

  @override
  List<Object?> get props => [period, customStart, customEnd];
}

class UpdateTrendConfigEvent extends ReportsEvent {
  final ReportKpiType? metric;
  final TrendGranularity? granularity;

  const UpdateTrendConfigEvent({
    this.metric,
    this.granularity,
  });

  @override
  List<Object?> get props => [metric, granularity];
}
