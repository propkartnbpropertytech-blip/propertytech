import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../models/area_analytics_model.dart';
import '../services/dashboard_service.dart';

class InventoryDemandAnalyticsSection extends StatefulWidget {
  final String businessType;

  const InventoryDemandAnalyticsSection({
    super.key,
    required this.businessType,
  });

  @override
  State<InventoryDemandAnalyticsSection> createState() =>
      _InventoryDemandAnalyticsSectionState();
}

class _InventoryDemandAnalyticsSectionState
    extends State<InventoryDemandAnalyticsSection> {
  final DashboardService _dashboardService = DashboardService();

  // Inventory state
  bool _isInventoryLoading = true;
  String? _inventoryError;
  List<AreaCountItem> _inventoryItems = [];

  // Lead demand state
  String _selectedLeadType = 'listing'; // 'listing' or 'requirement'
  bool _isLeadsLoading = true;
  String? _leadsError;
  List<AreaCountItem> _leadsItems = [];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant InventoryDemandAnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessType != widget.businessType) {
      _fetchInventory();
    }
  }

  Future<void> _fetchInventory() async {
    if (!mounted) return;
    setState(() {
      _isInventoryLoading = true;
      _inventoryError = null;
    });

    try {
      final data = await _dashboardService.getInventoryByArea(
        businessType: widget.businessType,
      );
      if (!mounted) return;
      setState(() {
        _inventoryItems = data;
        _isInventoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inventoryError = 'Failed to load inventory by area';
        _isInventoryLoading = false;
      });
    }
  }

  Future<void> _fetchLeads() async {
    if (!mounted) return;
    setState(() {
      _isLeadsLoading = true;
      _leadsError = null;
    });

    try {
      final data = await _dashboardService.getLeadsByArea(
        type: _selectedLeadType,
      );
      if (!mounted) return;
      setState(() {
        _leadsItems = data;
        _isLeadsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leadsError = 'Failed to load lead area demand';
        _isLeadsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Inventory & Demand Analytics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Locality Insights',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager().primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Two Cards Responsive Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            final inventoryCard = _buildInventoryCard(isDark);
            final leadsCard = _buildLeadDemandCard(isDark);

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: inventoryCard),
                  const SizedBox(width: 20),
                  Expanded(child: leadsCard),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inventoryCard,
                  const SizedBox(height: 16),
                  leadsCard,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // ==========================================
  // CARD 1: AVAILABLE INVENTORY BY AREA
  // ==========================================
  Widget _buildInventoryCard(bool isDark) {
    final primaryColor = const Color(0xFF2563EB); // Royal Blue
    final totalInventory = _inventoryItems.fold<int>(0, (s, i) => s + i.count);

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.apartment_rounded,
                  size: 18,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Inventory by Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active stock across localities (${widget.businessType})',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isInventoryLoading &&
                  _inventoryError == null &&
                  _inventoryItems.length > 6)
                TextButton(
                  onPressed: () => _showAllAreasDialog(
                    context: context,
                    title: 'Available Inventory by Area',
                    subtitle:
                        'All ${widget.businessType} available properties ranked by locality ($totalInventory total)',
                    items: _inventoryItems,
                    barColor: primaryColor,
                    tooltipSuffix: 'available properties',
                    isDark: isDark,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: primaryColor,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content body
          if (_isInventoryLoading)
            _buildSkeletonList()
          else if (_inventoryError != null)
            _buildErrorState(
              error: _inventoryError!,
              onRetry: _fetchInventory,
              isDark: isDark,
            )
          else if (_inventoryItems.isEmpty)
            _buildEmptyState(
              message: 'No available properties found',
              isDark: isDark,
            )
          else
            _buildHorizontalBars(
              items: _inventoryItems.take(6).toList(),
              barColor: primaryColor,
              tooltipSuffix: 'available properties',
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 2: LEAD AREA DEMAND
  // ==========================================
  Widget _buildLeadDemandCard(bool isDark) {
    final isListing = _selectedLeadType == 'listing';
    final accentColor = isListing
        ? const Color(0xFF0D9488) // Teal for listing
        : const Color(0xFF7C3AED); // Violet for requirement

    final totalLeads = _leadsItems.fold<int>(0, (s, i) => s + i.count);

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header + Segmented Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isListing
                      ? Icons.sell_outlined
                      : Icons.person_search_outlined,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead Area Demand',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isListing
                          ? 'Localities with top seller/landlord listings'
                          : 'Localities with top buyer/tenant requirements',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Segmented Toggle
              Container(
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTogglePill(
                      label: 'Listing',
                      isSelected: isListing,
                      activeColor: const Color(0xFF0D9488),
                      onTap: () {
                        if (_selectedLeadType != 'listing') {
                          setState(() => _selectedLeadType = 'listing');
                          _fetchLeads();
                        }
                      },
                      isDark: isDark,
                    ),
                    _buildTogglePill(
                      label: 'Requirement',
                      isSelected: !isListing,
                      activeColor: const Color(0xFF7C3AED),
                      onTap: () {
                        if (_selectedLeadType != 'requirement') {
                          setState(() => _selectedLeadType = 'requirement');
                          _fetchLeads();
                        }
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-header with View All if applicable
          if (!_isLeadsLoading &&
              _leadsError == null &&
              _leadsItems.length > 6)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showAllAreasDialog(
                  context: context,
                  title: isListing
                      ? 'Listing Leads by Area'
                      : 'Requirement Leads by Area',
                  subtitle:
                      'All ${isListing ? "Listing" : "Requirement"} leads ranked by locality ($totalLeads total)',
                  items: _leadsItems,
                  barColor: accentColor,
                  tooltipSuffix: isListing
                      ? 'listing leads'
                      : 'requirement leads',
                  isDark: isDark,
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: accentColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All (${_leadsItems.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded, size: 13),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 4),

          // Content body
          if (_isLeadsLoading)
            _buildSkeletonList()
          else if (_leadsError != null)
            _buildErrorState(
              error: _leadsError!,
              onRetry: _fetchLeads,
              isDark: isDark,
            )
          else if (_leadsItems.isEmpty)
            _buildEmptyState(
              message:
                  'No ${isListing ? "listing" : "requirement"} leads found',
              isDark: isDark,
            )
          else
            _buildHorizontalBars(
              items: _leadsItems.take(6).toList(),
              barColor: accentColor,
              tooltipSuffix:
                  isListing ? 'listing leads' : 'requirement leads',
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
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
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HORIZONTAL BARS LIST
  // ==========================================
  Widget _buildHorizontalBars({
    required List<AreaCountItem> items,
    required Color barColor,
    required String tooltipSuffix,
    required bool isDark,
  }) {
    final maxCount = items.map((e) => e.count).fold<int>(
          1,
          (prev, curr) => curr > prev ? curr : prev,
        );

    return Column(
      children: items.map((item) {
        final ratio = (item.count / maxCount).clamp(0.04, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Tooltip(
            message: '${item.area}\n${item.count} $tooltipSuffix',
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFF475569),
              ),
            ),
            textStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Area Name & Exact Count Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.area,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.count}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Bar Track & Fill
                LayoutBuilder(
                  builder: (context, constraints) {
                    final targetWidth = constraints.maxWidth * ratio;

                    return Stack(
                      children: [
                        // Track
                        Container(
                          height: 7,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Fill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          height: 7,
                          width: targetWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor.withValues(alpha: 0.75),
                                barColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // SKELETON / LOADING STATE
  // ==========================================
  Widget _buildSkeletonList() {
    final mockWidths = [0.85, 0.70, 0.55, 0.45, 0.35, 0.25];

    return Column(
      children: mockWidths.map((ratio) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CRMSkeleton(
                    width: 100 + (ratio * 50),
                    height: 12,
                    borderRadius: 4,
                  ),
                  const CRMSkeleton(
                    width: 32,
                    height: 14,
                    borderRadius: 6,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 7,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      CRMSkeleton(
                        width: constraints.maxWidth * ratio,
                        height: 7,
                        borderRadius: 4,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // ERROR STATE
  // ==========================================
  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 32,
            color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState({
    required String message,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 32,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW ALL MODAL DIALOG
  // ==========================================
  void _showAllAreasDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<AreaCountItem> items,
    required Color barColor,
    required String tooltipSuffix,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _AllAreasDialog(
          title: title,
          subtitle: subtitle,
          items: items,
          barColor: barColor,
          tooltipSuffix: tooltipSuffix,
          isDark: isDark,
        );
      },
    );
  }
}

class _AllAreasDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<AreaCountItem> items;
  final Color barColor;
  final String tooltipSuffix;
  final bool isDark;

  const _AllAreasDialog({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.barColor,
    required this.tooltipSuffix,
    required this.isDark,
  });

  @override
  State<_AllAreasDialog> createState() => _AllAreasDialogState();
}

class _AllAreasDialogState extends State<_AllAreasDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      if (_searchQuery.trim().isEmpty) return true;
      return i.area.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    final maxCount = widget.items.map((e) => e.count).fold<int>(
          1,
          (prev, curr) => curr > prev ? curr : prev,
        );

    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search field
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search locality / area...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.barColor,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable ranking list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No areas matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final item = filtered[index];
                          final ratio =
                              (item.count / maxCount).clamp(0.04, 1.0);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Tooltip(
                              message:
                                  '${item.area}\n${item.count} ${widget.tooltipSuffix}',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.area,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFFF1F5F9)
                                                : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.barColor.withValues(
                                            alpha: isDark ? 0.2 : 0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.count}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: widget.barColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final targetWidth =
                                          constraints.maxWidth * ratio;
                                      return Stack(
                                        children: [
                                          Container(
                                            height: 7,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF334155)
                                                      .withValues(alpha: 0.5)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          Container(
                                            height: 7,
                                            width: targetWidth,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  widget.barColor
                                                      .withValues(alpha: 0.75),
                                                  widget.barColor,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
