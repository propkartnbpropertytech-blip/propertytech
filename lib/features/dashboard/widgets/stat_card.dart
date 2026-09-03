import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isCompact;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool compact = widget.isCompact || screenWidth < 500;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 18,
            vertical: compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.accentColor.withValues(alpha: 0.5)
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE8ECF2)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: isDark ? 0.15 : 0.08)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: _isHovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Colored left vertical accent bar
              Positioned(
                left: 0,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 3.5,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Content inside card
              Padding(
                padding: EdgeInsets.only(left: compact ? 8 : 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title and Main Value
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF68738A),
                              fontSize: compact ? 11.5 : 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: compact ? 3 : 6),
                          Text(
                            widget.value,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF14213D),
                              fontSize: compact ? 22 : 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.8,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Circular tinted icon background
                    Container(
                      width: compact ? 36 : 46,
                      height: compact ? 36 : 46,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: compact ? 18 : 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
