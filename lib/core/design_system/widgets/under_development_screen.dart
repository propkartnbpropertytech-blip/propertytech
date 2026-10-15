import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme_manager.dart';
import '../tokens/app_colors.dart';

/// An attractive, modern, and responsive screen displayed when a page or module
/// has been marked as Under Development by the Super Admin.
class UnderDevelopmentScreen extends StatefulWidget {
  final String pageTitle;
  final String? route;
  final String? customMessage;
  final String? userRole;
  final bool isEmbedded;

  const UnderDevelopmentScreen({
    super.key,
    required this.pageTitle,
    this.route,
    this.customMessage,
    this.userRole,
    this.isEmbedded = false,
  });

  @override
  State<UnderDevelopmentScreen> createState() => _UnderDevelopmentScreenState();
}

class _UnderDevelopmentScreenState extends State<UnderDevelopmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = CRMColors.primary;
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 768;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final displayTitle = widget.pageTitle.isNotEmpty ? widget.pageTitle : 'This Page';
    final roleName = widget.userRole != null && widget.userRole!.isNotEmpty
        ? widget.userRole!
        : 'Team Member';

    Widget content = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : (widget.isEmbedded ? 20 : 32),
          vertical: widget.isEmbedded ? 20 : 40,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Animated Visual Hero ──────────────────────────────
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final glow = _pulseAnimation.value;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Outer Glow
                      Container(
                        width: isMobile ? 120 : 140,
                        height: isMobile ? 120 : 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15 + (0.15 * glow)),
                              blurRadius: 36 + (16 * glow),
                              spreadRadius: 4 + (8 * glow),
                            ),
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.10 + (0.10 * glow)),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Core Icon Squircle
                      Container(
                        width: isMobile ? 96 : 110,
                        height: isMobile ? 96 : 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFFFFBEB),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.45 + (0.35 * glow)),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.construction_rounded,
                            size: isMobile ? 44 : 52,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Status Pill ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF59E0B),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.8 * _pulseAnimation.value),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'UNDER ACTIVE DEVELOPMENT',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Main Heading ─────────────────────────────────────
              Text(
                '$displayTitle Is Under Development',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),

              // ── Explanatory Subtitle ──────────────────────────────
              Text(
                widget.customMessage != null && widget.customMessage!.trim().isNotEmpty
                    ? widget.customMessage!
                    : 'We are currently enhancing and upgrading the $displayTitle module to bring you a faster, more reliable experience. Access is temporarily paused while changes are being made.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: isMobile ? 13.5 : 15,
                  height: 1.55,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 28),

              // ── Feature Info Card ────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      label: 'Module Name',
                      value: displayTitle,
                      icon: Icons.layers_outlined,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    Divider(height: 20, color: borderColor),
                    _buildInfoRow(
                      context,
                      label: 'Target Role',
                      value: roleName,
                      icon: Icons.badge_outlined,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    Divider(height: 20, color: borderColor),
                    _buildInfoRow(
                      context,
                      label: 'Current Status',
                      value: 'In Progress / Maintenance',
                      valueColor: const Color(0xFFD97706),
                      icon: Icons.timelapse_rounded,
                      isDark: isDark,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Action Buttons ───────────────────────────────────
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.dashboard_outlined, size: 18),
                    label: const Text('Go to Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  if (widget.route != '/support')
                    TextButton.icon(
                      onPressed: () => context.go('/support'),
                      icon: const Icon(Icons.help_outline_rounded, size: 18),
                      label: const Text('Need Support?'),
                      style: TextButton.styleFrom(
                        foregroundColor: textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbedded) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(child: content),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
