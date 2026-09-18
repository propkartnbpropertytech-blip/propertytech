import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../requirements/models/requirement_model.dart';
import '../../../requirements/screens/add_edit_requirement_screen.dart';
import '../../../users/models/user_model.dart';
import '../../bloc/reports_bloc.dart';
import '../../bloc/reports_event.dart';
import '../../bloc/reports_state.dart';
import '../../models/report_configuration.dart';
import '../../models/report_data.dart';
import '../../models/report_date_range.dart';
import '../../models/report_kpi_type.dart';
import '../../services/report_data_engine.dart';
import '../../widgets/business_insights_section.dart';
import '../../widgets/call_performance_section.dart';
import '../../widgets/conversion_analysis_section.dart';
import '../../widgets/conversion_funnel_section.dart';
import '../../widgets/followup_analysis_section.dart';
import '../../widgets/growth_comparison_section.dart';
import '../../widgets/kpi_card_widget.dart';
import '../../widgets/lead_drilldown_dialog.dart';
import '../../widgets/lead_source_analysis_section.dart';
import '../../widgets/lead_status_pipeline_section.dart';
import '../../widgets/report_date_filter_bar.dart';
import '../../widgets/report_export_menu.dart';
import '../../widgets/report_global_filters_bar.dart';
import '../../widgets/telecaller_leads_table.dart';
import '../../widgets/telecaller_selector.dart';
import '../../widgets/trend_analysis_section.dart';

class TelecallerReportScreen extends StatelessWidget {
  final String? initialTelecallerId;
  final String? initialTelecallerName;

  const TelecallerReportScreen({
    super.key,
    this.initialTelecallerId,
    this.initialTelecallerName,
  });

  @override
  Widget build(BuildContext context) {
    try {
      context.read<ReportsBloc>();
      return _TelecallerReportContent(
        initialTelecallerId: initialTelecallerId,
        initialTelecallerName: initialTelecallerName,
      );
    } catch (_) {
      return BlocProvider(
        create: (context) => ReportsBloc()..add(const LoadReportEvent()),
        child: _TelecallerReportContent(
          initialTelecallerId: initialTelecallerId,
          initialTelecallerName: initialTelecallerName,
        ),
      );
    }
  }
}

class _TelecallerKpiSpec {
  final ReportKpiType type;
  final String title;

  const _TelecallerKpiSpec(this.type, this.title);
}

const _telecallerKpis = [
  _TelecallerKpiSpec(ReportKpiType.totalLeads, 'Leads Assigned'),
  _TelecallerKpiSpec(ReportKpiType.leadsContacted, 'Leads Contacted'),
  _TelecallerKpiSpec(ReportKpiType.callAttempted, 'Call Attempted'),
  _TelecallerKpiSpec(ReportKpiType.callPickedUp, 'Call Picked Up'),
  _TelecallerKpiSpec(ReportKpiType.callOpen, 'Call Open'),
  _TelecallerKpiSpec(ReportKpiType.leadQualificationRate, 'Qualified Leads'),
  _TelecallerKpiSpec(ReportKpiType.siteVisitsScheduled, 'Site Visits Scheduled'),
  _TelecallerKpiSpec(ReportKpiType.siteVisitsDone, 'Site Visits Done'),
  _TelecallerKpiSpec(ReportKpiType.convertedToWon, 'Converted to Won'),
  _TelecallerKpiSpec(ReportKpiType.lostUnsuccessful, 'Lost / Unsuccessful Leads'),
];

class _TelecallerReportContent extends StatefulWidget {
  final String? initialTelecallerId;
  final String? initialTelecallerName;

  const _TelecallerReportContent({
    this.initialTelecallerId,
    this.initialTelecallerName,
  });

  @override
  State<_TelecallerReportContent> createState() => _TelecallerReportContentState();
}

