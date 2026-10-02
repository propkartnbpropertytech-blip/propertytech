import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/utils/currency.dart';
import '../models/kpi_models.dart';
import '../services/dashboard_service.dart';

class KpiDrilldownDialogs {
  static final DashboardService _dashboardService = DashboardService();

  /// 1. Available Inventory Drill-down Modal
  static Future<T?> showInventoryDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _InventoryDrilldownDialog(params: params),
    );
  }

  /// 2. Total Leads Drill-down Modal
  static Future<T?> showLeadsDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _LeadsDrilldownDialog(params: params),
    );
  }

  /// Lead Lifecycle & Details Modal
  static Future<T?> showLeadDetails<T>(
    BuildContext context, {
    required LeadListItem lead,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _LeadDetailsDialog(lead: lead),
    );
  }

  /// 3. Telecallers Drill-down Modal
  static Future<T?> showTelecallersDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _TelecallersDrilldownDialog(params: params),
    );
  }

  /// 4. Leads Allocated Drill-down Modal
  static Future<T?> showLeadsAllocatedDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _LeadsAllocatedDrilldownDialog(params: params),
    );
  }

  /// 5. Assigned to Sales Drill-down Modal
  static Future<T?> showAssignedToSalesDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _AssignedToSalesDrilldownDialog(params: params),
    );
  }

  /// 6. Sales Users Drill-down Modal
  static Future<T?> showSalesUsersDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _SalesUsersDrilldownDialog(params: params),
    );
  }

  /// 7. Site Visits Done Drill-down Modal
  static Future<T?> showSiteVisitsDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _SiteVisitsDrilldownDialog(params: params),
    );
  }

  /// 8. Deal Won Drill-down Modal
  static Future<T?> showDealWonDrilldown<T>(
    BuildContext context, {
    required KpiFilterParams params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _DealWonDrilldownDialog(params: params),
    );
  }

  /// Single Telecaller Performance Drill-down
  static Future<T?> showTelecallerPerformance<T>(
    BuildContext context, {
    required String telecallerId,
    required String telecallerName,
    String initialLeadType = 'Both',
    KpiFilterParams? params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _TelecallerPerformanceDialog(
        telecallerId: telecallerId,
        telecallerName: telecallerName,
        initialLeadType: initialLeadType,
        params: params,
      ),
    );
  }

  /// Single Sales User Detailed KPI View (10 Lifecycle Statuses)
  static Future<T?> showSalesUserLifecycle<T>(
    BuildContext context, {
    required String salesUserId,
    required String salesUserName,
    KpiFilterParams? params,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => _SalesUserLifecycleDialog(
        salesUserId: salesUserId,
        salesUserName: salesUserName,
        params: params,
      ),
    );
  }
}

