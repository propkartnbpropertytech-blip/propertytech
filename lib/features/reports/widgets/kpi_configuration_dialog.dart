import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_configuration.dart';

class KpiConfigurationDialog extends StatefulWidget {
  final List<ReportKpiConfig> initialConfigs;
  final ValueChanged<List<ReportKpiConfig>> onSave;

  const KpiConfigurationDialog({
    super.key,
    required this.initialConfigs,
    required this.onSave,
  });

  @override
  State<KpiConfigurationDialog> createState() => _KpiConfigurationDialogState();
}

class _KpiConfigurationDialogState extends State<KpiConfigurationDialog> {
  late List<ReportKpiConfig> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialConfigs);
    _items.sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Description
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Configure Metrics & KPIs',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Drag items to reorder KPI cards on the dashboard. Check or uncheck to show or hide cards.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),

            // Reorderable List
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                    for (int i = 0; i < _items.length; i++) {
                      _items[i] = _items[i].copyWith(order: i);
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final kpi = _items[index];
                  return Container(
                    key: ValueKey(kpi.type.name),
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Drag Handle
                        const Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),

                        // Checkbox
                        Checkbox(
                          value: kpi.isEnabled,
                          activeColor: primaryColor,
                          onChanged: (val) {
                            setState(() {
                              _items[index] = kpi.copyWith(isEnabled: val ?? true);
                            });
                          },
                        ),
                        const SizedBox(width: 4),

                        // Icon & Title
                        Icon(
                          kpi.type.icon,
                          size: 16,
                          color: kpi.type.defaultColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            kpi.type.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kpi.isEnabled
                                  ? (isDark ? Colors.white : const Color(0xFF14213D))
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                          ),
                        ),

                        // Default metric indicators
                        Text(
                          kpi.type.denominatorExplanation,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // Reset to initial pool
                    setState(() {
                      _items = ReportConfiguration.initial().kpiConfigs;
                    });
                  },
                  child: const Text('Reset Defaults', style: TextStyle(fontSize: 12)),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onSave(_items);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text('Save Order & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
