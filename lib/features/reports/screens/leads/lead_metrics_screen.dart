import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../models/report_configuration.dart';
import '../../repository/reports_repository.dart';

class LeadMetricsScreen extends StatefulWidget {
  const LeadMetricsScreen({super.key});

  @override
  State<LeadMetricsScreen> createState() => _LeadMetricsScreenState();
}

class _LeadMetricsScreenState extends State<LeadMetricsScreen> {
  final ReportsRepository _reportsRepository = ReportsRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  late List<ReportKpiConfig> _kpiConfigs;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final config = await _reportsRepository.loadConfiguration();
    final items = List<ReportKpiConfig>.from(config.kpiConfigs);
    items.sort((a, b) => a.order.compareTo(b.order));

    if (mounted) {
      setState(() {
        _kpiConfigs = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    // Persist reordered and updated KPI configs
    await _reportsRepository.saveKpiConfiguration(_kpiConfigs);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Lead metrics & KPI settings saved successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetToDefaults() {
    final defaultConfig = ReportConfiguration.initial();
    final defaultKpis = List<ReportKpiConfig>.from(defaultConfig.kpiConfigs);
    defaultKpis.sort((a, b) => a.order.compareTo(b.order));

    setState(() {
      _kpiConfigs = defaultKpis;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration reset to system defaults. Click Save to persist.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Loading metrics configuration...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final activeCount = _kpiConfigs.where((k) => k.isEnabled).length;
    final totalCount = _kpiConfigs.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CRMBreakpoints.pagePadding(context),
        vertical: CRMSpacing.m,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: CRMBreakpoints.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header & Actions Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Lead Metrics & Configuration',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure Key Performance Indicators, arrange dashboard layout order, and manage default metric views for executive insights.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset Defaults'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/reports/leads/overall-business-insight'),
                        icon: const Icon(Icons.insights_rounded, size: 16),
                        label: const Text('View Dashboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveConfig,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 16),
                        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),

              // Overview Status Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth > 700 ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSummaryCard(
                        title: 'Active KPI Cards',
                        value: '$activeCount / $totalCount',
                        subtitle: 'Displayed on Business Insight page',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF16A34A),
                        width: cardWidth,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                      _buildSummaryCard(
                        title: 'Hidden KPIs',
                        value: '${totalCount - activeCount}',
                        subtitle: 'Inactive or excluded cards',
                        icon: Icons.visibility_off_outlined,
                        color: const Color(0xFFEAB308),
                        width: cardWidth,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                      _buildSummaryCard(
                        title: 'Drag & Drop Layout',
                        value: 'Enabled',
                        subtitle: 'Reorder cards to set display priority',
                        icon: Icons.swap_vert_rounded,
                        color: const Color(0xFF0284C7),
                        width: cardWidth,
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        borderColor: borderColor,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: CRMSpacing.l),

              // Section: KPI Order and Metric Toggles
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.format_list_numbered_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Key Performance Indicators (KPIs)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$activeCount of $totalCount Active',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Drag any item using the handle on the left to change its position on the dashboard. Use the switches and pills to configure visibility and default Count / % presentation.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Reorderable ListView
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _kpiConfigs.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _kpiConfigs.removeAt(oldIndex);
                          _kpiConfigs.insert(newIndex, item);
                          for (int i = 0; i < _kpiConfigs.length; i++) {
                            _kpiConfigs[i] = _kpiConfigs[i].copyWith(order: i);
                          }
                        });
                      },
                      itemBuilder: (context, index) {
                        final kpi = _kpiConfigs[index];
                        final isEnabled = kpi.isEnabled;

                        return Container(
                          key: ValueKey(kpi.type.name),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (isEnabled ? const Color(0xFF0F172A) : const Color(0xFF0F172A).withValues(alpha: 0.5))
                                : (isEnabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isEnabled
                                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Drag Handle
                              ReorderableDragStartListener(
                                index: index,
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                              // Position badge
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // KPI Icon
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: kpi.type.defaultColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  kpi.type.icon,
                                  size: 18,
                                  color: kpi.type.defaultColor,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // KPI Title & Denominator Formula
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kpi.type.displayName,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isEnabled
                                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                            : (isDark ? Colors.white38 : Colors.black38),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      kpi.type.denominatorExplanation,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Metric quick toggles (Count ON/OFF, % ON/OFF)
                              if (isEnabled) ...[
                                _buildMetricTogglePill(
                                  label: 'Count',
                                  isActive: kpi.showCount,
                                  canToggleOff: kpi.showPercentage,
                                  onTap: () {
                                    setState(() {
                                      _kpiConfigs[index] = kpi.copyWith(showCount: !kpi.showCount);
                                    });
                                  },
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                ),
                                const SizedBox(width: 6),
                                _buildMetricTogglePill(
                                  label: '%',
                                  isActive: kpi.showPercentage,
                                  canToggleOff: kpi.showCount,
                                  onTap: () {
                                    setState(() {
                                      _kpiConfigs[index] = kpi.copyWith(showPercentage: !kpi.showPercentage);
                                    });
                                  },
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                ),
                                const SizedBox(width: 16),
                              ],

                              // Enable / Disable Switch
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: isEnabled,
                                  activeThumbColor: primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      _kpiConfigs[index] = kpi.copyWith(isEnabled: val);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CRMSpacing.l),

              // Bottom Save Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Changes will be applied to the Overall Business Insight dashboard upon saving.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveConfig,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 16),
                      label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CRMSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTogglePill({
    required String label,
    required bool isActive,
    required bool canToggleOff,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: canToggleOff || !isActive ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive
                ? primaryColor
                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }
}
