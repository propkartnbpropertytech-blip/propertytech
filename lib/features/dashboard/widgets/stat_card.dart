import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isCompact;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
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
    final bool compact = widget.isCompact || screenWidth < 600;

    return Semantics(
      button: widget.onTap != null,
      label: '${widget.title}: ${widget.value}',
      child: MouseRegion(
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
            horizontal: compact ? 10 : 14,
            vertical: compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                blurRadius: _isHovered ? 8 : 4,
                offset: const Offset(0, 1.5),
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
                  width: 3.0,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Content inside card
              Padding(
                padding: EdgeInsets.only(left: compact ? 8 : 10),
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
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.value,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF14213D),
                              fontSize: compact ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.6,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),


                    const SizedBox(width: 6),

                    // Circular tinted icon background
                    Container(
                      width: compact ? 32 : 38,
                      height: compact ? 32 : 38,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: compact ? 16 : 19,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
