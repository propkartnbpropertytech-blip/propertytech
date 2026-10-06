import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../services/dashboard_service.dart';

class GenericKpiDrilldownDialog extends StatefulWidget {
  final String kpiKey;
  final String kpiLabel;
  final List<String> breadcrumbs;
  final Map<String, dynamic>? initialFilters;

  const GenericKpiDrilldownDialog({
    super.key,
    required this.kpiKey,
    required this.kpiLabel,
    this.breadcrumbs = const [],
    this.initialFilters,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String kpiKey,
    required String kpiLabel,
    List<String> breadcrumbs = const [],
    Map<String, dynamic>? initialFilters,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => GenericKpiDrilldownDialog(
        kpiKey: kpiKey,
        kpiLabel: kpiLabel,
        breadcrumbs: breadcrumbs,
        initialFilters: initialFilters,
      ),
    );
  }

  @override
  State<GenericKpiDrilldownDialog> createState() => _GenericKpiDrilldownDialogState();
}

class _GenericKpiDrilldownDialogState extends State<GenericKpiDrilldownDialog> {
  final DashboardService _service = DashboardService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _drilldownData = {};

  late Map<String, dynamic> _filters;
  String? _selectedStatusFilter;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters ?? {});
    _filters['dateFilter'] = _filters['dateFilter'] ?? 'Weekly';
    _loadDrilldown();
  }

  Future<void> _loadDrilldown() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final queryParams = Map<String, dynamic>.from(_filters);
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
        queryParams['status'] = _selectedStatusFilter;
      }
      queryParams['page'] = _currentPage.toString();
      queryParams['limit'] = '20';

      final res = await _service.getKpiDrilldownData(widget.kpiKey, filters: queryParams);
      if (mounted) {
        setState(() {
          _drilldownData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final drilldownConfig = _drilldownData['drilldown_config'] is Map
        ? Map<String, dynamic>.from(_drilldownData['drilldown_config'])
        : <String, dynamic>{};
    final components = (drilldownConfig['components'] as List?) ?? [];
    final componentsData = _drilldownData['components_data'] is Map
        ? Map<String, dynamic>.from(_drilldownData['components_data'])
        : <String, dynamic>{};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Breadcrumbs
              _buildHeader(textColor, subColor),
              const SizedBox(height: 12),

              // Filter Bar
              _buildFilterBar(cardBg, borderColor, subColor),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Body Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
                                const SizedBox(height: 10),
                                Text(_errorMessage, style: TextStyle(color: textColor)),
                                const SizedBox(height: 10),
                                ElevatedButton(onPressed: _loadDrilldown, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (components.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Center(
                                      child: Text(
                                        'No drilldown components configured for this KPI yet.',
                                        style: TextStyle(color: subColor, fontSize: 14),
                                      ),
                                    ),
                                  )
                                else
                                  ...components.map((comp) {
                                    final compMap = comp is Map ? Map<String, dynamic>.from(comp) : <String, dynamic>{};
                                    final compId = compMap['id']?.toString() ?? '';
                                    final compType = compMap['type']?.toString() ?? '';
                                    final compData = componentsData[compId];

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: _renderComponent(
                                        compMap,
                                        compType,
                                        compData,
                                        cardBg,
                                        textColor,
                                        subColor,
                                        borderColor,
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subColor) {
    final trail = [...widget.breadcrumbs, widget.kpiLabel];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ThemeManager().primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.analytics_rounded, color: ThemeManager().primaryColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs trail
              Row(
                children: List.generate(trail.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right_rounded, size: 14, color: subColor),
                    );
                  }
                  final itemIndex = index ~/ 2;
                  final isLast = itemIndex == trail.length - 1;
                  return Text(
                    trail[itemIndex],
                    style: TextStyle(
                      fontSize: isLast ? 16 : 13,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                      color: isLast ? textColor : subColor,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                'Interactive drilldown analysis with automatic context inheritance.',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Color cardBg, Color borderColor, Color subColor) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Date Filter
              DropdownButton<String>(
                value: _filters['dateFilter']?.toString() ?? 'Weekly',
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'Today', child: Text('Today')),
                  DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _filters['dateFilter'] = val;
                      _currentPage = 1;
                    });
                    _loadDrilldown();
                  }
                },
              ),

              // Status Filter reset if selected
              if (_selectedStatusFilter != null) ...[
                InputChip(
                  label: Text('Status: $_selectedStatusFilter'),
                  onDeleted: () {
                    setState(() {
                      _selectedStatusFilter = null;
                      _currentPage = 1;
                    });
                    _loadDrilldown();
                  },
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh Data',
          onPressed: _loadDrilldown,
        ),
      ],
    );
  }

  Widget _renderComponent(
    Map<String, dynamic> comp,
    String compType,
    dynamic compData,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final title = comp['title']?.toString() ?? 'Component';

    switch (compType) {
      case 'kpi_group':
        return _buildKpiGroupComponent(title, compData, textColor, subColor, borderColor);
      case 'chart':
        return _buildChartComponent(title, comp, compData, textColor, subColor, borderColor);
      case 'status_breakdown':
        return _buildStatusBreakdownComponent(title, compData, textColor, subColor, borderColor);
      case 'table':
        return _buildTableComponent(title, comp, compData, textColor, subColor, borderColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Sub-KPI Metric Cards
  Widget _buildKpiGroupComponent(
    String title,
    dynamic data,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final items = data is List ? data : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: items.map((item) {
            final itemMap = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
            final label = itemMap['label']?.toString() ?? 'Metric';
            final count = itemMap['count']?.toString() ?? '0';
            final isClickable = itemMap['is_clickable'] == true;
            final itemStatus = itemMap['status']?.toString();
            final itemKpiKey = itemMap['kpi_key']?.toString();

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: !isClickable
                  ? null
                  : () {
                      if (itemKpiKey != null && itemKpiKey.isNotEmpty) {
                        // Level 2 / Level 3 Nested Drilldown
                        GenericKpiDrilldownDialog.show(
                          context,
                          kpiKey: itemKpiKey,
                          kpiLabel: label,
                          breadcrumbs: [...widget.breadcrumbs, widget.kpiLabel],
                          initialFilters: _filters,
                        );
                      } else if (itemStatus != null) {
                        setState(() {
                          _selectedStatusFilter = itemStatus;
                          _currentPage = 1;
                        });
                        _loadDrilldown();
                      }
                    },
              child: Container(
                width: 180,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          count,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        if (isClickable)
                          Icon(Icons.arrow_forward_rounded, size: 16, color: ThemeManager().primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 2. Analytics Chart (Bar / Donut / Line)
  Widget _buildChartComponent(
    String title,
    Map<String, dynamic> comp,
    dynamic data,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final items = data is List ? data : [];
    int maxCount = 1;
    for (final it in items) {
      if (it is Map) {
        final c = int.tryParse(it['count']?.toString() ?? '0') ?? 0;
        if (c > maxCount) maxCount = c;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: ThemeManager().primaryColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text('No chart data available for the selected period.', style: TextStyle(color: subColor, fontSize: 12))
          else
            Column(
              children: items.map((item) {
                final itemMap = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                final label = itemMap['label']?.toString() ?? '';
                final count = int.tryParse(itemMap['count']?.toString() ?? '0') ?? 0;
                final ratio = (count / maxCount).clamp(0.02, 1.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          label,
                          style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: ThemeManager().primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 45,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // 3. Status Breakdown
  Widget _buildStatusBreakdownComponent(
    String title,
    dynamic data,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final items = data is List ? data : [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: ThemeManager().primaryColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final itemMap = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
              final label = itemMap['label']?.toString() ?? '';
              final count = itemMap['count']?.toString() ?? '0';
              final isSelected = _selectedStatusFilter == label;

              return FilterChip(
                label: Text('$label ($count)'),
                selected: isSelected,
                selectedColor: ThemeManager().primaryColor.withValues(alpha: 0.15),
                checkmarkColor: ThemeManager().primaryColor,
                onSelected: (val) {
                  setState(() {
                    _selectedStatusFilter = val ? label : null;
                    _currentPage = 1;
                  });
                  _loadDrilldown();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 4. Paginated Table Records
  Widget _buildTableComponent(
    String title,
    Map<String, dynamic> comp,
    dynamic data,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final tableData = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    final records = (tableData['records'] as List?) ?? [];
    final total = int.tryParse(tableData['total']?.toString() ?? '0') ?? 0;
    final columns = (tableData['columns'] as List?)?.map((c) => c.toString()).toList() ??
        ['Record ID', 'Created At'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.table_rows_rounded, size: 18, color: ThemeManager().primaryColor),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$total records', style: TextStyle(fontSize: 11, color: subColor)),
                  ),
                ],
              ),
              // Pagination
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage -= 1);
                            _loadDrilldown();
                          }
                        : null,
                  ),
                  Text('Page $_currentPage', style: TextStyle(fontSize: 12, color: subColor)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    onPressed: records.length >= 20
                        ? () {
                            setState(() => _currentPage += 1);
                            _loadDrilldown();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('No records match the current filters.', style: TextStyle(color: subColor, fontSize: 13)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                columns: columns.map((col) {
                  return DataColumn(label: Text(col, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
                }).toList(),
                rows: records.map((rec) {
                  final recMap = rec is Map ? Map<String, dynamic>.from(rec) : <String, dynamic>{};
                  return DataRow(
                    cells: columns.map((col) {
                      final val = _resolveColumnValue(recMap, col);
                      return DataCell(
                        Text(
                          val,
                          style: TextStyle(fontSize: 12, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _resolveColumnValue(Map<String, dynamic> rec, String col) {
    final lowerCol = col.toLowerCase().replaceAll(' ', '_');
    if (rec.containsKey(lowerCol)) return rec[lowerCol]?.toString() ?? '-';
    if (rec.containsKey('title') && lowerCol.contains('property')) return rec['title']?.toString() ?? '-';
    if (rec.containsKey('name') && lowerCol.contains('customer')) return rec['name']?.toString() ?? '-';
    if (rec.containsKey('phone') && lowerCol.contains('phone')) return rec['phone']?.toString() ?? '-';
    if (rec.containsKey('price') && lowerCol.contains('price')) return '₹${rec['price']}';
    if (rec.containsKey('status')) return rec['status']?.toString() ?? '-';
    if (rec.containsKey('created_at')) return rec['created_at']?.toString().split('T').first ?? '-';
    return rec.values.isNotEmpty ? rec.values.first?.toString() ?? '-' : '-';
  }
}
