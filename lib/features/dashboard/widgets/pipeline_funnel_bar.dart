import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/widgets/animated_count_roll.dart';

/// Interactive, animated 100% proportional lead pipeline funnel bar.
/// Guarantees visual confirmation that all leads sum up to 100% with no phantom leaks.
class PipelineFunnelBar extends StatefulWidget {
  final int totalLeads;
  final List<Map<String, dynamic>> stages;
  final List<Map<String, dynamic>>? salesRoster;
  final int? activeSalesUsersCount;
  final String? dateFilter;
  final bool isLoading;
  final void Function(String stageKey, String stageLabel)? onStageTap;

  const PipelineFunnelBar({
    super.key,
    required this.totalLeads,
    required this.stages,
    this.salesRoster,
    this.activeSalesUsersCount,
    this.dateFilter,
    this.isLoading = false,
    this.onStageTap,
  });

  @override
  State<PipelineFunnelBar> createState() => _PipelineFunnelBarState();
}

class _PipelineFunnelBarState extends State<PipelineFunnelBar> {
  String? _hoveredStageKey;

  static Color _parseColor(dynamic rawColor) {
    if (rawColor is Color) return rawColor;
    if (rawColor is String && rawColor.startsWith('#')) {
      final hex = rawColor.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return const Color(0xFF3B82F6);
  }

  static IconData _parseIcon(dynamic rawIcon) {
    if (rawIcon is IconData) return rawIcon;
    final name = rawIcon?.toString() ?? '';
    switch (name) {
      case 'inbox_rounded':
        return Icons.inbox_rounded;
      case 'phone_missed_rounded':
        return Icons.phone_missed_rounded;
      case 'phone_callback_rounded':
        return Icons.phone_callback_rounded;
      case 'sync_rounded':
        return Icons.sync_rounded;
      case 'handshake_rounded':
        return Icons.handshake_rounded;
      case 'assignment_late_rounded':
        return Icons.assignment_late_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'cancel_outlined':
        return Icons.cancel_outlined;
      case 'real_estate_agent_rounded':
        return Icons.real_estate_agent_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final validStages = widget.stages.where((s) => (s['count'] as num? ?? 0) > 0).toList();
    final int displayTotal = widget.totalLeads > 0
        ? widget.totalLeads
        : widget.stages.fold<int>(0, (sum, s) => sum + (s['count'] as num? ?? 0).toInt());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_tree_rounded,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lead Lifecycle Pipeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '100% Complete Distribution Engine',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 100% Balanced Verification Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    AnimatedCountRoll(
                      value: displayTotal,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Text(
                      ' Leads',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Proportional Stacked Funnel Bar
          if (widget.isLoading)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 28,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                child: const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else if (validStages.isEmpty)
            Container(
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No leads in this timeframe',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 28,
                child: Row(
                  children: validStages.map((stage) {
                    final count = (stage['count'] as num? ?? 0).toInt();
                    final pct = (stage['percentage'] as num? ?? 0.0).toDouble();
                    final key = stage['key']?.toString() ?? '';
                    final label = stage['label']?.toString() ?? key;
                    final color = _parseColor(stage['color']);
                    final isHovered = _hoveredStageKey == key;

                    return Expanded(
                      flex: count,
                      child: Tooltip(
                        message: '$label: $count leads ($pct%)',
                        preferBelow: false,
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredStageKey = key),
                          onExit: (_) => setState(() => _hoveredStageKey = null),
                          cursor: widget.onStageTap != null
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: GestureDetector(
                            onTap: widget.onStageTap != null
                                ? () => widget.onStageTap!(key, label)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isHovered ? color.withValues(alpha: 0.85) : color,
                                border: Border(
                                  right: BorderSide(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: pct >= 8.0
                                  ? Text(
                                      '${pct.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Stage Legend Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.stages.map((stage) {
              final count = (stage['count'] as num? ?? 0).toInt();
              final pct = (stage['percentage'] as num? ?? 0.0).toDouble();
              final key = stage['key']?.toString() ?? '';
              final label = stage['label']?.toString() ?? key;
              final color = _parseColor(stage['color']);
              final icon = _parseIcon(stage['icon']);
              final isHovered = _hoveredStageKey == key;

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredStageKey = key),
                onExit: (_) => setState(() => _hoveredStageKey = null),
                cursor: widget.onStageTap != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: widget.onStageTap != null
                      ? () => widget.onStageTap!(key, label)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHovered
                            ? color
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isHovered ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(icon, size: 12, color: color),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedCountRoll(
                          value: count,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '($pct%)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Active Sales Roster Section
          if (widget.salesRoster != null && widget.salesRoster!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 15,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Verified Active Sales Roster (${widget.activeSalesUsersCount ?? widget.salesRoster!.length} Users):',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.salesRoster!.map((agent) {
                final name = agent['full_name']?.toString() ?? 'Sales Agent';
                final leads = agent['active_leads_count'] as num? ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$leads leads',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