String _cleanKpiDisplayText(String val) {
  final clean = val.replaceAll('_', ' ').trim();
  if (clean.isEmpty) return '';
  return clean.split(' ').map((word) {
    final upper = word.toUpperCase();
    if (upper == 'BHK' || upper == 'RK') return upper;
    if (word.length <= 1) return upper;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

Widget _buildKpiMiniBadge({
  required IconData icon,
  required String text,
  required Color color,
  required bool isDark,
  bool isMuted = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: BoxDecoration(
      color: isMuted
          ? (isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
          : color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: isMuted
            ? (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0))
            : color.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isMuted ? FontWeight.w500 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

/// Dynamic responsive dialog wrapper that adapts perfectly to any screen size
/// without horizontal or vertical pixel overflow.
Widget _buildResponsiveDialog({
  required BuildContext context,
  required Widget child,
  double targetMaxWidth = 880,
  double targetMaxHeight = 720,
  EdgeInsetsGeometry? contentPadding,
}) {
  final media = MediaQuery.sizeOf(context);
  final isDark = ThemeManager().isDarkMode;
  final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

  final isSmallScreen = media.width < 600;
  final isShortScreen = media.height < 680;

  final horizontalInset = isSmallScreen ? 10.0 : 20.0;
  final verticalInset = isShortScreen ? 10.0 : 20.0;

  final maxWidth = media.width < (targetMaxWidth + horizontalInset * 2)
      ? (media.width - horizontalInset * 2)
      : targetMaxWidth;

  final maxHeight = media.height < (targetMaxHeight + verticalInset * 2)
      ? (media.height - verticalInset * 2)
      : targetMaxHeight;

  final padding = contentPadding ?? EdgeInsets.all(isSmallScreen ? 14.0 : 20.0);

  return Dialog(
    backgroundColor: cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    insetPadding: EdgeInsets.symmetric(
      horizontal: horizontalInset,
      vertical: verticalInset,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    ),
  );
}

// ============================================================================
// 1. INVENTORY DRILLDOWN DIALOG (Two-Level)
// ============================================================================
class _InventoryDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _InventoryDrilldownDialog({required this.params});

  @override
  State<_InventoryDrilldownDialog> createState() => _InventoryDrilldownDialogState();
}

class _InventoryDrilldownDialogState extends State<_InventoryDrilldownDialog> {
  bool _isLoadingBreakdown = true;
  InventoryBreakdownData _breakdown = const InventoryBreakdownData();

  String? _selectedStatus; // When selected, shows 2nd level property list
  bool _isLoadingProperties = false;
  List<InventoryPropertyItem> _properties = [];
  int _propTotal = 0;
  int _propPage = 1;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    setState(() => _isLoadingBreakdown = true);
    final res = await KpiDrilldownDialogs._dashboardService.getInventoryBreakdown(widget.params);
    if (mounted) {
      setState(() {
        _breakdown = res;
        _isLoadingBreakdown = false;
      });
    }
  }

  Future<void> _loadProperties(String status, {int page = 1}) async {
    setState(() {
      _selectedStatus = status;
      _isLoadingProperties = true;
      _propPage = page;
    });

    final res = await KpiDrilldownDialogs._dashboardService.getInventoryProperties(
      status: status,
      params: widget.params,
      page: page,
      limit: 20,
    );

    if (mounted) {
      setState(() {
        _properties = res.properties;
        _propTotal = res.total;
        _isLoadingProperties = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 860,
      targetMaxHeight: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              if (_selectedStatus != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedStatus = null),
                  tooltip: 'Back to Statuses',
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.home_work_rounded,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStatus != null
                          ? '$_selectedStatus Properties'
                          : 'Available Inventory Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Business: ${widget.params.businessType} | Range: ${widget.params.dateFilter}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: _selectedStatus == null
                ? _buildStatusCards(textColor, subColor, borderColor, isDark)
                : _buildPropertyList(textColor, subColor, borderColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    if (_isLoadingBreakdown) {
      return const Center(child: CircularProgressIndicator());
    }

    final statuses = [
      {'status': 'Available', 'count': _breakdown.available, 'color': const Color(0xFF10B981), 'icon': Icons.check_circle_outline},
      {'status': 'To Be Available', 'count': _breakdown.toBeAvailable, 'color': const Color(0xFF3B82F6), 'icon': Icons.schedule_rounded},
      {'status': 'Rented Out', 'count': _breakdown.rentedOut, 'color': const Color(0xFFF59E0B), 'icon': Icons.key_rounded},
      {'status': 'Sold Out', 'count': _breakdown.soldOut, 'color': const Color(0xFFEF4444), 'icon': Icons.block_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Properties Evaluated',
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
              Text(
                '${_breakdown.total}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: ThemeManager().primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select a status to view individual property listings:',
          style: TextStyle(fontSize: 13, color: subColor),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final cols = isWide ? 4 : 2;
              final ratio = isWide ? 2.1 : 2.1;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: ratio,
                ),
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final item = statuses[index];
                  final statusName = item['status'] as String;
                  final count = item['count'] as int;
                  final color = item['color'] as Color;
                  final icon = item['icon'] as IconData;

                  return InkWell(
                    onTap: () => _loadProperties(statusName),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count Properties',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: color.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyList(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    if (_isLoadingProperties) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: subColor),
            const SizedBox(height: 12),
            Text(
              'No $_selectedStatus properties found.',
              style: TextStyle(color: subColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _properties.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final prop = _properties[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prop.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: prop.listingType.toLowerCase().contains('rent')
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        prop.listingType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: prop.listingType.toLowerCase().contains('rent')
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      if (prop.propertyCode.isNotEmpty) ...[
                        Text(
                          prop.propertyCode,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subColor),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (prop.areaName != null && prop.areaName!.isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, size: 13, color: subColor),
                        const SizedBox(width: 2),
                        Text(prop.areaName!, style: TextStyle(fontSize: 12, color: subColor)),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        CRMCurrencyFormatter.formatWords(prop.price.toDouble()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ThemeManager().primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/properties/${prop.id}');
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Pagination info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${_properties.length} of $_propTotal properties',
              style: TextStyle(fontSize: 12, color: subColor),
            ),
            Row(
              children: [
                if (_propPage > 1)
                  TextButton.icon(
                    onPressed: () => _loadProperties(_selectedStatus!, page: _propPage - 1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 16),
                    label: const Text('Prev'),
                  ),
                if (_propPage * 20 < _propTotal)
                  TextButton.icon(
                    onPressed: () => _loadProperties(_selectedStatus!, page: _propPage + 1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 16),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 2. TOTAL LEADS DRILLDOWN DIALOG (Two-Level: Dynamic Sources -> Lead List)
// ============================================================================
class _LeadsDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _LeadsDrilldownDialog({required this.params});

  @override
  State<_LeadsDrilldownDialog> createState() => _LeadsDrilldownDialogState();
}

class _LeadsDrilldownDialogState extends State<_LeadsDrilldownDialog> {
  late String _selectedLeadType;
  bool _isLoading = true;
  LeadsBreakdownData _breakdown = const LeadsBreakdownData();

  String? _selectedSource;
  bool _isLoadingLeads = false;
  List<LeadListItem> _leads = [];
  int _leadsTotal = 0;
  int _leadsPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedLeadType = widget.params.leadType;
    _fetchBreakdown();
  }

  Future<void> _fetchBreakdown() async {
    setState(() => _isLoading = true);
    final currentParams = widget.params.copyWith(leadType: _selectedLeadType);
    final res = await KpiDrilldownDialogs._dashboardService.getLeadsBreakdown(currentParams);
    if (mounted) {
      setState(() {
        _breakdown = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLeadsList(String source, {int page = 1}) async {
    setState(() {
      _selectedSource = source;
      _isLoadingLeads = true;
      _leadsPage = page;
    });

    final currentParams = widget.params.copyWith(leadType: _selectedLeadType);
    final res = await KpiDrilldownDialogs._dashboardService.getLeadsList(
      source: source,
      params: currentParams,
      page: page,
      limit: 25,
    );

    if (mounted) {
      setState(() {
        _leads = res.leads;
        _leadsTotal = res.total;
        _isLoadingLeads = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 860,
      targetMaxHeight: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              if (_selectedSource != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedSource = null),
                  tooltip: 'Back to Sources',
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.assignment_outlined,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSource != null
                          ? '$_selectedSource Leads'
                          : 'Total Leads by Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Type: $_selectedLeadType | Range: ${widget.params.dateFilter}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              // Lead Type Toggle
              if (_selectedSource == null) _buildLeadTypeToggle(isDark),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Content Area
          Expanded(
            child: _selectedSource == null
                ? _buildSourcesList(textColor, subColor, borderColor, isDark)
                : _buildLeadsList(textColor, subColor, borderColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadTypeToggle(bool isDark) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Both', 'Listing', 'Requirement'].map((type) {
          final isSel = _selectedLeadType == type;
          return GestureDetector(
            onTap: () {
              if (_selectedLeadType != type) {
                setState(() => _selectedLeadType = type);
                _fetchBreakdown();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? ThemeManager().primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSourcesList(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Leads Across Sources',
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
              Text(
                '${_breakdown.totalLeads}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: ThemeManager().primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Dynamic Lead Sources (Click to drill down into individual leads):',
          style: TextStyle(fontSize: 13, color: subColor),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _breakdown.sources.isEmpty
              ? Center(child: Text('No leads found for selected filters.', style: TextStyle(color: subColor)))
              : ListView.separated(
                  itemCount: _breakdown.sources.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _breakdown.sources[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeManager().primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.source_rounded, color: ThemeManager().primaryColor, size: 18),
                      ),
                      title: Text(
                        item.source,
                        style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.count} Leads',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: ThemeManager().primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: subColor),
                        ],
                      ),
                      onTap: () => _fetchLeadsList(item.source),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLeadsList(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    if (_isLoadingLeads) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leads.isEmpty) {
      return Center(
        child: Text('No leads found for source $_selectedSource.', style: TextStyle(color: subColor)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: _leads.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lead = _leads[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                hoverColor: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                onTap: () => KpiDrilldownDialogs.showLeadDetails(context, lead: lead),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lead.customerName,
                        style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lead.stage,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            lead.sanitizedPhone.isNotEmpty ? lead.sanitizedPhone : lead.phone,
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: lead.leadType == 'Property Listing'
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lead.leadType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: lead.leadType == 'Property Listing'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          if (lead.budgetDisplay != null && lead.budgetDisplay!.trim().isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.payments_outlined, size: 12, color: subColor),
                            const SizedBox(width: 3),
                            Text(
                              lead.budgetDisplay!,
                              style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                          if (lead.telecallerName != null && lead.telecallerName!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.headset_mic_rounded, size: 12, color: subColor),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                lead.telecallerName!,
                                style: TextStyle(fontSize: 11, color: subColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if ((lead.configuration != null && lead.configuration!.trim().isNotEmpty) ||
                          (lead.locality != null && lead.locality!.trim().isNotEmpty) ||
                          (lead.campaignName != null && lead.campaignName!.trim().isNotEmpty)) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (lead.configuration != null && lead.configuration!.trim().isNotEmpty)
                              _buildKpiMiniBadge(
                                icon: Icons.apartment_rounded,
                                text: _cleanKpiDisplayText(lead.configuration!),
                                color: const Color(0xFF6366F1),
                                isDark: isDark,
                              ),
                            if (lead.locality != null && lead.locality!.trim().isNotEmpty)
                              _buildKpiMiniBadge(
                                icon: Icons.location_on_outlined,
                                text: _cleanKpiDisplayText(lead.locality!),
                                color: const Color(0xFF0EA5E9),
                                isDark: isDark,
                              ),
                            if (lead.campaignName != null && lead.campaignName!.trim().isNotEmpty)
                              _buildKpiMiniBadge(
                                icon: Icons.campaign_outlined,
                                text: lead.campaignName!,
                                color: subColor,
                                isDark: isDark,
                                isMuted: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View', style: TextStyle(fontSize: 12, color: ThemeManager().primaryColor, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 18, color: ThemeManager().primaryColor),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${_leads.length} of $_leadsTotal leads',
              style: TextStyle(fontSize: 12, color: subColor),
            ),
            Row(
              children: [
                if (_leadsPage > 1)
                  TextButton.icon(
                    onPressed: () => _fetchLeadsList(_selectedSource!, page: _leadsPage - 1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 16),
                    label: const Text('Prev'),
                  ),
                if (_leadsPage * 25 < _leadsTotal)
                  TextButton.icon(
                    onPressed: () => _fetchLeadsList(_selectedSource!, page: _leadsPage + 1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 16),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 2.1 LEAD DETAILS MODAL (Full Lifecycle, Allocation, Telecaller & Sales Status)
// ============================================================================
class _LeadDetailsDialog extends StatelessWidget {
  final LeadListItem lead;

  const _LeadDetailsDialog({required this.lead});

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year}, $hour:$minute $ampm';
  }

  String _formatBudget() {
    if (lead.budgetDisplay != null && lead.budgetDisplay!.trim().isNotEmpty) {
      return lead.budgetDisplay!;
    }
    if (lead.budget != null && lead.budget! > 0) {
      return CRMCurrencyFormatter.format(lead.budget!.toDouble());
    }
    if (lead.budgetFrom != null || lead.budgetTo != null) {
      final f = lead.budgetFrom != null ? CRMCurrencyFormatter.format(lead.budgetFrom!.toDouble()) : '₹0';
      final t = lead.budgetTo != null ? CRMCurrencyFormatter.format(lead.budgetTo!.toDouble()) : 'Open';
      return '$f - $t';
    }
    return 'Not Specified';
  }

  Color _getStageColor(String stage) {
    switch (stage.toUpperCase()) {
      case 'NEW':
        return const Color(0xFF3B82F6);
      case 'QUALIFICATION':
      case 'INTERESTED':
        return const Color(0xFF10B981);
      case 'SALES':
        return const Color(0xFF6366F1);
      case 'WON':
        return const Color(0xFF059669);
      case 'LOST':
        return const Color(0xFFEF4444);
      case 'ARCHIVED':
      case 'LISTED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final stageColor = _getStageColor(lead.stage);

    final raw = lead.rawJson ?? {};
    final ignoredKeys = {
      'id', 'ad_id', 'form_id', 'adset_id', 'campaign_id', 'platform',
      'is_organic', 'lead_status', 'created_time', 'phone_number', 'full_name',
      'Full Name', 'lead_name', 'Name', 'name', 'Client Name', 'Customer Name',
      'email', 'Email ID', 'lead_email', 'Ad Name', 'ad_name', 'Campaign Name',
      'campaign_name', 'form_name', 'Form Name', 'adset_name', 'city', 'City',
      'city_name', 'Status', 'status', 'Remarks', 'Remarks ', 'Number', 'lead_phone',
      'Phone Number', 'country_code', 'service_type', 'category_type', 'flat_id',
      'lead_date', 'max_area', 'min_area', 'min_price', 'max_price', '_transfer',
      'assignment_history', 'status_updated_at', 'status_updated_by_id',
      'status_updated_by_name', 'status_updated_by_role', 'not_interested_at',
      'not_interested_by_id', 'not_interested_by_name', 'not_interested_notes',
      'not_interested_reason', ''
    };

    final questionnaire = <MapEntry<String, String>>[];
    for (final entry in raw.entries) {
      final k = entry.key.toString().trim();
      dynamic rawV = entry.value;
      String v;
      if (rawV is List) {
        v = rawV.map((item) => item.toString()).join(', ');
      } else {
        v = rawV?.toString().trim() ?? '';
      }
      if (!ignoredKeys.contains(k) && v.isNotEmpty && v != 'null') {
        var title = k.replaceAll('_', ' ').replaceAll('?', '').trim();
        if (title.isNotEmpty) {
          title = title.split(' ').map((w) => w.isNotEmpty ? (w[0].toUpperCase() + w.substring(1).toLowerCase()) : '').join(' ');
        }
        var cleanV = v.replaceAll('_', ' ').trim();
        questionnaire.add(MapEntry(title, cleanV));
      }
    }

    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 760,
      targetMaxHeight: 700,
      contentPadding: EdgeInsets.zero,
      child: Column(
        children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: ThemeManager().primaryColor.withValues(alpha: 0.15),
                    child: Icon(Icons.person_rounded, color: ThemeManager().primaryColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                lead.customerName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stageColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                lead.stage,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: stageColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lead.source.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Created ${_formatDateTime(lead.createdAt)}',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Customer Contact & Requirements Summary
                    _buildSectionHeader('Contact & Requirement Details', Icons.contact_phone_outlined, textColor),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Phone',
                                  lead.sanitizedPhone.isNotEmpty ? lead.sanitizedPhone : lead.phone,
                                  Icons.phone_rounded,
                                  textColor,
                                  subColor,
                                  canCopy: true,
                                  context: context,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Email',
                                  (lead.sanitizedEmail != null && lead.sanitizedEmail!.isNotEmpty)
                                      ? lead.sanitizedEmail!
                                      : (lead.email ?? 'N/A'),
                                  Icons.email_outlined,
                                  textColor,
                                  subColor,
                                  canCopy: lead.email != null && lead.email!.isNotEmpty,
                                  context: context,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Lead Type',
                                  lead.leadType,
                                  lead.leadType == 'Property Listing' ? Icons.home_work_outlined : Icons.search_rounded,
                                  textColor,
                                  subColor,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Budget',
                                  _formatBudget(),
                                  Icons.payments_outlined,
                                  textColor,
                                  subColor,
                                ),
                              ),
                            ],
                          ),
                          if ((lead.configuration != null && lead.configuration!.trim().isNotEmpty) ||
                              (lead.locality != null && lead.locality!.trim().isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    'Configuration / Property',
                                    (lead.configuration != null && lead.configuration!.trim().isNotEmpty)
                                        ? _cleanKpiDisplayText(lead.configuration!)
                                        : 'Not Specified',
                                    Icons.apartment_rounded,
                                    textColor,
                                    subColor,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoItem(
                                    'Locality / Area',
                                    (lead.locality != null && lead.locality!.trim().isNotEmpty)
                                        ? _cleanKpiDisplayText(lead.locality!)
                                        : 'Not Specified',
                                    Icons.location_on_outlined,
                                    textColor,
                                    subColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (lead.campaignName != null && lead.campaignName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Campaign Name',
                              lead.campaignName!,
                              Icons.campaign_outlined,
                              textColor,
                              subColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (questionnaire.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionHeader('Form Enquiry & Requirements', Icons.assignment_outlined, textColor),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: innerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < questionnaire.length; i++) ...[
                              if (i > 0) ...[
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                              ],
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 14, color: ThemeManager().primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      questionnaire[i].key,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subColor),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: SelectableText(
                                      questionnaire[i].value,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Section 2: Current Lifecycle & State
                    _buildSectionHeader('Current Lifecycle & Disposition', Icons.timeline_rounded, textColor),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Stage',
                                  lead.stage,
                                  Icons.flag_outlined,
                                  textColor,
                                  subColor,
                                  customValueColor: stageColor,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Call Disposition',
                                  lead.callDisposition ?? 'Not Attempted',
                                  Icons.call_end_outlined,
                                  textColor,
                                  subColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Allocation Status',
                                  lead.allocationStatus ?? 'None',
                                  Icons.swap_horiz_rounded,
                                  textColor,
                                  subColor,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  'Call Attempts',
                                  '${lead.callAttemptCount} attempted',
                                  Icons.repeat_rounded,
                                  textColor,
                                  subColor,
                                ),
                              ),
                            ],
                          ),
                          if (lead.rejectionReason != null && lead.rejectionReason!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Rejection Reason',
                              lead.rejectionReason!,
                              Icons.cancel_outlined,
                              textColor,
                              subColor,
                              customValueColor: Colors.redAccent,
                            ),
                          ],
                          if (lead.archiveReason != null && lead.archiveReason!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              'Archive Reason',
                              lead.archiveReason!,
                              Icons.archive_outlined,
                              textColor,
                              subColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Telecaller Allocation & Remarks
                    _buildSectionHeader('Telecaller Allocation & Remarks', Icons.headset_mic_rounded, textColor),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: lead.telecallerName != null && lead.telecallerName!.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      child: const Icon(Icons.person_outline, color: Color(0xFF10B981), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lead.telecallerName!,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            [
                                              if (lead.telecallerPhone != null && lead.telecallerPhone!.isNotEmpty)
                                                lead.telecallerPhone!,
                                              if (lead.telecallerEmail != null && lead.telecallerEmail!.isNotEmpty)
                                                lead.telecallerEmail!,
                                            ].join(' • '),
                                            style: TextStyle(fontSize: 11, color: subColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (lead.telecallerAssignedAt != null)
                                      Text(
                                        'Allocated: ${_formatDateTime(lead.telecallerAssignedAt)}',
                                        style: TextStyle(fontSize: 11, color: subColor),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Telecaller Remarks
                                Text('Telecaller Remarks / Notes', style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Text(
                                    (lead.telecallerRemarks != null && lead.telecallerRemarks!.trim().isNotEmpty)
                                        ? lead.telecallerRemarks!
                                        : 'No telecaller remarks recorded.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: (lead.telecallerRemarks != null && lead.telecallerRemarks!.trim().isNotEmpty)
                                          ? textColor
                                          : subColor,
                                      fontStyle: (lead.telecallerRemarks != null && lead.telecallerRemarks!.trim().isNotEmpty)
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ),
                                if (lead.latestCallRemarks != null && lead.latestCallRemarks!.trim().isNotEmpty && lead.latestCallRemarks != lead.telecallerRemarks) ...[
                                  const SizedBox(height: 10),
                                  Text('Latest Call Attempt Remarks', style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lead.latestCallRemarks!,
                                          style: TextStyle(fontSize: 13, color: textColor),
                                        ),
                                        if (lead.latestCallOutcome != null || lead.latestCallAt != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (lead.latestCallOutcome != null) 'Outcome: ${lead.latestCallOutcome}',
                                              if (lead.latestCallAt != null) _formatDateTime(lead.latestCallAt),
                                            ].join(' • '),
                                            style: TextStyle(fontSize: 10, color: subColor),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                if (lead.transferRemarks != null && lead.transferRemarks!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text('Handoff / Transfer Remarks to Sales', style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      lead.transferRemarks!,
                                      style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: subColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No telecaller has been allocated to this lead yet.',
                                    style: TextStyle(fontSize: 13, color: subColor, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Sales User Assignment & Remarks
                    _buildSectionHeader('Sales User Assignment & Current Status', Icons.badge_outlined, textColor),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: lead.salesUserName != null && lead.salesUserName!.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      child: const Icon(Icons.person_outline, color: Color(0xFF3B82F6), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lead.salesUserName!,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            [
                                              if (lead.salesUserPhone != null && lead.salesUserPhone!.isNotEmpty)
                                                lead.salesUserPhone!,
                                              if (lead.salesUserEmail != null && lead.salesUserEmail!.isNotEmpty)
                                                lead.salesUserEmail!,
                                            ].join(' • '),
                                            style: TextStyle(fontSize: 11, color: subColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (lead.salesStatus != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          lead.salesStatus!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Sales Remarks
                                Text('Sales User Remarks / Status', style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Text(
                                    (lead.salesRemarks != null && lead.salesRemarks!.trim().isNotEmpty)
                                        ? lead.salesRemarks!
                                        : 'No sales remarks recorded yet.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: (lead.salesRemarks != null && lead.salesRemarks!.trim().isNotEmpty)
                                          ? textColor
                                          : subColor,
                                      fontStyle: (lead.salesRemarks != null && lead.salesRemarks!.trim().isNotEmpty)
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: subColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'This lead has not been assigned to any sales user yet.',
                                    style: TextStyle(fontSize: 13, color: subColor, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ThemeManager().primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color subColor, {
    Color? customValueColor,
    bool canCopy = false,
    BuildContext? context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: subColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: subColor)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: customValueColor ?? textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canCopy && context != null && value.isNotEmpty && value != 'N/A') ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied $label: $value'), duration: const Duration(seconds: 1)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 12, color: subColor),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 3. TELECALLERS DRILLDOWN DIALOG (Summary List -> Telecaller Performance)
// ============================================================================
class _TelecallersDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _TelecallersDrilldownDialog({required this.params});

  @override
  State<_TelecallersDrilldownDialog> createState() => _TelecallersDrilldownDialogState();
}

class _TelecallersDrilldownDialogState extends State<_TelecallersDrilldownDialog> {
  bool _isLoading = true;
  TelecallersSummaryResponse _summary = const TelecallersSummaryResponse();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getTelecallersSummary(widget.params);
    if (mounted) {
      setState(() {
        _summary = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 760,
      targetMaxHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Telecallers (${_summary.totalTelecallers})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Allocation and performance overview | Range: ${widget.params.dateFilter}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _summary.telecallers.isEmpty
                    ? Center(child: Text('No active telecallers found.', style: TextStyle(color: subColor)))
                    : ListView.separated(
                        itemCount: _summary.telecallers.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tc = _summary.telecallers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ThemeManager().primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                tc.name.isNotEmpty ? tc.name[0].toUpperCase() : 'T',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ThemeManager().primaryColor,
                                ),
                              ),
                            ),
                            title: Text(
                              tc.name,
                              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                            ),
                            subtitle: Text(
                              tc.email,
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${tc.leadsAllocated} Allocated',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: ThemeManager().primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'List: ${tc.listingLeads} | Req: ${tc.requirementLeads}',
                                      style: TextStyle(fontSize: 11, color: subColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: subColor),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              KpiDrilldownDialogs.showTelecallerPerformance(
                                context,
                                telecallerId: tc.id,
                                telecallerName: tc.name,
                                initialLeadType: widget.params.leadType,
                                params: widget.params,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TELECALLER PERFORMANCE DRILL-DOWN (Section 8 Requirements)
// ============================================================================
class _TelecallerPerformanceDialog extends StatefulWidget {
  final String telecallerId;
  final String telecallerName;
  final String initialLeadType;
  final KpiFilterParams? params;

  const _TelecallerPerformanceDialog({
    required this.telecallerId,
    required this.telecallerName,
    required this.initialLeadType,
    this.params,
  });

  @override
  State<_TelecallerPerformanceDialog> createState() => _TelecallerPerformanceDialogState();
}

class _TelecallerPerformanceDialogState extends State<_TelecallerPerformanceDialog> {
  late String _leadType;
  bool _isLoading = true;
  TelecallerDrilldownData? _data;
  bool _showSalesBreakdown = false;

  // Category drill-down state
  String? _selectedCategory; // null = overview; 'all', 'listing', 'requirement', 'open', 'cnr', 'callback', 'follow_up', 'assigned_to_sales', 'not_interested', 'archived'
  String _selectedCategoryTitle = '';
  bool _isLoadingCategoryLeads = false;
  List<LeadListItem> _categoryLeads = [];
  int _categoryTotal = 0;
  int _categoryPage = 1;
  final TextEditingController _categorySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _leadType = widget.initialLeadType;
    _fetch();
  }

  @override
  void dispose() {
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getTelecallerDrilldown(
      widget.telecallerId,
      leadType: _leadType,
      params: widget.params,
    );
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCategory(String categoryKey, String title) async {
    setState(() {
      _selectedCategory = categoryKey;
      _selectedCategoryTitle = title;
      _categoryPage = 1;
      _categorySearchController.clear();
      _isLoadingCategoryLeads = true;
    });
    await _fetchCategoryLeads();
  }

  Future<void> _fetchCategoryLeads() async {
    if (_selectedCategory == null) return;
    setState(() => _isLoadingCategoryLeads = true);

    final res = await KpiDrilldownDialogs._dashboardService.getTelecallerLeads(
      widget.telecallerId,
      category: _selectedCategory!,
      leadType: _leadType,
      search: _categorySearchController.text,
      page: _categoryPage,
      limit: 25,
      params: widget.params,
    );

    if (mounted) {
      setState(() {
        _categoryLeads = res.leads;
        _categoryTotal = res.total;
        _isLoadingCategoryLeads = false;
      });
    }
  }

  Color _getStageColor(String stage) {
    switch (stage.toUpperCase()) {
      case 'NEW':
        return const Color(0xFF3B82F6);
      case 'QUALIFICATION':
      case 'INTERESTED':
        return const Color(0xFF10B981);
      case 'SALES':
        return const Color(0xFF6366F1);
      case 'WON':
        return const Color(0xFF059669);
      case 'LOST':
        return const Color(0xFFEF4444);
      case 'ARCHIVED':
      case 'LISTED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  String _formatBudget(LeadListItem lead) {
    if (lead.budgetDisplay != null && lead.budgetDisplay!.trim().isNotEmpty) {
      return lead.budgetDisplay!;
    }
    if (lead.budget != null && lead.budget! > 0) {
      return CRMCurrencyFormatter.format(lead.budget!.toDouble());
    }
    if (lead.budgetFrom != null || lead.budgetTo != null) {
      final f = lead.budgetFrom != null ? CRMCurrencyFormatter.format(lead.budgetFrom!.toDouble()) : '₹0';
      final t = lead.budgetTo != null ? CRMCurrencyFormatter.format(lead.budgetTo!.toDouble()) : 'Open';
      return '$f - $t';
    }
    return 'Not Specified';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 920,
      targetMaxHeight: 740,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              if (_selectedCategory != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedCategory = null),
                  tooltip: 'Back to Performance Overview',
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                _selectedCategory != null ? Icons.assignment_outlined : Icons.speed_rounded,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCategory != null
                          ? '${widget.telecallerName} — $_selectedCategoryTitle'
                          : '${widget.telecallerName} — Performance Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedCategory != null
                          ? 'Showing ${_categoryLeads.length} of $_categoryTotal leads | Type: $_leadType | Range: ${widget.params?.dateFilter ?? "Weekly"}'
                          : 'Click any metric or category card below to view matching leads | Range: ${widget.params?.dateFilter ?? "Weekly"}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              // Lead Type Toggle
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Both', 'Listing', 'Requirement'].map((type) {
                    final isSel = _leadType == type;
                    return GestureDetector(
                      onTap: () {
                        if (_leadType != type) {
                          setState(() => _leadType = type);
                          _fetch();
                          if (_selectedCategory != null) {
                            _fetchCategoryLeads();
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel ? ThemeManager().primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? Colors.white : subColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Body: Overview vs Category Leads
          Expanded(
            child: _selectedCategory == null
                ? (_isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _data == null
                        ? Center(child: Text('Failed to load telecaller performance.', style: TextStyle(color: subColor)))
                        : _buildOverviewView(textColor, subColor, borderColor, isDark))
                : _buildCategoryLeadsView(textColor, subColor, borderColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewView(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    final d = _data!;
    final primaryColor = ThemeManager().primaryColor;

    final categories = [
      {'key': 'open', 'title': 'Open Leads', 'count': d.openLeads, 'color': const Color(0xFF3B82F6), 'icon': Icons.folder_open_rounded, 'desc': 'New & unattempted'},
      {'key': 'cnr', 'title': 'CNR', 'count': d.cnr, 'color': const Color(0xFFF59E0B), 'icon': Icons.phone_missed_rounded, 'desc': 'Call not received'},
      {'key': 'callback', 'title': 'Callbacks', 'count': d.callbacks, 'color': const Color(0xFF8B5CF6), 'icon': Icons.ring_volume_rounded, 'desc': 'Callback requested'},
      {'key': 'follow_up', 'title': 'Follow Up', 'count': d.followUp, 'color': const Color(0xFF06B6D4), 'icon': Icons.update_rounded, 'desc': 'Contacted & interested'},
      {'key': 'assigned_to_sales', 'title': 'Assigned to Sales', 'count': d.assignedToSales, 'color': const Color(0xFF10B981), 'icon': Icons.person_add_alt_1_rounded, 'desc': 'Transferred to sales'},
      {'key': 'not_interested', 'title': 'Not Interested', 'count': d.notInterested, 'color': const Color(0xFFEF4444), 'icon': Icons.thumb_down_alt_rounded, 'desc': 'Lost / rejected'},
      {'key': 'archived', 'title': 'Archived', 'count': d.archived, 'color': const Color(0xFF64748B), 'icon': Icons.archive_rounded, 'desc': 'Listed or closed'},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Allocation Summary: 3 Clickable Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 580;
              final topCards = [
                _buildTopStatCard(
                  title: 'Total Allocated',
                  count: d.totalAllocated,
                  subtitle: 'All allocated leads',
                  icon: Icons.assignment_ind_rounded,
                  color: primaryColor,
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () => _selectCategory('all', 'Total Allocated Leads'),
                ),
                _buildTopStatCard(
                  title: 'Listing Allocated',
                  count: d.listingAllocated,
                  subtitle: 'Property listings',
                  icon: Icons.home_work_rounded,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () => _selectCategory('listing', 'Listing Allocated Leads'),
                ),
                _buildTopStatCard(
                  title: 'Requirement Allocated',
                  count: d.requirementAllocated,
                  subtitle: 'Client requirements',
                  icon: Icons.search_rounded,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                  subColor: subColor,
                  onTap: () => _selectCategory('requirement', 'Requirement Allocated Leads'),
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: topCards[0]),
                    const SizedBox(width: 10),
                    Expanded(child: topCards[1]),
                    const SizedBox(width: 10),
                    Expanded(child: topCards[2]),
                  ],
                );
              }
              return Column(
                children: [
                  topCards[0],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: topCards[1]),
                      const SizedBox(width: 8),
                      Expanded(child: topCards[2]),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lifecycle & Status Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              Text(
                'Click any card to view lead details',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: subColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. 7 Category KPI Cards Grid (Clickable)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 720
                  ? 4
                  : (constraints.maxWidth >= 480 ? 3 : 2);
              final ratio = constraints.maxWidth >= 720
                  ? 2.2
                  : (constraints.maxWidth >= 480 ? 2.0 : 2.0);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: ratio,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final key = cat['key'] as String;
                  final title = cat['title'] as String;
                  final count = cat['count'] as int;
                  final color = cat['color'] as Color;
                  final icon = cat['icon'] as IconData;
                  final desc = cat['desc'] as String;

                  return InkWell(
                    onTap: () => _selectCategory(key, '$title Leads'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: subColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 16, color: color.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // 3. Sales Users Transfer Breakdown Toggle
          if (d.salesUserBreakdown.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _showSalesBreakdown = !_showSalesBreakdown),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          'Sales Users Transfer Breakdown (${d.salesUserBreakdown.length} sales users)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                        ),
                      ],
                    ),
                    Icon(
                      _showSalesBreakdown ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: subColor,
                    ),
                  ],
                ),
              ),
            ),
            if (_showSalesBreakdown) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: d.salesUserBreakdown.length,
                  separatorBuilder: (context, _) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = d.salesUserBreakdown[idx];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                        child: Text(
                          item.salesUserName.isNotEmpty ? item.salesUserName[0].toUpperCase() : 'S',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                      title: Text(item.salesUserName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                      trailing: Text(
                        '${item.leadCount} Leads Transferred',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTopStatCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11.5, color: subColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLeadsView(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    final innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Column(
      children: [
        // Search bar & count
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _categorySearchController,
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search customer name, phone, or email...',
                    hintStyle: TextStyle(fontSize: 12, color: subColor),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _categorySearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _categorySearchController.clear();
                              _fetchCategoryLeads();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  onSubmitted: (_) {
                    setState(() => _categoryPage = 1);
                    _fetchCategoryLeads();
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _categoryPage = 1);
                _fetchCategoryLeads();
              },
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeManager().primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Leads List
        Expanded(
          child: _isLoadingCategoryLeads
              ? const Center(child: CircularProgressIndicator())
              : _categoryLeads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: subColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('No $_selectedCategoryTitle leads found.', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          const SizedBox(height: 4),
                          Text('Try adjusting your search or lead type filter.', style: TextStyle(fontSize: 12, color: subColor)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _categoryLeads.length,
                      itemBuilder: (context, index) {
                        final lead = _categoryLeads[index];
                        final stageColor = _getStageColor(lead.stage);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: InkWell(
                            onTap: () => KpiDrilldownDialogs.showLeadDetails(context, lead: lead),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Name, Stage, Lead Type, Source
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: stageColor.withValues(alpha: 0.15),
                                        child: Icon(Icons.person_outline_rounded, size: 16, color: stageColor),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          lead.customerName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Stage badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: stageColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          lead.stage,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stageColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Lead type badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          lead.leadType == 'Property Listing' ? 'Listing' : 'Requirement',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Source tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          lead.source.toUpperCase(),
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 13, color: subColor),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Row 2: Phone, Email, Budget
                                  Row(
                                    children: [
                                      Icon(Icons.phone_rounded, size: 13, color: subColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        lead.sanitizedPhone.isNotEmpty ? lead.sanitizedPhone : lead.phone,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(Icons.payments_outlined, size: 13, color: subColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Budget: ${_formatBudget(lead)}',
                                        style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Attempts: ${lead.callAttemptCount}',
                                        style: TextStyle(fontSize: 11, color: subColor),
                                      ),
                                    ],
                                  ),

                                  // Row 2.5: Configuration, Locality, Campaign
                                  if ((lead.configuration != null && lead.configuration!.trim().isNotEmpty) ||
                                      (lead.locality != null && lead.locality!.trim().isNotEmpty) ||
                                      (lead.campaignName != null && lead.campaignName!.trim().isNotEmpty)) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (lead.configuration != null && lead.configuration!.trim().isNotEmpty)
                                          _buildKpiMiniBadge(
                                            icon: Icons.apartment_rounded,
                                            text: _cleanKpiDisplayText(lead.configuration!),
                                            color: const Color(0xFF6366F1),
                                            isDark: isDark,
                                          ),
                                        if (lead.locality != null && lead.locality!.trim().isNotEmpty)
                                          _buildKpiMiniBadge(
                                            icon: Icons.location_on_outlined,
                                            text: _cleanKpiDisplayText(lead.locality!),
                                            color: const Color(0xFF0EA5E9),
                                            isDark: isDark,
                                          ),
                                        if (lead.campaignName != null && lead.campaignName!.trim().isNotEmpty)
                                          _buildKpiMiniBadge(
                                            icon: Icons.campaign_outlined,
                                            text: lead.campaignName!,
                                            color: subColor,
                                            isDark: isDark,
                                            isMuted: true,
                                          ),
                                      ],
                                    ),
                                  ],

                                  // Row 3: Telecaller notes (if any)
                                  if (lead.telecallerRemarks != null && lead.telecallerRemarks!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.edit_note_rounded, size: 15, color: ThemeManager().primaryColor),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Telecaller Remark: ${lead.telecallerRemarks}',
                                              style: TextStyle(fontSize: 12, color: textColor),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Row 4: Assigned Sales User (if any)
                                  if (lead.salesUserName != null && lead.salesUserName!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person_pin_rounded, size: 15, color: Color(0xFF10B981)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Assigned to: ${lead.salesUserName}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                          ),
                                          if (lead.salesStatus != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${lead.salesStatus})',
                                              style: TextStyle(fontSize: 11, color: textColor),
                                            ),
                                          ],
                                          if (lead.salesRemarks != null && lead.salesRemarks!.trim().isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '• ${lead.salesRemarks}',
                                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: subColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Pagination Bar
        if (_categoryTotal > 25) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $_categoryPage of ${((_categoryTotal - 1) ~/ 25) + 1} ($_categoryTotal leads total)',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _categoryPage > 1
                        ? () {
                            setState(() => _categoryPage--);
                            _fetchCategoryLeads();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Previous', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: (_categoryPage * 25) < _categoryTotal
                        ? () {
                            setState(() => _categoryPage++);
                            _fetchCategoryLeads();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Next', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// 4. LEADS ALLOCATED DRILLDOWN DIALOG
// ============================================================================
class _LeadsAllocatedDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _LeadsAllocatedDrilldownDialog({required this.params});

  @override
  State<_LeadsAllocatedDrilldownDialog> createState() => _LeadsAllocatedDrilldownDialogState();
}

class _LeadsAllocatedDrilldownDialogState extends State<_LeadsAllocatedDrilldownDialog> {
  bool _isLoading = true;
  LeadsAllocatedResponse _data = const LeadsAllocatedResponse();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getLeadsAllocatedBreakdown(widget.params);
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 820,
      targetMaxHeight: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_ind_rounded,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leads Allocated Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Allocation by telecaller | ${widget.params.dateFilter}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final pills = [
                  _buildSummaryPill('New Allocated', '${_data.newAllocated}', ThemeManager().primaryColor, isDark, borderColor),
                  _buildSummaryPill('Old Allocated', '${_data.oldAllocated}', const Color(0xFFF59E0B), isDark, borderColor),
                  _buildSummaryPill('Listing Leads', '${_data.listingAllocated}', const Color(0xFF10B981), isDark, borderColor),
                  _buildSummaryPill('Requirement Leads', '${_data.requirementAllocated}', const Color(0xFF3B82F6), isDark, borderColor),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: pills[0]),
                      const SizedBox(width: 8),
                      Expanded(child: pills[1]),
                      const SizedBox(width: 8),
                      Expanded(child: pills[2]),
                      const SizedBox(width: 8),
                      Expanded(child: pills[3]),
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: pills[0]),
                        const SizedBox(width: 8),
                        Expanded(child: pills[1]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: pills[2]),
                        const SizedBox(width: 8),
                        Expanded(child: pills[3]),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Telecaller Allocation Table (Tap to view telecaller performance):',
              style: TextStyle(fontSize: 13, color: subColor),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _data.telecallers.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _data.telecallers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ThemeManager().primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        item.telecallerName.isNotEmpty ? item.telecallerName[0].toUpperCase() : 'T',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ThemeManager().primaryColor,
                        ),
                      ),
                    ),
                    title: Text(item.telecallerName, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text(
                      'New: ${item.newCount} | Old: ${item.oldCount} | Listing: ${item.listingCount} | Req: ${item.requirementCount}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.totalCount} Leads',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: ThemeManager().primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: subColor),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      KpiDrilldownDialogs.showTelecallerPerformance(
                        context,
                        telecallerId: item.telecallerId,
                        telecallerName: item.telecallerName,
                        initialLeadType: widget.params.leadType,
                        params: widget.params,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPill(
    String label,
    String value,
    Color color,
    bool isDark,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. ASSIGNED TO SALES DRILLDOWN DIALOG
// ============================================================================
class _AssignedToSalesDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _AssignedToSalesDrilldownDialog({required this.params});

  @override
  State<_AssignedToSalesDrilldownDialog> createState() => _AssignedToSalesDrilldownDialogState();
}

class _AssignedToSalesDrilldownDialogState extends State<_AssignedToSalesDrilldownDialog> {
  bool _isLoading = true;
  AssignedToSalesResponse _data = const AssignedToSalesResponse();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getAssignedToSalesBreakdown(widget.params);
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 820,
      targetMaxHeight: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.badge_rounded,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Assigned to Sales Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Total assigned across telecallers & sales users | Range: ${widget.params.dateFilter}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            // Metrics bar (responsive layout)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                Widget buildMetricCard(String label, String value, Color color) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: TextStyle(fontSize: 11, color: subColor)),
                        const SizedBox(height: 2),
                        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  );
                }

                if (isNarrow) {
                  return Column(
                    children: [
                      buildMetricCard('Total Assigned', '${_data.totalAssigned}', ThemeManager().primaryColor),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: buildMetricCard('Listing Assigned', '${_data.listingAssigned}', const Color(0xFF10B981))),
                          const SizedBox(width: 8),
                          Expanded(child: buildMetricCard('Requirement Assigned', '${_data.requirementAssigned}', const Color(0xFF3B82F6))),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: buildMetricCard('Total Assigned', '${_data.totalAssigned}', ThemeManager().primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(child: buildMetricCard('Listing Assigned', '${_data.listingAssigned}', const Color(0xFF10B981))),
                    const SizedBox(width: 12),
                    Expanded(child: buildMetricCard('Requirement Assigned', '${_data.requirementAssigned}', const Color(0xFF3B82F6))),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Sales Assignments (Transferred by Telecaller to Sales User):', style: TextStyle(fontSize: 13, color: subColor)),
            const SizedBox(height: 10),
            Expanded(
              child: _data.breakdown.isEmpty
                  ? Center(child: Text('No assigned leads found.', style: TextStyle(color: subColor)))
                  : ListView.separated(
                      itemCount: _data.breakdown.length,
                      separatorBuilder: (context, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final b = _data.breakdown[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 18),
                          ),
                          title: Text(
                            '${b.telecallerName} ➔ ${b.salesUserName}',
                            style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Listing: ${b.listingCount} | Requirement: ${b.requirementCount}',
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${b.totalCount} Leads',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: ThemeManager().primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right_rounded, color: subColor),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            KpiDrilldownDialogs.showSalesUserLifecycle(
                              context,
                              salesUserId: b.salesUserId,
                              salesUserName: b.salesUserName,
                              params: widget.params,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 6. SALES USERS DRILLDOWN DIALOG (Summary -> Sales User Lifecycle)
// ============================================================================
class _SalesUsersDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _SalesUsersDrilldownDialog({required this.params});

  @override
  State<_SalesUsersDrilldownDialog> createState() => _SalesUsersDrilldownDialogState();
}

class _SalesUsersDrilldownDialogState extends State<_SalesUsersDrilldownDialog> {
  bool _isLoading = true;
  SalesUsersSummaryResponse _summary = const SalesUsersSummaryResponse();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getSalesUsersSummary(widget.params);
    if (mounted) {
      setState(() {
        _summary = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 720,
      targetMaxHeight: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: ThemeManager().primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Sales Users (${_summary.totalSalesUsers})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Lifecycle overview by sales rep | Range: ${widget.params.dateFilter}',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _summary.salesUsers.isEmpty
                    ? Center(child: Text('No sales users found.', style: TextStyle(color: subColor)))
                    : ListView.separated(
                        itemCount: _summary.salesUsers.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final su = _summary.salesUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ThemeManager().primaryColor.withValues(alpha: 0.12),
                              child: Text(
                                su.name.isNotEmpty ? su.name[0].toUpperCase() : 'S',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ThemeManager().primaryColor,
                                ),
                              ),
                            ),
                            title: Text(su.name, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                            subtitle: Text(su.email, style: TextStyle(fontSize: 12, color: subColor)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${su.leadsCount} Leads',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: ThemeManager().primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: subColor),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              KpiDrilldownDialogs.showSalesUserLifecycle(
                                context,
                                salesUserId: su.id,
                                salesUserName: su.name,
                                params: widget.params,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SALES USER DETAILED KPI VIEW (Section 12: 10 Lifecycle Statuses)
// ============================================================================
class _SalesUserLifecycleDialog extends StatefulWidget {
  final String salesUserId;
  final String salesUserName;
  final KpiFilterParams? params;

  const _SalesUserLifecycleDialog({
    required this.salesUserId,
    required this.salesUserName,
    this.params,
  });

  @override
  State<_SalesUserLifecycleDialog> createState() => _SalesUserLifecycleDialogState();
}

class _SalesUserLifecycleDialogState extends State<_SalesUserLifecycleDialog> {
  bool _isLoading = true;
  SalesUserDrilldownData? _data;
  bool _showRejectionBreakdown = false;

  // Drilldown to requirements list state:
  String? _selectedStatusKey;
  String? _selectedStatusTitle;
  Color? _selectedStatusColor;
  String? _selectedRejectionReason;
  bool _isReqLoading = false;
  List<SalesUserRequirementItem> _requirements = [];
  int _reqTotal = 0;
  int _reqPage = 1;
  final TextEditingController _reqSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _reqSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getSalesUserDrilldown(
      widget.salesUserId,
      params: widget.params,
    );
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  void _selectStatus(String key, String title, Color color, {String? rejectionReason}) {
    setState(() {
      _selectedStatusKey = key;
      _selectedStatusTitle = title;
      _selectedStatusColor = color;
      _selectedRejectionReason = rejectionReason;
      _reqPage = 1;
      _reqSearchController.clear();
    });
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    if (_selectedStatusKey == null) return;
    setState(() => _isReqLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getSalesUserRequirements(
      widget.salesUserId,
      status: _selectedStatusKey!,
      rejectionReason: _selectedRejectionReason,
      search: _reqSearchController.text,
      page: _reqPage,
      limit: 25,
      params: widget.params,
    );
    if (mounted) {
      setState(() {
        _requirements = res.requirements;
        _reqTotal = res.total;
        _isReqLoading = false;
      });
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year}, $hour:$minute $ampm';
  }

  String _formatBudget(SalesUserRequirementItem item) {
    if (item.budget != null && item.budget! > 0) {
      return CRMCurrencyFormatter.format(item.budget!.toDouble());
    }
    if (item.budgetFrom != null || item.budgetTo != null) {
      final f = item.budgetFrom != null ? CRMCurrencyFormatter.format(item.budgetFrom!.toDouble()) : '₹0';
      final t = item.budgetTo != null ? CRMCurrencyFormatter.format(item.budgetTo!.toDouble()) : 'Open';
      return '$f - $t';
    }
    return 'Not Specified';
  }

  void _showRequirementDetails(BuildContext context, SalesUserRequirementItem req) {
    showDialog(
      context: context,
      builder: (ctx) => _RequirementDetailsDialog(requirement: req),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 920,
      targetMaxHeight: 740,
      child: _selectedStatusKey != null
          ? _buildRequirementsView(textColor, subColor, borderColor, isDark)
          : _buildLifecycleOverview(textColor, subColor, borderColor, isDark),
    );
  }

  Widget _buildLifecycleOverview(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline_rounded,
              color: ThemeManager().primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.salesUserName} — Lifecycle Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '10 Lifecycle Statuses | ${widget.params?.dateFilter ?? 'Weekly'} (Tap any card to view leads)',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _data == null
                  ? Center(child: Text('Failed to load sales user lifecycle.', style: TextStyle(color: subColor)))
                  : _buildLifecycleGrid(textColor, subColor, borderColor, isDark),
        ),
      ],
    );
  }

  Widget _buildLifecycleGrid(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    final s = _data!.statuses;
    final lifecycleCards = [
      {'key': 'call_attempted', 'title': 'Call Attempted', 'count': s.callAttempted, 'color': const Color(0xFF3B82F6), 'icon': Icons.phone_forwarded_rounded},
      {'key': 'open', 'title': 'Open', 'count': s.open, 'color': const Color(0xFF06B6D4), 'icon': Icons.folder_open_rounded},
      {'key': 'picked_up', 'title': 'Picked Up', 'count': s.pickedUp, 'color': const Color(0xFF6366F1), 'icon': Icons.touch_app_rounded},
      {'key': 'follow_up', 'title': 'Follow Up', 'count': s.followUp, 'color': const Color(0xFF8B5CF6), 'icon': Icons.update_rounded},
      {'key': 're_follow_up', 'title': 'Re-Follow Up', 'count': s.reFollowUp, 'color': const Color(0xFFA855F7), 'icon': Icons.history_rounded},
      {'key': 'interested', 'title': 'Interested', 'count': s.interested, 'color': const Color(0xFF10B981), 'icon': Icons.thumb_up_alt_rounded},
      {'key': 'site_visit_scheduled', 'title': 'Site Visit Scheduled', 'count': s.siteVisitScheduled, 'color': const Color(0xFF0EA5E9), 'icon': Icons.calendar_month_rounded},
      {'key': 'site_visit_done', 'title': 'Site Visit Done', 'count': s.siteVisitDone, 'color': const Color(0xFF14B8A6), 'icon': Icons.pin_drop_rounded},
      {'key': 'deal_won', 'title': 'Deal Won', 'count': s.dealWon, 'color': const Color(0xFFF97316), 'icon': Icons.emoji_events_rounded},
      {'key': 'rejected', 'title': 'Rejected', 'count': s.rejected, 'color': const Color(0xFFEF4444), 'icon': Icons.cancel_outlined, 'isRejected': true},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Requirements Handled', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                Text(
                  '${s.total}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ThemeManager().primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int crossAxisCount;
              final double childAspectRatio;

              if (width >= 720) {
                crossAxisCount = 5;
                childAspectRatio = 2.3;
              } else if (width >= 540) {
                crossAxisCount = 4;
                childAspectRatio = 2.2;
              } else if (width >= 380) {
                crossAxisCount = 3;
                childAspectRatio = 2.0;
              } else {
                crossAxisCount = 2;
                childAspectRatio = 1.8;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: lifecycleCards.length,
                itemBuilder: (context, index) {
                  final c = lifecycleCards[index];
                  final key = c['key'] as String;
                  final title = c['title'] as String;
                  final count = c['count'] as int;
                  final color = c['color'] as Color;
                  final icon = c['icon'] as IconData;
                  final isRejected = c['isRejected'] == true;

                  return InkWell(
                    onTap: () => _selectStatus(key, title, color),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isRejected ? color : borderColor,
                          width: isRejected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(icon, color: color, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '$count',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                          ),
                          if (isRejected)
                            IconButton(
                              icon: Icon(
                                _showRejectionBreakdown ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: color,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _showRejectionBreakdown = !_showRejectionBreakdown);
                              },
                            )
                          else
                            Icon(Icons.chevron_right_rounded, size: 14, color: color.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_showRejectionBreakdown) ...[
            const SizedBox(height: 16),
            Text(
              'Dynamic Rejection Reasons Breakdown (${_data!.rejectionBreakdown.length} Categories — Tap to filter):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _data!.rejectionBreakdown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text('No rejections recorded for this sales user.', style: TextStyle(color: subColor)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _data!.rejectionBreakdown.length,
                      separatorBuilder: (context, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = _data!.rejectionBreakdown[idx];
                        return ListTile(
                          dense: true,
                          title: Text(item.reason, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                          subtitle: item.rawStatus != item.reason
                              ? Text(item.rawStatus, style: TextStyle(fontSize: 11, color: subColor))
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.count} Leads',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFEF4444)),
                            ],
                          ),
                          onTap: () {
                            _selectStatus('rejected', 'Rejected (${item.reason})', const Color(0xFFEF4444), rejectionReason: item.reason);
                          },
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsView(
    Color textColor,
    Color subColor,
    Color borderColor,
    bool isDark,
  ) {
    final statusColor = _selectedStatusColor ?? ThemeManager().primaryColor;
    final innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Navigation & Header
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _selectedStatusKey = null),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 16, color: textColor),
                    const SizedBox(width: 4),
                    Text('Back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.folder_shared_rounded, color: statusColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.salesUserName} — $_selectedStatusTitle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$_reqTotal Requirements | ${widget.params?.dateFilter ?? 'Weekly'}',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$_reqTotal Leads',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Rejection Reason Filter Chips (if in rejected mode)
        if (_selectedStatusKey == 'rejected' && _data != null && _data!.rejectionBreakdown.isNotEmpty) ...[
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All (${_data!.statuses.rejected})', _selectedRejectionReason == null, () {
                  setState(() => _selectedRejectionReason = null);
                  _loadRequirements();
                }, statusColor, isDark),
                ..._data!.rejectionBreakdown.map((item) {
                  final isSelected = _selectedRejectionReason == item.reason;
                  return _buildFilterChip('${item.reason} (${item.count})', isSelected, () {
                    setState(() => _selectedRejectionReason = isSelected ? null : item.reason);
                    _loadRequirements();
                  }, statusColor, isDark);
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Search bar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _reqSearchController,
                  style: TextStyle(fontSize: 13, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search customer name, phone, area, remarks...',
                    hintStyle: TextStyle(fontSize: 12, color: subColor),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _reqSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _reqSearchController.clear();
                              _loadRequirements();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  onSubmitted: (_) {
                    setState(() => _reqPage = 1);
                    _loadRequirements();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _reqPage = 1);
                _loadRequirements();
              },
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of requirements
        Expanded(
          child: _isReqLoading
              ? const Center(child: CircularProgressIndicator())
              : _requirements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: subColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No requirements found in $_selectedStatusTitle.',
                            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try changing filters or search terms.',
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _requirements.length,
                      itemBuilder: (context, index) {
                        final req = _requirements[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: innerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: InkWell(
                            onTap: () => _showRequirementDetails(context, req),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Name, Status badge, Listing type, Property type, Chevron
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: statusColor.withValues(alpha: 0.15),
                                        child: Text(
                                          req.customerName.isNotEmpty ? req.customerName[0].toUpperCase() : 'R',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          req.customerName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          req.status,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                      if (req.listingType != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            req.listingType!,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
                                          ),
                                        ),
                                      ],
                                      if (req.propertyType != null) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            req.propertyType!,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 6),
                                      Icon(Icons.chevron_right_rounded, size: 16, color: subColor),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Row 2: Phone, Budget, Area, Timestamp (Wrap for zero overflow)
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.phone_rounded, size: 12, color: subColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            req.mobile.isNotEmpty ? req.mobile : 'N/A',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.payments_outlined, size: 12, color: subColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Budget: ${_formatBudget(req)}',
                                            style: TextStyle(fontSize: 12, color: textColor),
                                          ),
                                        ],
                                      ),
                                      if (req.areaName != null && req.areaName!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 12, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              req.areaName!,
                                              style: TextStyle(fontSize: 12, color: subColor),
                                            ),
                                          ],
                                        ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time_rounded, size: 11, color: subColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateTime(req.updatedAt ?? req.createdAt),
                                            style: TextStyle(fontSize: 10.5, color: subColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Row 3: Notes / Remarks snippet
                                  if ((req.notes != null && req.notes!.trim().isNotEmpty) ||
                                      (req.remarks != null && req.remarks!.trim().isNotEmpty)) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        (req.remarks != null && req.remarks!.trim().isNotEmpty)
                                            ? req.remarks!
                                            : req.notes!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11.5, color: textColor, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Pagination
        if (_reqTotal > 25) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $_reqPage of ${((_reqTotal - 1) ~/ 25) + 1} ($_reqTotal total)',
                style: TextStyle(fontSize: 11, color: subColor),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _reqPage > 1
                        ? () {
                            setState(() => _reqPage--);
                            _loadRequirements();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: const Size(55, 28),
                    ),
                    child: const Text('Previous', style: TextStyle(fontSize: 10.5)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: (_reqPage * 25) < _reqTotal
                        ? () {
                            setState(() => _reqPage++);
                            _loadRequirements();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: const Size(55, 28),
                    ),
                    child: const Text('Next', style: TextStyle(fontSize: 10.5)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color activeColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: activeColor.withValues(alpha: 0.15),
        checkmarkColor: activeColor,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: isSelected ? activeColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        ),
      ),
    );
  }
}

class _RequirementDetailsDialog extends StatelessWidget {
  final SalesUserRequirementItem requirement;

  const _RequirementDetailsDialog({required this.requirement});

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year}, $hour:$minute $ampm';
  }

  String _formatBudget() {
    if (requirement.budget != null && requirement.budget! > 0) {
      return CRMCurrencyFormatter.format(requirement.budget!.toDouble());
    }
    if (requirement.budgetFrom != null || requirement.budgetTo != null) {
      final f = requirement.budgetFrom != null ? CRMCurrencyFormatter.format(requirement.budgetFrom!.toDouble()) : '₹0';
      final t = requirement.budgetTo != null ? CRMCurrencyFormatter.format(requirement.budgetTo!.toDouble()) : 'Open';
      return '$f - $t';
    }
    return 'Not Specified';
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('won')) return const Color(0xFF059669);
    if (s.contains('site visit done')) return const Color(0xFF14B8A6);
    if (s.contains('site visit scheduled')) return const Color(0xFF0EA5E9);
    if (s.contains('interested')) return const Color(0xFF10B981);
    if (s.contains('follow')) return const Color(0xFF8B5CF6);
    if (s.contains('picked up') || s.contains('assigned')) return const Color(0xFF6366F1);
    if (s.contains('open') || s.contains('new') || s.contains('live')) return const Color(0xFF06B6D4);
    if (s.contains('rejected')) return const Color(0xFFEF4444);
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final statusColor = _getStatusColor(requirement.status);

    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 680,
      targetMaxHeight: 650,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requirement.customerName,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${requirement.id}',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  requirement.status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Grid (responsive layout)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: innerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 420;
                        if (isNarrow) {
                          return Column(
                            children: [
                              _buildInfoItem('Mobile / Phone', requirement.mobile.isNotEmpty ? requirement.mobile : 'N/A', Icons.phone_rounded, textColor, subColor),
                              const SizedBox(height: 12),
                              _buildInfoItem('Budget', _formatBudget(), Icons.payments_outlined, textColor, subColor),
                              const SizedBox(height: 12),
                              _buildInfoItem('Listing Type', requirement.listingType ?? 'N/A', Icons.sell_outlined, textColor, subColor),
                              const SizedBox(height: 12),
                              _buildInfoItem('Property Type', requirement.propertyType ?? 'N/A', Icons.apartment_rounded, textColor, subColor),
                              const SizedBox(height: 12),
                              _buildInfoItem('Preferred Area', requirement.areaName ?? 'N/A', Icons.location_on_outlined, textColor, subColor),
                              const SizedBox(height: 12),
                              _buildInfoItem('Created Date', _formatDateTime(requirement.createdAt), Icons.calendar_today_rounded, textColor, subColor),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('Mobile / Phone', requirement.mobile.isNotEmpty ? requirement.mobile : 'N/A', Icons.phone_rounded, textColor, subColor),
                                ),
                                Expanded(
                                  child: _buildInfoItem('Budget', _formatBudget(), Icons.payments_outlined, textColor, subColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('Listing Type', requirement.listingType ?? 'N/A', Icons.sell_outlined, textColor, subColor),
                                ),
                                Expanded(
                                  child: _buildInfoItem('Property Type', requirement.propertyType ?? 'N/A', Icons.apartment_rounded, textColor, subColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem('Preferred Area', requirement.areaName ?? 'N/A', Icons.location_on_outlined, textColor, subColor),
                                ),
                                Expanded(
                                  child: _buildInfoItem('Created Date', _formatDateTime(requirement.createdAt), Icons.calendar_today_rounded, textColor, subColor),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes section
                  if (requirement.notes != null && requirement.notes!.trim().isNotEmpty) ...[
                    Text('Requirement Notes / Activity Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        requirement.notes!,
                        style: TextStyle(fontSize: 13, color: textColor, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Remarks section
                  if (requirement.remarks != null && requirement.remarks!.trim().isNotEmpty) ...[
                    Text('Remarks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        requirement.remarks!,
                        style: TextStyle(fontSize: 13, color: textColor, fontStyle: FontStyle.italic, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color textColor, Color subColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: subColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 7. SITE VISITS DONE DRILLDOWN DIALOG
// ============================================================================
class _SiteVisitsDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _SiteVisitsDrilldownDialog({required this.params});

  @override
  State<_SiteVisitsDrilldownDialog> createState() => _SiteVisitsDrilldownDialogState();
}

class _SiteVisitsDrilldownDialogState extends State<_SiteVisitsDrilldownDialog> {
  bool _isLoading = true;
  List<SiteVisitItem> _siteVisits = [];
  int _total = 0;
  int _page = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getSiteVisitsList(
      params: widget.params,
      search: _searchController.text,
      page: _page,
      limit: 25,
    );
    if (mounted) {
      setState(() {
        _siteVisits = res.siteVisits;
        _total = res.total;
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year}, $hour:$minute $ampm';
  }

  String _formatBudget(SiteVisitItem item) {
    if (item.budget != null && item.budget! > 0) {
      return CRMCurrencyFormatter.format(item.budget!.toDouble());
    }
    if (item.budgetFrom != null || item.budgetTo != null) {
      final f = item.budgetFrom != null ? CRMCurrencyFormatter.format(item.budgetFrom!.toDouble()) : '₹0';
      final t = item.budgetTo != null ? CRMCurrencyFormatter.format(item.budgetTo!.toDouble()) : 'Open';
      return '$f - $t';
    }
    return 'Not Specified';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final isRejectedDrilldown = widget.params.outcome == 'REJECTED_AFTER_VISIT';
    final accentColor = isRejectedDrilldown ? const Color(0xFFEF4444) : const Color(0xFFEC4899);

    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 880,
      targetMaxHeight: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isRejectedDrilldown ? Icons.person_off_rounded : Icons.location_on_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRejectedDrilldown ? 'Rejected After Site Visit' : 'Site Visits Done',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Business: ${widget.params.businessType} | Range: ${widget.params.dateFilter}',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$_total ${isRejectedDrilldown ? 'Rejected Visits' : 'Completed Visits'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search customer name, mobile, or sales user...',
                          hintStyle: TextStyle(fontSize: 12, color: subColor),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadVisits();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        onSubmitted: (_) {
                          setState(() => _page = 1);
                          _loadVisits();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _page = 1);
                      _loadVisits();
                    },
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Body: List of Site Visits
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _siteVisits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off_outlined, size: 48, color: subColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No site visits done found matching current filters.',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adjusting the date range or business type.',
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _siteVisits.length,
                            itemBuilder: (context, index) {
                              final item = _siteVisits[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: innerBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Customer Name, Status Badge, Listing Type, Property Type, Date
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: accentColor.withValues(alpha: 0.15),
                                          child: Icon(Icons.person_pin_circle_rounded, size: 16, color: accentColor),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item.customerName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                          ),
                                          child: const Text(
                                            'Site Visit Done',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                        if (item.listingType != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.listingType!,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
                                            ),
                                          ),
                                        ],
                                        if (item.propertyType != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.propertyType!,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 2: Mobile, Budget, Area, Date (Wrap for zero overflow)
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.phone_rounded, size: 13, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.mobile.isNotEmpty ? item.mobile : 'N/A',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                            ),
                                            if (item.mobile.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: item.mobile));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Phone number copied!'), duration: Duration(seconds: 1)),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(2),
                                                  child: Icon(Icons.copy_rounded, size: 12, color: subColor),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.payments_outlined, size: 13, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Budget: ${_formatBudget(item)}',
                                              style: TextStyle(fontSize: 12, color: subColor),
                                            ),
                                          ],
                                        ),
                                        if (item.areaName != null && item.areaName!.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 13, color: subColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.areaName!,
                                                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 12, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDateTime(item.createdAt),
                                              style: TextStyle(fontSize: 11, color: subColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 3: Sales User (Wrap for zero overflow)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF3B82F6)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Assigned Sales Executive: ',
                                                style: TextStyle(fontSize: 12, color: subColor),
                                              ),
                                              Text(
                                                item.salesUserName ?? 'Unassigned',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.salesUserName != null ? textColor : subColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.salesUserPhone != null && item.salesUserPhone!.isNotEmpty)
                                            Text(
                                              '• ${item.salesUserPhone}',
                                              style: TextStyle(fontSize: 11, color: subColor),
                                            ),
                                          if (item.salesUserEmail != null && item.salesUserEmail!.isNotEmpty)
                                            Text(
                                              '• ${item.salesUserEmail}',
                                              style: TextStyle(fontSize: 11, color: subColor),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Row 4: Visit Notes (if any)
                                    if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.rate_review_outlined, size: 14, color: accentColor),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Site Visit Notes / Activity Log:',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.notes!,
                                              style: TextStyle(fontSize: 12, color: textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Row 5: Requirement Remarks (if any)
                                    if (item.remarks != null && item.remarks!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.notes_rounded, size: 14, color: subColor),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Client Requirements: ${item.remarks}',
                                                style: TextStyle(fontSize: 12, color: textColor, fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Pagination Bar
              if (_total > 25) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $_page of ${((_total - 1) ~/ 25) + 1} ($_total site visits total)',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _page > 1
                              ? () {
                                  setState(() => _page--);
                                  _loadVisits();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('Previous', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: (_page * 25) < _total
                              ? () {
                                  setState(() => _page++);
                                  _loadVisits();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('Next', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
    );
  }
}

// ============================================================================
// 8. DEAL WON DRILLDOWN DIALOG
// ============================================================================
class _DealWonDrilldownDialog extends StatefulWidget {
  final KpiFilterParams params;

  const _DealWonDrilldownDialog({required this.params});

  @override
  State<_DealWonDrilldownDialog> createState() => _DealWonDrilldownDialogState();
}

class _DealWonDrilldownDialogState extends State<_DealWonDrilldownDialog> {
  bool _isLoading = true;
  List<DealWonItem> _dealsWon = [];
  int _total = 0;
  int _page = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeals() async {
    setState(() => _isLoading = true);
    final res = await KpiDrilldownDialogs._dashboardService.getDealWonList(
      params: widget.params,
      search: _searchController.text,
      page: _page,
      limit: 25,
    );
    if (mounted) {
      setState(() {
        _dealsWon = res.dealsWon;
        _total = res.total;
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[local.month - 1];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day} $month ${local.year}, $hour:$minute $ampm';
  }

  String _formatBudget(DealWonItem item) {
    if (item.budget != null && item.budget! > 0) {
      return CRMCurrencyFormatter.format(item.budget!.toDouble());
    }
    if (item.budgetFrom != null || item.budgetTo != null) {
      final f = item.budgetFrom != null ? CRMCurrencyFormatter.format(item.budgetFrom!.toDouble()) : '₹0';
      final t = item.budgetTo != null ? CRMCurrencyFormatter.format(item.budgetTo!.toDouble()) : 'Open';
      return '$f - $t';
    }
    return 'Not Specified';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final innerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFFF59E0B); // Amber / Gold Trophy
    const wonColor = Color(0xFF059669); // Emerald Won

    return _buildResponsiveDialog(
      context: context,
      targetMaxWidth: 880,
      targetMaxHeight: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deal Won — Closed Deals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Business: ${widget.params.businessType} | Range: ${widget.params.dateFilter}',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '$_total Closed Deals',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search customer name, mobile, or sales user...',
                          hintStyle: TextStyle(fontSize: 12, color: subColor),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadDeals();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        onSubmitted: (_) {
                          setState(() => _page = 1);
                          _loadDeals();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _page = 1);
                      _loadDeals();
                    },
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Body: List of Won Deals
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dealsWon.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.emoji_events_outlined, size: 48, color: subColor.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No won deals found matching current filters.',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try adjusting the date range or search query.',
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _dealsWon.length,
                            itemBuilder: (context, index) {
                              final item = _dealsWon[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: innerBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Customer Name, Won badge, Listing Type, Property Type
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: accentColor.withValues(alpha: 0.15),
                                          child: const Icon(Icons.emoji_events_rounded, size: 16, color: accentColor),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            item.customerName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Won status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: wonColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: wonColor.withValues(alpha: 0.3)),
                                          ),
                                          child: const Text(
                                            'Won',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: wonColor,
                                            ),
                                          ),
                                        ),
                                        if (item.listingType != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.listingType!,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
                                            ),
                                          ),
                                        ],
                                        if (item.propertyType != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.propertyType!,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 2: Mobile, Budget, Area, Date (Wrap for zero overflow)
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.phone_rounded, size: 13, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.mobile.isNotEmpty ? item.mobile : 'N/A',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                            ),
                                            if (item.mobile.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: item.mobile));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Phone number copied!'), duration: Duration(seconds: 1)),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(2),
                                                  child: Icon(Icons.copy_rounded, size: 12, color: subColor),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.payments_outlined, size: 13, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Budget: ${_formatBudget(item)}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                            ),
                                          ],
                                        ),
                                        if (item.areaName != null && item.areaName!.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 13, color: subColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.areaName!,
                                                style: TextStyle(fontSize: 12, color: subColor),
                                              ),
                                            ],
                                          ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.event_available_rounded, size: 13, color: subColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDateTime(item.updatedAt ?? item.createdAt),
                                              style: TextStyle(fontSize: 11, color: subColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Row 3: Sales User (Wrap for zero overflow)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF3B82F6)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Closed By: ',
                                                style: TextStyle(fontSize: 12, color: subColor),
                                              ),
                                              Text(
                                                item.salesUserName ?? 'Unassigned',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: item.salesUserName != null ? textColor : subColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item.salesUserPhone != null && item.salesUserPhone!.isNotEmpty)
                                            Text(
                                              '• ${item.salesUserPhone}',
                                              style: TextStyle(fontSize: 11, color: subColor),
                                            ),
                                          if (item.salesUserEmail != null && item.salesUserEmail!.isNotEmpty)
                                            Text(
                                              '• ${item.salesUserEmail}',
                                              style: TextStyle(fontSize: 11, color: subColor),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Row 4: Notes (if any)
                                    if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: wonColor.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: wonColor.withValues(alpha: 0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.rate_review_outlined, size: 14, color: wonColor),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Deal Notes / Activity Log:',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: wonColor),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.notes!,
                                              style: TextStyle(fontSize: 12, color: textColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Row 5: Remarks (if any)
                                    if (item.remarks != null && item.remarks!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.notes_rounded, size: 14, color: subColor),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Client Requirements: ${item.remarks}',
                                                style: TextStyle(fontSize: 12, color: textColor, fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Pagination Bar
              if (_total > 25) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $_page of ${((_total - 1) ~/ 25) + 1} ($_total won deals total)',
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _page > 1
                              ? () {
                                  setState(() => _page--);
                                  _loadDeals();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('Previous', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: (_page * 25) < _total
                              ? () {
                                  setState(() => _page++);
                                  _loadDeals();
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('Next', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
    );
  }
}


