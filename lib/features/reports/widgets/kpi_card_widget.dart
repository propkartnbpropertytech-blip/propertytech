import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_configuration.dart';
import '../models/report_data.dart';

class KpiCardWidget extends StatefulWidget {
  final ReportKpiConfig config;
  final KpiValue? value;
  final Function(bool showCount, bool showPercentage)? onTogglesChanged;
  final bool showToggles;
  final VoidCallback onExpand;

  const KpiCardWidget({
    super.key,
    required this.config,
    required this.value,
    this.onTogglesChanged,
    this.showToggles = false,
    required this.onExpand,
  });

  @override
  State<KpiCardWidget> createState() => _KpiCardWidgetState();
}

class _KpiCardWidgetState extends State<KpiCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final kpiType = widget.config.type;
    final accentColor = kpiType.defaultColor;
    final count = widget.value?.formattedCount ?? '0';
    final percentage = widget.value?.formattedPercentage ?? '0.0%';
    final denominatorLabel = widget.value?.denominatorLabel ?? kpiType.denominatorExplanation;

    final showCount = widget.config.showCount;
    final showPercentage = widget.config.showPercentage;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? accentColor.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? accentColor.withValues(alpha: isDark ? 0.2 : 0.08)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left vertical accent bar
            Positioned(
              left: 0,
              top: 2,
              bottom: 2,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Row 1: Title, Icon, and Expand Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          kpiType.displayName,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Expand action button
                          IconButton(
                            icon: const Icon(Icons.open_in_full_rounded, size: 14),
                            onPressed: widget.onExpand,
                            tooltip: 'Expand ${kpiType.displayName} Details',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          // Icon container
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              kpiType.icon,
                              color: accentColor,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Row 2: Metric Values Display
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (showCount) ...[
                          Text(
                            count,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.6,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                        if (showCount && showPercentage) const SizedBox(width: 8),
                        if (showPercentage) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              percentage,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: showCount ? 14 : 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Row 3: Denominator basis (Static on executive dashboard)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Denominator Basis subtitle
                      Expanded(
                        child: Text(
                          denominatorLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Count & Percentage Toggle Pills (Hidden by default; configured in Lead Metrics)
                      if (widget.showToggles && widget.onTogglesChanged != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleChip(
                              label: '#',
                              tooltip: 'Toggle Count',
                              isActive: showCount,
                              onTap: () {
                                if (showCount && !showPercentage) return;
                                widget.onTogglesChanged!(!showCount, showPercentage);
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildToggleChip(
                              label: '%',
                              tooltip: 'Toggle Percentage',
                              isActive: showPercentage,
                              onTap: () {
                                if (showPercentage && !showCount) return;
                                widget.onTogglesChanged!(showCount, !showPercentage);
                              },
                            ),
                          ],
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
  }

  Widget _buildToggleChip({
    required String label,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withValues(alpha: isDark ? 0.3 : 0.15)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? primaryColor
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
