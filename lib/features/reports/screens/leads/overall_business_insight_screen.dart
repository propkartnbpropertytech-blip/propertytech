import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../bloc/reports_bloc.dart';
import '../../bloc/reports_event.dart';
import '../../bloc/reports_state.dart';
import '../../models/report_data.dart';
import '../../widgets/report_date_filter_bar.dart';
import '../../widgets/report_global_filters_bar.dart';
import '../../widgets/kpi_card_widget.dart';
import '../../widgets/kpi_expand_dialog.dart';
import '../../widgets/lead_status_pipeline_section.dart';
import '../../widgets/conversion_funnel_section.dart';
import '../../widgets/followup_analysis_section.dart';
import '../../widgets/team_ranking_section.dart';
import '../../widgets/business_insights_section.dart';
import '../../widgets/growth_comparison_section.dart';
import '../../widgets/lead_source_analysis_section.dart';
import '../../widgets/trend_analysis_section.dart';
import '../../widgets/report_export_menu.dart';
import '../../widgets/user_performance_summary_dialog.dart';

class OverallBusinessInsightScreen extends StatelessWidget {
  const OverallBusinessInsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<ReportsBloc>();
      return const _OverallBusinessInsightContent();
    } catch (_) {
      return BlocProvider(
        create: (context) => ReportsBloc()..add(const LoadReportEvent()),
        child: const _OverallBusinessInsightContent(),
      );
    }
  }
}

