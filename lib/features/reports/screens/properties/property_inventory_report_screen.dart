import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../models/property_inventory_report_model.dart';

class PropertyInventoryReportScreen extends StatefulWidget {
  const PropertyInventoryReportScreen({super.key});

  @override
  State<PropertyInventoryReportScreen> createState() => _PropertyInventoryReportScreenState();
}

class _PropertyInventoryReportScreenState extends State<PropertyInventoryReportScreen> {
  // 1. Main Tabs: Rent vs Resale
  String _activeTab = 'Rent'; // 'Rent' or 'Resale'

  // 2. Category Filters
  String _activeCategory = 'All'; // 'All', 'Residential', 'Commercial', 'Industrial', 'Land & Plot'

  // 3. KPI Filter: 'available_inventory', 'ready_with_images', 'no_images', or 'all'
  String _activeKpi = 'available_inventory';

  // 4. Date Filters: 'All Time', 'Today', 'Yesterday', 'Last 7 Days', 'This Month', 'Custom Range'
  String _dateFilter = 'All Time';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // 5. Search & View Mode
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isTableView = true;

  // State data
  bool _isLoading = true;
  String? _errorMessage;
  PropertyInventoryReportData? _data;

  final List<String> _categories = const [
    'All',
    'Residential',
    'Commercial',
    'Industrial',
    'Land & Plot',
  ];

  final List<String> _dateFilters = const [
    'All Time',
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'listing_type': _activeTab.toUpperCase(),
        'category': _activeCategory,
        'dateFilter': _dateFilter,
        'limit': 300,
      };

      if (_activeKpi.isNotEmpty && _activeKpi != 'all') {
        queryParams['kpi'] = _activeKpi;
      }

      if (_dateFilter == 'Custom Range' && _customStartDate != null && _customEndDate != null) {
        queryParams['startDate'] = _customStartDate!.toIso8601String();
        queryParams['endDate'] = _customEndDate!.toIso8601String();
      }

      if (_searchQuery.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.trim();
      }

      final response = await DioClient.dio.get('/reports/properties', queryParameters: queryParams);
      final body = response.data;

