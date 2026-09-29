import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../bloc/reports_bloc.dart';
import '../../bloc/reports_event.dart';
import '../../bloc/reports_state.dart';
import '../../models/report_data.dart';
import '../../models/report_kpi_type.dart';
import '../../models/report_configuration.dart';
import '../../models/business_insight_summary.dart';
import '../../widgets/report_date_filter_bar.dart';
import '../../widgets/kpi_card_widget.dart';
import '../../widgets/kpi_expand_dialog.dart';
import '../../widgets/report_export_menu.dart';
import '../../widgets/business_insight_drilldowns.dart';
import '../../widgets/campaign_kpi_drilldowns.dart';
import '../../widgets/leads_page_kpi_drilldowns.dart';

enum BusinessInsightView {
  main,
  totalLeadsSources,
  sourceLeadsDetail,
  propertyListingLeads,
  requirementLeads,
  telecallersList,
  telecallerDetail,
  newOpenLeads,
  cnrLeads,
  callbackLeads,
  campaignFollowups,
  notInterestedLeads,
  salesAssignedPickedUp,
  leadsPageKpi,
}

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

class _OverallBusinessInsightContent extends StatefulWidget {
  const _OverallBusinessInsightContent();

  @override
  State<_OverallBusinessInsightContent> createState() => _OverallBusinessInsightContentState();
}

class _OverallBusinessInsightContentState extends State<_OverallBusinessInsightContent> {
  BusinessInsightView _currentView = BusinessInsightView.main;
  String _selectedSource = 'Meta';
  String? _selectedSourceTab;
  TelecallerSummaryItem? _selectedTelecaller;
  ReportKpiType _selectedLeadsPageKpi = ReportKpiType.leadsNotStarted;

  BusinessInsightSummary _resolveSummary(ReportOverallData data) {
    if (data.insightSummary != null) {
      return data.insightSummary!;
    }
    return const BusinessInsightSummary.empty();
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
          final summary = _resolveSummary(reportData);

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
                  child: _buildCurrentView(context, reportData, config, summary, isSoftLoading),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    ReportOverallData reportData,
    ReportConfiguration config,
    BusinessInsightSummary summary,
    bool isSoftLoading,
  ) {
    switch (_currentView) {
      case BusinessInsightView.main:
        return _buildMainContent(context, reportData, config, summary, isSoftLoading);

      case BusinessInsightView.totalLeadsSources:
        return LeadSourceGridView(
          summary: summary,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
          onSelectSource: (src, {initialTab}) {
            setState(() {
              _selectedSource = src;
              _selectedSourceTab = initialTab;
              _currentView = BusinessInsightView.sourceLeadsDetail;
            });
          },
        );

      case BusinessInsightView.sourceLeadsDetail:
        return SourceLeadsDetailView(
          source: _selectedSource,
          summary: summary,
          initialTab: _selectedSourceTab,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.totalLeadsSources),
        );

      case BusinessInsightView.propertyListingLeads:
        return PropertyListingLeadsView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.requirementLeads:
        return RequirementLeadsView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.telecallersList:
        return TelecallersListView(
          summary: summary,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
          onSelectTelecaller: (tc) {
            setState(() {
              _selectedTelecaller = tc;
              _currentView = BusinessInsightView.telecallerDetail;
            });
          },
        );

      case BusinessInsightView.telecallerDetail:
        return TelecallerDetailView(
          telecaller: _selectedTelecaller ?? summary.telecallers.list.first,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.telecallersList),
        );

      case BusinessInsightView.newOpenLeads:
        return NewOpenLeadsDrilldownView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.cnrLeads:
        return CnrLeadsDrilldownView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.callbackLeads:
        return CallbackLeadsDrilldownView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.campaignFollowups:
        return CampaignFollowupsDrilldownView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.notInterestedLeads:
        return NotInterestedLeadsDrilldownView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.salesAssignedPickedUp:
        return SalesAssignedPickedUpDrilldownView(
          summary: summary,
          from: config.dateRange.startDate,
          to: config.dateRange.endDate,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );

