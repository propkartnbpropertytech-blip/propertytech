import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'report_kpi_type.dart';
import 'report_date_range.dart';
import 'report_filter_state.dart';

class ReportKpiConfig extends Equatable {
  final ReportKpiType type;
  final bool isEnabled;
  final int order;
  final bool showCount;
  final bool showPercentage;

  const ReportKpiConfig({
    required this.type,
    this.isEnabled = true,
    required this.order,
    this.showCount = true,
    this.showPercentage = false,
  });

  ReportKpiConfig copyWith({
    ReportKpiType? type,
    bool? isEnabled,
    int? order,
    bool? showCount,
    bool? showPercentage,
  }) {
    // Rule: At least one of count or percentage must remain enabled
    final newShowCount = showCount ?? this.showCount;
    final newShowPercentage = showPercentage ?? this.showPercentage;
    if (!newShowCount && !newShowPercentage) {
      // Reject invalid state where both are off
      return this;
    }

    return ReportKpiConfig(
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
      showCount: newShowCount,
      showPercentage: newShowPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'isEnabled': isEnabled,
      'order': order,
      'showCount': showCount,
      'showPercentage': showPercentage,
    };
  }

  factory ReportKpiConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? '';
    final type = ReportKpiType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => ReportKpiType.totalLeads,
    );
    return ReportKpiConfig(
      type: type,
      isEnabled: json['isEnabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      showCount: json['showCount'] as bool? ?? true,
      showPercentage: json['showPercentage'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [type, isEnabled, order, showCount, showPercentage];
}

enum GrowthComparisonPeriod {
  previousDay,
  previousWeek,
  previousMonth,
  previousYear,
  customPeriod;

  String get displayName {
    switch (this) {
      case GrowthComparisonPeriod.previousDay:
        return 'Previous Day';
      case GrowthComparisonPeriod.previousWeek:
        return 'Previous Week';
      case GrowthComparisonPeriod.previousMonth:
        return 'Previous Month';
      case GrowthComparisonPeriod.previousYear:
        return 'Previous Year';
      case GrowthComparisonPeriod.customPeriod:
        return 'Custom Comparison Period';
    }
  }
}

enum TrendGranularity {
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case TrendGranularity.daily:
        return 'Daily';
      case TrendGranularity.weekly:
        return 'Weekly';
      case TrendGranularity.monthly:
        return 'Monthly';
    }
  }
}

class ReportConfiguration extends Equatable {
  final ReportDateRange dateRange;
  final ReportFilterState filters;
  final List<ReportKpiConfig> kpiConfigs;

  // Section Visibilities
  final bool showLeadStatusPipeline; // default ON
  final bool showConversionFunnel;   // default ON
  final bool showFollowupAnalysis;   // default ON
  final bool showTeamRanking;        // default ON
  final bool showBusinessInsights;   // default ON
  final bool showGrowthComparison;   // default OFF
  final bool showLeadSourceAnalysis; // default OFF
  final bool showTrendAnalysis;      // default OFF

  // Growth & Comparison config
  final GrowthComparisonPeriod comparisonPeriod;
  final DateTime? customComparisonStart;
  final DateTime? customComparisonEnd;

  // Trend config
  final ReportKpiType trendMetric;
  final TrendGranularity trendGranularity;

  const ReportConfiguration({
    required this.dateRange,
    this.filters = const ReportFilterState.empty(),
    required this.kpiConfigs,
    this.showLeadStatusPipeline = true,
    this.showConversionFunnel = true,
    this.showFollowupAnalysis = true,
    this.showTeamRanking = true,
    this.showBusinessInsights = true,
    this.showGrowthComparison = false,
    this.showLeadSourceAnalysis = false,
    this.showTrendAnalysis = false,
    this.comparisonPeriod = GrowthComparisonPeriod.previousMonth,
    this.customComparisonStart,
    this.customComparisonEnd,
    this.trendMetric = ReportKpiType.totalLeads,
    this.trendGranularity = TrendGranularity.daily,
  });

  /// Generate default configuration
  factory ReportConfiguration.initial() {
    final List<ReportKpiConfig> defaultKpis = [];
    for (int i = 0; i < ReportKpiType.values.length; i++) {
      defaultKpis.add(
        ReportKpiConfig(
          type: ReportKpiType.values[i],
          isEnabled: true,
          order: i,
          showCount: true,
          showPercentage: false,
        ),
      );
    }

    return ReportConfiguration(
      dateRange: ReportDateRange.currentMonth(),
      filters: const ReportFilterState.empty(),
      kpiConfigs: defaultKpis,
    );
  }

  /// Get enabled KPIs in order
  List<ReportKpiConfig> get sortedEnabledKpis {
    final list = kpiConfigs.where((k) => k.isEnabled).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  ReportConfiguration copyWith({
    ReportDateRange? dateRange,
    ReportFilterState? filters,
    List<ReportKpiConfig>? kpiConfigs,
    bool? showLeadStatusPipeline,
    bool? showConversionFunnel,
    bool? showFollowupAnalysis,
    bool? showTeamRanking,
    bool? showBusinessInsights,
    bool? showGrowthComparison,
    bool? showLeadSourceAnalysis,
    bool? showTrendAnalysis,
    GrowthComparisonPeriod? comparisonPeriod,
    DateTime? customComparisonStart,
    DateTime? customComparisonEnd,
    ReportKpiType? trendMetric,
    TrendGranularity? trendGranularity,
  }) {
    return ReportConfiguration(
      dateRange: dateRange ?? this.dateRange,
      filters: filters ?? this.filters,
      kpiConfigs: kpiConfigs ?? this.kpiConfigs,
      showLeadStatusPipeline: showLeadStatusPipeline ?? this.showLeadStatusPipeline,
      showConversionFunnel: showConversionFunnel ?? this.showConversionFunnel,
      showFollowupAnalysis: showFollowupAnalysis ?? this.showFollowupAnalysis,
      showTeamRanking: showTeamRanking ?? this.showTeamRanking,
      showBusinessInsights: showBusinessInsights ?? this.showBusinessInsights,
      showGrowthComparison: showGrowthComparison ?? this.showGrowthComparison,
      showLeadSourceAnalysis: showLeadSourceAnalysis ?? this.showLeadSourceAnalysis,
      showTrendAnalysis: showTrendAnalysis ?? this.showTrendAnalysis,
      comparisonPeriod: comparisonPeriod ?? this.comparisonPeriod,
      customComparisonStart: customComparisonStart ?? this.customComparisonStart,
      customComparisonEnd: customComparisonEnd ?? this.customComparisonEnd,
      trendMetric: trendMetric ?? this.trendMetric,
      trendGranularity: trendGranularity ?? this.trendGranularity,
    );
  }

  String serializeKpiPreferences() {
    final list = kpiConfigs.map((k) => k.toJson()).toList();
    return jsonEncode(list);
  }

  static List<ReportKpiConfig>? deserializeKpiPreferences(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((item) => ReportKpiConfig.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        dateRange,
        filters,
        kpiConfigs,
        showLeadStatusPipeline,
        showConversionFunnel,
        showFollowupAnalysis,
        showTeamRanking,
        showBusinessInsights,
        showGrowthComparison,
        showLeadSourceAnalysis,
        showTrendAnalysis,
        comparisonPeriod,
        customComparisonStart,
        customComparisonEnd,
        trendMetric,
        trendGranularity,
      ];
}