class _TelecallerReportContentState extends State<_TelecallerReportContent> {
  String? _selectedId;
  String? _selectedName;
  late ReportKpiType _trendMetric;
  late TrendGranularity _trendGranularity;
  late GrowthComparisonPeriod _comparisonPeriod;
  DateTime? _customStart;
  DateTime? _customEnd;
  final Map<ReportKpiType, ReportKpiConfig> _kpiToggles = {
    for (final spec in _telecallerKpis)
      spec.type: ReportKpiConfig(type: spec.type, order: 0, showCount: true, showPercentage: false),
  };
  bool _pendingShowCount = true;
  bool _pendingShowPercentage = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialTelecallerId;
    _selectedName = widget.initialTelecallerName;
    final config = context.read<ReportsBloc>().state.config;
    _selectedId ??= config.subjectTelecallerId;
    _selectedName ??= config.subjectTelecallerName;
    _trendMetric = ReportKpiType.totalLeads;
    _trendGranularity = _granularityFor(config.dateRange);
    _comparisonPeriod = config.comparisonPeriod;
    _customStart = config.customComparisonStart;
    _customEnd = config.customComparisonEnd;

    if (_selectedId != null && _selectedId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReportsBloc>().add(
              SelectTelecallerSubjectEvent(
                userId: _selectedId,
                userName: _selectedName,
              ),
            );
      });
    }
  }

  TrendGranularity _granularityFor(ReportDateRange range) {
    switch (range.periodType) {
      case ReportPeriodType.today:
      case ReportPeriodType.weekly:
        return TrendGranularity.daily;
      case ReportPeriodType.monthly:
        return TrendGranularity.weekly;
      case ReportPeriodType.yearly:
        return TrendGranularity.monthly;
      case ReportPeriodType.customRange:
        final days = range.endDate.difference(range.startDate).inDays;
        if (days <= 14) return TrendGranularity.daily;
        if (days <= 90) return TrendGranularity.weekly;
        return TrendGranularity.monthly;
    }
  }

  void _selectTelecaller(UserModel user) {
    setState(() {
      _selectedId = user.id;
      _selectedName = user.fullName.isNotEmpty ? user.fullName : user.email;
    });
    context.read<ReportsBloc>().add(
          SelectTelecallerSubjectEvent(userId: _selectedId, userName: _selectedName),
        );
  }

  ReportOverallData? _scopedData(ReportsState state, ReportOverallData base) {
    if (_selectedId == null || _selectedId!.isEmpty) return null;
    final telecallers = base.availableTelecallers;
    final sales = base.availableSalesUsers;
    final localConfig = state.config.copyWith(
      comparisonPeriod: _comparisonPeriod,
      customComparisonStart: _customStart,
      customComparisonEnd: _customEnd,
      trendMetric: _trendMetric,
      trendGranularity: _trendGranularity,
    );
    return ReportDataEngine.computeTelecallerReport(
      telecallerId: _selectedId!,
      telecallerName: _selectedName ?? '',
      config: localConfig,
      allLeads: base.allLeads,
      allUsers: [...telecallers, ...sales],
      allProperties: base.availableProperties,
      allFollowups: base.allFollowups,
      systemStatuses: base.availableStatuses,
    );
  }

  UserModel? _selectedUser(ReportOverallData base) {
    if (_selectedId == null) return null;
    final match = base.availableTelecallers.where((u) => u.id == _selectedId);
    return match.isEmpty ? null : match.first;
  }

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
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFDC2626)),
            );
          }
          if (_selectedId == null && state.config.subjectTelecallerId != null) {
            setState(() {
              _selectedId = state.config.subjectTelecallerId;
              _selectedName = state.config.subjectTelecallerName;
            });
          }
        },
        builder: (context, state) {
          final config = state.config;

          if (state is ReportsInitial || (state is ReportsLoading && state.previousData == null)) {
            return _centeredStatus(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading telecaller performance data...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          if (state is ReportsError && state.previousData == null) {
            return _centeredStatus(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 14),
                    const Text(
                      'Failed to load telecaller report',
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
                      label: const Text('Retry'),
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

          final ReportOverallData? baseData = (state is ReportsLoaded)
              ? state.data
              : (state is ReportsLoading
                  ? state.previousData
                  : (state is ReportsError ? state.previousData : null));

          if (baseData == null) {
            return _centeredStatus(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final isSoftLoading = state is ReportsLoading;
          final scoped = _scopedData(state, baseData);
          final selectedUser = _selectedUser(baseData);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReportsBloc>().add(const LoadReportEvent(forceRefresh: true));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                CRMBreakpoints.pagePadding(context),
                CRMSpacing.m,
                CRMBreakpoints.pagePadding(context),
                MediaQuery.sizeOf(context).width < 768 ? 96 : CRMSpacing.m,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: CRMBreakpoints.maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context: context,
                        isDark: isDark,
                        primaryColor: primaryColor,
                        isSoftLoading: isSoftLoading,
                        scoped: scoped,
                        config: config,
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      ReportDateFilterBar(
                        activeRange: config.dateRange,
                        onRangeChanged: (newRange) {
                          context.read<ReportsBloc>().add(UpdateDateRangeEvent(newRange));
                          setState(() => _trendGranularity = _granularityFor(newRange));
                        },
                      ),
                      const SizedBox(height: 10),
                      ReportGlobalFiltersBar(
                        filters: config.filters,
                        availableStatuses: baseData.availableStatuses,
                        availableSources: baseData.availableSources,
                        telecallers: baseData.availableTelecallers,
                        salesUsers: baseData.availableSalesUsers,
                        properties: baseData.availableProperties,
                        hideUserFilters: true,
                        onFiltersChanged: (updated) {
                          context.read<ReportsBloc>().add(UpdateFiltersEvent(updated));
                        },
                        onResetFilters: () {
                          context.read<ReportsBloc>().add(ResetFiltersEvent());
                        },
                      ),
                      const SizedBox(height: 10),
                      TelecallerSelector(
                        telecallers: baseData.availableTelecallers,
                        selectedId: _selectedId,
                        onSelected: _selectTelecaller,
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      if (_selectedId == null || _selectedId!.isEmpty)
                        _emptyCard(
                          isDark: isDark,
                          icon: Icons.person_search_rounded,
                          title: 'Select a Telecaller',
                          message: 'Choose a telecaller to view their individual performance report for the selected period and filters.',
                        )
                      else if (scoped == null)
                        _emptyCard(
                          isDark: isDark,
                          icon: Icons.insights_outlined,
                          title: 'Preparing report',
                          message: 'Calculating performance for ${_selectedName ?? 'this telecaller'}.',
                        )
                      else ...[
                        _buildTelecallerHeader(
                          isDark: isDark,
                          primaryColor: primaryColor,
                          user: selectedUser,
                          dateLabel: config.dateRange.formattedRange,
                        ),
                        const SizedBox(height: CRMSpacing.m),
                        if (scoped.isEmpty)
                          _emptyCard(
                            isDark: isDark,
                            icon: Icons.inbox_outlined,
                            title: 'No performance data available for this Telecaller',
                            message: 'No performance data available for this Telecaller for the selected period.',
                          )
                        else ...[
                          _buildKpiGrid(context, scoped, isDark),
                          const SizedBox(height: CRMSpacing.l),
                          CallPerformanceSection(data: scoped),
                          const SizedBox(height: CRMSpacing.l),
                          ConversionFunnelSection(
                            stages: scoped.funnelStages,
                            title: 'Telecaller Conversion Funnel',
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          LeadStatusPipelineSection(
                            stages: scoped.pipelineStages,
                            title: 'Lead Status',
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          FollowupAnalysisSection(
                            categories: scoped.followupCategories,
                            title: 'Follow-up Performance',
                            onLeadTap: (item) => _openFollowupLead(scoped, item),
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          LeadSourceAnalysisSection(
                            isVisible: true,
                            leadSources: scoped.leadSources,
                            onToggleVisibility: (_) {},
                            title: 'Lead Source Performance',
                            showVisibilityToggle: false,
                            showOutcomeBreakdown: true,
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          ConversionAnalysisSection(data: scoped),
                          const SizedBox(height: CRMSpacing.l),
                          TrendAnalysisSection(
                            isVisible: true,
                            selectedMetric: _trendMetric,
                            selectedGranularity: _trendGranularity,
                            trendPoints: scoped.trendPoints,
                            onToggleVisibility: (_) {},
                            onMetricChanged: (metric) => setState(() => _trendMetric = metric),
                            onGranularityChanged: (gran) => setState(() => _trendGranularity = gran),
                            title: 'Performance Trend',
                            showVisibilityToggle: false,
                            metricLabels: const {
                              ReportKpiType.totalLeads: 'Leads Assigned',
                              ReportKpiType.leadsContacted: 'Contacted',
                              ReportKpiType.callAttempted: 'Call Attempted',
                              ReportKpiType.callPickedUp: 'Call Picked Up',
                              ReportKpiType.leadQualificationRate: 'Qualified',
                              ReportKpiType.siteVisitsScheduled: 'Site Visits Scheduled',
                              ReportKpiType.siteVisitsDone: 'Site Visits Done',
                              ReportKpiType.convertedToWon: 'Won',
                              ReportKpiType.lostUnsuccessful: 'Lost',
                            },
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          GrowthComparisonSection(
                            isVisible: true,
                            activePeriod: _comparisonPeriod,
                            customStart: _customStart,
                            customEnd: _customEnd,
                            comparisonItems: scoped.growthComparisonItems,
                            showVisibilityToggle: false,
                            onToggleVisibility: (_) {},
                            onPeriodChanged: (period) => setState(() => _comparisonPeriod = period),
                            onCustomDatesChanged: (start, end) {
                              setState(() {
                                _customStart = start;
                                _customEnd = end;
                                _comparisonPeriod = GrowthComparisonPeriod.customPeriod;
                              });
                            },
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          BusinessInsightsSection(
                            insights: scoped.insights,
                            title: 'Telecaller Insights',
                          ),
                          const SizedBox(height: CRMSpacing.l),
                          TelecallerLeadsTable(
                            leads: scoped.filteredLeads,
                            availableStatuses: scoped.availableStatuses,
                            availableSources: scoped.availableSources,
                            telecallerName: _selectedName ?? '',
                          ),
                          const SizedBox(height: CRMSpacing.xl),
                        ],
                      ],
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

  Widget _buildHeader({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required bool isSoftLoading,
    required ReportOverallData? scoped,
    required ReportConfiguration config,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Back to Overall Business Insight',
                  onPressed: () => context.go('/reports/leads/overall-business-insight'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
                const Text(
                  'Telecaller Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                ),
                if (isSoftLoading) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                'Individual telecaller performance for the selected reporting period.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        if (scoped != null)
          ReportExportMenu(
            reportData: scoped,
            config: config.copyWith(
              showTeamRanking: false,
              showGrowthComparison: true,
              showLeadSourceAnalysis: true,
              showTrendAnalysis: true,
              filters: config.filters.copyWith(
                telecallerId: _selectedId,
                telecallerName: _selectedName,
              ),
            ),
            reportTitle: 'PropKart CRM - Telecaller Report',
            subjectLabel: _selectedName == null ? null : 'Telecaller: $_selectedName',
            filenamePrefix: 'PropKart_Telecaller_Report',
            tooltip: 'Export Telecaller Report',
          ),
      ],
    );
  }

  Widget _buildTelecallerHeader({
    required bool isDark,
    required Color primaryColor,
    required UserModel? user,
    required String dateLabel,
  }) {
    final name = user != null && user.fullName.isNotEmpty
        ? user.fullName
        : (_selectedName ?? 'Telecaller');
    final initials = name.trim().isEmpty
        ? 'T'
        : name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _pill('Telecaller', primaryColor, isDark),
                    if (user?.email != null && user!.email.isNotEmpty)
                      _pill(user.email, const Color(0xFF64748B), isDark),
                    if (user?.mobile != null && user!.mobile!.isNotEmpty)
                      _pill(user.mobile!, const Color(0xFF64748B), isDark),
                    if (user != null && !user.isActive)
                      _pill('Inactive', const Color(0xFFDC2626), isDark),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.date_range_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, ReportOverallData scoped, bool isDark) {
    final pending = scoped.followupCategories.isEmpty ? 0 : scoped.followupCategories.first.count;
    final assigned = scoped.kpiValues[ReportKpiType.totalLeads]?.count ?? 0;
    final pendingPct = assigned == 0 ? 0.0 : pending / assigned * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 4;
        if (width < 520) {
          columns = 1;
        } else if (width < 820) {
          columns = 2;
        } else if (width < 1100) {
          columns = 3;
        }
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: width < 520 ? 2.4 : 1.55,
          children: [
            ..._telecallerKpis.map((spec) {
              final toggle = _kpiToggles[spec.type]!;
              return KpiCardWidget(
                config: toggle,
                value: scoped.kpiValues[spec.type],
                titleOverride: spec.title,
                showToggles: true,
                onTogglesChanged: (showCount, showPercentage) {
                  setState(() {
                    _kpiToggles[spec.type] = toggle.copyWith(
                      showCount: showCount,
                      showPercentage: showPercentage,
                    );
                  });
                },
                onExpand: () => _expandKpi(context, spec, scoped),
              );
            }),
            KpiCardWidget(
              config: ReportKpiConfig(
                type: ReportKpiType.lostUnsuccessful,
                order: 10,
                showCount: _pendingShowCount,
                showPercentage: _pendingShowPercentage,
              ),
              value: KpiValue.create(
                count: pending,
                percentage: pendingPct,
                denominatorLabel: '% of Assigned Leads ($assigned)',
              ),
              titleOverride: 'Pending Follow-ups',
              iconOverride: Icons.pending_actions_rounded,
              colorOverride: const Color(0xFFD97706),
              showToggles: true,
              onTogglesChanged: (showCount, showPercentage) {
                setState(() {
                  _pendingShowCount = showCount;
                  _pendingShowPercentage = showPercentage;
                });
              },
              onExpand: () {
                final items = scoped.followupCategories.isEmpty
                    ? const <FollowupItemData>[]
                    : scoped.followupCategories.first.items;
                _openFollowupItems(context, 'Pending Follow-ups', items, scoped);
              },
            ),
          ],
        );
      },
    );
  }

  void _expandKpi(BuildContext context, _TelecallerKpiSpec spec, ReportOverallData scoped) {
    List<RequirementModel> leads = scoped.filteredLeads;
    switch (spec.type) {
      case ReportKpiType.leadsContacted:
        leads = _funnelLeads(scoped, 'Contacted');
        break;
      case ReportKpiType.leadQualificationRate:
        leads = _funnelLeads(scoped, 'Qualified');
        break;
      case ReportKpiType.siteVisitsScheduled:
        leads = _funnelLeads(scoped, 'Site Visit Scheduled');
        break;
      case ReportKpiType.siteVisitsDone:
        leads = _funnelLeads(scoped, 'Site Visit Done');
        break;
      case ReportKpiType.convertedToWon:
        leads = _funnelLeads(scoped, 'Won');
        break;
      case ReportKpiType.lostUnsuccessful:
        leads = scoped.filteredLeads.where((l) {
          final s = l.status.toLowerCase();
          return s.startsWith('rejected') || s == 'lost' || s == 'dead' || s == 'bin' || s == 'not interested';
        }).toList();
        break;
      default:
        leads = scoped.filteredLeads;
    }
    showDialog(
      context: context,
      builder: (_) => LeadDrilldownDialog(
        title: spec.title,
        subtitle: '${_selectedName ?? 'Telecaller'} · ${scoped.kpiValues[spec.type]?.denominatorLabel ?? ''}',
        leads: leads,
      ),
    );
  }

  List<RequirementModel> _funnelLeads(ReportOverallData scoped, String stageName) {
    final match = scoped.funnelStages.where((s) => s.stageName == stageName);
    return match.isEmpty ? const [] : match.first.leads;
  }

  void _openFollowupLead(ReportOverallData scoped, FollowupItemData item) {
    RequirementModel? lead;
    if (item.leadId != null) {
      final match = scoped.filteredLeads.where((l) => l.id == item.leadId);
      if (match.isNotEmpty) lead = match.first;
    }
    lead ??= scoped.filteredLeads.where((l) => l.clientName == item.leadName).firstOrNull;
    if (lead != null) {
      final selectedLead = lead;
      showDialog(
        context: context,
        builder: (dialogContext) => AddEditRequirementScreen(
          requirement: selectedLead,
          onSaved: () {},
        ),
      );
      return;
    }
    context.go('/requirements?search=${Uri.encodeComponent(item.leadName)}');
  }

  void _openFollowupItems(
    BuildContext context,
    String title,
    List<FollowupItemData> items,
    ReportOverallData scoped,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('$title (${items.length})'),
          content: SizedBox(
            width: 520,
            height: 360,
            child: items.isEmpty
                ? const Center(child: Text('No pending follow-ups for this telecaller.'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item.leadName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${item.leadStatus} · ${item.nextAction}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _openFollowupLead(scoped, item);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _emptyCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredStatus({required Widget child}) {
    return Center(child: child);
  }
}
