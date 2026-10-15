/// ============================================================================
/// ⚠️ PROPKART MASTER KPI GOVERNANCE RULE:
/// All KPI metrics computed or displayed here MUST adhere to the
/// Master KPI Rulebook: lib/core/constants/kpi_rulebook.dart and docs/KPIs.docx.
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../../../core/design_system/mobile/mobile.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../users/models/user_model.dart';
import '../../bloc/reports_bloc.dart';
import '../../bloc/reports_event.dart';
import '../../bloc/reports_state.dart';
import '../../models/report_configuration.dart';
import '../../models/report_data.dart';
import '../../models/report_date_range.dart';
import '../../models/report_kpi_type.dart';
import '../../services/report_data_engine.dart';
import '../../widgets/report_date_filter_bar.dart';
import '../../widgets/report_export_menu.dart';
import '../../widgets/report_global_filters_bar.dart';
import '../../widgets/telecaller_selector.dart';

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
            AppStatusSnackBar.show(
              context,
              message: state.message,
              isSuccess: false,
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
                (MobileShellScope.isInShell(context) || MediaQuery.sizeOf(context).width >= 768) ? CRMSpacing.m : 96,
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
                      else
                        _buildTelecallerHeader(
                          isDark: isDark,
                          primaryColor: primaryColor,
                          user: selectedUser,
                          dateLabel: config.dateRange.formattedRange,
                        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final titleCol = Column(
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
                const Flexible(
                  child: Text(
                    'Telecaller Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
        );

        final exportBtn = scoped != null
            ? ReportExportMenu(
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
              )
            : const SizedBox.shrink();

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleCol,
              if (scoped != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: exportBtn,
                ),
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleCol),
            exportBtn,
          ],
        );
      },
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
