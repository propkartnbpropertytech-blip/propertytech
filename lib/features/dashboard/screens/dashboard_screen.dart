/// ============================================================================
/// ⚠️ PROPKART MASTER KPI GOVERNANCE RULE:
/// Before modifying, adding, or renaming any dashboard KPI card, stat value,
/// or drilldown dialog trigger, you MUST strictly adhere to the Master KPI Rulebook:
/// `lib/core/constants/kpi_rulebook.dart` and `docs/KPIs.docx`.
/// ============================================================================
import 'dart:math' as math;
import '../../../core/constants/kpi_rulebook.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/model_mappers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/mobile/mobile.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../telecaller/screens/telecaller_dashboard_screen.dart';
import '../../sales/screens/sales_dashboard_screen.dart';
import '../../requirements/bloc/requirements_bloc.dart';
import '../../campaign/bloc/campaign_leads_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';
import '../models/kpi_models.dart';
import '../widgets/kpi_drilldown_dialogs.dart';
import '../widgets/generic_kpi_drilldown_dialog.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/security/role_guard.dart';
import '../widgets/welcome_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_properties_card.dart';
import '../widgets/todays_schedule_card.dart';
import '../widgets/followups_card.dart';
import '../../requirements/screens/requirements_screen.dart';
import '../widgets/inventory_demand_analytics_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  Set<String> _selectedAreaFilters = {};
  String _priceSortOrder = 'none'; // 'none', 'high_to_low', 'low_to_high'

  // Pagination states
  int _propertyPage = 1;
  static const int _propertiesPerPage = 8;

  bool _isLoadingProperty = false;
  late AnimationController _nameShimmerController;
  static bool _greetingPlayedThisSession = false;
  final Map<String, Future<PropertyModel?>> _propertyDetailFutures = {};

  bool get _isRent => ThemeManager().isRentMode;


  Future<PropertyModel?> _propertyDetailFuture(String id) {
    return _propertyDetailFutures.putIfAbsent(
      id,
      () => PropertiesRepository().getPropertyById(id),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameShimmerController = AnimationController(
      vsync: this,
      duration: CRMMotion.nameShimmer,
    );
    if (!_greetingPlayedThisSession) {
      _nameShimmerController.forward().whenComplete(() {
        _greetingPlayedThisSession = true;
      });
    } else {
      _nameShimmerController.value = 1.0;
    }
    final currentDashboardState = context.read<DashboardBloc>().state;
    if (currentDashboardState is DashboardLoadedState) {
      context.read<DashboardBloc>().add(RefreshDashboard());
    } else {
      context.read<DashboardBloc>().add(LoadDashboard());
    }
  }

  @override
  void dispose() {
    _nameShimmerController.dispose();
    _propertyDetailFutures.clear();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthBloc, String>((bloc) {
      final state = bloc.state;
      return state is Authenticated ? state.user.role : '';
    });
    if (RoleGuard.isTelecaller(role)) {
      return const TelecallerDashboardScreen();
    }
    if (RoleGuard.isSales(role)) {
      return const SalesDashboardScreen();
    }

    Theme.of(context);
    final userName = context.select<AuthBloc, String>((bloc) {
      final state = bloc.state;
      return state is Authenticated ? state.user.fullName : '';
    });

    return MultiBlocListener(
      listeners: [
        BlocListener<RequirementsBloc, RequirementsState>(
          listenWhen: (previous, current) =>
              current is RequirementsSuccess ||
              (previous is RequirementsLoading && current is RequirementsLoaded),
          listener: (context, state) {
            context.read<DashboardBloc>().add(RefreshDashboard());
          },
        ),
        BlocListener<CampaignLeadsBloc, CampaignLeadsState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == CampaignLeadsStatus.success,
          listener: (context, state) {
            context.read<DashboardBloc>().add(RefreshDashboard());
          },
        ),
      ],
      child: Stack(
        children: [
          BlocConsumer<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) =>
              current is DashboardError || current is DashboardLoadedState,
          buildWhen: (previous, current) =>
              current is DashboardLoading ||
              current is DashboardInitial ||
              current is DashboardError ||
              current is DashboardLoadedState ||
              current is DashboardRefreshing,
          listener: (context, state) {
            if (state is DashboardLoadedState || state is DashboardRefreshing) {
              _propertyDetailFutures.clear();
            }
          },
          builder: (context, state) {
            final viewport = MediaQuery.sizeOf(context).width;
            final isMobile = MobileLayout.isMobileShell(viewport);

            if (state is DashboardLoading || state is DashboardInitial) {
              if (isMobile) {
                return const MobileScreenScaffold(
                  scrollable: false,
                  body: MobileLoadingState(),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(CRMSpacing.l),
                child: CRMListSkeleton(count: 4),
              );
            } else if (state is DashboardError) {
              if (isMobile) {
                return MobileScreenScaffold(
                  scrollable: false,
                  body: MobileErrorState(
                    title: 'Failed to load dashboard',
                    message: state.message,
                    onRetry: () => context.read<DashboardBloc>().add(RefreshDashboard()),
                  ),
                );
              }
              return _buildErrorState(state.message);
            } else if (state is DashboardLoadedState ||
                state is DashboardRefreshing) {
              final data = (state is DashboardLoadedState)
                  ? state.data
                  : (state as DashboardRefreshing).data;
              final kpis = (state is DashboardLoadedState)
                  ? state.kpis
                  : (state as DashboardRefreshing).kpis;
              final kpiFilters = (state is DashboardLoadedState)
                  ? state.kpiFilters
                  : (state as DashboardRefreshing).kpiFilters;
              final isKpiLoading = (state is DashboardLoadedState)
                  ? state.isKpiLoading
                  : false;

              final allDisplayItems = _getAllDisplayProperties(data);
              final filteredDisplayItems = _getFilteredDisplayProperties(allDisplayItems);
              final recentPropsWidget = _buildRecentPropsWidget(data, allDisplayItems, filteredDisplayItems);
              final scheduleWidget = _buildScheduleWidget(data);
              final followupsWidget = _buildFollowupsWidget(data);

              if (isMobile) {
                return _buildMobileAdminDashboardView(
                  context: context,
                  data: data,
                  kpis: kpis,
                  kpiFilters: kpiFilters,
                  isKpiLoading: isKpiLoading,
                  userName: userName,
                  recentPropsWidget: recentPropsWidget,
                  scheduleWidget: scheduleWidget,
                  followupsWidget: followupsWidget,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _propertyDetailFutures.clear();
                  context.read<DashboardBloc>().add(RefreshDashboard());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: CRMBreakpoints.pagePadding(context),
                    vertical: CRMSpacing.l,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: CRMBreakpoints.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Welcome Header
                          WelcomeHeader(
                            userName: userName.isNotEmpty
                                ? userName
                                : (RoleGuard.currentUser?.fullName ?? 'User'),
                          ),
                          const SizedBox(height: 16),

                          // 2. Global Top KPIs (Available Inventory & Total Leads)
                          _buildGlobalTopKpis(data, kpis, kpiFilters),
                          const SizedBox(height: 16),

                          // 3. Global Filter Bar (Business Type, Date, Lead Type)
                          _buildGlobalFilterBar(kpiFilters, isKpiLoading, kpis),
                          const SizedBox(height: 20),

                          // 4. Responsive Main Content Area
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 1100;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Telecaller Section KPIs
                                  _buildTelecallerKpisSection(data, kpis, kpiFilters),
                                  const SizedBox(height: 16),

                                  // Sales Section KPIs
                                  _buildSalesKpisSection(data, kpis, kpiFilters),
                                  const SizedBox(height: 16),

                                  // Dynamic Custom KPIs (if configured)
                                  _buildDynamicCustomKpisSection(kpis, kpiFilters),
                                  const SizedBox(height: 20),

                                  // Inventory & Demand Analytics Section

                                  InventoryDemandAnalyticsSection(
                                    businessType: kpiFilters.businessType,
                                  ),
                                  const SizedBox(height: 24),

                                  // Middle Section: Recent Properties & (Note + Follow-ups)
                                  if (isDesktop)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: recentPropsWidget,
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            children: [
                                              scheduleWidget,
                                              const SizedBox(height: 20),
                                              followupsWidget,
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        recentPropsWidget,
                                        const SizedBox(height: 20),
                                        scheduleWidget,
                                        const SizedBox(height: 20),
                                        followupsWidget,
                                      ],
                                    ),
                                  SizedBox(height: isDesktop ? 32 : 96),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        if (_isLoadingProperty)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}

  List<_DisplayProperty> _getAllDisplayProperties(DashboardData data) {
    return data.recentProperties.map((p) {
      DateTime parsedDate = DateTime.now();
      if (p.createdAt.isNotEmpty) {
        parsedDate = DateTime.tryParse(p.createdAt) ?? DateTime.now();
      }
      return _DisplayProperty(
        id: p.id,
        title: p.title,
        areaName: p.areaName,
        price: p.price,
        listingType: p.listingType,
        createdAt: parsedDate,
        status: p.status,
      );
    }).toList();
  }

  List<_DisplayProperty> _getFilteredDisplayProperties(List<_DisplayProperty> allItems) {
    List<_DisplayProperty> tabFiltered = allItems.where((p) {
      final typeLower = p.listingType.toLowerCase();
      if (_isRent) {
        return typeLower.contains('rent');
      } else {
        return !typeLower.contains('rent');
      }
    }).toList();

    if (_selectedAreaFilters.isNotEmpty) {
      tabFiltered = tabFiltered
          .where((p) => _selectedAreaFilters.contains(p.areaName))
          .toList();
    }

    if (_priceSortOrder == 'high_to_low') {
      tabFiltered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_priceSortOrder == 'low_to_high') {
      tabFiltered.sort((a, b) => a.price.compareTo(b.price));
    } else {
      tabFiltered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (tabFiltered.length > 16) {
      tabFiltered = tabFiltered.sublist(0, 16);
    }
    return tabFiltered;
  }

  Widget _buildRecentPropsWidget(
    DashboardData data,
    List<_DisplayProperty> allItems,
    List<_DisplayProperty> filteredItems,
  ) {
    final totalCount = filteredItems.length;
    final totalPages = (totalCount / _propertiesPerPage).ceil();
    final currentPage = _propertyPage.clamp(
      1,
      totalPages > 0 ? totalPages : 1,
    );
    final startIndex = (currentPage - 1) * _propertiesPerPage;
    final endIndex = (startIndex + _propertiesPerPage).clamp(
      0,
      totalCount,
    );

    final pageItems = (startIndex < totalCount)
        ? filteredItems.sublist(startIndex, endIndex)
        : <_DisplayProperty>[];

    final recentPropsToDisplay = pageItems.map((p) {
      return RecentProperty(
        id: p.id,
        code: '',
        title: p.title,
        area: '',
        price: p.price,
        status: p.status,
        areaName: p.areaName,
        listingType: p.listingType,
        createdBy: '',
        createdAt: p.createdAt.toIso8601String(),
      );
    }).toList();

    return RecentPropertiesCard(
      properties: recentPropsToDisplay,
      propertyDetailFuture: _propertyDetailFuture,
      onPropertyTap: (p) => _openPropertyDetails(p.id),
      onFilterTap: () => _showFilterModal(allItems),
      activeFilterCount: _selectedAreaFilters.length +
          (_priceSortOrder != 'none' ? 1 : 0),
      currentPage: currentPage,
      totalPages: totalPages > 0 ? totalPages : 1,
      onNextPage: () => setState(() => _propertyPage++),
      onPrevPage: () => setState(() => _propertyPage--),
    );
  }

  Widget _buildScheduleWidget(DashboardData data) {
    return TodaysScheduleCard(
      siteVisits: data.siteVisits,
      onSiteVisitTap: _openSiteVisit,
    );
  }

  Widget _buildFollowupsWidget(DashboardData data) {
    return FollowupsCard(
      followups: data.followups,
      siteVisits: data.siteVisits,
      onFollowupTap: (f) => _showEditFollowupDialog(f),
      onAddFollowup: () => _showCreateFollowupDialog(),
      onViewAll: () => context.go('/requirements?tab=Follow-ups'),
    );
  }

  Widget _buildMobileAdminDashboardView({
    required BuildContext context,
    required DashboardData data,
    required DashboardKpisResponse? kpis,
    required KpiFilterParams kpiFilters,
    required bool isKpiLoading,
    required String userName,
    required Widget recentPropsWidget,
    required Widget scheduleWidget,
    required Widget followupsWidget,
  }) {
    return MobileScreenScaffold(
      scrollable: true,
      onRefresh: () async {
        _propertyDetailFutures.clear();
        context.read<DashboardBloc>().add(RefreshDashboard());
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Welcome Header
          WelcomeHeader(
            userName: userName.isNotEmpty
                ? userName
                : (RoleGuard.currentUser?.fullName ?? 'User'),
          ),
          const SizedBox(height: 14),

          // 2. Global Top KPIs (Available Inventory & Total Leads)
          _buildGlobalTopKpis(data, kpis, kpiFilters),
          const SizedBox(height: 14),

          // 3. Global Filter Bar (Business Type, Date, Lead Type)
          _buildGlobalFilterBar(kpiFilters, isKpiLoading, kpis),
          const SizedBox(height: 16),

          // 4. Telecaller Section KPIs
          _buildTelecallerKpisSection(data, kpis, kpiFilters),
          const SizedBox(height: 14),

          // 5. Sales Section KPIs
          _buildSalesKpisSection(data, kpis, kpiFilters),
          const SizedBox(height: 14),

          // 6. Dynamic Custom KPIs (if configured)
          _buildDynamicCustomKpisSection(kpis, kpiFilters),
          const SizedBox(height: 16),

          // Inventory & Demand Analytics Section
          InventoryDemandAnalyticsSection(
            businessType: kpiFilters.businessType,
          ),
          const SizedBox(height: 16),


          // 4. Middle Section Widgets
          recentPropsWidget,
          const SizedBox(height: 16),
          scheduleWidget,
          const SizedBox(height: 16),
          followupsWidget,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGlobalFilterBar(KpiFilterParams kpiFilters, bool isKpiLoading, DashboardKpisResponse? kpis) {
    final isDark = ThemeManager().isDarkMode;
    final dateRangeText = _computeDateRangeDisplay(kpiFilters, kpis);
    final isMobile = CRMBreakpoints.isPhone(context);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Business Type (Left side)
              Text(
                'Business:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterPill('Rent', kpiFilters.businessType == 'Rent', () {
                      ThemeManager().setRentMode(true);
                      setState(() => _propertyPage = 1);
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(businessType: 'Rent'));
                    }, isDark),
                    _buildFilterPill('Re-sale', kpiFilters.businessType == 'Re-sale', () {
                      ThemeManager().setRentMode(false);
                      setState(() => _propertyPage = 1);
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(businessType: 'Re-sale'));
                    }, isDark),
                    _buildFilterPill('Both', kpiFilters.businessType == 'Both', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(businessType: 'Both'));
                    }, isDark),
                  ],
                ),
              ),

              // Separator
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),

              // 2. Date Filter (Center)
              Text(
                'Date:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterPill('Today', kpiFilters.dateFilter == 'Today', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Today'));
                    }, isDark),
                    _buildFilterPill('Weekly', kpiFilters.dateFilter == 'Weekly', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Weekly'));
                    }, isDark),
                    _buildFilterPill('Monthly', kpiFilters.dateFilter == 'Monthly', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Monthly'));
                    }, isDark),
                    _buildFilterPill('Yearly', kpiFilters.dateFilter == 'Yearly', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Yearly'));
                    }, isDark),
                    _buildFilterPill(
                      kpiFilters.dateFilter.startsWith('Custom') && kpiFilters.startDate != null
                          ? '${kpiFilters.startDate} ~ ${kpiFilters.endDate}'
                          : 'Custom Range',
                      kpiFilters.dateFilter.startsWith('Custom'),
                      () => _pickCustomDateRange(context, kpiFilters),
                      isDark,
                    ),
                  ],
                ),
              ),
              if (dateRangeText.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: ThemeManager().primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeManager().primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: ThemeManager().primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateRangeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ThemeManager().primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Separator
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),

              // 3. Lead Type Filter (Right side)
              Text(
                'Lead Type:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterPill('Both', kpiFilters.leadType == 'Both', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(leadType: 'Both'));
                    }, isDark),
                    _buildFilterPill('Listing', kpiFilters.leadType == 'Listing', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(leadType: 'Listing'));
                    }, isDark),
                    _buildFilterPill('Requirement', kpiFilters.leadType == 'Requirement', () {
                      context.read<DashboardBloc>().add(const UpdateKpiFilter(leadType: 'Requirement'));
                    }, isDark),
                  ],
                ),
              ),
              if (isKpiLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // 1. Business Type Filter: Rent (default), Re-sale, Both
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Business:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterPill('Rent', kpiFilters.businessType == 'Rent', () {
                        ThemeManager().setRentMode(true);
                        setState(() => _propertyPage = 1);
                        context.read<DashboardBloc>().add(const UpdateKpiFilter(businessType: 'Rent'));
                      }, isDark),
                      _buildFilterPill('Re-sale', kpiFilters.businessType == 'Re-sale', () {
                        ThemeManager().setRentMode(false);
                        setState(() => _propertyPage = 1);
                        context.read<DashboardBloc>().add(const UpdateKpiFilter(businessType: 'Re-sale'));
                      }, isDark),
                      _buildFilterPill('Both', kpiFilters.businessType == 'Both', () {
                        context.read<DashboardBloc>().add(const UpdateKpiFilter(businessType: 'Both'));
                      }, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Date Filter: Today, Weekly (default), Monthly, Yearly, Custom Range
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 64),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Date:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFilterPill('Today', kpiFilters.dateFilter == 'Today', () {
                          context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Today'));
                        }, isDark),
                        _buildFilterPill('Weekly', kpiFilters.dateFilter == 'Weekly', () {
                          context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Weekly'));
                        }, isDark),
                        _buildFilterPill('Monthly', kpiFilters.dateFilter == 'Monthly', () {
                          context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Monthly'));
                        }, isDark),
                        _buildFilterPill('Yearly', kpiFilters.dateFilter == 'Yearly', () {
                          context.read<DashboardBloc>().add(const UpdateKpiFilter(dateFilter: 'Yearly'));
                        }, isDark),
                        _buildFilterPill(
                          kpiFilters.dateFilter.startsWith('Custom') && kpiFilters.startDate != null
                              ? '${kpiFilters.startDate} ~ ${kpiFilters.endDate}'
                              : 'Custom Range',
                          kpiFilters.dateFilter.startsWith('Custom'),
                          () => _pickCustomDateRange(context, kpiFilters),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  if (dateRangeText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: ThemeManager().primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ThemeManager().primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: ThemeManager().primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateRangeText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: ThemeManager().primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Lead Type Filter & Loading Indicator
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lead Type:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterPill('Both', kpiFilters.leadType == 'Both', () {
                        context.read<DashboardBloc>().add(const UpdateKpiFilter(leadType: 'Both'));
                      }, isDark),
                      _buildFilterPill('Listing', kpiFilters.leadType == 'Listing', () {
                        context.read<DashboardBloc>().add(const UpdateKpiFilter(leadType: 'Listing'));
                      }, isDark),
                      _buildFilterPill('Requirement', kpiFilters.leadType == 'Requirement', () {
                        context.read<DashboardBloc>().add(const UpdateKpiFilter(leadType: 'Requirement'));
                      }, isDark),
                    ],
                  ),
                ),
                if (isKpiLoading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context, KpiFilterParams current) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: current.startDate != null && current.endDate != null
          ? DateTimeRange(
              start: DateTime.tryParse(current.startDate!) ?? now.subtract(const Duration(days: 7)),
              end: DateTime.tryParse(current.endDate!) ?? now,
            )
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) {
      if (picked.start.isAfter(picked.end)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start Date must be less than or equal to End Date.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final startStr = DateFormat('yyyy-MM-dd').format(picked.start);
      final endStr = DateFormat('yyyy-MM-dd').format(picked.end);

      context.read<DashboardBloc>().add(UpdateKpiFilter(
        dateFilter: 'Custom Range',
        startDate: startStr,
        endDate: endStr,
      ));
    }
  }

  String _computeDateRangeDisplay(KpiFilterParams filters, DashboardKpisResponse? kpis) {
    if (kpis?.dateRangeDisplay != null && kpis!.dateRangeDisplay!.trim().isNotEmpty) {
      return kpis.dateRangeDisplay!;
    }
    final now = DateTime.now();
    final formatter = DateFormat('dd MMM yyyy');
    final filter = filters.dateFilter.trim().toLowerCase();
    if (filter == 'today') {
      return 'Today: ${formatter.format(now)}';
    } else if (filter == 'weekly') {
      final start = now.subtract(const Duration(days: 7));
      return '${formatter.format(start)} – ${formatter.format(now)}';
    } else if (filter == 'monthly') {
      final start = now.subtract(const Duration(days: 30));
      return '${formatter.format(start)} – ${formatter.format(now)}';
    } else if (filter == 'yearly') {
      final start = now.subtract(const Duration(days: 365));
      return '${formatter.format(start)} – ${formatter.format(now)}';
    } else if (filters.startDate != null && filters.endDate != null) {
      final s = DateTime.tryParse(filters.startDate!);
      final e = DateTime.tryParse(filters.endDate!);
      if (s != null && e != null) {
        return '${formatter.format(s)} – ${formatter.format(e)}';
      }
    }
    return '';
  }

  Widget _buildFilterPill(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    final primaryColor = ThemeManager().primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    int? count,
  }) {
    final isDark = ThemeManager().isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<Widget> cards, {int? maxCols}) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final int cols;
        if (maxCols != null && maxCols == 2) {
          cols = availableWidth >= 440 ? 2 : 1;
        } else {
          if (availableWidth >= 1200) {
            cols = math.min(maxCols ?? 5, 5);
          } else if (availableWidth >= 900) {
            cols = math.min(maxCols ?? 4, 4);
          } else if (availableWidth >= 650) {
            cols = math.min(maxCols ?? 3, 3);
          } else if (availableWidth >= 360) {
            cols = 2;
          } else {
            cols = 1;
          }
        }

        final List<Widget> rows = [];
        for (int i = 0; i < cards.length; i += cols) {
          final rowCards = cards.sublist(i, math.min(i + cols, cards.length));
          final rowChildren = <Widget>[];
          for (final c in rowCards) {
            rowChildren.add(
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: c,
                ),
              ),
            );
          }
          while (rowChildren.length < cols) {
            rowChildren.add(
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: SizedBox.shrink(),
                ),
              ),
            );
          }
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: rowChildren),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildGlobalTopKpis(
    DashboardData data,
    DashboardKpisResponse? kpis,
    KpiFilterParams kpiFilters,
  ) {
    final themeManager = ThemeManager();
    final primaryColor = themeManager.primaryColor;

    final bool enableInv = kpis?.isKpiEnabled('available_inventory') ?? true;
    final bool enableLeads = kpis?.isKpiEnabled('total_leads') ?? true;

    // Strictly independent of filters: always shows all available inventory and all total leads
    final invCount = (kpis != null && kpis.counts.allAvailableInventory > 0)
        ? kpis.counts.allAvailableInventory
        : (data.summary.available > 0
            ? data.summary.available
            : (data.summary.rentalAvailable + data.summary.resaleAvailable));

    final leadsCount = (kpis != null && kpis.counts.allTotalLeads > 0)
        ? kpis.counts.allTotalLeads
        : (data.summary.requirements > 0
            ? data.summary.requirements
            : (data.summary.rentalRequirements + data.summary.resaleRequirements));

    final cards = <Widget>[];

    // 1. Available Inventory (Independent of filters: Clickable Drilldown)
    if (enableInv) {
      cards.add(
        StatCard(
          title: 'Available Inventory',
          value: '$invCount',
          icon: Icons.home_work_rounded,
          accentColor: primaryColor,
          onTap: () async {
            await KpiDrilldownDialogs.showInventoryDrilldown(
              context,
              params: const KpiFilterParams(
                businessType: 'Both',
                dateFilter: 'All',
              ),
              initialStatus: 'Available',
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 2. Total Leads (Independent of filters: Clickable Drilldown)
    if (enableLeads) {
      cards.add(
        StatCard(
          title: 'Total Leads',
          value: '$leadsCount',
          icon: Icons.assignment_rounded,
          accentColor: const Color(0xFF6366F1),
          onTap: () async {
            await KpiDrilldownDialogs.showLeadsDrilldown(
              context,
              params: const KpiFilterParams(
                businessType: 'Both',
                dateFilter: 'All',
                leadType: 'Both',
              ),
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return _buildCardGrid(cards, maxCols: 2);
  }

  Widget _buildTelecallerKpisSection(
    DashboardData data,
    DashboardKpisResponse? kpis,
    KpiFilterParams kpiFilters,
  ) {
    final bool enableTelecallers = kpis?.isKpiEnabled('telecallers') ?? true;
    final bool enableAlloc = kpis?.isKpiEnabled('leads_allocated') ?? true;
    final bool enableOldAlloc = kpis?.isKpiEnabled('old_leads_allocated') ?? true;
    final bool enableCnr = kpis?.isKpiEnabled('cnr') ?? true;
    final bool enableNotInterested = kpis?.isKpiEnabled('not_interested') ?? true;

    final telecallersCount = kpis != null ? kpis.counts.telecallers : 0;
    final allocCount = kpis != null ? kpis.counts.leadsAllocated : 0;
    final oldAllocCount = kpis != null ? kpis.counts.oldLeadsAllocated : 0;
    final cnrCount = kpis != null ? kpis.counts.cnr : 0;
    final notInterestedCount = kpis != null ? kpis.counts.notInterested : 0;

    final cards = <Widget>[];

    // 1. Telecallers
    if (enableTelecallers) {
      cards.add(
        StatCard(
          title: 'Telecallers',
          value: '$telecallersCount',
          icon: Icons.support_agent_rounded,
          accentColor: const Color(0xFF0EA5E9),
          onTap: () async {
            await KpiDrilldownDialogs.showTelecallersDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 2. New Leads Allocated
    if (enableAlloc) {
      cards.add(
        StatCard(
          title: 'New Leads Allocated',
          value: '$allocCount',
          icon: Icons.assignment_ind_rounded,
          accentColor: const Color(0xFF8B5CF6),
          onTap: () async {
            await KpiDrilldownDialogs.showLeadsAllocatedDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 3. Old Leads Allocated
    if (enableOldAlloc) {
      cards.add(
        StatCard(
          title: 'Old Leads Allocated',
          value: '$oldAllocCount',
          icon: Icons.history_toggle_off_rounded,
          accentColor: const Color(0xFFF59E0B),
          onTap: () async {
            await KpiDrilldownDialogs.showLeadsAllocatedDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 4. CNR (Call Not Received / No Response)
    if (enableCnr) {
      cards.add(
        StatCard(
          title: 'CNR (No Response)',
          value: '$cnrCount',
          icon: Icons.phone_missed_rounded,
          accentColor: const Color(0xFFF97316),
          onTap: () async {
            await KpiDrilldownDialogs.showLeadsDrilldown(
              context,
              params: kpiFilters,
              initialStage: 'CNR',
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 5. Not Interested
    if (enableNotInterested) {
      cards.add(
        StatCard(
          title: 'Not Interested',
          value: '$notInterestedCount',
          icon: Icons.do_not_disturb_on_rounded,
          accentColor: const Color(0xFFEF4444),
          onTap: () async {
            await KpiDrilldownDialogs.showNotInterestedDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Telecaller Operations',
          icon: Icons.headset_mic_rounded,
          color: const Color(0xFF0EA5E9),
        ),
        _buildCardGrid(cards),
      ],
    );
  }

  Widget _buildSalesKpisSection(
    DashboardData data,
    DashboardKpisResponse? kpis,
    KpiFilterParams kpiFilters,
  ) {
    final bool enableSalesUsers = kpis?.isKpiEnabled('sales_users') ?? true;
    final bool enableSales = kpis?.isKpiEnabled('assigned_to_sales') ?? true;
    final bool enableVisits = kpis?.isKpiEnabled('site_visits_done') ?? true;
    final bool enableRejectedAfterVisits = kpis?.isKpiEnabled('rejected_after_site_visit') ?? true;
    final bool enableDealWon = kpis?.isKpiEnabled('deal_won') ?? true;

    final salesUsersCount = kpis != null ? kpis.counts.salesUsers : 0;
    final assignedSalesCount = kpis != null ? kpis.counts.assignedToSales : 0;
    final visitsCount = kpis != null ? kpis.counts.siteVisitsDone : 0;
    final rejectedAfterVisitsCount = kpis != null ? kpis.counts.rejectedAfterSiteVisit : 0;
    final dealWonCount = kpis != null ? kpis.counts.dealWon : 0;

    final cards = <Widget>[];

    // 1. Sales Users
    if (enableSalesUsers) {
      cards.add(
        StatCard(
          title: 'Sales Users',
          value: '$salesUsersCount',
          icon: Icons.groups_rounded,
          accentColor: const Color(0xFF0D9488),
          onTap: () async {
            await KpiDrilldownDialogs.showSalesUsersDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 2. Assigned to Sales
    if (enableSales) {
      cards.add(
        StatCard(
          title: 'Assigned to Sales',
          value: '$assignedSalesCount',
          icon: Icons.badge_rounded,
          accentColor: const Color(0xFF10B981),
          onTap: () async {
            await KpiDrilldownDialogs.showAssignedToSalesDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 3. Site Visits Done
    if (enableVisits) {
      cards.add(
        StatCard(
          title: 'Site Visits Done',
          value: '$visitsCount',
          icon: Icons.location_on_rounded,
          accentColor: const Color(0xFFEC4899),
          onTap: () async {
            await KpiDrilldownDialogs.showSiteVisitsDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 4. Rejected After Visit
    if (enableRejectedAfterVisits) {
      cards.add(
        StatCard(
          title: 'Rejected After Visit',
          value: '$rejectedAfterVisitsCount',
          icon: Icons.person_off_rounded,
          accentColor: const Color(0xFFEF4444),
          onTap: () async {
            await KpiDrilldownDialogs.showSiteVisitsDrilldown(
              context,
              params: kpiFilters.copyWith(outcome: 'REJECTED_AFTER_VISIT'),
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 5. Deal Won
    if (enableDealWon) {
      cards.add(
        StatCard(
          title: 'Deal Won',
          value: '$dealWonCount',
          icon: Icons.emoji_events_rounded,
          accentColor: const Color(0xFFF59E0B),
          onTap: () async {
            await KpiDrilldownDialogs.showDealWonDrilldown(
              context,
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Sales Pipeline',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF10B981),
        ),
        _buildCardGrid(cards),
      ],
    );
  }

  Widget _buildDynamicCustomKpisSection(
    DashboardKpisResponse? kpis,
    KpiFilterParams kpiFilters,
  ) {
    if (kpis == null) return const SizedBox.shrink();

    final customKpis = kpis.config.where((c) =>
        !c.isSystem &&
        !KpiRegistryItem.isCanonicalKey(c.kpiKey) &&
        c.isEnabled &&
        c.pages.contains('Admin Dashboard'));

    final cards = <Widget>[];
    for (final customKpi in customKpis) {
      final count = kpis.getDynamicCount(customKpi.kpiKey);
      final iconData = _resolveKpiIcon(customKpi.icon);
      final accentColor = _resolveKpiColor(customKpi.kpiKey);
      cards.add(
        StatCard(
          title: customKpi.kpiLabel,
          value: '$count',
          icon: iconData,
          accentColor: accentColor,
          onTap: customKpi.isClickable
              ? () async {
                  await GenericKpiDrilldownDialog.show(
                    context,
                    kpiKey: customKpi.kpiKey,
                    kpiLabel: customKpi.kpiLabel,
                    initialFilters: kpiFilters.toJson(),
                  );
                  if (mounted) {
                    context.read<DashboardBloc>().add(RefreshDashboard());
                  }
                }
              : null,
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Custom KPIs',
          icon: Icons.tune_rounded,
          color: const Color(0xFF8B5CF6),
        ),
        _buildCardGrid(cards),
      ],
    );
  }

  IconData _resolveKpiIcon(String iconName) {
    switch (iconName) {
      case 'location_on_rounded':
        return Icons.location_on_rounded;
      case 'home_work_rounded':
        return Icons.home_work_rounded;
      case 'assignment_rounded':
        return Icons.assignment_rounded;
      case 'support_agent_rounded':
        return Icons.support_agent_rounded;
      case 'badge_rounded':
        return Icons.badge_rounded;
      case 'emoji_events_rounded':
        return Icons.emoji_events_rounded;
      case 'groups_rounded':
        return Icons.groups_rounded;
      case 'phone_disabled_rounded':
        return Icons.phone_disabled_rounded;
      case 'map_rounded':
        return Icons.map_rounded;
      case 'bar_chart_rounded':
        return Icons.bar_chart_rounded;
      case 'pie_chart_rounded':
        return Icons.pie_chart_rounded;
      case 'check_circle_rounded':
        return Icons.check_circle_rounded;
      case 'trending_up_rounded':
        return Icons.trending_up_rounded;
      case 'monetization_on_rounded':
        return Icons.monetization_on_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'insights_rounded':
      default:
        return Icons.insights_rounded;
    }
  }

  Color _resolveKpiColor(String key) {
    const palette = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF0EA5E9), // Sky
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple
      Color(0xFF14B8A6), // Teal
      Color(0xFF3B82F6), // Blue
    ];
    final hash = key.codeUnits.fold(0, (acc, c) => acc + c);
    return palette[hash % palette.length];
  }


  void _showFilterModal(List<_DisplayProperty> allItems) {
    // Extract all distinct non-empty area names
    final distinctAreas = allItems
        .map((e) => e.areaName)
        .where((a) => a.isNotEmpty && a != 'N/A')
        .toSet()
        .toList();
    distinctAreas.sort();

    Set<String> tempAreas = Set.from(_selectedAreaFilters);
    String tempPriceSort = _priceSortOrder;
    String locationSearchQuery = '';

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final filteredAreas = distinctAreas.where((area) {
                if (locationSearchQuery.isEmpty) return true;
                return area.toLowerCase().contains(
                  locationSearchQuery.toLowerCase(),
                );
              }).toList();

              return SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: CRMColors.cardBgOf(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(CRMBorderRadius.l),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: CRMSpacing.m,
                    right: CRMSpacing.m,
                    top: CRMSpacing.m,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CRMColors.borderOf(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Recent Properties',
                            style: CRMTypography.sectionTitle.copyWith(
                              color: CRMColors.textOf(context),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.45,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price Sorting',
                                  style: CRMTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: CRMColors.textOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RadioListTile<String>(
                                  title: const Text(
                                    'Default Order (Newest First)',
                                  ),
                                  value: 'none',
                                  groupValue: tempPriceSort,
                                  dense: true,
                                  activeColor: CRMColors.primary,
                                  onChanged: (val) =>
                                      setModalState(() => tempPriceSort = val!),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Price: High to Low'),
                                  value: 'high_to_low',
                                  groupValue: tempPriceSort,
                                  dense: true,
                                  activeColor: CRMColors.primary,
                                  onChanged: (val) =>
                                      setModalState(() => tempPriceSort = val!),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Price: Low to High'),
                                  value: 'low_to_high',
                                  groupValue: tempPriceSort,
                                  dense: true,
                                  activeColor: CRMColors.primary,
                                  onChanged: (val) =>
                                      setModalState(() => tempPriceSort = val!),
                                ),
                                const Divider(height: 24),
                                Text(
                                  'Area Filter (Multi-select)',
                                  style: CRMTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: CRMColors.textOf(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  style: TextStyle(
                                    color: CRMColors.textOf(context),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search locations / areas...',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor: CRMColors.backgroundOf(context),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        CRMBorderRadius.s,
                                      ),
                                      borderSide: BorderSide(
                                        color: CRMColors.borderOf(context),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        CRMBorderRadius.s,
                                      ),
                                      borderSide: BorderSide(
                                        color: CRMColors.borderOf(
                                          context,
                                        ).withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setModalState(() {
                                      locationSearchQuery = val.trim();
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                if (filteredAreas.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      distinctAreas.isEmpty
                                          ? 'No area options available.'
                                          : 'No matching locations found.',
                                      style: TextStyle(
                                        color: CRMColors.textSecondaryOf(
                                          context,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredAreas.map((area) {
                                    final isChecked = tempAreas.contains(area);
                                    return CheckboxListTile(
                                      title: Text(
                                        area,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      value: isChecked,
                                      dense: true,
                                      activeColor: CRMColors.primary,
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            tempAreas.add(area);
                                          } else {
                                            tempAreas.remove(area);
                                          }
                                        });
                                      },
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempAreas.clear();
                                tempPriceSort = 'none';
                                locationSearchQuery = '';
                              });
                            },
                            child: const Text('Reset All'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          CRMButton(
                            label: 'Apply Filters',
                            onPressed: () {
                              setState(() {
                                _selectedAreaFilters = tempAreas;
                                _priceSortOrder = tempPriceSort;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final filteredAreas = distinctAreas.where((area) {
                if (locationSearchQuery.isEmpty) return true;
                return area.toLowerCase().contains(
                  locationSearchQuery.toLowerCase(),
                );
              }).toList();

              return AlertDialog(
                backgroundColor: CRMColors.cardBgOf(context),
                title: Text(
                  'Filter Recent Properties',
                  style: CRMTypography.sectionTitle.copyWith(
                    color: CRMColors.textOf(context),
                  ),
                ),
                content: SizedBox(
                  width: CRMBreakpoints.adaptiveWidth(context, 400),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price Sorting',
                          style: CRMTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        RadioListTile<String>(
                          title: const Text('Default Order (Newest First)'),
                          value: 'none',
                          groupValue: tempPriceSort,
                          dense: true,
                          activeColor: CRMColors.primary,
                          onChanged: (val) =>
                              setModalState(() => tempPriceSort = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Price: High to Low'),
                          value: 'high_to_low',
                          groupValue: tempPriceSort,
                          dense: true,
                          activeColor: CRMColors.primary,
                          onChanged: (val) =>
                              setModalState(() => tempPriceSort = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Price: Low to High'),
                          value: 'low_to_high',
                          groupValue: tempPriceSort,
                          dense: true,
                          activeColor: CRMColors.primary,
                          onChanged: (val) =>
                              setModalState(() => tempPriceSort = val!),
                        ),
                        const Divider(height: 24),
                        Text(
                          'Area Filter (Multi-select)',
                          style: CRMTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          style: TextStyle(color: CRMColors.textOf(context)),
                          decoration: InputDecoration(
                            hintText: 'Search locations / areas...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 18,
                            ),
                            filled: true,
                            fillColor: CRMColors.backgroundOf(context),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                CRMBorderRadius.s,
                              ),
                              borderSide: BorderSide(
                                color: CRMColors.borderOf(context),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                CRMBorderRadius.s,
                              ),
                              borderSide: BorderSide(
                                color: CRMColors.borderOf(
                                  context,
                                ).withOpacity(0.5),
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              locationSearchQuery = val.trim();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (filteredAreas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              distinctAreas.isEmpty
                                  ? 'No area options available.'
                                  : 'No matching locations found.',
                              style: TextStyle(
                                color: CRMColors.textSecondaryOf(context),
                              ),
                            ),
                          )
                        else
                          ...filteredAreas.map((area) {
                            final isChecked = tempAreas.contains(area);
                            return CheckboxListTile(
                              title: Text(
                                area,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: isChecked,
                              dense: true,
                              activeColor: CRMColors.primary,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    tempAreas.add(area);
                                  } else {
                                    tempAreas.remove(area);
                                  }
                                });
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempAreas.clear();
                            tempPriceSort = 'none';
                            locationSearchQuery = '';
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      CRMButton(
                        label: 'Apply Filters',
                        onPressed: () {
                          setState(() {
                            _selectedAreaFilters = tempAreas;
                            _priceSortOrder = tempPriceSort;
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _showEditFollowupDialog(DashboardFollowup f) {
    final notesController = TextEditingController(text: f.notes);
    DateTime selectedDate =
        DateTime.tryParse(f.followupDate)?.toLocal() ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hourInt = selectedTime.hour;
            final displayHour = hourInt > 12
                ? hourInt - 12
                : (hourInt == 0 ? 12 : hourInt);
            final amPm = hourInt >= 12 ? 'PM' : 'AM';
            final formattedTimeStr =
                "${displayHour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $amPm";

            return AlertDialog(
              backgroundColor: CRMColors.cardBgOf(context),
              title: Text(
                'Edit / Reschedule Follow-up',
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.textOf(context),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client: ${f.clientName}',
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mobile: ${f.mobile}',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Notes',
                        filled: true,
                        fillColor: CRMColors.backgroundOf(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CRMBorderRadius.s,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date & Time: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $formattedTimeStr',
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.textOf(context),
                        ),
                      ),
                      trailing: Icon(
                        Icons.access_time_rounded,
                        color: CRMColors.primary,
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null && ctx.mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (pickedTime != null) {
                            setModalState(() {
                              selectedTime = pickedTime;
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                CRMButton(
                  label: 'Save Changes',
                  onPressed: () async {
                    final notes = notesController.text.trim();
                    try {
                      await DioClient.dio.patch(
                        '/followups/${f.id}',
                        data: {
                          'notes': notes,
                          'followup_date': selectedDate
                              .toUtc()
                              .toIso8601String(),
                        },
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Follow-up updated successfully.'),
                          ),
                        );
                        context.read<DashboardBloc>().add(RefreshDashboard());
                      }
                    } catch (_) {}
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateFollowupDialog() {
    final clientNameController = TextEditingController();
    final mobileController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hourInt = selectedTime.hour;
            final displayHour = hourInt > 12
                ? hourInt - 12
                : (hourInt == 0 ? 12 : hourInt);
            final amPm = hourInt >= 12 ? 'PM' : 'AM';
            final formattedTimeStr =
                "${displayHour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $amPm";

            return AlertDialog(
              backgroundColor: CRMColors.cardBgOf(context),
              title: Text(
                'Schedule Follow-up',
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.textOf(context),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clientNameController,
                      decoration: InputDecoration(
                        labelText: 'Client Name',
                        filled: true,
                        fillColor: CRMColors.backgroundOf(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CRMBorderRadius.s,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        filled: true,
                        fillColor: CRMColors.backgroundOf(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CRMBorderRadius.s,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Notes',
                        filled: true,
                        fillColor: CRMColors.backgroundOf(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            CRMBorderRadius.s,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ListTile(
                      title: Text(
                        'Date & Time: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $formattedTimeStr',
                      ),
                      trailing: Icon(
                        Icons.access_time_rounded,
                        color: CRMColors.primary,
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (pickedDate != null && ctx.mounted) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (pickedTime != null) {
                            setModalState(() {
                              selectedTime = pickedTime;
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                CRMButton(
                  label: 'Schedule',
                  onPressed: () async {
                    final clientName = clientNameController.text.trim();
                    final mobile = mobileController.text.trim();
                    final notes = notesController.text.trim();

                    if (clientName.isNotEmpty && mobile.isNotEmpty) {
                      try {
                        await DioClient.dio.post(
                          '/followups',
                          data: {
                            'client_name': clientName,
                            'mobile': mobile,
                            'notes': notes,
                            'followup_date': selectedDate
                                .toUtc()
                                .toIso8601String(),
                          },
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Follow-up scheduled successfully.',
                              ),
                            ),
                          );
                          context.read<DashboardBloc>().add(RefreshDashboard());
                        }
                      } catch (_) {}
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSiteVisit(DashboardSiteVisit sv) async {
    final propertyId = sv.propertyId;
    if (propertyId != null && propertyId.isNotEmpty) {
      _openPropertyDetails(propertyId);
      return;
    }

    if (sv.propertyCode != null && sv.propertyCode!.isNotEmpty) {
      final byCode = await PropertiesRepository().getPropertyById(
        sv.propertyCode!,
      );
      if (byCode != null) {
        _openPropertyDetails(byCode.id);
        return;
      }
    }

    final reqId = sv.requirementId;
    if (reqId != null && reqId.isNotEmpty) {
      try {
        final local = await RepositoryCoordinator().requirementLocal
            .getRequirement(reqId);
        if (local != null && mounted) {
          showCRMRequirementDrawer(context, local.toModel());
          return;
        }
      } catch (_) {}

      if (mounted) {
        final name = sv.requirementCustomerName ?? '';
        context.go(
          name.isNotEmpty
              ? '/requirements?openId=${Uri.encodeComponent(reqId)}&search=${Uri.encodeComponent(name)}'
              : '/requirements?openId=${Uri.encodeComponent(reqId)}',
        );
      }
      return;
    }

    if (mounted) {
      _showSiteVisitDetailsSheet(sv);
    }
  }

  void _showSiteVisitDetailsSheet(DashboardSiteVisit sv) {
    final parsed = DateTime.tryParse(sv.visitDate);
    final when = parsed != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal())
        : (sv.visitDate.isNotEmpty ? sv.visitDate : 'Today');
    final title = (sv.requirementCustomerName != null &&
            sv.requirementCustomerName!.isNotEmpty)
        ? sv.requirementCustomerName!
        : (sv.propertyTitle ?? 'Site visit');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Visit: $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: $when'),
              if (sv.creatorName != null && sv.creatorName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Agent: ${sv.creatorName}'),
              ],
              if (sv.remarks != null && sv.remarks!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(sv.remarks!),
              ],
              const SizedBox(height: 8),
              Text('Status: ${sv.status.isNotEmpty ? sv.status : 'Pending'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/requirements');
              },
              child: const Text('Open requirements'),
            ),
          ],
        );
      },
    );
  }

  void _openPropertyDetails(String propertyId) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    if (kIsWeb && !isMobile) {
      final String url = '${Uri.base.origin}/properties/$propertyId';
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } else {
      setState(() {
        _isLoadingProperty = true;
      });
      PropertiesRepository()
          .getPropertyById(propertyId)
          .then((p) {
            if (mounted) {
              setState(() {
                _isLoadingProperty = false;
              });
              if (p != null) {
                showCRMPropertyDrawer(context, p);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to load property details.'),
                  ),
                );
              }
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                _isLoadingProperty = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading property: $e')),
              );
            }
          });
    }
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: CRMColors.danger,
              size: 54,
            ),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Failed to Load Dashboard',
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(
              message,
              style: CRMTypography.body.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.l),
            CRMButton(
              label: 'Retry Connection',
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboard());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplayProperty {
  final String id;
  final String title;
  final String areaName;
  final double price;
  final String listingType;
  final DateTime createdAt;
  final String status;

  _DisplayProperty({
    required this.id,
    required this.title,
    required this.areaName,
    required this.price,
    required this.listingType,
    required this.createdAt,
    required this.status,
  });
}

class StatusPieChartPainter extends CustomPainter {
  final double won;
  final double live;
  final double dead;
  final Color wonColor;
  final Color liveColor;
  final Color deadColor;
  final Color trackColor;
  final double progress;

  StatusPieChartPainter({
    required this.won,
    required this.live,
    required this.dead,
    required this.wonColor,
    required this.liveColor,
    required this.deadColor,
    this.trackColor = const Color(0x1F9CA3AF),
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = won + live + dead;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.34;
    final arcRadius = radius - strokeWidth / 2;
    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);

    // Soft donut track behind the segments — keeps contrast in both themes.
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, arcRadius, trackPaint);

    if (total == 0 || progress <= 0) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    void drawArcSegment(double count, Color color) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 2 * math.pi * progress;
      if (sweepAngle > 0) {
        final gapAdjusted = sweepAngle > 0.05 ? sweepAngle - 0.04 : sweepAngle;
        paint.color = color;
        canvas.drawArc(arcRect, startAngle, gapAdjusted, false, paint);
      }
      startAngle += sweepAngle;
    }

    drawArcSegment(won, wonColor);
    drawArcSegment(live, liveColor);
    drawArcSegment(dead, deadColor);
  }

  @override
  bool shouldRepaint(covariant StatusPieChartPainter oldDelegate) {
    return oldDelegate.won != won ||
        oldDelegate.live != live ||
        oldDelegate.dead != dead ||
        oldDelegate.wonColor != wonColor ||
        oldDelegate.liveColor != liveColor ||
        oldDelegate.deadColor != deadColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progress != progress;
  }
}