      if (body is Map && body['data'] is Map) {
        final parsed = PropertyInventoryReportData.fromJson(Map<String, dynamic>.from(body['data'] as Map));
        setState(() {
          _data = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _data = const PropertyInventoryReportData();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load property reports. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(String tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      _activeCategory = 'All'; // Default category on tab change
    });
    _fetchReport();
  }

  void _onCategoryChanged(String category) {
    if (_activeCategory == category) return;
    setState(() {
      _activeCategory = category;
    });
    _fetchReport();
  }

  void _onKpiSelected(String kpiKey) {
    setState(() {
      if (_activeKpi == kpiKey) {
        _activeKpi = 'all'; // Toggle off to show all properties
      } else {
        _activeKpi = kpiKey;
      }
    });
    _fetchReport();
  }

  Future<void> _onDateFilterChanged(String filter) async {
    if (filter == 'Custom Range') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 5),
        initialDateRange: _customStartDate != null && _customEndDate != null
            ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
            : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
        builder: (context, child) {
          final isDark = ThemeManager().isDarkMode;
          final primaryColor = CRMColors.primary;
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      surface: const Color(0xFF1E293B),
                      onSurface: Colors.white,
                    )
                  : ColorScheme.light(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: const Color(0xFF0F172A),
                    ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _dateFilter = 'Custom Range';
          _customStartDate = picked.start;
          _customEndDate = picked.end;
        });
        _fetchReport();
      }
    } else {
      if (_dateFilter == filter) return;
      setState(() {
        _dateFilter = filter;
        _customStartDate = null;
        _customEndDate = null;
      });
      _fetchReport();
    }
  }

  String _getDateFilterLabel(String filter) {
    if (filter == 'Custom Range' && _customStartDate != null && _customEndDate != null) {
      final f = DateFormat('dd MMM');
      return '${f.format(_customStartDate!)} - ${f.format(_customEndDate!)}';
    }
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: RefreshIndicator(
        onRefresh: _fetchReport,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12 : CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Subtitle
              _buildHeader(isDark, primaryColor, isMobile: isMobile),
              SizedBox(height: isMobile ? 14 : 18),

              // 1. Main Tabs: Rent & Resale
              _buildMainTabs(isDark, primaryColor),
              SizedBox(height: isMobile ? 12 : 16),

              // 2. Category Filters Bar
              _buildCategoryFilters(isDark, primaryColor),
              SizedBox(height: isMobile ? 10 : 14),

              // 4. Date Filters Bar
              _buildDateFilters(isDark, primaryColor),
              SizedBox(height: isMobile ? 16 : 20),

              // 3. Property Performance KPI Cards
              _buildKpiCards(isDark, primaryColor),
              SizedBox(height: isMobile ? 18 : 24),

              // 5. Detailed Records Section
              _buildRecordsSection(isDark, primaryColor, isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor, {bool isMobile = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Property Reports',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Executive overview of inventory availability, media readiness, and property performance.',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainTabs(bool isDark, Color primaryColor) {
    final rentCount = _data?.tabs.rentCount ?? 0;
    final resaleCount = _data?.tabs.resaleCount ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabPill(
              title: 'Rent',
              count: rentCount,
              isSelected: _activeTab == 'Rent',
              icon: Icons.key_rounded,
              isDark: isDark,
              primaryColor: primaryColor,
              onTap: () => _onTabChanged('Rent'),
            ),
            const SizedBox(width: 4),
            _buildTabPill(
              title: 'Resale',
              count: resaleCount,
              isSelected: _activeTab == 'Resale',
              icon: Icons.real_estate_agent_rounded,
              isDark: isDark,
              primaryColor: primaryColor,
              onTap: () => _onTabChanged('Resale'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required int count,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? primaryColor
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = _activeCategory == category;
          final count = _data?.categories.countFor(category) ?? 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => _onCategoryChanged(category),
              selectedColor: primaryColor,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateFilters(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'DATE FILTER:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            ..._dateFilters.map((filter) {
              final isSelected = _dateFilter == filter;
              final label = _getDateFilterLabel(filter);

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _onDateFilterChanged(filter),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (filter == 'Custom Range') ...[
                          Icon(
                            Icons.date_range_rounded,
                            size: 13,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCards(bool isDark, Color primaryColor) {
    final kpis = _data?.kpis ?? const PropertyInventoryKpis();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final cards = [
          _buildKpiCard(
            title: 'Available Inventory',
            count: kpis.availableInventory,
            subtext: 'Currently available in active stock',
            icon: Icons.storefront_rounded,
            color: const Color(0xFF059669), // Emerald
            kpiKey: 'available_inventory',
            isSelected: _activeKpi == 'available_inventory',
            isDark: isDark,
          ),
          _buildKpiCard(
            title: 'Ready With Images',
            count: kpis.readyWithImages,
            subtext: 'Properties with verified photo media',
            icon: Icons.photo_library_rounded,
            color: const Color(0xFF2563EB), // Blue
            kpiKey: 'ready_with_images',
            isSelected: _activeKpi == 'ready_with_images',
            isDark: isDark,
          ),
          _buildKpiCard(
            title: 'No Images',
            count: kpis.noImages,
            subtext: 'Missing property photo uploads',
            icon: Icons.no_photography_rounded,
            color: const Color(0xFFD97706), // Amber
            kpiKey: 'no_images',
            isSelected: _activeKpi == 'no_images',
            isDark: isDark,
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required String subtext,
    required IconData icon,
    required Color color,
    required String kpiKey,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _onKpiSelected(kpiKey),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: isDark ? 0.25 : 0.12)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.8,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE FILTER',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsSection(bool isDark, Color primaryColor, {bool isMobile = false}) {
    final rows = _data?.rows ?? const [];
    final totalCount = _data?.filteredCount ?? rows.length;

    String sectionTitle;
    if (_activeKpi == 'available_inventory') {
      sectionTitle = 'Available Inventory Properties';
    } else if (_activeKpi == 'ready_with_images') {
      sectionTitle = 'Properties Ready With Images';
    } else if (_activeKpi == 'no_images') {
      sectionTitle = 'Properties With No Images';
    } else {
      sectionTitle = 'All $_activeTab Properties';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Controls Bar
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 580;

                final titleWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        sectionTitle,
                        style: TextStyle(
                          fontSize: isMobile ? 14.5 : 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                );

                final searchBox = SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      setState(() => _searchQuery = val);
                      _fetchReport();
                    },
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Search code, title, locality...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _fetchReport();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                );

                final toggleView = Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.table_chart_rounded, size: 16),
                        color: _isTableView
                            ? primaryColor
                            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        tooltip: 'Table View',
                        onPressed: () => setState(() => _isTableView = true),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.grid_view_rounded, size: 16),
                        color: !_isTableView
                            ? primaryColor
                            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        tooltip: 'Cards View',
                        onPressed: () => setState(() => _isTableView = false),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleWidget,
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: searchBox),
                          const SizedBox(width: 8),
                          toggleView,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleWidget,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 240, child: searchBox),
                        const SizedBox(width: 10),
                        toggleView,
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Content: Table or Cards or Empty / Error
          if (_errorMessage != null)
            _buildErrorState(isDark)
          else if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rows.isEmpty)
            _buildEmptyState(isDark)
          else if (_isTableView)
            _buildPropertiesTable(rows, isDark, primaryColor)
          else
            _buildPropertiesCards(rows, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.apartment_rounded,
                size: 40,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No properties match the selected criteria',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your tab, category, date filter, or search term.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: CRMColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesTable(List<PropertyInventoryItem> items, bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1000),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          horizontalMargin: 16,
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
          columns: const [
            DataColumn(label: Text('Property ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Property Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Locality / City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Price / Rent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                // Property ID
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      item.propertyCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),

                // Property Name & Config
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.configurationName.isNotEmpty)
                        Text(
                          item.configurationName,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),

                // Images Thumbnail & Count
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item.coverImageUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 32,
                              height: 32,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              child: const Icon(Icons.broken_image_rounded, size: 14),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.no_photography_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.hasImages
                              ? const Color(0xFF059669).withValues(alpha: 0.1)
                              : const Color(0xFFD97706).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.hasImages ? '${item.imageCount} Imgs' : 'No Img',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: item.hasImages ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      item.categoryName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                // Type (Rent / Resale)
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: item.listingType.toUpperCase() == 'RENT'
                          ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                          : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.listingType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: item.listingType.toUpperCase() == 'RENT'
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ),

                // Status
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.statusName.toLowerCase() == 'available'
                          ? const Color(0xFF059669).withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.statusName.toLowerCase() == 'available'
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.statusName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.statusName.toLowerCase() == 'available'
                                ? const Color(0xFF059669)
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Locality / City
                DataCell(
                  Text(
                    item.locality.isNotEmpty
                        ? (item.cityName.isNotEmpty ? '${item.locality}, ${item.cityName}' : item.locality)
                        : (item.cityName.isNotEmpty ? item.cityName : '—'),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Price
                DataCell(
                  Text(
                    item.formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),

                // Created Date
                DataCell(
                  Text(
                    item.formattedDateShort,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),

                // Action
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    color: primaryColor,
                    tooltip: 'View Property Details',
                    onPressed: () {
                      context.push('/properties/${item.id}');
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPropertiesCards(List<PropertyInventoryItem> items, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSingleColumn = constraints.maxWidth < 650;
          final isNarrowScreen = constraints.maxWidth < 420;
          final crossAxisCount = isSingleColumn ? 1 : 2;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: isSingleColumn ? 165 : 160,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final item = items[index];

              return InkWell(
                onTap: () => context.push('/properties/${item.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                            ? Image.network(
                                item.coverImageUrl!,
                                width: isNarrowScreen ? 90 : 100,
                                height: isNarrowScreen ? 141 : 136,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildCardImagePlaceholder(isDark, item),
                              )
                            : _buildCardImagePlaceholder(isDark, item),
                      ),
                      SizedBox(width: isNarrowScreen ? 10 : 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.propertyCode,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.statusName.toLowerCase() == 'available'
                                            ? const Color(0xFF059669).withValues(alpha: 0.12)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.statusName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: item.statusName.toLowerCase() == 'available'
                                              ? const Color(0xFF059669)
                                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${item.categoryName} · ${item.listingType} ${item.configurationName.isNotEmpty ? '· ${item.configurationName}' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.locality.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.cityName.isNotEmpty ? '${item.locality}, ${item.cityName}' : item.locality,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  item.formattedDateShort,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCardImagePlaceholder(bool isDark, PropertyInventoryItem item) {
    return Container(
      width: 100,
      height: 136,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.hasImages ? Icons.image_rounded : Icons.no_photography_rounded,
            size: 26,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            item.hasImages ? '${item.imageCount} Imgs' : 'No Image',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
