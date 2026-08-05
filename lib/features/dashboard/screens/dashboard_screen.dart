import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/models/property_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../requirements/models/requirement_model.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../models/dashboard_summary.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/currency.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/model_mappers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Table filter and tab states
  String _activeTab = 'Rental'; // 'Rental' or 'Only Re-Sale'
  Set<String> _selectedAreaFilters = {};
  String _priceSortOrder = 'none'; // 'none', 'high_to_low', 'low_to_high'

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

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboard());
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

    return BlocConsumer<DashboardBloc, DashboardState>(
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
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m,
                vertical: CRMSpacing.l,
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
                                  const SizedBox(height: 54),
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
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWelcomeHeader(String name, String dateString, String greeting) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
        Text(
          name,
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 22 : 28,
          ),
        ),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          dateString,
          style: CRMTypography.bodyMedium.copyWith(
            color: CRMColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      children: [
        leftColumn,
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
    final double screenWidth = MediaQuery.of(context).size.width;

    final int availableVal = _activeTab == 'Rental' ? summary.rentalAvailable : summary.resaleAvailable;
    final int soldVal = summary.resaleSold;
    final int rentedVal = summary.rentalRented;
    final int requirementsVal = _activeTab == 'Rental' ? summary.rentalRequirements : summary.resaleRequirements;

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
      ),
      if (_activeTab == 'Re-Sale')
        CRMKPICard(
          title: siteVisitTitle,
          value: '$soldVal',
          icon: Icons.directions_walk_rounded,
          iconColor: CRMColors.warning,
        ),
      if (_activeTab == 'Rental')
        CRMKPICard(
          title: siteVisitTitle,
          value: '$rentedVal',
          icon: Icons.directions_walk_rounded,
          iconColor: CRMColors.info,
        ),
      CRMKPICard(
        title: requirementsTitle,
        value: '$requirementsVal',
        icon: Icons.assignment_turned_in_outlined,
      ),
      CRMKPICard(
        title: wonTitle,
        value: '${_activeTab == 'Rental' ? summary.rentalWonRequirements : summary.resaleWonRequirements}',
        icon: Icons.emoji_events_outlined,
        iconColor: CRMColors.success,
      ),
    ];

    final int crossAxisCount = isDesktop ? 2 : (screenWidth >= 600 ? cards.length : 2);
    final double childAspectRatio = isDesktop ? 2.4 : (screenWidth >= 600 ? 2.5 : 1.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: CRMSpacing.xs, bottom: CRMSpacing.m),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: CRMSpacing.s,
            runSpacing: CRMSpacing.xs,
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMetricsTabButton('Rental'),
                    const SizedBox(width: 4),
                    _buildMetricsTabButton('Re-Sale'),
                  ],
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: CRMSpacing.m,
            mainAxisSpacing: CRMSpacing.m,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return cards[index];
          },
        ),
      ],
    );
  }

  Widget _buildMetricsTabButton(String label) {
    final isSelected = _activeTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = label;
          _propertyPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.tabSwitch,
        curve: CRMMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.l),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64826F) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label == 'Rental' ? 'Rent' : label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
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

    return CRMCard(
      elevated: true,
      title: 'Recent Properties',
      subtitle: 'Latest registered listings in CRM platform',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: hasActiveFilter ? CRMColors.primary : CRMColors.textSecondaryOf(context),
          side: BorderSide(
            color: hasActiveFilter ? CRMColors.primary : CRMColors.borderOf(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () => _showFilterModal(displayItems),
        icon: Icon(
          Icons.tune_rounded,
          size: 16,
          color: hasActiveFilter ? CRMColors.primary : CRMColors.textSecondaryOf(context),
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
                : isMobile
                    ? Column(
                        children: pageItems.map((p) => _buildMobilePropertyCard(p)).toList(),
                      )
                    : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3.0), // Title
                          1: FlexColumnWidth(2.0), // Area
                          2: FlexColumnWidth(1.5), // Price
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: CRMColors.borderOf(context).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: CRMColors.backgroundOf(context).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                            ),
                            children: [
                              _buildTableHeaderCell('Property Name'),
                              _buildTableHeaderCell('Area'),
                              _buildTableHeaderCell('Price'),
                            ],
                          ),
                          ...pageItems.map((p) {
                            return TableRow(
                              children: [
                                _buildTableDataCell(
                                  InkWell(
                                    onTap: () => _openPropertyDetails(p.id),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Text(
                                        p.title,
                                        style: TextStyle(
                                          color: CRMColors.textOf(context),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildTableDataCell(
                                  InkWell(
                                    onTap: () => _openPropertyDetails(p.id),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Text(
                                        p.areaName,
                                        style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildTableDataCell(
                                  InkWell(
                                    onTap: () => _openPropertyDetails(p.id),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Text(
                                        CRMCurrencyFormatter.formatShort(p.price),
                                        style: TextStyle(
                                          color: CRMColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
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
            );
          },
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: CRMColors.textOf(context),
        ),
      ),
    );
  }

  Widget _buildTableDataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 12),
      child: child,
    );
  }

  Widget _buildMobilePropertyCard(_DisplayProperty p) {
    return InkWell(
      onTap: () => _openPropertyDetails(p.id),
      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      child: Container(
        margin: const EdgeInsets.only(bottom: CRMSpacing.s),
        padding: const EdgeInsets.all(CRMSpacing.m),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context).withOpacity(0.4),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: CRMColors.backgroundOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CRMColors.textOf(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: CRMSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      p.areaName,
                      style: TextStyle(
                        color: CRMColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  CRMCurrencyFormatter.formatShort(p.price),
                  style: TextStyle(
                    color: CRMColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
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
      title: "Note's",
      subtitle: 'Operations and tasks assigned for today',
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
      title: "Scheduled",
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
    final String url = '${Uri.base.origin}/properties/$propertyId';
    launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
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

  _DisplayProperty({
    required this.id,
    required this.title,
    required this.areaName,
    required this.price,
    required this.listingType,
    required this.createdAt,
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