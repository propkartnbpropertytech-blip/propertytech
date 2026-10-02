import 'dart:math' as math;
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
import '../../requirements/repository/requirements_repository.dart';
import '../../requirements/models/requirement_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/mobile/mobile.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../telecaller/screens/telecaller_dashboard_screen.dart';
import '../../sales/bloc/sales_dashboard_bloc.dart';
import '../../requirements/bloc/requirements_bloc.dart';
import '../../campaign/bloc/campaign_leads_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';
import '../models/kpi_models.dart';
import '../widgets/kpi_drilldown_dialogs.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/currency.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/security/role_guard.dart';
import '../widgets/welcome_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_properties_card.dart';
import '../widgets/todays_schedule_card.dart';
import '../widgets/followups_card.dart';
import '../widgets/analytics_section.dart';
import '../../requirements/screens/requirements_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // Table filter and tab states
  String get _activeTab => ThemeManager().isRentMode ? 'Rental' : 'Re-Sale';
  set _activeTab(String value) {
    ThemeManager().setRentMode(value == 'Rental');
  }

  Set<String> _selectedAreaFilters = {};
  String _priceSortOrder = 'none'; // 'none', 'high_to_low', 'low_to_high'

  // Pagination states
  int _propertyPage = 1;
  static const int _propertiesPerPage = 8;

  int _followupPage = 1;
  static const int _followupsPerPage = 5;
  DateTime _selectedFollowupDate = DateTime.now();
  String _activeFollowupSection = 'Follow-ups'; // 'Follow-ups' or 'Schedule'
  String _dashboardFollowupSubTab = 'Today'; // 'Today', 'Due', or 'Future'

  int _notePage = 1;
  static const int _notesPerPage = 5;
  final Map<String, bool> _optimisticChecklistStates = {};
  final List<ChecklistItem> _optimisticAddedChecklistItems = [];
  final Set<String> _optimisticDeletedChecklistIds = {};
  bool _isChecklistLoading = false;
  bool _isLoadingProperty = false;
  late AnimationController _nameShimmerController;
  static bool _greetingPlayedThisSession = false;
  final Map<String, Future<PropertyModel?>> _propertyDetailFutures = {};

  bool get _isRent => _activeTab == 'Rental';
  Color get _atmosphere => CRMColors.terracotta;

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
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
                          const SizedBox(height: 20),

                          // Global Filter Bar (Business Type, Date, Lead Type)
                          _buildGlobalFilterBar(kpiFilters, isKpiLoading, kpis),
                          const SizedBox(height: 20),

                          // 2. Responsive Main Content Area
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 1100;
                              final isTablet =
                                  constraints.maxWidth >= 680 &&
                                  constraints.maxWidth < 1100;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // KPI Cards (Strictly NO percentage values)
                                  _buildModernKpiCards(
                                    data,
                                    kpis,
                                    kpiFilters,
                                    isDesktop,
                                    isTablet,
                                  ),
                                  const SizedBox(height: 24),

                                  // Rent & Re-sale Overview and City -> Area Analytics
                                  AnalyticsSection(
                                    data: data,
                                    kpiFilters: kpiFilters,
                                    kpis: kpis,
                                    isRent: _isRent,
                                    onPropertyTap: (id) => _openPropertyDetails(id),
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
          const SizedBox(height: 16),

          // 2. Global Filter Bar (Business Type, Date, Lead Type)
          _buildGlobalFilterBar(kpiFilters, isKpiLoading, kpis),
          const SizedBox(height: 16),

          // 3. KPI Cards
          _buildModernKpiCards(
            data,
            kpis,
            kpiFilters,
            false,
            false,
          ),
          const SizedBox(height: 16),

          // 4. Middle Section Widgets
          recentPropsWidget,
          const SizedBox(height: 16),
          scheduleWidget,
          const SizedBox(height: 16),
          followupsWidget,
          const SizedBox(height: 16),

          // 5. Analytics Section
          AnalyticsSection(
            data: data,
            isRent: _isRent,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGlobalFilterBar(KpiFilterParams kpiFilters, bool isKpiLoading, DashboardKpisResponse? kpis) {
    final isDark = ThemeManager().isDarkMode;
    final dateRangeText = _computeDateRangeDisplay(kpiFilters, kpis);

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

  Widget _buildModernAtmosphereToggle() {
    final isDark = ThemeManager().isDarkMode;
    final isRent = _isRent;
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF243044) : const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTogglePill('Rental', isRent, isDark),
          _buildTogglePill('Re-Sale', !isRent, isDark),
        ],
      ),
    );
  }

  Widget _buildTogglePill(String label, bool isSelected, bool isDark) {
    final themeManager = ThemeManager();
    final primaryColor = themeManager.primaryColor;
    final primaryHoverColor = themeManager.primaryHoverColor;

    return GestureDetector(
      onTap: () {
        if ((label == 'Rental' && !_isRent) || (label == 'Re-Sale' && _isRent)) {
          setState(() {
            _activeTab = label;
            _propertyPage = 1;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label == 'Rental' ? 'Rent' : 'Re-Sale',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? primaryHoverColor : primaryColor)
                : (isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF68738A)),
          ),
        ),
      ),
    );
  }

  Widget _buildModernKpiCards(
    DashboardData data,
    DashboardKpisResponse? kpis,
    KpiFilterParams kpiFilters,
    bool isDesktop,
    bool isTablet,
  ) {
    final themeManager = ThemeManager();
    final primaryColor = themeManager.primaryColor;

    // Check enabled KPIs from database configuration
    final bool enableInv = kpis?.isKpiEnabled('available_inventory') ?? true;
    final bool enableLeads = kpis?.isKpiEnabled('total_leads') ?? true;
    final bool enableTelecallers = kpis?.isKpiEnabled('telecallers') ?? true;
    final bool enableAlloc = kpis?.isKpiEnabled('leads_allocated') ?? true;
    final bool enableOldAlloc = kpis?.isKpiEnabled('old_leads_allocated') ?? true;
    final bool enableSales = kpis?.isKpiEnabled('assigned_to_sales') ?? true;
    final bool enableVisits = kpis?.isKpiEnabled('site_visits_done') ?? true;
    final bool enableRejectedAfterVisits = kpis?.isKpiEnabled('rejected_after_site_visit') ?? true;
    final bool enableDealWon = kpis?.isKpiEnabled('deal_won') ?? true;
    final bool enableSalesUsers = kpis?.isKpiEnabled('sales_users') ?? true;

    // Database-authoritative exact counts
    final invCount = kpis != null
        ? kpis.counts.availableInventory
        : (_isRent ? data.summary.rentalAvailable : data.summary.resaleAvailable);
    final leadsCount = kpis != null
        ? kpis.counts.totalLeads
        : (_isRent ? data.summary.rentalRequirements : data.summary.resaleRequirements);
    final telecallersCount = kpis != null ? kpis.counts.telecallers : 0;
    final allocCount = kpis != null ? kpis.counts.leadsAllocated : 0;
    final oldAllocCount = kpis != null ? kpis.counts.oldLeadsAllocated : 0;
    final assignedSalesCount = kpis != null ? kpis.counts.assignedToSales : 0;
    final visitsCount = kpis != null ? kpis.counts.siteVisitsDone : 0;
    final rejectedAfterVisitsCount = kpis != null ? kpis.counts.rejectedAfterSiteVisit : 0;
    final dealWonCount = kpis != null ? kpis.counts.dealWon : 0;
    final salesUsersCount = kpis != null ? kpis.counts.salesUsers : 0;

    final cards = <Widget>[];

    // 1. Available Inventory
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
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }
  }

    // 2. Total Leads
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
              params: kpiFilters,
            );
            if (mounted) {
              context.read<DashboardBloc>().add(RefreshDashboard());
            }
          },
        ),
      );
    }

    // 3. Telecallers
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

    // 4. New Leads Allocated
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

    // 5. Old Leads Allocated
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

    // 5. Assigned to Sales
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

    // 6. Site Visits Done
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

    // Rejected After Site Visit
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

    // 7. Deal Won
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

    // 8. Sales Users
    if (enableSalesUsers) {
      cards.add(
        StatCard(
          title: 'Sales Users',
          value: '$salesUsersCount',
          icon: Icons.groups_rounded,
          accentColor: const Color(0xFF10B981),
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

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final int cols;
        if (availableWidth >= 1050) {
          cols = cards.length >= 8 ? 4 : 3;
        } else if (availableWidth >= 700) {
          cols = 3;
        } else if (availableWidth >= 360) {
          cols = 2;
        } else {
          cols = 1;
        }

        final List<Widget> rows = [];
        for (int i = 0; i < cards.length; i += cols) {
          final rowCards = cards.sublist(i, (i + cols).clamp(0, cards.length));
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


  Widget _buildWelcomeHeader(String name, String dateString, String greeting) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final title = Text(
          compact
              ? '$greeting ${name.isNotEmpty ? name : 'there'}'
              : 'Dashboard',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.pageTitle.copyWith(
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w700,
            color: CRMColors.textOf(context),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: CRMSpacing.s),
              Wrap(
                spacing: CRMSpacing.s,
                runSpacing: CRMSpacing.s,
                children: [_buildDateChip(dateString)],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: CRMSpacing.s,
                runSpacing: CRMSpacing.s,
                children: [_buildDateChip(dateString)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateChip(String dateString) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CRMColors.groupedBackground,
        borderRadius: BorderRadius.circular(CRMBorderRadius.button),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Text(
        dateString,
        style: CRMTypography.caption.copyWith(
          color: CRMColors.textSecondaryOf(context),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getRequirementListingTypeLabel(RequirementModel r) {
    final name = r.listingTypeName ?? '';
    final id = r.listingTypeId ?? '';
    final combined = '$name $id'.toLowerCase();
    if (combined.contains('rent')) {
      return 'Rent';
    } else if (combined.contains('sale') || combined.contains('resale')) {
      return 'Re-Sale';
    }
    return 'All';
  }

  int _todayFollowupCount(List<DashboardFollowup> followups) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seen = <String>{};
    var count = 0;
    for (final f in followups) {
      final statusLower = f.status.toLowerCase();
      if (statusLower == 'completed' ||
          statusLower == 'resolved' ||
          statusLower == 'closed' ||
          statusLower == 'done') {
        continue;
      }
      final key = (f.requirementId != null && f.requirementId!.isNotEmpty)
          ? f.requirementId!
          : f.id;
      if (!seen.add(key)) continue;
      final parsed = DateTime.tryParse(f.followupDate);
      if (parsed == null) continue;
      final fDate = DateTime(parsed.year, parsed.month, parsed.day);
      if (fDate.isAtSameMomentAs(today) || fDate.isBefore(today)) {
        count++;
      }
    }
    return count;
  }

  Widget _buildDeskMetrics(DashboardData data, {required bool isDesktop}) {
    final summary = data.summary;
    final availableVal = _isRent
        ? summary.rentalAvailable
        : summary.resaleAvailable;
    final siteVisitsVal = _isRent ? summary.rentalRented : summary.resaleSold;
    final leadsVal = _isRent
        ? summary.rentalRequirements
        : summary.resaleRequirements;
    final wonVal = _isRent
        ? summary.rentalWonRequirements
        : summary.resaleWonRequirements;

    final metrics = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isRent ? 'Rental desk' : 'Re-Sale desk',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildAtmosphereToggle(),
          ],
        ),
        const SizedBox(height: CRMSpacing.m),
        CRMHeroMetric(
          label: 'Available Inventory',
          value: '$availableVal',
          icon: Icons.home_work_rounded,
          backgroundColor: CRMColors.strongCard,
          accentColor: CRMColors.terracotta,
          onTap: () => context.go('/properties'),
        ),
        const SizedBox(height: CRMSpacing.s),
        CRMResponsiveKpiRow(
          minCardWidth: 148,
          children: [
            CRMTintedMetric(
              label: 'Site visits done',
              value: '$siteVisitsVal',
              backgroundColor: CRMColors.cardBgOf(context),
              accentColor: CRMColors.textMutedOf(context),
              onTap: () {
                ThemeManager().setRentMode(_isRent);
                context.go('/requirements?tab=Leads&group=all&status=Site%20Visit%20Done&mode=${_isRent ? 'rent' : 'resale'}');
              },
            ),
            CRMTintedMetric(
              label: 'Leads',
              value: '$leadsVal',
              backgroundColor: CRMColors.cardBgOf(context),
              accentColor: CRMColors.textMutedOf(context),
              onTap: () => context.go('/requirements'),
            ),
            CRMTintedMetric(
              label: 'Won',
              value: '$wonVal',
              backgroundColor: CRMColors.cardBgOf(context),
              accentColor: CRMColors.terracotta,
            ),
          ],
        ),
      ],
    );

    if (!isDesktop) return metrics;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: metrics),
        const SizedBox(width: CRMSpacing.m),
        Expanded(flex: 3, child: _buildTodayWork(data.checklist)),
      ],
    );
  }

  Widget _buildInventoryOverview(DashboardSummary summary) {
    final int availableVal = _isRent
        ? summary.rentalAvailable
        : summary.resaleAvailable;
    final int closedVal = _isRent ? summary.rentalRented : summary.resaleSold;
    final int requirementsVal = _isRent
        ? summary.rentalRequirements
        : summary.resaleRequirements;
    final int wonVal = _isRent
        ? summary.rentalWonRequirements
        : summary.resaleWonRequirements;

    return CRMInventoryOverview(
      title: _isRent ? 'Rental inventory' : 'Re-sale inventory',
      bars: [
        CRMInventoryBar(
          label: 'Available',
          value: availableVal,
          color: CRMColors.strongCard,
        ),
        CRMInventoryBar(
          label: 'Active Requirements',
          value: requirementsVal,
          color: CRMColors.terracotta,
        ),
        CRMInventoryBar(
          label: _isRent ? 'Rented' : 'Sold',
          value: closedVal,
          color: CRMColors.textMuted,
        ),
        CRMInventoryBar(
          label: 'Deals Won',
          value: wonVal,
          color: CRMColors.terracottaHover,
        ),
      ],
    );
  }

  Widget _buildPriorityFollowupsCard(List<DashboardFollowup> followups) {
    final count = _todayFollowupCount(followups);
    return CRMPriorityActionCard(
      title: "Today's Follow-ups",
      value: '$count',
      caption: count == 1 ? 'pending' : 'pending',
      actionLabel: 'View Follow-ups',
      backgroundColor: CRMColors.strongCard,
      accentColor: CRMColors.terracotta,
      onAction: () {
        context.go('/requirements?tab=Follow-ups&subTab=Today');
      },
    );
  }

  Widget _buildAtmosphereToggle() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.button),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetricsTabButton('Rental'),
          _buildMetricsTabButton('Re-Sale'),
        ],
      ),
    );
  }

  Widget _buildMetricsTabButton(String label) {
    final isSelected = _activeTab == label;
    final selectedFill = label == 'Rental'
        ? CRMColors.rentAccent
        : CRMColors.terracotta;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = label;
          _propertyPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.tabSwitch,
        curve: CRMMotion.emphasized,
        padding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.m,
          vertical: 6,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.button - 1),
        ),
        child: Text(
          label == 'Rental' ? 'Rent' : label,
          style: CRMTypography.captionBold.copyWith(
            fontSize: 12,
            color: isSelected
                ? CRMColors.onAtmosphereAccent(label == 'Rental')
                : CRMColors.textSecondaryOf(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentProperties(
    List<RecentProperty> dashboardRecentProperties,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    // Collect display items from dashboardRecentProperties directly
    final List<_DisplayProperty> displayItems = dashboardRecentProperties.map((
      p,
    ) {
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

    // 1. Tab Filtering (Rental vs Sale/Re-Sale)
    List<_DisplayProperty> tabFiltered = displayItems.where((p) {
      final typeLower = p.listingType.toLowerCase();
      if (_activeTab == 'Rental') {
        return typeLower.contains('rent');
      } else {
        return !typeLower.contains('rent');
      }
    }).toList();

    // 2. Area Multi-Checkbox Filter
    if (_selectedAreaFilters.isNotEmpty) {
      tabFiltered = tabFiltered.where((p) {
        return _selectedAreaFilters.contains(p.areaName);
      }).toList();
    }

    // 3. Price Sorting Filter (Default: Newly added properties on top)
    if (_priceSortOrder == 'high_to_low') {
      tabFiltered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_priceSortOrder == 'low_to_high') {
      tabFiltered.sort((a, b) => a.price.compareTo(b.price));
    } else {
      tabFiltered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final hasActiveFilter =
        _selectedAreaFilters.isNotEmpty || _priceSortOrder != 'none';

    // 4. Pagination
    final totalCount = tabFiltered.length;
    final totalPages = (totalCount / _propertiesPerPage).ceil();
    final currentPage = _propertyPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (currentPage - 1) * _propertiesPerPage;
    final endIndex = (startIndex + _propertiesPerPage).clamp(0, totalCount);

    final pageItems = (startIndex < totalCount)
        ? tabFiltered.sublist(startIndex, endIndex)
        : <_DisplayProperty>[];

    return AnimatedContainer(
      duration: CRMMotion.atmosphere,
      child: CRMCard(
        elevated: true,
        accentBorder: _atmosphere.withValues(alpha: 0.28),
        title: 'Recent Properties',
        headerAction: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: hasActiveFilter
                ? _atmosphere
                : CRMColors.textSecondaryOf(context),
            side: BorderSide(
              color: hasActiveFilter
                  ? _atmosphere
                  : CRMColors.borderOf(context),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: () => _showFilterModal(displayItems),
          icon: Icon(
            Icons.tune_rounded,
            size: 16,
            color: hasActiveFilter
                ? _atmosphere
                : CRMColors.textSecondaryOf(context),
          ),
          label: Text(
            hasActiveFilter
                ? 'Filter (${_selectedAreaFilters.length + (_priceSortOrder != 'none' ? 1 : 0)})'
                : 'Filter',
            style: TextStyle(
              fontSize: 13,
              fontWeight: hasActiveFilter ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: CRMSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display Active Filter Chips if any
              if (hasActiveFilter) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_priceSortOrder != 'none')
                      Chip(
                        label: Text(
                          _priceSortOrder == 'high_to_low'
                              ? 'Price: High to Low'
                              : 'Price: Low to High',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onDeleted: () {
                          setState(() {
                            _priceSortOrder = 'none';
                            _propertyPage = 1;
                          });
                        },
                        deleteIcon: const Icon(Icons.cancel_rounded, size: 14),
                      ),
                    ..._selectedAreaFilters.map((area) {
                      return Chip(
                        label: Text(area, style: const TextStyle(fontSize: 11)),
                        onDeleted: () {
                          setState(() {
                            _selectedAreaFilters.remove(area);
                            _propertyPage = 1;
                          });
                        },
                        deleteIcon: const Icon(Icons.cancel_rounded, size: 14),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: CRMSpacing.s),
              ],

              // Table Content (Code and Status columns removed!)
              tabFiltered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No properties found matching criteria.',
                          style: TextStyle(
                            color: CRMColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: pageItems
                          .map((p) => _buildRecentPropertyCard(p))
                          .toList(),
                    ),

              // Pagination Controls for Recent Properties
              if (totalPages > 1) ...[
                const SizedBox(height: CRMSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $currentPage of $totalPages ($totalCount listings)',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                          ),
                          onPressed: currentPage > 1
                              ? () => setState(() => _propertyPage--)
                              : null,
                          tooltip: 'Previous Page',
                        ),
                        Text(
                          '$currentPage / $totalPages',
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onPressed: currentPage < totalPages
                              ? () => setState(() => _propertyPage++)
                              : null,
                          tooltip: 'Next Page',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  Widget _buildRecentPropertyCard(_DisplayProperty p) {
    return FutureBuilder<PropertyModel?>(
      future: _propertyDetailFuture(p.id),
      builder: (context, snapshot) {
        final fullProperty = snapshot.data;
        final hasImage = fullProperty != null && fullProperty.images.isNotEmpty;
        final firstImage = hasImage ? fullProperty.images.first : '';
        final bedCount = fullProperty?.bedrooms ?? 0;
        final bathCount = fullProperty?.bathrooms ?? 0;
        final displayStatus = fullProperty?.propertyStatusName ?? p.status;
        final hasStatus = displayStatus.isNotEmpty && displayStatus != 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _atmosphere.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _atmosphere.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openPropertyDetails(p.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Image on the left
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: hasImage
                              ? () => _showFullImageDialog(context, firstImage)
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 110,
                              height: 85,
                              child: hasImage
                                  ? _buildPropertyThumbnail(firstImage)
                                  : Container(
                                      color: _atmosphere.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Icon(
                                        (fullProperty != null &&
                                                fullProperty.videos.isNotEmpty)
                                            ? Icons.play_circle_outline_rounded
                                            : Icons.apartment_rounded,
                                        color: _atmosphere,
                                        size: 32,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (hasImage &&
                            fullProperty != null &&
                            fullProperty.videos.isNotEmpty)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white30,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.redAccent,
                                size: 14,
                              ),
                            ),
                          ),
                        if (hasStatus)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                displayStatus.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Details on the right
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            style: CRMTypography.cardTitle.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: CRMColors.textSecondaryOf(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  p.areaName,
                                  style: CRMTypography.bodyMedium.copyWith(
                                    color: CRMColors.textSecondaryOf(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                CRMCurrencyFormatter.formatShort(p.price),
                                style: CRMTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _atmosphere,
                                  fontSize: 14,
                                ),
                              ),
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  fullProperty != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bed_outlined,
                                      size: 15,
                                      color: CRMColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$bedCount',
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textSecondaryOf(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.bathroom_outlined,
                                      size: 15,
                                      color: CRMColors.textSecondaryOf(context),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$bathCount',
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.textSecondaryOf(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else if (snapshot.connectionState ==
                                  ConnectionState.waiting)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                  ),
                                )
                              else
                                const SizedBox(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyThumbnail(String url) {
    return CrmNetworkImage(
      url: url,
      fit: BoxFit.cover,
      cacheLogicalWidth: 110,
      cacheLogicalHeight: 85,
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: _buildPropertyThumbnail(imageUrl),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayWork(List<ChecklistItem> items) {
    // Self-clean optimistic checklist states: remove when local item state matches the optimistic target
    _optimisticChecklistStates.removeWhere((itemId, optVal) {
      final match = items.where((x) => x.id == itemId);
      if (match.isNotEmpty) {
        return match.first.isCompleted == optVal;
      }
      return false;
    });

    // Self-clean optimistic deleted checklist IDs: remove when the item is no longer present in the source list
    _optimisticDeletedChecklistIds.removeWhere((itemId) {
      return items.where((x) => x.id == itemId).isEmpty;
    });

    // Self-clean optimistic added checklist items: remove when an item with the same title is in the source list
    _optimisticAddedChecklistItems.removeWhere((addedItem) {
      return items.any(
        (x) =>
            x.title.trim().toLowerCase() ==
            addedItem.title.trim().toLowerCase(),
      );
    });

    final allItems = [...items, ..._optimisticAddedChecklistItems];
    final activeItems = allItems
        .where((item) => !_optimisticDeletedChecklistIds.contains(item.id))
        .toList();

    final totalCount = activeItems.length;
    final totalPages = (totalCount / _notesPerPage).ceil();
    final currentPage = _notePage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (currentPage - 1) * _notesPerPage;
    final endIndex = (startIndex + _notesPerPage).clamp(0, totalCount);

    final pageItems = (startIndex < totalCount)
        ? activeItems.sublist(startIndex, endIndex)
        : <ChecklistItem>[];

    return CRMCard(
      elevated: true,
      accentBorder: CRMColors.primaryOf(context).withValues(alpha: 0.22),
      title: 'Notes',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isChecklistLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(CRMColors.primary),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: CRMColors.primary,
              size: 20,
            ),
            onPressed: _isChecklistLoading ? null : _showAddChecklistDialog,
            tooltip: 'Add Task',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: activeItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No tasks for today.',
                    style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...pageItems.map((item) => _buildTaskTile(item)),
                  if (totalPages > 1) ...[
                    const SizedBox(height: CRMSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page $currentPage of $totalPages ($totalCount notes)',
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondaryOf(context),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 20,
                              ),
                              onPressed: currentPage > 1
                                  ? () => setState(() => _notePage--)
                                  : null,
                              tooltip: 'Previous Page',
                            ),
                            Text(
                              '$currentPage / $totalPages',
                              style: CRMTypography.captionBold.copyWith(
                                color: CRMColors.textOf(context),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                              onPressed: currentPage < totalPages
                                  ? () => setState(() => _notePage++)
                                  : null,
                              tooltip: 'Next Page',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _updateLocalChecklistState(
    String itemId,
    bool isCompleted,
  ) async {}

  Future<void> _deleteLocalChecklistItem(String itemId) async {}

  Widget _buildTaskTile(ChecklistItem item) {
    final bool isCompleted = _optimisticChecklistStates.containsKey(item.id)
        ? _optimisticChecklistStates[item.id]!
        : item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.m,
        vertical: CRMSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCompleted,
            activeColor: CRMColors.success,
            onChanged: _isChecklistLoading
                ? null
                : (val) async {
                    if (val != null) {
                      setState(() {
                        _optimisticChecklistStates[item.id] = val;
                        _isChecklistLoading = true;
                      });
                      if (!item.id.startsWith('temp_')) {
                        try {
                          await _updateLocalChecklistState(item.id, val);
                          await DioClient.dio.patch(
                            '/checklist/${item.id}/toggle',
                            data: {'is_completed': val},
                          );
                          if (mounted) {
                            context.read<DashboardBloc>().add(
                              RefreshDashboard(),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(() {
                              _optimisticChecklistStates.remove(item.id);
                            });
                            await _updateLocalChecklistState(item.id, !val);
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isChecklistLoading = false;
                            });
                          }
                        }
                      } else {
                        setState(() {
                          _isChecklistLoading = false;
                        });
                      }
                    }
                  },
          ),
          const SizedBox(width: CRMSpacing.s),
          Expanded(
            child: Text(
              item.title,
              style: CRMTypography.bodyMedium.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.w600,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: _isChecklistLoading
                  ? CRMColors.textSecondaryOf(context)
                  : CRMColors.danger,
              size: 18,
            ),
            onPressed: _isChecklistLoading
                ? null
                : () async {
                    final itemId = item.id;
                    setState(() {
                      _optimisticDeletedChecklistIds.add(itemId);
                      _optimisticAddedChecklistItems.removeWhere(
                        (x) => x.id == itemId,
                      );
                      _isChecklistLoading = true;
                    });
                    if (!itemId.startsWith('temp_')) {
                      try {
                        await _deleteLocalChecklistItem(itemId);
                        await DioClient.dio.delete('/checklist/$itemId');
                        if (mounted) {
                          context.read<DashboardBloc>().add(RefreshDashboard());
                        }
                      } catch (_) {
                        if (mounted) {
                          setState(() {
                            _optimisticDeletedChecklistIds.remove(itemId);
                          });
                          context.read<DashboardBloc>().add(RefreshDashboard());
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isChecklistLoading = false;
                          });
                        }
                      }
                    } else {
                      setState(() {
                        _isChecklistLoading = false;
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  void _showAddChecklistDialog() {
    final controller = TextEditingController();

    Future<void> saveTask(String text, BuildContext dialogCtx) async {
      final title = text.trim();
      if (title.isNotEmpty) {
        final tempItem = ChecklistItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          isCompleted: false,
          dueDate: '',
        );
        setState(() {
          _optimisticAddedChecklistItems.add(tempItem);
          _isChecklistLoading = true;
        });
        Navigator.pop(dialogCtx);
        try {
          await DioClient.dio.post('/checklist', data: {'title': title});
          if (mounted) {
            context.read<DashboardBloc>().add(RefreshDashboard());
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _optimisticAddedChecklistItems.removeWhere(
                (x) => x.id == tempItem.id,
              );
            });
          }
        } finally {
          if (mounted) {
            setState(() {
              _isChecklistLoading = false;
            });
          }
        }
      } else {
        Navigator.pop(dialogCtx);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBgOf(context),
          title: Text(
            'Add New Task',
            style: CRMTypography.sectionTitle.copyWith(
              color: CRMColors.textOf(context),
            ),
          ),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Task Title',
              filled: true,
              fillColor: CRMColors.backgroundOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              ),
            ),
            autofocus: true,
            onSubmitted: (val) => saveTask(val, ctx),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CRMButton(
              label: 'Save',
              onPressed: () => saveTask(controller.text, ctx),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBigFollowupTabSwitcher(
    int activeFollowups,
    int activeSiteVisits,
  ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(CRMSpacing.xxs),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(
          color: CRMColors.borderOf(context).withOpacity(0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBigFollowupTabButton('Follow-ups', activeFollowups),
          ),
          const SizedBox(width: CRMSpacing.xxs),
          Expanded(
            child: _buildBigFollowupTabButton('Site Visits', activeSiteVisits),
          ),
        ],
      ),
    );
  }

  Widget _buildBigFollowupTabButton(String label, int count) {
    final isSelected = _activeFollowupSection == label;
    return GestureDetector(
      onTap: () => setState(() {
        _activeFollowupSection = label;
        _followupPage = 1;
      }),
      child: AnimatedContainer(
        duration: CRMMotion.tabSwitch,
        curve: CRMMotion.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? CRMColors.primary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
          border: isSelected
              ? Border.all(
                  color: CRMColors.primary.withOpacity(0.3),
                  width: 0.5,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected
                ? CRMColors.primary
                : CRMColors.textSecondaryOf(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSubTabPill(
    String label,
    String tabKey,
    int count,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = _dashboardFollowupSubTab == tabKey;
    return InkWell(
      onTap: () {
        setState(() {
          _dashboardFollowupSubTab = tabKey;
          _followupPage = 1;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : CRMColors.borderOf(context).withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : CRMColors.textSecondaryOf(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowups(
    List<DashboardFollowup> followups,
    List<DashboardSiteVisit> siteVisits,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, DashboardFollowup> latestDashFollowupsMap = {};
    for (final f in followups) {
      final reqIdStr = f.requirementId ?? '';
      final key = reqIdStr.isNotEmpty ? reqIdStr : f.id;
      final existing = latestDashFollowupsMap[key];
      if (existing == null) {
        latestDashFollowupsMap[key] = f;
      } else {
        final dtExisting =
            DateTime.tryParse(existing.followupDate) ?? DateTime(1970);
        final dtCurrent = DateTime.tryParse(f.followupDate) ?? DateTime(1970);
        if (dtCurrent.isAfter(dtExisting)) {
          latestDashFollowupsMap[key] = f;
        }
      }
    }

    final activeFollowups = latestDashFollowupsMap.values.where((f) {
      final statusLower = f.status.toLowerCase();
      return statusLower != 'completed' &&
          statusLower != 'resolved' &&
          statusLower != 'closed' &&
          statusLower != 'done';
    }).toList();

    final todayFollowups = <DashboardFollowup>[];
    final dueFollowups = <DashboardFollowup>[];
    final futureFollowups = <DashboardFollowup>[];

    for (final f in activeFollowups) {
      final parsed = DateTime.tryParse(f.followupDate);
      if (parsed == null) continue;
      final fDate = DateTime(parsed.year, parsed.month, parsed.day);
      if (fDate.isBefore(today)) {
        dueFollowups.add(f);
      } else if (fDate.isAtSameMomentAs(today)) {
        todayFollowups.add(f);
      } else {
        futureFollowups.add(f);
      }
    }

    todayFollowups.sort(
      (a, b) => (DateTime.tryParse(b.followupDate) ?? DateTime(0)).compareTo(
        DateTime.tryParse(a.followupDate) ?? DateTime(0),
      ),
    );
    dueFollowups.sort(
      (a, b) => (DateTime.tryParse(b.followupDate) ?? DateTime(0)).compareTo(
        DateTime.tryParse(a.followupDate) ?? DateTime(0),
      ),
    );
    futureFollowups.sort(
      (a, b) => (DateTime.tryParse(b.followupDate) ?? DateTime(0)).compareTo(
        DateTime.tryParse(a.followupDate) ?? DateTime(0),
      ),
    );

    final filteredSiteVisits = siteVisits.where((sv) {
      final statusLower = sv.status.toLowerCase();
      if (statusLower == 'completed' ||
          statusLower == 'resolved' ||
          statusLower == 'closed' ||
          statusLower == 'done') {
        return false;
      }
      final parsed = DateTime.tryParse(sv.visitDate);
      if (parsed == null) return false;
      return parsed.year == _selectedFollowupDate.year &&
          parsed.month == _selectedFollowupDate.month &&
          parsed.day == _selectedFollowupDate.day;
    }).toList();

    filteredSiteVisits.sort((a, b) {
      final dateA =
          DateTime.tryParse(a.visitDate) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateTime.tryParse(b.visitDate) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    final isSiteVisitsTab = _activeFollowupSection == 'Site Visits';

    List<DashboardFollowup> targetFollowups;
    if (_dashboardFollowupSubTab == 'Due') {
      targetFollowups = dueFollowups;
    } else if (_dashboardFollowupSubTab == 'Future') {
      targetFollowups = futureFollowups;
    } else {
      targetFollowups = todayFollowups;
    }

    final totalCount = isSiteVisitsTab
        ? filteredSiteVisits.length
        : targetFollowups.length;
    final totalPages = (totalCount / _followupsPerPage).ceil();
    final currentPage = _followupPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (currentPage - 1) * _followupsPerPage;
    final endIndex = (startIndex + _followupsPerPage).clamp(0, totalCount);

    final pageItems = (startIndex < totalCount)
        ? (isSiteVisitsTab
              ? filteredSiteVisits.sublist(startIndex, endIndex)
              : targetFollowups.sublist(startIndex, endIndex))
        : [];

    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedFollowupDate);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final Widget dateSelection = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dateStr,
          style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
        ),
        IconButton(
          icon: Icon(
            Icons.calendar_today_rounded,
            color: CRMColors.primary,
            size: 18,
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedFollowupDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() {
                _selectedFollowupDate = picked;
                _followupPage = 1;
              });
            }
          },
          tooltip: 'Filter by Date',
        ),
        IconButton(
          icon: Icon(
            Icons.open_in_new_rounded,
            color: CRMColors.primary,
            size: 18,
          ),
          onPressed: () => context.go(
            '/requirements?tab=Follow-ups&subTab=$_dashboardFollowupSubTab',
          ),
          tooltip: 'Open in Leads',
        ),
      ],
    );

    return CRMCard(
      elevated: true,
      accentBorder: CRMColors.secondaryOf(context).withValues(alpha: 0.28),
      title: 'Scheduled',
      headerAction: isMobile ? null : dateSelection,
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBigFollowupTabSwitcher(
              activeFollowups.length,
              filteredSiteVisits.length,
            ),
            const SizedBox(height: CRMSpacing.m),
            if (!isSiteVisitsTab) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDashboardSubTabPill(
                      "Today's Follow-ups",
                      "Today",
                      todayFollowups.length,
                      Icons.today_rounded,
                      CRMColors.success,
                    ),
                    const SizedBox(width: CRMSpacing.s),
                    _buildDashboardSubTabPill(
                      "Due Follow-ups",
                      "Due",
                      dueFollowups.length,
                      Icons.warning_amber_rounded,
                      CRMColors.warning,
                    ),
                    const SizedBox(width: CRMSpacing.s),
                    _buildDashboardSubTabPill(
                      "Future Follow-ups",
                      "Future",
                      futureFollowups.length,
                      Icons.next_plan_rounded,
                      CRMColors.info,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
            ],
            if (isMobile) ...[
              Align(alignment: Alignment.centerRight, child: dateSelection),
              const SizedBox(height: CRMSpacing.s),
            ],
            pageItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        isSiteVisitsTab
                            ? 'No scheduled site visits for $dateStr.'
                            : 'No ${_dashboardFollowupSubTab.toLowerCase()} follow-ups available.',
                        style: TextStyle(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ...pageItems.map((item) {
                        if (isSiteVisitsTab) {
                          return _buildSiteVisitTile(
                            item as DashboardSiteVisit,
                          );
                        } else {
                          return _buildFollowupTile(item as DashboardFollowup);
                        }
                      }),
                      if (totalPages > 1) ...[
                        const SizedBox(height: CRMSpacing.m),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Page $currentPage of $totalPages ($totalCount total)',
                              style: CRMTypography.caption.copyWith(
                                color: CRMColors.textSecondaryOf(context),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    size: 20,
                                  ),
                                  onPressed: currentPage > 1
                                      ? () => setState(() => _followupPage--)
                                      : null,
                                  tooltip: 'Previous Page',
                                ),
                                Text(
                                  '$currentPage / $totalPages',
                                  style: CRMTypography.captionBold.copyWith(
                                    color: CRMColors.textOf(context),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                  ),
                                  onPressed: currentPage < totalPages
                                      ? () => setState(() => _followupPage++)
                                      : null,
                                  tooltip: 'Next Page',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteVisitTile(DashboardSiteVisit sv) {
    final date = DateTime.tryParse(sv.visitDate)?.toLocal() ?? DateTime.now();
    final hourInt = date.hour;
    final displayHour = hourInt > 12
        ? hourInt - 12
        : (hourInt == 0 ? 12 : hourInt);
    final amPm = hourInt >= 12 ? 'PM' : 'AM';
    final formattedTime =
        "${displayHour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm";
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    return InkWell(
      onTap: () => _openSiteVisit(sv),
      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      child: Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context).withOpacity(0.4),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.backgroundOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: sv.status == 'Pending'
                ? CRMColors.warning.withOpacity(0.1)
                : CRMColors.success.withOpacity(0.1),
            radius: 18,
            child: Icon(
              Icons.location_on_rounded,
              color: sv.status == 'Pending'
                  ? CRMColors.warning
                  : CRMColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sv.requirementCustomerName ?? 'Client Site Visit',
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sv.propertyCode != null || sv.propertyTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Property: ${sv.propertyCode ?? ""} - ${sv.propertyTitle ?? ""}',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                    ),
                  ),
                ],
                if (sv.remarks != null && sv.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sv.remarks!,
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Scheduled: $formattedDate at $formattedTime',
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (context.read<AuthBloc>().state is Authenticated &&
                    (context.read<AuthBloc>().state as Authenticated)
                            .user
                            .role !=
                        'Sales' &&
                    sv.creatorName != null &&
                    sv.creatorName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: CRMColors.textSecondaryOf(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ${sv.creatorName}',
                        style: CRMTypography.captionBold.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (sv.status == 'Pending') ...[
            IconButton(
              icon: Icon(
                Icons.check_circle_outline_rounded,
                color: CRMColors.success,
                size: 20,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor: CRMColors.cardBgOf(context),
                      title: Text(
                        'Site Visit Outcome',
                        style: CRMTypography.sectionTitle.copyWith(
                          color: CRMColors.textOf(context),
                        ),
                      ),
                      content: Text(
                        'What was the outcome of this site visit?',
                        style: CRMTypography.body.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        CRMButton(
                          label: 'Not Interested',
                          variant: CRMButtonVariant.outline,
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _handleSiteVisitOutcome(sv, 'Not Interested');
                          },
                        ),
                        const SizedBox(width: 8),
                        CRMButton(
                          label: 'Site Visit Done',
                          variant: CRMButtonVariant.primary,
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _handleSiteVisitOutcome(
                              sv,
                              'Site Visit Done',
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Mark Completed',
            ),
          ],
        ],
      ),
    ),
    );
  }

  Future<void> _handleSiteVisitOutcome(
    DashboardSiteVisit sv,
    String outcomeStatus,
  ) async {
    try {
      final isRejected = outcomeStatus.toLowerCase().contains('not') || outcomeStatus.toLowerCase().contains('reject');
      final outcomeKey = isRejected ? 'REJECTED_AFTER_VISIT' : 'INTERESTED';

      // 1. Mark the site visit as completed in the backend with historical outcome
      await DioClient.dio.patch(
        '/site-visits/${sv.id}/status',
        data: {
          'status': 'Completed',
          'outcome': outcomeKey,
        },
      );

      // 2. Automatically update the requirement status in the backend and local cache
      if (sv.requirementId != null) {
        final localReq = await RepositoryCoordinator().requirementLocal
            .getRequirement(sv.requirementId!);
        if (localReq != null) {
          final model = localReq.toModel();
          final RequirementsRepository requirementsRepository =
              RequirementsRepository();
          await requirementsRepository.updateRequirement(
            model.copyWith(status: outcomeStatus),
          );
        } else {
          // Fallback: send the update request directly to backend
          await DioClient.dio.put(
            '/requirements/${sv.requirementId}',
            data: {'status': outcomeStatus},
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Site visit marked as completed. Requirement updated to $outcomeStatus.',
            ),
            backgroundColor: CRMColors.success,
          ),
        );
        // Refresh dashboard bloc
        context.read<DashboardBloc>().add(RefreshDashboard());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildFollowupTile(DashboardFollowup f) {
    final date = DateTime.tryParse(f.followupDate)?.toLocal() ?? DateTime.now();
    final hourInt = date.hour;
    final displayHour = hourInt > 12
        ? hourInt - 12
        : (hourInt == 0 ? 12 : hourInt);
    final amPm = hourInt >= 12 ? 'PM' : 'AM';
    final formattedTime =
        "${displayHour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm";
    final formattedDate = "${date.day}/${date.month}/${date.year}";
    final currentRole = (RoleGuard.currentUser?.role ??
            (context.read<AuthBloc>().state is Authenticated
                ? (context.read<AuthBloc>().state as Authenticated).user.role
                : ''))
        .toLowerCase();
    final isRealAdmin = currentRole == 'admin' || currentRole == 'super admin';

    return InkWell(
      onTap: () => _showEditFollowupDialog(f),
      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      child: Container(
        margin: const EdgeInsets.only(bottom: CRMSpacing.s),
        padding: const EdgeInsets.all(CRMSpacing.m),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context).withOpacity(0.4),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: CRMColors.backgroundOf(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: f.status == 'Pending'
                  ? CRMColors.warning.withOpacity(0.1)
                  : CRMColors.success.withOpacity(0.1),
              radius: 18,
              child: Icon(
                Icons.phone_in_talk_rounded,
                color: f.status == 'Pending'
                    ? CRMColors.warning
                    : CRMColors.success,
                size: 18,
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.clientName,
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.textOf(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mobile: ${f.mobile}',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                    ),
                  ),
                  if (f.notes != null && f.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      f.notes!,
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Scheduled: $formattedDate at $formattedTime',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isRealAdmin &&
                      f.creatorName != null &&
                      f.creatorName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.support_agent_rounded,
                          size: 13,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Telecaller: ${f.creatorName}',
                            style: CRMTypography.captionBold.copyWith(
                              color: const Color(0xFF6366F1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (f.status == 'Pending') ...[
              IconButton(
                icon: Icon(
                  Icons.check_circle_outline_rounded,
                  color: CRMColors.success,
                  size: 20,
                ),
                onPressed: () async {
                  try {
                    await DioClient.dio.patch(
                      '/followups/${f.id}/status',
                      data: {'status': 'Completed'},
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Follow-up marked as completed.'),
                        ),
                      );
                      context.read<DashboardBloc>().add(RefreshDashboard());
                    }
                  } catch (_) {}
                },
                tooltip: 'Mark Completed',
              ),
            ],
          ],
        ),
      ),
    );
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