      case BusinessInsightView.leadsPageKpi:
        return LeadsPageKpiDrilldownView(
          kpiType: _selectedLeadsPageKpi,
          reportData: reportData,
          onBack: () => setState(() => _currentView = BusinessInsightView.main),
        );
    }
  }

  Widget _buildMainContent(
    BuildContext context,
    ReportOverallData reportData,
    ReportConfiguration config,
    BusinessInsightSummary summary,
    bool isSoftLoading,
  ) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    final campaignKpis = config.enabledCampaignKpis;
    final leadsPageKpis = config.enabledLeadsPageKpis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Title & Export Bar
        if (MediaQuery.of(context).size.width < 700) ...[
          const Text(
            'Overall Business Insight',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
          if (isSoftLoading) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ReportExportMenu(
                reportData: reportData,
                config: config,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Executive overview of lead lifecycle, agent productivity, conversion funnel, and pipeline velocity.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ] else ...[
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
                  ReportExportMenu(
                    reportData: reportData,
                    config: config,
                  ),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: CRMSpacing.m),

        // Filter Section: Date Filter Bar
        ReportDateFilterBar(
          activeRange: config.dateRange,
          onRangeChanged: (newRange) {
            context.read<ReportsBloc>().add(UpdateDateRangeEvent(newRange));
          },
        ),
        const SizedBox(height: CRMSpacing.l),

        // ====================================================================
        // SECTION 1: CAMPAIGN KPIS (Top Row / Section)
        // ====================================================================
        Row(
          children: [
            const Icon(Icons.campaign_rounded, size: 20, color: Color(0xFF1877F2)),
            const SizedBox(width: 8),
            const Text(
              'Campaign Performance KPIs',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${campaignKpis.length} Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1877F2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Campaign KPI Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = CRMBreakpoints.kpiColumns(context);
            final spacing = 12.0;
            final cardWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: campaignKpis.map((kpiConfig) {
                return SizedBox(
                  width: cardWidth,
                  child: KpiCardWidget(
                    config: kpiConfig,
                    value: reportData.kpiValues[kpiConfig.type],
                    showToggles: false,
                    onExpand: () => _handleCampaignKpiClick(kpiConfig.type, reportData, config),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: CRMSpacing.xl),
        const Divider(height: 1),
        const SizedBox(height: CRMSpacing.l),

        // ====================================================================
        // SECTION 2: LEADS PAGE KPIS (Displayed below existing Campaign KPIs)
        // ====================================================================
        Row(
          children: [
            const Icon(Icons.people_alt_rounded, size: 20, color: Color(0xFF0D9488)),
            const SizedBox(width: 8),
            const Text(
              'Leads Page KPIs',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${leadsPageKpis.length} Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9488),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Synchronized with Leads page pipeline',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Leads Page KPI Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = CRMBreakpoints.kpiColumns(context);
            final spacing = 12.0;
            final cardWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: leadsPageKpis.map((kpiConfig) {
                return SizedBox(
                  width: cardWidth,
                  child: KpiCardWidget(
                    config: kpiConfig,
                    value: reportData.kpiValues[kpiConfig.type],
                    showToggles: false,
                    onExpand: () {
                      setState(() {
                        _selectedLeadsPageKpi = kpiConfig.type;
                        _currentView = BusinessInsightView.leadsPageKpi;
                      });
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: CRMSpacing.xl),
      ],
    );
  }

  void _handleCampaignKpiClick(ReportKpiType type, ReportOverallData reportData, ReportConfiguration config) {
    switch (type) {
      case ReportKpiType.totalLeads:
        setState(() => _currentView = BusinessInsightView.totalLeadsSources);
        break;
      case ReportKpiType.propertyListingLeads:
        setState(() => _currentView = BusinessInsightView.propertyListingLeads);
        break;
      case ReportKpiType.requirementLeads:
        setState(() => _currentView = BusinessInsightView.requirementLeads);
        break;
      case ReportKpiType.telecallers:
        setState(() => _currentView = BusinessInsightView.telecallersList);
        break;
      case ReportKpiType.newOpenLeads:
        setState(() => _currentView = BusinessInsightView.newOpenLeads);
        break;
      case ReportKpiType.cnrLeads:
        setState(() => _currentView = BusinessInsightView.cnrLeads);
        break;
      case ReportKpiType.callbackLeads:
        setState(() => _currentView = BusinessInsightView.callbackLeads);
        break;
      case ReportKpiType.campaignFollowupLeads:
        setState(() => _currentView = BusinessInsightView.campaignFollowups);
        break;
      case ReportKpiType.notInterestedLeads:
        setState(() => _currentView = BusinessInsightView.notInterestedLeads);
        break;
      case ReportKpiType.leadsAssignedToSalesPickedUp:
      case ReportKpiType.leadsAssignedToSales:
        setState(() => _currentView = BusinessInsightView.salesAssignedPickedUp);
        break;
      default:
        showDialog(
          context: context,
          builder: (dCtx) => KpiExpandDialog(
            kpiType: type,
            reportData: reportData,
            config: config,
          ),
        );
        break;
    }
  }
}
