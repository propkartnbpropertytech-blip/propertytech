import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/tokens/app_spacing.dart';

class CampaignSubshellHeader extends StatelessWidget {
  final String activeTab; // 'connections' or 'leads'
  final Widget? trailing;

  const CampaignSubshellHeader({
    super.key,
    required this.activeTab,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Trailing actions
          if (isMobile) ...[
            Text(
              'Campaign',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Marketing automation, webhook integrations & lead pipelines',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: 12),
              trailing!,
            ],
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campaign',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Marketing automation, webhook integrations & lead pipelines',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                ?trailing,
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Subshell Tab Switcher: Connections & Leads
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(
                  context,
                  title: 'Connections',
                  icon: Icons.hub_rounded,
                  isActive: activeTab == 'connections',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onTap: () {
                    if (activeTab != 'connections') {
                      context.go('/campaign/connections');
                    }
                  },
                ),
                const SizedBox(width: 4),
                _buildTabButton(
                  context,
                  title: 'Leads',
                  icon: Icons.table_chart_rounded,
                  isActive: activeTab == 'leads',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onTap: () {
                    if (activeTab != 'leads') {
                      context.go('/campaign/leads');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
            border: isActive
                ? Border.all(
                    color: primaryColor.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isActive
                    ? primaryColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? primaryColor
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
