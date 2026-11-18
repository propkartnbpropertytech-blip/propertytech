import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/security/permission_matrix_service.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/theme/theme_manager.dart';
import '../../integration/services/integration_service.dart';

enum ReportDomain {
  leads,
  properties;

  String get displayName {
    switch (this) {
      case ReportDomain.leads:
        return 'Leads';
      case ReportDomain.properties:
        return 'Properties';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportDomain.leads:
        return Icons.assignment_outlined;
      case ReportDomain.properties:
        return Icons.home_work_outlined;
    }
  }
}

class ReportsSubshellNav extends StatelessWidget {
  final String currentPath;

  const ReportsSubshellNav({
    super.key,
    required this.currentPath,
  });

  /// Role Drill-down action key controlling the report at [path], or null when always visible.
  static String? actionKeyForPath(String path) {
    if (path.startsWith('/reports/properties')) return 'page.reports.properties';
    if (path.startsWith('/reports/leads/telecaller')) return 'page.reports.telecaller';
    if (path.startsWith('/reports/leads/sales')) return 'page.reports.sales';
    if (path.startsWith('/reports/leads/metrics')) return 'page.reports.lead_metrics';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PermissionMatrixService.instance,
      builder: (context, _) => _buildNav(context),
    );
  }

  Widget _buildNav(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final isProperties = currentPath.startsWith('/reports/properties');
    final activeDomain = isProperties ? ReportDomain.properties : ReportDomain.leads;
    final isAdmin = RoleGuard.isAdmin(RoleGuard.currentUser?.role);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Domain Switcher (Leads / Properties)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
            child: Row(
              children: [
                _buildDomainPill(
                  context,
                  domain: ReportDomain.leads,
                  isSelected: activeDomain == ReportDomain.leads,
                  onTap: () {
                    if (activeDomain != ReportDomain.leads) {
                      context.go('/reports/leads/overall-business-insight');
                    }
                  },
                ),
                if (RoleGuard.canAction('page.reports.properties')) ...[
                const SizedBox(width: 8),
                _buildDomainPill(
                  context,
                  domain: ReportDomain.properties,
                  isSelected: activeDomain == ReportDomain.properties,
                  onTap: () {
                    if (activeDomain != ReportDomain.properties) {
                      context.go('/reports/properties');
                    }
                  },
                ),
                ],
              ],
            ),
          ),

          // Secondary Sub-tabs for the Active Domain
          if (activeDomain == ReportDomain.leads)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
              child: Row(
                children: [
                  _buildSubTab(
                    context,
                    title: 'Overall Business Insight',
                    icon: Icons.insights_rounded,
                    route: '/reports/leads/overall-business-insight',
                    isActive: currentPath.contains('/overall-business-insight'),
                    isFunctional: true,
                  ),
                  if (RoleGuard.canAction('page.reports.telecaller') &&
                      IntegrationService().lastTargetRole != 'Sales')
                  _buildSubTab(
                    context,
                    title: 'Telecaller Report',
                    icon: Icons.headset_mic_outlined,
                    route: '/reports/leads/telecaller',
                    isActive: currentPath.contains('/telecaller'),
                    isFunctional: true,
                  ),
                  if (RoleGuard.canAction('page.reports.sales'))
                  _buildSubTab(
                    context,
                    title: 'Sales Report',
                    icon: Icons.person_outline_rounded,
                    route: '/reports/leads/sales',
                    isActive: currentPath.contains('/sales'),
                    isFunctional: true,
                  ),
                  if (isAdmin && RoleGuard.canAction('page.reports.lead_metrics'))
                    _buildSubTab(
                      context,
                      title: 'Lead Metrics',
                      icon: Icons.tune_rounded,
                      route: '/reports/leads/metrics',
                      isActive: currentPath.contains('/metrics'),
                      isFunctional: true,
                    ),
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
              child: Row(
                children: [
                  _buildSubTab(
                    context,
                    title: 'Property Reports',
                    icon: Icons.home_work_outlined,
                    route: '/reports/properties',
                    isActive: true,
                    isFunctional: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDomainPill(
    BuildContext context, {
    required ReportDomain domain,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              domain.icon,
              size: 16,
              color: isSelected ? primaryColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              domain.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTab(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required bool isActive,
    required bool isFunctional,
    String? badgeText,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primaryColor : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? primaryColor
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? (isDark ? Colors.white : const Color(0xFF14213D))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
