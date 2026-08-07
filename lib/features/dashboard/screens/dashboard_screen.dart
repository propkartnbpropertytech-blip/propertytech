import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../../core/design_system/widgets/crm_donut_chart.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/currency.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/model_mappers.dart';

import '../../../core/theme/theme_manager.dart';

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
  String? _chartFilterLabel;
  bool _showPortfolioChart = false;

  // Pagination states
  int _propertyPage = 1;
  static const int _propertiesPerPage = 5;

  int _followupPage = 1;
  static const int _followupsPerPage = 5;
  DateTime _selectedFollowupDate = DateTime.now();
  String _activeFollowupSection = 'Follow-ups'; // 'Follow-ups' or 'Schedule'

  int _notePage = 1;
  static const int _notesPerPage = 5;
  final Map<String, bool> _optimisticChecklistStates = {};
  final List<ChecklistItem> _optimisticAddedChecklistItems = [];
  final Set<String> _optimisticDeletedChecklistIds = {};
  bool _isChecklistLoading = false;
  bool _isLoadingProperty = false;
  late AnimationController _nameShimmerController;
  static bool _greetingPlayedThisSession = false;

  bool get _isRent => _activeTab == 'Rental';
  Color get _atmosphere => CRMColors.atmosphereAccent(_isRent);

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
    context.read<DashboardBloc>().add(LoadDashboard());
  }

  @override
  void dispose() {
    _nameShimmerController.dispose();
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final authState = context.watch<AuthBloc>().state;
    String userName = '';
    if (authState is Authenticated) {
      userName = authState.user.fullName;
    }

    final dateString = _getFormattedDate();
    final greeting = _getGreeting();

    return Stack(
      children: [
        BlocConsumer<DashboardBloc, DashboardState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is DashboardLoading || state is DashboardInitial) {
              return const Padding(
                padding: EdgeInsets.all(CRMSpacing.l),
                child: CRMListSkeleton(count: 4),
              );
            } else if (state is DashboardError) {
              return _buildErrorState(state.message);
            } else if (state is DashboardLoadedState || state is DashboardRefreshing) {
              final data = (state is DashboardLoadedState)
                  ? state.data
                  : (state as DashboardRefreshing).data;

              return RefreshIndicator(
                onRefresh: () async {
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
                      _buildWelcomeHeader(userName, dateString, greeting),
                      const SizedBox(height: CRMSpacing.l),

                      // 2. Responsive Main Content Area
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 900;
                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      _buildKPIGrids(data.summary, isDesktop: true),
                                      const SizedBox(height: CRMSpacing.l),
                                      _buildRecentProperties(data.recentProperties),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: CRMSpacing.l),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _buildTodayWork(data.checklist),
                                      const SizedBox(height: CRMSpacing.l),
                                      _buildFollowups(data.followups, data.siteVisits),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildKPIGrids(data.summary, isDesktop: false),
                                const SizedBox(height: CRMSpacing.l),
                                _buildRecentProperties(data.recentProperties),
                                const SizedBox(height: CRMSpacing.l),
                                _buildTodayWork(data.checklist),
                                const SizedBox(height: CRMSpacing.l),
                                _buildFollowups(data.followups, data.siteVisits),
                              ],
                            );
                          }
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWelcomeHeader(String name, String dateString, String greeting) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget nameWidget = AnimatedBuilder(
      animation: _nameShimmerController,
      builder: (context, _) {
        final t = _nameShimmerController.value;
        final shimmer = (t < 1.0)
            ? LinearGradient(
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(-0.5 + 3 * t, 0),
                colors: [
                  CRMColors.textOf(context),
                  CRMColors.primaryOf(context),
                  CRMColors.accentOf(context),
                  CRMColors.textOf(context),
                ],
                stops: const [0.0, 0.35, 0.55, 1.0],
              )
            : null;

        final style = CRMTypography.greetingName.copyWith(
          fontSize: isMobile ? 24 : 32,
          color: CRMColors.textOf(context),
        );

        if (shimmer == null) {
          return Text(name, style: style);
        }
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => shimmer.createShader(bounds),
          child: Text(name, style: style.copyWith(color: Colors.white)),
        );
      },
    );

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondaryOf(context),
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        nameWidget,
      ],
    );

    Widget rightColumn = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CRMColors.primaryOf(context).withValues(alpha: isDark ? 0.18 : 0.1),
            CRMColors.cardBgOf(context),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CRMColors.primaryOf(context).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            dateString,
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.primaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          const SizedBox(height: CRMSpacing.s),
          rightColumn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leftColumn),
        rightColumn,
      ],
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
    return 'Other';
  }

  Widget _buildKPIGrids(DashboardSummary summary, {required bool isDesktop}) {
    final atmosphere = _atmosphere;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int availableVal =
        _isRent ? summary.rentalAvailable : summary.resaleAvailable;
    final int closedVal = _isRent ? summary.rentalRented : summary.resaleSold;
    final int requirementsVal =
        _isRent ? summary.rentalRequirements : summary.resaleRequirements;
    final int wonVal =
        _isRent ? summary.rentalWonRequirements : summary.resaleWonRequirements;

    final authState = context.read<AuthBloc>().state;
    String role = 'Sales';
    if (authState is Authenticated) {
      role = authState.user.role;
    }

    String availableTitle = 'Available Inventory';
    String siteVisitTitle = 'My Site Visits Done';
    String requirementsTitle = 'My Requirements';
    String wonTitle = 'My Won';

    if (role == 'Super Admin') {
      availableTitle = 'All Properties';
      siteVisitTitle = 'All Site Visits Done';
      requirementsTitle = 'All Requirements';
      wonTitle = 'All Won';
    } else if (role == 'Admin') {
      availableTitle = 'Available Inventory';
      siteVisitTitle = 'Site visits done';
      requirementsTitle = 'Leads';
      wonTitle = 'Won';
    }

    final List<Widget> cards = [
      CRMKPICard(
        title: availableTitle,
        value: '$availableVal',
        icon: Icons.check_circle_outline_rounded,
        iconColor: CRMColors.success,
        onTap: () => context.go('/properties'),
      ),
      CRMKPICard(
        title: siteVisitTitle,
        value: '$closedVal',
        icon: Icons.directions_walk_rounded,
        iconColor: _isRent ? CRMColors.info : CRMColors.warning,
      ),
      CRMKPICard(
        title: requirementsTitle,
        value: '$requirementsVal',
        icon: Icons.assignment_turned_in_outlined,
        iconColor: CRMColors.secondaryOf(context),
        onTap: () => context.go('/requirements'),
      ),
      CRMKPICard(
        title: wonTitle,
        value: '$wonVal',
        icon: Icons.emoji_events_outlined,
        iconColor: CRMColors.success,
      ),
    ];

    final sectors = [
      ChartSector(
        label: 'Available',
        value: availableVal.toDouble().clamp(0.01, double.infinity),
        color: atmosphere,
      ),
      ChartSector(
        label: siteVisitTitle,
        value: closedVal.toDouble().clamp(0.01, double.infinity),
        color: _isRent ? CRMColors.info : CRMColors.warning,
      ),
      ChartSector(
        label: 'Requirements',
        value: requirementsVal.toDouble().clamp(0.01, double.infinity),
        color: CRMColors.secondaryOf(context),
      ),
      ChartSector(
        label: 'Won',
        value: wonVal.toDouble().clamp(0.01, double.infinity),
        color: CRMColors.success,
      ),
    ];

    final int crossAxisCount = isDesktop
        ? 2
        : CRMBreakpoints.kpiColumns(context, desktop: 4);
    final double childAspectRatio = isDesktop
        ? 2.4
        : CRMBreakpoints.kpiAspectRatio(context);

    return AnimatedContainer(
      duration: CRMMotion.atmosphere,
      curve: CRMMotion.emphasized,
      padding: const EdgeInsets.all(CRMSpacing.s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            atmosphere.withValues(alpha: isDark ? 0.12 : 0.07),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: atmosphere.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: CRMSpacing.xs,
              bottom: CRMSpacing.m,
              right: CRMSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRent ? 'Rental desk' : 'Re-Sale desk',
                        style: CRMTypography.sectionTitle.copyWith(
                          color: CRMColors.textOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAtmosphereToggle(),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: CRMMotion.atmosphere,
            switchInCurve: CRMMotion.emphasized,
            child: KeyedSubtree(
              key: ValueKey(_activeTab),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: CRMSpacing.m,
                  mainAxisSpacing: CRMSpacing.m,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => cards[index],
              ),
            ),
          ),
          const SizedBox(height: CRMSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showPortfolioChart = !_showPortfolioChart;
                  if (!_showPortfolioChart) {
                    _chartFilterLabel = null;
                  }
                });
              },
              icon: Icon(
                _showPortfolioChart
                    ? Icons.expand_less_rounded
                    : Icons.pie_chart_outline_rounded,
                size: 18,
                color: atmosphere,
              ),
              label: Text(
                _showPortfolioChart ? 'Hide chart' : 'View chart',
                style: CRMTypography.captionBold.copyWith(color: atmosphere),
              ),
              style: TextButton.styleFrom(
                foregroundColor: atmosphere,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          AnimatedSize(
            duration: CRMMotion.sheet,
            curve: CRMMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _showPortfolioChart
                ? Padding(
                    padding: const EdgeInsets.only(top: CRMSpacing.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TweenAnimationBuilder<double>(
                          key: const ValueKey('portfolio-chart-enter'),
                          tween: Tween(begin: 0, end: 1),
                          duration: CRMMotion.entrySettle,
                          curve: CRMMotion.emphasized,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: CRMDonutChartCard(
                            title: 'Portfolio mix',
                            subtitle:
                                'See where inventory, demand, and wins sit — tap a slice to focus',
                            sectors: sectors,
                            accent: atmosphere,
                            replayOnUpdate: false,
                            onSectorTap: (sector) {
                              setState(() {
                                _chartFilterLabel = sector.label;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Focusing ${_isRent ? 'Rent' : 'Re-Sale'} · ${sector.label}',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_chartFilterLabel != null) ...[
                          const SizedBox(height: CRMSpacing.s),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ActionChip(
                              label: Text('Filter: $_chartFilterLabel'),
                              avatar: const Icon(
                                Icons.filter_alt_rounded,
                                size: 16,
                              ),
                              onPressed: () =>
                                  setState(() => _chartFilterLabel = null),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphereToggle() {
    return AnimatedContainer(
      duration: CRMMotion.tabSwitch,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _atmosphere.withValues(alpha: 0.45)),
        boxShadow: CRMShadows.atmosphereGlow(_atmosphere),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetricsTabButton('Rental'),
          const SizedBox(width: 4),
          _buildMetricsTabButton('Re-Sale'),
        ],
      ),
    );
  }

  Widget _buildMetricsTabButton(String label) {
    final isSelected = _activeTab == label;
    final accent = label == 'Rental' ? CRMColors.rentAccent : CRMColors.resaleAccent;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = label;
          _propertyPage = 1;
          _chartFilterLabel = null;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.tabSwitch,
        curve: CRMMotion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.l),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: CRMColors.atmosphereGradient(label == 'Rental'),
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label == 'Rental' ? 'Rent' : label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? Colors.white
                : CRMColors.textSecondaryOf(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }



  Widget _buildRecentProperties(List<RecentProperty> dashboardRecentProperties) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    // Collect display items from dashboardRecentProperties directly
    final List<_DisplayProperty> displayItems = dashboardRecentProperties.map((p) {
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

    final hasActiveFilter = _selectedAreaFilters.isNotEmpty || _priceSortOrder != 'none';

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
      subtitle: _isRent
          ? 'Latest rental inventory matching your desk — act without leaving the dashboard'
          : 'Latest re-sale inventory matching your desk — act without leaving the dashboard',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: hasActiveFilter ? _atmosphere : CRMColors.textSecondaryOf(context),
          side: BorderSide(
            color: hasActiveFilter ? _atmosphere : CRMColors.borderOf(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () => _showFilterModal(displayItems),
        icon: Icon(
          Icons.tune_rounded,
          size: 16,
          color: hasActiveFilter ? _atmosphere : CRMColors.textSecondaryOf(context),
        ),
        label: Text(
          hasActiveFilter ? 'Filter (${_selectedAreaFilters.length + (_priceSortOrder != 'none' ? 1 : 0)})' : 'Filter',
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
                        _priceSortOrder == 'high_to_low' ? 'Price: High to Low' : 'Price: Low to High',
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
                        style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                      ),
                    ),
                  )
                : Column(
                    children: pageItems.map((p) => _buildRecentPropertyCard(p)).toList(),
                  ),

            // Pagination Controls for Recent Properties
            if (totalPages > 1) ...[
              const SizedBox(height: CRMSpacing.m),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $currentPage of $totalPages ($totalCount listings)',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: currentPage > 1
                            ? () => setState(() => _propertyPage--)
                            : null,
                        tooltip: 'Previous Page',
                      ),
                      Text(
                        '$currentPage / $totalPages',
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
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
                return area.toLowerCase().contains(locationSearchQuery.toLowerCase());
              }).toList();

              return SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: CRMColors.cardBgOf(context),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.l)),
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
                            style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
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
                            maxHeight: MediaQuery.of(context).size.height * 0.45,
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
                                  title: const Text('Default Order (Newest First)'),
                                  value: 'none',
                                  groupValue: tempPriceSort,
                                  dense: true,
                                  activeColor: CRMColors.primary,
                                  onChanged: (val) => setModalState(() => tempPriceSort = val!),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Price: High to Low'),
                                  value: 'high_to_low',
                                  groupValue: tempPriceSort,
                                  dense: true,
                                  activeColor: CRMColors.primary,
                                  onChanged: (val) => setModalState(() => tempPriceSort = val!),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Price: Low to High'),
                                  value: 'low_to_high',
                                  groupValue: tempPriceSort,
                                  dense: true,
                                  activeColor: CRMColors.primary,
                                  onChanged: (val) => setModalState(() => tempPriceSort = val!),
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
                                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                    filled: true,
                                    fillColor: CRMColors.backgroundOf(context),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                      borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5)),
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
                                      distinctAreas.isEmpty ? 'No area options available.' : 'No matching locations found.',
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                                    ),
                                  )
                                else
                                  ...filteredAreas.map((area) {
                                    final isChecked = tempAreas.contains(area);
                                    return CheckboxListTile(
                                      title: Text(area, style: const TextStyle(fontSize: 14)),
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
                return area.toLowerCase().contains(locationSearchQuery.toLowerCase());
              }).toList();

              return AlertDialog(
                backgroundColor: CRMColors.cardBgOf(context),
                title: Text(
                  'Filter Recent Properties',
                  style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                ),
                content: SizedBox(
                  width: 400,
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
                          onChanged: (val) => setModalState(() => tempPriceSort = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Price: High to Low'),
                          value: 'high_to_low',
                          groupValue: tempPriceSort,
                          dense: true,
                          activeColor: CRMColors.primary,
                          onChanged: (val) => setModalState(() => tempPriceSort = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Price: Low to High'),
                          value: 'low_to_high',
                          groupValue: tempPriceSort,
                          dense: true,
                          activeColor: CRMColors.primary,
                          onChanged: (val) => setModalState(() => tempPriceSort = val!),
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
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            filled: true,
                            fillColor: CRMColors.backgroundOf(context),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                              borderSide: BorderSide(color: CRMColors.borderOf(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                              borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5)),
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
                              distinctAreas.isEmpty ? 'No area options available.' : 'No matching locations found.',
                              style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                            ),
                          )
                        else
                          ...filteredAreas.map((area) {
                            final isChecked = tempAreas.contains(area);
                            return CheckboxListTile(
                              title: Text(area, style: const TextStyle(fontSize: 14)),
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
      future: PropertiesRepository().getPropertyById(p.id),
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
            color: CRMColors.cardBgOf(context).withValues(alpha: 0.55),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
                                        color: _atmosphere.withValues(alpha: 0.12),
                                        child: Icon(
                                          Icons.apartment_rounded,
                                          color: _atmosphere,
                                          size: 32,
                                        ),
                                      ),
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
                                if (snapshot.connectionState == ConnectionState.done && fullProperty != null)
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
                                          color: CRMColors.textSecondaryOf(context),
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
                                          color: CRMColors.textSecondaryOf(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (snapshot.connectionState == ConnectionState.waiting)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
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
          ),
        );
      },
    );
  }

  Widget _buildPropertyThumbnail(String url) {
    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {}
    }
    if (kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image_outlined, size: 16),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image_outlined, size: 16),
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
      return items.any((x) => x.title.trim().toLowerCase() == addedItem.title.trim().toLowerCase());
    });

    final allItems = [...items, ..._optimisticAddedChecklistItems];
    final activeItems = allItems.where((item) => !_optimisticDeletedChecklistIds.contains(item.id)).toList();

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
      title: "Today's Focus",
      subtitle: 'Notes that need attention before you leave the desk',
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
            icon: Icon(Icons.add_circle_outline_rounded, color: CRMColors.primary, size: 20),
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
                  child: Text('No tasks for today.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
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
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 20),
                              onPressed: currentPage > 1
                                  ? () => setState(() => _notePage--)
                                  : null,
                              tooltip: 'Previous Page',
                            ),
                            Text(
                              '$currentPage / $totalPages',
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 20),
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

  Future<void> _updateLocalChecklistState(String itemId, bool isCompleted) async {}

  Future<void> _deleteLocalChecklistItem(String itemId) async {}

  Widget _buildTaskTile(ChecklistItem item) {
    final bool isCompleted = _optimisticChecklistStates.containsKey(item.id)
        ? _optimisticChecklistStates[item.id]!
        : item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
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
                          await DioClient.dio.patch('/checklist/${item.id}/toggle', data: {'is_completed': val});
                          if (mounted) {
                            context.read<DashboardBloc>().add(RefreshDashboard());
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
              color: _isChecklistLoading ? CRMColors.textSecondaryOf(context) : CRMColors.danger,
              size: 18,
            ),
            onPressed: _isChecklistLoading
                ? null
                : () async {
                    final itemId = item.id;
                    setState(() {
                      _optimisticDeletedChecklistIds.add(itemId);
                      _optimisticAddedChecklistItems.removeWhere((x) => x.id == itemId);
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
              _optimisticAddedChecklistItems.removeWhere((x) => x.id == tempItem.id);
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
          title: Text('Add New Task', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Task Title',
              filled: true,
              fillColor: CRMColors.backgroundOf(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
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

  Widget _buildBigFollowupTabSwitcher(int activeFollowups, int activeSiteVisits) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(CRMSpacing.xxs),
      decoration: BoxDecoration(
        color: CRMColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 0.5),
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
          color: isSelected ? CRMColors.primary.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
          border: isSelected
              ? Border.all(color: CRMColors.primary.withOpacity(0.3), width: 0.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected ? CRMColors.primary : CRMColors.textSecondaryOf(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFollowups(List<DashboardFollowup> followups, List<DashboardSiteVisit> siteVisits) {
    // 1. Filter followups by _selectedFollowupDate (default today) and status
    final filteredFollowups = followups.where((f) {
      final statusLower = f.status.toLowerCase();
      if (statusLower == 'completed' || statusLower == 'resolved' || statusLower == 'closed' || statusLower == 'done') {
        return false;
      }
      final parsed = DateTime.tryParse(f.followupDate);
      if (parsed == null) return false;
      return parsed.year == _selectedFollowupDate.year &&
          parsed.month == _selectedFollowupDate.month &&
          parsed.day == _selectedFollowupDate.day;
    }).toList();

    // 2. Sort followups: latest scheduled/created followups on top
    filteredFollowups.sort((a, b) {
      final dateA = DateTime.tryParse(a.followupDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.followupDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // Latest on top
    });

    // Filter site visits by _selectedFollowupDate and status
    final filteredSiteVisits = siteVisits.where((sv) {
      final statusLower = sv.status.toLowerCase();
      if (statusLower == 'completed' || statusLower == 'resolved' || statusLower == 'closed' || statusLower == 'done') {
        return false;
      }
      final parsed = DateTime.tryParse(sv.visitDate);
      if (parsed == null) return false;
      return parsed.year == _selectedFollowupDate.year &&
          parsed.month == _selectedFollowupDate.month &&
          parsed.day == _selectedFollowupDate.day;
    }).toList();

    // Sort site visits: latest scheduled site visits on top
    filteredSiteVisits.sort((a, b) {
      final dateA = DateTime.tryParse(a.visitDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b.visitDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    final isSiteVisitsTab = _activeFollowupSection == 'Site Visits';

    // 3. Pagination calculation
    final totalCount = isSiteVisitsTab ? filteredSiteVisits.length : filteredFollowups.length;
    final totalPages = (totalCount / _followupsPerPage).ceil();
    final currentPage = _followupPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (currentPage - 1) * _followupsPerPage;
    final endIndex = (startIndex + _followupsPerPage).clamp(0, totalCount);

    final pageItems = (startIndex < totalCount)
        ? (isSiteVisitsTab
            ? filteredSiteVisits.sublist(startIndex, endIndex)
            : filteredFollowups.sublist(startIndex, endIndex))
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
          icon: Icon(Icons.calendar_today_rounded, color: CRMColors.primary, size: 18),
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
            _buildBigFollowupTabSwitcher(filteredFollowups.length, filteredSiteVisits.length),
            const SizedBox(height: CRMSpacing.m),
            if (isMobile) ...[
              Align(
                alignment: Alignment.centerRight,
                child: dateSelection,
              ),
              const SizedBox(height: CRMSpacing.s),
            ],
                pageItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            isSiteVisitsTab ? 'No scheduled site visits for $dateStr.' : 'No follow-ups for $dateStr.',
                            style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          ...pageItems.map((item) {
                            if (isSiteVisitsTab) {
                              return _buildSiteVisitTile(item as DashboardSiteVisit);
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
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                      onPressed: currentPage > 1
                                          ? () => setState(() => _followupPage--)
                                          : null,
                                      tooltip: 'Previous Page',
                                    ),
                                    Text(
                                      '$currentPage / $totalPages',
                                      style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
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
    final displayHour = hourInt > 12 ? hourInt - 12 : (hourInt == 0 ? 12 : hourInt);
    final amPm = hourInt >= 12 ? 'PM' : 'AM';
    final formattedTime = "${displayHour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm";
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    return Container(
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
            backgroundColor: sv.status == 'Pending' ? CRMColors.warning.withOpacity(0.1) : CRMColors.success.withOpacity(0.1),
            radius: 18,
            child: Icon(
              Icons.location_on_rounded,
              color: sv.status == 'Pending' ? CRMColors.warning : CRMColors.success,
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
                  style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold),
                ),
                if (sv.propertyCode != null || sv.propertyTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Property: ${sv.propertyCode ?? ""} - ${sv.propertyTitle ?? ""}',
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
                if (sv.remarks != null && sv.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sv.remarks!,
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Scheduled: $formattedDate at $formattedTime',
                  style: CRMTypography.caption.copyWith(color: CRMColors.primary, fontWeight: FontWeight.w600),
                ),
                if (context.read<AuthBloc>().state is Authenticated &&
                    (context.read<AuthBloc>().state as Authenticated).user.role != 'Sales' &&
                    sv.creatorName != null &&
                    sv.creatorName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: CRMColors.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Assigned to: ${sv.creatorName}',
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (sv.status == 'Pending') ...[
            IconButton(
              icon: Icon(Icons.check_circle_outline_rounded, color: CRMColors.success, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      backgroundColor: CRMColors.cardBgOf(context),
                      title: Text(
                        'Site Visit Outcome',
                        style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                      ),
                      content: Text(
                        'What was the outcome of this site visit?',
                        style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
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
                            await _handleSiteVisitOutcome(sv, 'Site Visit Done');
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
    );
  }

  Future<void> _handleSiteVisitOutcome(DashboardSiteVisit sv, String outcomeStatus) async {
    try {
      // 1. Mark the site visit as completed in the backend
      await DioClient.dio.patch('/site-visits/${sv.id}/status', data: {'status': 'Completed'});
      
      // 2. Automatically update the requirement status in the backend and local cache
      if (sv.requirementId != null) {
        final localReq = await RepositoryCoordinator().requirementLocal.getRequirement(sv.requirementId!);
        if (localReq != null) {
          final model = localReq.toModel();
          final RequirementsRepository requirementsRepository = RequirementsRepository();
          await requirementsRepository.updateRequirement(
            model.copyWith(status: outcomeStatus),
          );
        } else {
          // Fallback: send the update request directly to backend
          await DioClient.dio.put('/requirements/${sv.requirementId}', data: {
            'status': outcomeStatus,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site visit marked as completed. Requirement updated to $outcomeStatus.'),
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
    final displayHour = hourInt > 12 ? hourInt - 12 : (hourInt == 0 ? 12 : hourInt);
    final amPm = hourInt >= 12 ? 'PM' : 'AM';
    final formattedTime = "${displayHour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm";
    final formattedDate = "${date.day}/${date.month}/${date.year}";

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
              backgroundColor: f.status == 'Pending' ? CRMColors.warning.withOpacity(0.1) : CRMColors.success.withOpacity(0.1),
              radius: 18,
              child: Icon(
                Icons.phone_in_talk_rounded,
                color: f.status == 'Pending' ? CRMColors.warning : CRMColors.success,
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
                    style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text('Mobile: ${f.mobile}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
                  if (f.notes != null && f.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(f.notes!, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 6),
                  Text('Scheduled: $formattedDate at $formattedTime', style: CRMTypography.caption.copyWith(color: CRMColors.primary, fontWeight: FontWeight.w600)),
                  if (context.read<AuthBloc>().state is Authenticated &&
                      (context.read<AuthBloc>().state as Authenticated).user.role != 'Sales' &&
                      f.creatorName != null &&
                      f.creatorName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Assigned to: ${f.creatorName}',
                            style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
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
                icon: Icon(Icons.check_circle_outline_rounded, color: CRMColors.success, size: 20),
                onPressed: () async {
                  try {
                    await DioClient.dio.patch('/followups/${f.id}/status', data: {'status': 'Completed'});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Follow-up marked as completed.')),
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
    DateTime selectedDate = DateTime.tryParse(f.followupDate)?.toLocal() ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hourInt = selectedTime.hour;
            final displayHour = hourInt > 12 ? hourInt - 12 : (hourInt == 0 ? 12 : hourInt);
            final amPm = hourInt >= 12 ? 'PM' : 'AM';
            final formattedTimeStr = "${displayHour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $amPm";

            return AlertDialog(
              backgroundColor: CRMColors.cardBgOf(context),
              title: Text('Edit / Reschedule Follow-up', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client: ${f.clientName}',
                      style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mobile: ${f.mobile}',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Notes',
                        filled: true,
                        fillColor: CRMColors.backgroundOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date & Time: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $formattedTimeStr',
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                      ),
                      trailing: Icon(Icons.access_time_rounded, color: CRMColors.primary),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                      await DioClient.dio.patch('/followups/${f.id}', data: {
                        'notes': notes,
                        'followup_date': selectedDate.toUtc().toIso8601String(),
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Follow-up updated successfully.')),
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
            final displayHour = hourInt > 12 ? hourInt - 12 : (hourInt == 0 ? 12 : hourInt);
            final amPm = hourInt >= 12 ? 'PM' : 'AM';
            final formattedTimeStr = "${displayHour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $amPm";

            return AlertDialog(
              backgroundColor: CRMColors.cardBgOf(context),
              title: Text('Schedule Follow-up', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Follow-up Notes',
                        filled: true,
                        fillColor: CRMColors.backgroundOf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ListTile(
                      title: Text('Date & Time: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at $formattedTimeStr'),
                      trailing: Icon(Icons.access_time_rounded, color: CRMColors.primary),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        await DioClient.dio.post('/followups', data: {
                          'client_name': clientName,
                          'mobile': mobile,
                          'notes': notes,
                          'followup_date': selectedDate.toUtc().toIso8601String(),
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Follow-up scheduled successfully.')),
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

  void _openPropertyDetails(String propertyId) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    if (kIsWeb && !isMobile) {
      final String url = '${Uri.base.origin}/properties/$propertyId';
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } else {
      setState(() {
        _isLoadingProperty = true;
      });
      PropertiesRepository().getPropertyById(propertyId).then((p) {
        if (mounted) {
          setState(() {
            _isLoadingProperty = false;
          });
          if (p != null) {
            showCRMPropertyDrawer(context, p);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load property details.')),
            );
          }
        }
      }).catchError((e) {
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
            Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 54),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Failed to Load Dashboard',
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: CRMSpacing.xs),
            Text(message, style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)), textAlign: TextAlign.center),
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
        // Soft radial gradient (lighter core, richer edge) for a subtle glassy feel.
        paint.shader = RadialGradient(
          colors: [color.withValues(alpha: 0.7), color],
          stops: const [0.35, 1.0],
        ).createShader(arcRect);
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