class _OverallBusinessInsightContent extends StatelessWidget {
  const _OverallBusinessInsightContent();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is ReportsError && state.previousData != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        },
        builder: (context, state) {
          final config = state.config;

          // 1. Initial or hard Loading state (no previous data)
          if (state is ReportsInitial || (state is ReportsLoading && state.previousData == null)) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading business analytics & pipeline data...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          // 2. Hard Error state (no previous data)
          if (state is ReportsError && state.previousData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 14),
                    const Text(
                      'Failed to load business reports',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<ReportsBloc>().add(const LoadReportEvent(forceRefresh: true));
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Loaded or soft refreshing state
          final ReportOverallData? reportData = (state is ReportsLoaded)
              ? state.data
              : (state is ReportsLoading
                  ? state.previousData
                  : (state is ReportsError ? state.previousData : null));

          if (reportData == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading business analytics & pipeline data...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          final isSoftLoading = state is ReportsLoading;
          final enabledKpis = config.sortedEnabledKpis;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReportsBloc>().add(const LoadReportEvent(forceRefresh: true));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: CRMBreakpoints.pagePadding(context),
                vertical: CRMSpacing.m,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: CRMBreakpoints.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Title & Export Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Overall Business Insight',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  if (isSoftLoading) ...[
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Executive overview of lead lifecycle, agent productivity, conversion funnel, and pipeline velocity.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              PopupMenuButton<String>(
                                tooltip: 'Analytical Sections Visibility',
                                offset: const Offset(0, 36),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                itemBuilder: (ctx) => [
                                  _buildSectionToggleItem(
                                    'Pipeline Velocity',
                                    config.showLeadStatusPipeline,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showPipeline: !config.showLeadStatusPipeline),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Conversion Funnel',
                                    config.showConversionFunnel,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showFunnel: !config.showConversionFunnel),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Follow-up Analysis',
                                    config.showFollowupAnalysis,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showFollowup: !config.showFollowupAnalysis),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Team Ranking',
                                    config.showTeamRanking,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showTeamRanking: !config.showTeamRanking),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Business Insights',
                                    config.showBusinessInsights,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showInsights: !config.showBusinessInsights),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Growth & Comparison',
                                    config.showGrowthComparison,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showGrowth: !config.showGrowthComparison),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Lead Sources',
                                    config.showLeadSourceAnalysis,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showLeadSource: !config.showLeadSourceAnalysis),
                                        ),
                                  ),
                                  _buildSectionToggleItem(
                                    'Trend Analysis',
                                    config.showTrendAnalysis,
                                    () => context.read<ReportsBloc>().add(
                                          ToggleSectionEvent(showTrend: !config.showTrendAnalysis),
                                        ),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.view_quilt_outlined,
                                        size: 16,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Sections',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ReportExportMenu(
                                reportData: reportData,
                                config: config,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.m),

                      // Filter Section: Date Filter Bar
                      ReportDateFilterBar(
                        activeRange: config.dateRange,
                        onRangeChanged: (newRange) {
                          context.read<ReportsBloc>().add(UpdateDateRangeEvent(newRange));
                        },
                      ),
                      const SizedBox(height: 10),

                      // Filter Section: Global Attributes Filter Bar
                      ReportGlobalFiltersBar(
                        filters: config.filters,
                        availableStatuses: reportData.availableStatuses,
                        availableSources: reportData.availableSources,
                        telecallers: reportData.availableTelecallers,
                        salesUsers: reportData.availableSalesUsers,
                        properties: reportData.availableProperties,
                        onFiltersChanged: (updated) {
                          context.read<ReportsBloc>().add(UpdateFiltersEvent(updated));
                        },
                        onResetFilters: () {
                          context.read<ReportsBloc>().add(ResetFiltersEvent());
                        },
                      ),
                      const SizedBox(height: CRMSpacing.m),

                      // KPI Header
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Key Performance Indicators',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${enabledKpis.length} / 13 Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.tune_rounded, size: 14),
                            label: const Text(
                              'Configure in Lead Metrics',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              context.go('/reports/leads/metrics');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Responsive KPI Cards Grid (Static executive display)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = CRMBreakpoints.kpiColumns(context);
                          final spacing = 12.0;
                          final cardWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: enabledKpis.map((kpiConfig) {
                              return SizedBox(
                                width: cardWidth,
                                child: KpiCardWidget(
                                  config: kpiConfig,
                                  value: reportData.kpiValues[kpiConfig.type],
                                  showToggles: false,
                                  onExpand: () {
                                    showDialog(
                                      context: context,
                                      builder: (dCtx) => KpiExpandDialog(
                                        kpiType: kpiConfig.type,
                                        reportData: reportData,
                                        config: config,
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: CRMSpacing.l),

                      // Section: Business Insights (Default ON)
                      if (config.showBusinessInsights) ...[
                        BusinessInsightsSection(insights: reportData.insights),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Lead Status Pipeline (Default ON)
                      if (config.showLeadStatusPipeline) ...[
                        LeadStatusPipelineSection(stages: reportData.pipelineStages),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Conversion Funnel (Default ON)
                      if (config.showConversionFunnel) ...[
                        ConversionFunnelSection(stages: reportData.funnelStages),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Follow-up Analysis (Default ON)
                      if (config.showFollowupAnalysis) ...[
                        FollowupAnalysisSection(categories: reportData.followupCategories),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Team Ranking (Default ON)
                      if (config.showTeamRanking) ...[
                        TeamRankingSection(
                          telecallerRankings: reportData.telecallerRankings,
                          salesRankings: reportData.salesRankings,
                          onUserSelected: (member) {
                            UserPerformanceSummaryDialog.show(
                              context,
                              userId: member.userId,
                              userName: member.userName,
                              role: member.role,
                              config: config,
                              allLeads: reportData.allLeads,
                              allFollowups: reportData.allFollowups,
                            );
                          },
                        ),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Growth & Comparison (Only shown if toggled ON in Lead Metrics)
                      if (config.showGrowthComparison) ...[
                        GrowthComparisonSection(
                          isVisible: config.showGrowthComparison,
                          activePeriod: config.comparisonPeriod,
                          customStart: config.customComparisonStart,
                          customEnd: config.customComparisonEnd,
                          comparisonItems: reportData.growthComparisonItems,
                          onToggleVisibility: (visible) {
                            context.read<ReportsBloc>().add(ToggleSectionEvent(showGrowth: visible));
                          },
                          onPeriodChanged: (newPeriod) {
                            context.read<ReportsBloc>().add(UpdateComparisonConfigEvent(period: newPeriod));
                          },
                          onCustomDatesChanged: (start, end) {
                            context.read<ReportsBloc>().add(
                                  UpdateComparisonConfigEvent(
                                    customStart: start,
                                    customEnd: end,
                                  ),
                                );
                          },
                        ),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Lead Source Distribution (Only shown if toggled ON in Lead Metrics)
                      if (config.showLeadSourceAnalysis) ...[
                        LeadSourceAnalysisSection(
                          isVisible: config.showLeadSourceAnalysis,
                          leadSources: reportData.leadSources,
                          onToggleVisibility: (visible) {
                            context.read<ReportsBloc>().add(ToggleSectionEvent(showLeadSource: visible));
                          },
                        ),
                        const SizedBox(height: CRMSpacing.l),
                      ],

                      // Section: Trend Analysis (Only shown if toggled ON in Lead Metrics)
                      if (config.showTrendAnalysis) ...[
                        TrendAnalysisSection(
                          isVisible: config.showTrendAnalysis,
                          selectedMetric: config.trendMetric,
                          selectedGranularity: config.trendGranularity,
                          trendPoints: reportData.trendPoints,
                          onToggleVisibility: (visible) {
                            context.read<ReportsBloc>().add(ToggleSectionEvent(showTrend: visible));
                          },
                          onMetricChanged: (newMetric) {
                            context.read<ReportsBloc>().add(UpdateTrendConfigEvent(metric: newMetric));
                          },
                          onGranularityChanged: (newGran) {
                            context.read<ReportsBloc>().add(UpdateTrendConfigEvent(granularity: newGran));
                          },
                        ),
                        const SizedBox(height: CRMSpacing.l),
                      ],
                      const SizedBox(height: CRMSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildSectionToggleItem(
    String title,
    bool isChecked,
    VoidCallback onToggle,
  ) {
    return PopupMenuItem<String>(
      onTap: onToggle,
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 18,
            color: isChecked ? CRMColors.primary : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
