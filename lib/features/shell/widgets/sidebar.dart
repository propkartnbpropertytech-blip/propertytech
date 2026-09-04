import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/widgets/crm_brand_lockup.dart';
import 'user_profile_card.dart';

class ModernSidebar extends StatefulWidget {
  final String currentPath;
  final String userName;
  final String userEmail;
  final String userRole;
  final int leadsBadgeCount;
  final VoidCallback? onItemTapped;
  final bool isCollapsed;

  const ModernSidebar({
    super.key,
    required this.currentPath,
    this.userName = 'User',
    this.userEmail = '',
    this.userRole = '',
    this.leadsBadgeCount = 0,
    this.onItemTapped,
    this.isCollapsed = false,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  late bool _isCampaignExpanded;

  @override
  void initState() {
    super.initState();
    _isCampaignExpanded = widget.currentPath.startsWith('/campaign') ||
        widget.currentPath.startsWith('/integration');
  }

  @override
  void didUpdateWidget(covariant ModernSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath.startsWith('/campaign') ||
        widget.currentPath.startsWith('/integration')) {
      _isCampaignExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final primaryHoverColor = themeManager.primaryHoverColor;
    final currentPath = widget.currentPath;
    final userName = widget.userName;
    final userEmail = widget.userEmail;
    final leadsBadgeCount = widget.leadsBadgeCount;
    final isCollapsed = widget.isCollapsed;

    return Container(
      width: isCollapsed ? 70 : 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header: PropKart Logo ───────────────────────────
            Container(
              height: 74,
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 14 : 20),
              alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: CRMBrandLockup(
                expanded: !isCollapsed,
                compact: false,
                markSize: 38,
                wordmarkColor: isDark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF14213D),
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
            ),

            // ── Navigation Items ───────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: isCollapsed ? 6 : 12,
                ),
                children: [
                  _buildNavItem(
                    context,
                    title: 'Dashboard',
                    icon: Icons.grid_view_rounded,
                    route: '/dashboard',
                    isActive:
                        currentPath.startsWith('/dashboard') ||
                        currentPath == '/',
                  ),
                  _buildNavItem(
                    context,
                    title: 'Properties',
                    icon: Icons.home_work_outlined,
                    route: '/properties',
                    isActive: currentPath.startsWith('/properties'),
                  ),
                  _buildNavItem(
                    context,
                    title: 'Leads',
                    icon: Icons.assignment_outlined,
                    route: '/requirements',
                    isActive: currentPath.startsWith('/requirements'),
                    badgeCount: leadsBadgeCount > 0 ? leadsBadgeCount : null,
                  ),
                  if (widget.userRole.isEmpty ||
                      RoleGuard.canManageEmployees(widget.userRole))
                    _buildNavItem(
                      context,
                      title: 'Employees',
                      icon: Icons.people_outline_rounded,
                      route: '/users',
                      isActive: currentPath.startsWith('/users'),
                    ),
                  if (widget.userRole.isEmpty ||
                      RoleGuard.canAccessCampaign(widget.userRole))
                    _buildCampaignTreeItem(
                      context,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      primaryHoverColor: primaryHoverColor,
                    ),
                  _buildNavItem(
                    context,
                    title: 'Library',
                    icon: Icons.folder_outlined,
                    route: '/library',
                    isActive: currentPath.startsWith('/library'),
                  ),
                  _buildNavItem(
                    context,
                    title: 'Settings',
                    icon: Icons.settings_outlined,
                    route: '/settings',
                    isActive: currentPath.startsWith('/settings'),
                  ),
                  _buildNavItem(
                    context,
                    title: 'Recycle Bin',
                    icon: Icons.delete_outline_rounded,
                    route: '/bin',
                    isActive: currentPath.startsWith('/bin'),
                  ),
                ],
              ),
            ),

            // ── Bottom User Profile ───────────────────────────
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: UserProfileCard(
                name: userName,
                email: userEmail,
                isCollapsed: isCollapsed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required bool isActive,
    int? badgeCount,
    bool hasDropdown = false,
  }) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final primaryHoverColor = themeManager.primaryHoverColor;

    if (widget.isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Tooltip(
          message: title,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                widget.onItemTapped?.call();
                if (GoRouterState.of(context).matchedLocation != route) {
                  context.go(route);
                }
              },
              borderRadius: BorderRadius.circular(10),
              hoverColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark
                          ? primaryColor.withValues(alpha: 0.2)
                          : primaryColor.withValues(alpha: 0.12))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? (isDark
                            ? primaryColor.withValues(alpha: 0.45)
                            : primaryColor.withValues(alpha: 0.35))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isActive
                            ? (isDark ? primaryHoverColor : primaryColor)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF4A5568)),
                      ),
                      if (badgeCount != null && badgeCount > 0)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            widget.onItemTapped?.call();
            if (GoRouterState.of(context).matchedLocation != route) {
              context.go(route);
            }
          },
          borderRadius: BorderRadius.circular(10),
          hoverColor:
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? primaryColor.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? (isDark
                        ? primaryColor.withValues(alpha: 0.45)
                        : primaryColor.withValues(alpha: 0.35))
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? (isDark ? primaryHoverColor : primaryColor)
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF4A5568)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive
                          ? (isDark ? primaryHoverColor : primaryColor)
                          : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF2D3748)),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? primaryHoverColor : primaryColor,
                      shape: BoxShape.circle,
                    ),
                  )
                else if (hasDropdown)
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF718096),
                  )
                else if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignTreeItem(
    BuildContext context, {
    required bool isDark,
    required Color primaryColor,
    required Color primaryHoverColor,
  }) {
    final isChildActive = widget.currentPath.startsWith('/campaign') ||
        widget.currentPath.startsWith('/integration');
    final isConnectionsActive =
        widget.currentPath.startsWith('/campaign/connections');
    final isLeadsActive = widget.currentPath.startsWith('/campaign/leads');

    if (widget.isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Tooltip(
          message: 'Campaign',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                widget.onItemTapped?.call();
                if (!isChildActive) {
                  context.go('/campaign/connections');
                }
              },
              borderRadius: BorderRadius.circular(10),
              hoverColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isChildActive
                      ? (isDark
                          ? primaryColor.withValues(alpha: 0.14)
                          : primaryColor.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isChildActive
                        ? (isDark
                            ? primaryColor.withValues(alpha: 0.35)
                            : primaryColor.withValues(alpha: 0.25))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.campaign_outlined,
                    size: 20,
                    color: isChildActive
                        ? (isDark ? primaryHoverColor : primaryColor)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF4A5568)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Parent item: Campaign
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isCampaignExpanded = !_isCampaignExpanded;
                });
                if (_isCampaignExpanded && !isChildActive) {
                  widget.onItemTapped?.call();
                  context.go('/campaign/connections');
                }
              },
              borderRadius: BorderRadius.circular(10),
              hoverColor:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isChildActive
                      ? (isDark
                          ? primaryColor.withValues(alpha: 0.14)
                          : primaryColor.withValues(alpha: 0.08))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isChildActive
                        ? (isDark
                            ? primaryColor.withValues(alpha: 0.35)
                            : primaryColor.withValues(alpha: 0.25))
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 20,
                      color: isChildActive
                          ? (isDark ? primaryHoverColor : primaryColor)
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF4A5568)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Campaign',
                        style: TextStyle(
                          color: isChildActive
                              ? (isDark ? primaryHoverColor : primaryColor)
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF2D3748)),
                          fontSize: 14,
                          fontWeight:
                              isChildActive ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isCampaignExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isChildActive
                            ? (isDark ? primaryHoverColor : primaryColor)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF718096)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sub-items Tree (Connections & Leads)
          if (_isCampaignExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 18.0, top: 4.0, bottom: 2.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  children: [
                    _buildSubNavItem(
                      context,
                      title: 'Connections',
                      icon: Icons.hub_outlined,
                      route: '/campaign/connections',
                      isActive: isConnectionsActive,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      primaryHoverColor: primaryHoverColor,
                    ),
                    const SizedBox(height: 2),
                    _buildSubNavItem(
                      context,
                      title: 'Leads',
                      icon: Icons.table_chart_outlined,
                      route: '/campaign/leads',
                      isActive: isLeadsActive,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      primaryHoverColor: primaryHoverColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required bool isActive,
    required bool isDark,
    required Color primaryColor,
    required Color primaryHoverColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          widget.onItemTapped?.call();
          if (GoRouterState.of(context).matchedLocation != route) {
            context.go(route);
          }
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F4F9),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                    ? primaryColor.withValues(alpha: 0.20)
                    : primaryColor.withValues(alpha: 0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? (isDark
                      ? primaryColor.withValues(alpha: 0.45)
                      : primaryColor.withValues(alpha: 0.35))
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? (isDark ? primaryHoverColor : primaryColor)
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? (isDark ? primaryHoverColor : primaryColor)
                        : (isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? primaryHoverColor : primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
