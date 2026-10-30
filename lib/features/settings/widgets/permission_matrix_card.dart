import 'page_control_settings_card.dart';
import '../../../core/navigation/app_nav_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/security/permission_matrix_service.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

/// Comprehensive interactive Permission Metrics Control Center for Super Admin.
/// Allows viewing and dynamically managing permissions for Admin, Telecaller, and Sales,
/// while keeping Super Admin permanently safeguarded at 100%.
class PermissionMatrixCard extends StatefulWidget {
  const PermissionMatrixCard({super.key});

  @override
  State<PermissionMatrixCard> createState() => _PermissionMatrixCardState();
}

class _PermissionMatrixCardState extends State<PermissionMatrixCard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _activeViewTab = 0; // 0: Matrix Grid, 1: Role Drill-down, 2: App Shell Simulator
  String _selectedRoleForDrilldown = 'Admin';
  bool _isDashboardExpanded = false;
  String _simulatorRole = 'Sales';

  late TabController _tabController;

  final List<String> _targetRoles = const ['Admin', 'Telecaller', 'Sales'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) {
        setState(() {
          _activeViewTab = _tabController.index;
        });
      }
    });
    PermissionMatrixService.instance.addListener(_onServiceChanged);
    PermissionMatrixService.instance.syncFromBackend();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    PermissionMatrixService.instance.removeListener(_onServiceChanged);
    super.dispose();
  }

  List<PermissionItem> get _filteredPermissions {
    return PermissionMatrixService.allPermissions.where((item) {
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        final matchKey = item.key.toLowerCase().contains(q);
        final matchCat = item.category.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc && !matchKey && !matchCat) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primary = ThemeManager().primaryColor;
    final service = PermissionMatrixService.instance;
    final totalPerms = PermissionMatrixService.allPermissions.length;

    final superAdminCount = totalPerms;
    final adminCount = service.getActiveCount('Admin');
    final telecallerCount = service.getActiveCount('Telecaller');
    final salesCount = service.getActiveCount('Sales');

    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Master Super Admin Gold Badge Banner ───────────
        _buildMasterHeader(context, isDark, primary),

        const SizedBox(height: CRMSpacing.m),

        // ── 2. Metric Counters Summary Strip ─────────────────
        _buildMetricsOverview(
          context,
          isDark: isDark,
          total: totalPerms,
          superAdminCount: superAdminCount,
          adminCount: adminCount,
          telecallerCount: telecallerCount,
          salesCount: salesCount,
          isMobile: isMobile,
        ),

        const SizedBox(height: CRMSpacing.m),

        // ── 3. Controls & Filter Bar ──────────────────────────
        _buildControlsBar(context, isDark, primary, isMobile),

        const SizedBox(height: CRMSpacing.m),

        // ── 4. Main Body Content Based on Active View ─────────
        if (_activeViewTab == 0)
          const PageControlSettingsCard()
        else if (_activeViewTab == 1)
          _buildRoleDrilldownView(context, isDark, primary, isMobile)
        else
          _buildAppShellSimulatorView(context, isDark, primary, isMobile),

        const SizedBox(height: CRMSpacing.xl),
      ],
    );
  }

  // ── Master Super Admin Banner ───────────────────────────────
  Widget _buildMasterHeader(
    BuildContext context,
    bool isDark,
    Color primary,
  ) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFFAF5FF),
                  const Color(0xFFF1F5F9),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Color(0xFFF59E0B),
                  size: 26,
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Super Admin Permission Matrix & Access Metrics',
                            style: CRMTypography.sectionTitle.copyWith(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'SUPER ADMIN ONLY',
                            style: CRMTypography.captionBold.copyWith(
                              color: const Color(0xFFD97706),
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live dynamic access engine: Manage App Shell navigation routes, inventory operations, pipeline workflows, campaigns, and team access for Admin, Telecaller, and Sales.',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_person_rounded,
                  size: 16,
                  color: primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fail-safe Architecture: Super Admin retains 100% unrestricted master authority across all endpoints. Modifications to Admin, Telecaller, or Sales apply immediately without service restarts.',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Metrics Overview Cards Strip ────────────────────────────
  Widget _buildMetricsOverview(
    BuildContext context, {
    required bool isDark,
    required int total,
    required int superAdminCount,
    required int adminCount,
    required int telecallerCount,
    required int salesCount,
    required bool isMobile,
  }) {
    final cards = [
      _buildRoleMetricPill(
        context,
        roleName: 'Super Admin',
        activeCount: superAdminCount,
        total: total,
        accentColor: const Color(0xFFF59E0B),
        badgeText: 'MASTER LOCKED',
        icon: Icons.shield_outlined,
        isLocked: true,
      ),
      _buildRoleMetricPill(
        context,
        roleName: 'Admin',
        activeCount: adminCount,
        total: total,
        accentColor: const Color(0xFF3B82F6),
        badgeText: 'MANAGED',
        icon: Icons.admin_panel_settings_outlined,
        isLocked: false,
      ),
      _buildRoleMetricPill(
        context,
        roleName: 'Telecaller',
        activeCount: telecallerCount,
        total: total,
        accentColor: const Color(0xFF10B981),
        badgeText: 'MANAGED',
        icon: Icons.support_agent_outlined,
        isLocked: false,
      ),
      _buildRoleMetricPill(
        context,
        roleName: 'Sales',
        activeCount: salesCount,
        total: total,
        accentColor: const Color(0xFF8B5CF6),
        badgeText: 'MANAGED',
        icon: Icons.trending_up_rounded,
        isLocked: false,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: c,
                ))
            .toList(),
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRoleMetricPill(
    BuildContext context, {
    required String roleName,
    required int activeCount,
    required int total,
    required Color accentColor,
    required String badgeText,
    required IconData icon,
    required bool isLocked,
  }) {
    final pct = total > 0 ? (activeCount / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    roleName,
                    style: CRMTypography.captionBold.copyWith(
                      color: CRMColors.textOf(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: CRMTypography.captionBold.copyWith(
                    color: accentColor,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$activeCount',
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                ' / $total',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: CRMTypography.captionBold.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total > 0 ? activeCount / total : 0,
              backgroundColor: CRMColors.borderOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Controls, Tabs & Filter Bar ─────────────────────────────
  Widget _buildControlsBar(
    BuildContext context,
    bool isDark,
    Color primary,
    bool isMobile,
  ) {
    return CRMCard(
      padding: const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Views switch & Action buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Segmented Tab bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.borderOf(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewTabButton(
                      context,
                      label: 'Matrix Grid',
                      icon: Icons.table_chart_outlined,
                      index: 0,
                    ),
                    _buildViewTabButton(
                      context,
                      label: 'Role Drill-down',
                      icon: Icons.tune_rounded,
                      index: 1,
                    ),
                    _buildViewTabButton(
                      context,
                      label: 'Live Nav Simulator',
                      icon: Icons.remove_red_eye_outlined,
                      index: 2,
                    ),
                  ],
                ),
              ),

              // Action Buttons: Reset & Export
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showResetConfirmationDialog,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CRMColors.danger,
                      side: BorderSide(color: CRMColors.danger.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: CRMTypography.captionBold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      ),
                    ),
                  ),
                  CRMButton(
                    label: 'Export JSON',
                    prefixIcon: Icons.file_download_outlined,
                    onPressed: _showExportDialog,
                  ),
                ],
              ),
            ],
          ),

          if (_activeViewTab != 0) ...[
            const SizedBox(height: CRMSpacing.m),

            // Search Field & Category Chips
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                    decoration: InputDecoration(
                      hintText: 'Search permissions by name, key, or category...',
                      hintStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: CRMColors.textSecondaryOf(context)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: CRMColors.borderOf(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: CRMColors.borderOf(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: CRMSpacing.s),

            // Categories Horizontal Filter Scroll
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('All'),
                  ...PermissionCategory.all.map(_buildCategoryChip),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewTabButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required int index,
  }) {
    final active = _activeViewTab == index;
    final primary = ThemeManager().primaryColor;

    return InkWell(
      onTap: () => setState(() => _activeViewTab = index),
      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? primary : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: CRMTypography.captionBold.copyWith(
                color: active ? primary : CRMColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final selected = _selectedCategory == category;
    final primary = ThemeManager().primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(category),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.transparent,
        selectedColor: primary.withValues(alpha: 0.12),
        checkmarkColor: primary,
        labelStyle: CRMTypography.caption.copyWith(
          color: selected ? primary : CRMColors.textSecondaryOf(context),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
        ),
        side: BorderSide(
          color: selected ? primary.withValues(alpha: 0.4) : CRMColors.borderOf(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── VIEW 2: Role Drill-down View ────────────────────────────
  static const List<_AdminDrilldownPageConfig> _adminPages = [
    _AdminDrilldownPageConfig(
      key: 'page.dashboard',
      title: 'Dashboard',
      description: 'Access main overview KPIs, recent leads, and inventory summary (/dashboard).',
      route: '/dashboard',
      icon: Icons.grid_view_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.dashboard.followups',
          title: 'Follow-ups',
          description: 'Scheduled client reminders and follow-up activities desk on Admin Dashboard.',
          route: '/dashboard#followups',
          icon: Icons.phone_callback_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.dashboard.site_visits',
          title: 'Site Visit Scheduled',
          description: 'Scheduled property inspections and client site visits on Admin Dashboard.',
          route: '/dashboard#site_visits',
          icon: Icons.location_city_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.properties',
      title: 'Property Inventory',
      description: 'Browse, filter, add, edit, and manage all property listings and unit inventory.',
      route: '/properties',
      icon: Icons.home_work_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.leads',
      title: 'Leads & Pipeline',
      description: 'Manage real estate leads, customer requirements, stage transitions, and pipeline status.',
      route: '/requirements',
      icon: Icons.assignment_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.employees',
      title: 'Users',
      description: 'Team member directory, staff invitations, assignment settings, and user role management.',
      route: '/users',
      icon: Icons.people_outline_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.reports',
      title: 'Reports',
      description: 'View analytical reports, conversion ratios, sales performance metrics, and activity logs.',
      route: '/reports',
      icon: Icons.bar_chart_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.campaign',
      title: 'Campaign',
      description: 'Run and track lead generation campaigns, marketing channels, and inbound ad sources.',
      route: '/campaign',
      icon: Icons.campaign_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.lead_allocation',
      title: 'Lead Allocation',
      description: 'Automated routing rules, round-robin assignments, and direct lead distribution engine.',
      route: '/lead-allocation',
      icon: Icons.alt_route_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.library',
      title: 'Library',
      description: 'Access shared templates, marketing collateral, brochures, agreements, and document repository.',
      route: '/library',
      icon: Icons.folder_shared_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.settings',
      title: 'Setting',
      description: 'Configure branch details, notification channels, branding, and core workspace preferences.',
      route: '/settings',
      icon: Icons.settings_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.support',
      title: 'Support',
      description: 'Contact technical support, submit helpdesk inquiries, and review ticket resolutions.',
      route: '/support',
      icon: Icons.support_agent_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.recycle_bin',
      title: 'Recycle Bin',
      description: 'View and restore soft-deleted properties, archived requirements, and removed assets.',
      route: '/bin',
      icon: Icons.delete_outline_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.audit_logs',
      title: 'Security & Administration',
      description: 'Security audit logs, chronological activity trail, and administrative system safeguards.',
      route: '/settings/audit-logs',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  int _getAdminActiveCount(PermissionMatrixService service) {
    int count = 0;
    for (final p in _adminPages) {
      if (service.hasPermission('Admin', p.key)) count++;
      for (final s in p.subItems) {
        if (service.hasPermission('Admin', s.key)) count++;
      }
    }
    return count;
  }

  Widget _buildRoleDrilldownView(
    BuildContext context,
    bool isDark,
    Color primary,
    bool isMobile,
  ) {
    final perms = _filteredPermissions;
    final service = PermissionMatrixService.instance;
    final isAdmin = _selectedRoleForDrilldown == 'Admin';

    if (!isAdmin && perms.isEmpty) return _buildEmptyState(context);

    final Map<String, List<PermissionItem>> grouped = {};
    for (final p in perms) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    final roleColor = _getRoleColor(_selectedRoleForDrilldown);
    final adminActiveCount = _getAdminActiveCount(service);
    final activeCount = isAdmin ? adminActiveCount : service.getActiveCount(_selectedRoleForDrilldown);
    const totalAdminPerms = 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector Tabs
        Container(
          padding: const EdgeInsets.all(CRMSpacing.s),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Row(
            children: _targetRoles.map((role) {
              final selected = _selectedRoleForDrilldown == role;
              final count = role == 'Admin' ? adminActiveCount : service.getActiveCount(role);
              final col = _getRoleColor(role);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedRoleForDrilldown = role),
                    borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selected ? col.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(
                          color: selected ? col : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            role,
                            style: CRMTypography.captionBold.copyWith(
                              color: selected ? col : CRMColors.textOf(context),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$count active',
                            style: CRMTypography.caption.copyWith(
                              color: selected ? col : CRMColors.textSecondaryOf(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: CRMSpacing.m),

        // Role Detail Header Card
        CRMCard(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.15),
                radius: 20,
                child: Icon(_getRoleIcon(_selectedRoleForDrilldown), color: roleColor, size: 22),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedRoleForDrilldown Capabilities Configuration',
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getRoleDescription(_selectedRoleForDrilldown),
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
                ),
                child: Text(
                  isAdmin
                      ? '$adminActiveCount / $totalAdminPerms Active'
                      : '$activeCount / ${PermissionMatrixService.allPermissions.length} Active',
                  style: CRMTypography.captionBold.copyWith(color: roleColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: CRMSpacing.m),

        // Admin dedicated view vs standard categories view
        if (isAdmin)
          _buildAdminDrilldownView(context, isDark, primary, roleColor, service, isMobile)
        else
          // Category Cards for Telecaller and Sales
          ...grouped.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;
            final allActive = items.every((p) => service.hasPermission(_selectedRoleForDrilldown, p.key));

            return Padding(
              padding: const EdgeInsets.only(bottom: CRMSpacing.m),
              child: CRMCard(
                title: category,
                headerAction: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          service.setCategoryPermissions(_selectedRoleForDrilldown, category, !allActive);
                        });
                      },
                      icon: Icon(
                        allActive ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: roleColor,
                      ),
                      label: Text(
                        allActive ? 'Disable All' : 'Enable All',
                        style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: items.map((p) {
                    final allowed = service.hasPermission(_selectedRoleForDrilldown, p.key);
                    return Column(
                      children: [
                        SwitchListTile(
                          value: allowed,
                          activeThumbColor: roleColor,
                          onChanged: (val) {
                            setState(() {
                              service.setPermission(_selectedRoleForDrilldown, p.key, val);
                            });
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.title,
                                  style: CRMTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: CRMColors.textOf(context),
                                  ),
                                ),
                              ),
                              if (p.relatedRoute != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.relatedRoute!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              p.description,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (p != items.last) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAdminDrilldownView(
    BuildContext context,
    bool isDark,
    Color primary,
    Color roleColor,
    PermissionMatrixService service,
    bool isMobile,
  ) {
    final search = _searchQuery.trim().toLowerCase();
    final filtered = _adminPages.where((p) {
      if (search.isEmpty) return true;
      final matchParent = p.title.toLowerCase().contains(search) ||
          p.description.toLowerCase().contains(search) ||
          p.route.toLowerCase().contains(search) ||
          p.key.toLowerCase().contains(search);
      final matchSub = p.subItems.any((s) =>
          s.title.toLowerCase().contains(search) ||
          s.description.toLowerCase().contains(search) ||
          s.route.toLowerCase().contains(search) ||
          s.key.toLowerCase().contains(search));
      return matchParent || matchSub;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(context);
    }

    final allAdminKeys = [
      for (final p in _adminPages) ...[p.key, ...p.subItems.map((s) => s.key)]
    ];
    final allActive = allAdminKeys.every((k) => service.hasPermission('Admin', k));

    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: CRMCard(
        title: 'Admin Role Pages & Permissions',
        headerAction: TextButton.icon(
          onPressed: () {
            setState(() {
              for (final k in allAdminKeys) {
                service.setPermission('Admin', k, !allActive);
              }
            });
          },
          icon: Icon(
            allActive ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 16,
            color: roleColor,
          ),
          label: Text(
            allActive ? 'Disable All' : 'Enable All',
            style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        child: Column(
          children: filtered.map((p) {
            final isLast = p == filtered.last;
            if (p.key == 'page.dashboard') {
              return Column(
                children: [
                  _buildAdminDashboardRow(context, p, isDark, primary, roleColor, service, search),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }

            final allowed = service.hasPermission('Admin', p.key);
            return Column(
              children: [
                SwitchListTile(
                  value: allowed,
                  activeThumbColor: roleColor,
                  onChanged: (val) {
                    setState(() {
                      service.setPermission('Admin', p.key, val);
                    });
                  },
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(p.icon, color: roleColor, size: 19),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.title,
                          style: CRMTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: CRMColors.textOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.route,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      p.description,
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdminDashboardRow(
    BuildContext context,
    _AdminDrilldownPageConfig config,
    bool isDark,
    Color primary,
    Color roleColor,
    PermissionMatrixService service,
    String search,
  ) {
    final isAllowed = service.hasPermission('Admin', config.key);
    final autoExpand = search.isNotEmpty &&
        config.subItems.any((s) =>
            s.title.toLowerCase().contains(search) ||
            s.description.toLowerCase().contains(search) ||
            s.route.toLowerCase().contains(search) ||
            s.key.toLowerCase().contains(search));
    final isExpanded = _isDashboardExpanded || autoExpand;

    final activeSubCount = config.subItems
        .where((s) => service.hasPermission('Admin', s.key))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isDashboardExpanded = !_isDashboardExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Expand chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: roleColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(config.icon, color: roleColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            config.title,
                            style: CRMTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: CRMColors.textOf(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              config.route,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$activeSubCount/2 sub-options',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        config.description,
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isAllowed,
                  activeThumbColor: roleColor,
                  onChanged: (val) {
                    setState(() {
                      service.setPermission('Admin', config.key, val);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        // Expandable sub-options panel
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Container(
                  margin: const EdgeInsets.only(left: 40, right: 8, top: 4, bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2434) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3D52) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: roleColor),
                          const SizedBox(width: 6),
                          Text(
                            'Dashboard Sub-Permissions & Component Controls',
                            style: CRMTypography.captionBold.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      ...config.subItems.map((sub) {
                        final isSubAllowed = service.hasPermission('Admin', sub.key);
                        final isLastSub = sub == config.subItems.last;
                        return Column(
                          children: [
                            SwitchListTile(
                              value: isSubAllowed,
                              activeThumbColor: roleColor,
                              onChanged: (val) {
                                setState(() {
                                  service.setPermission('Admin', sub.key, val);
                                });
                              },
                              secondary: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(sub.icon, color: roleColor, size: 17),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    sub.title,
                                    style: CRMTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: CRMColors.textOf(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      sub.route,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  sub.description,
                                  style: CRMTypography.caption.copyWith(
                                    color: CRMColors.textSecondaryOf(context),
                                  ),
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (!isLastSub) const Divider(height: 1),
                          ],
                        );
                      }),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── VIEW 3: App Shell Navigation Simulator ──────────────────────────
  Widget _buildAppShellSimulatorView(
    BuildContext context,
    bool isDark,
    Color primary,
    bool isMobile,
  ) {
    final service = PermissionMatrixService.instance;
    final roleColor = _getRoleColor(_simulatorRole);

    // Dynamic Navigation Tree directly sourced from centralized AppNavigationRegistry
    var navTree = AppNavigationRegistry.getNavItemsForRole(_simulatorRole);

    // Dynamic search filtering across routes, keys, and nested subpages
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      navTree = navTree.where((item) {
        final matchesItem = item.title.toLowerCase().contains(q) ||
            item.route.toLowerCase().contains(q) ||
            item.key.toLowerCase().contains(q);
        final matchesChild = item.children.any((c) =>
            c.title.toLowerCase().contains(q) ||
            c.route.toLowerCase().contains(q) ||
            c.key.toLowerCase().contains(q));
        return matchesItem || matchesChild;
      }).toList();
    }

    final totalRoutesAndSubpages = navTree.fold<int>(
      0,
      (sum, item) => sum + 1 + item.children.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector Banner for Simulator
        CRMCard(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Shell Navigation Live Preview Simulator',
                style: CRMTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CRMColors.textOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select any role below to preview which items appear in their sidebar and whether their route access is granted or blocked.',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
              ),
              const SizedBox(height: CRMSpacing.m),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Super Admin', 'Admin', 'Telecaller', 'Sales'].map((r) {
                  final selected = _simulatorRole == r;
                  final col = _getRoleColor(r);
                  return ChoiceChip(
                    label: Text(r),
                    selected: selected,
                    selectedColor: col.withValues(alpha: 0.15),
                    labelStyle: CRMTypography.captionBold.copyWith(
                      color: selected ? col : CRMColors.textSecondaryOf(context),
                    ),
                    side: BorderSide(color: selected ? col : CRMColors.borderOf(context)),
                    onSelected: (_) => setState(() => _simulatorRole = r),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: CRMSpacing.m),

        // Simulated Sidebar Preview & Route Access Matrix
        if (isMobile) ...[
          _buildSimulatedSidebar(context, isDark, navTree, service, roleColor),
          const SizedBox(height: CRMSpacing.m),
          _buildRoutePermissionsTable(context, isDark, navTree, service, roleColor, totalRoutesAndSubpages),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 260,
                child: _buildSimulatedSidebar(context, isDark, navTree, service, roleColor),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: _buildRoutePermissionsTable(context, isDark, navTree, service, roleColor, totalRoutesAndSubpages),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSimulatedSidebar(
    BuildContext context,
    bool isDark,
    List<AppNavItem> navTree,
    PermissionMatrixService service,
    Color roleColor,
  ) {
    final isSuper = _simulatorRole == 'Super Admin';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_rounded, size: 16, color: roleColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sidebar ($_simulatorRole)',
                  style: CRMTypography.captionBold.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...navTree.map((item) {
            final visible = isSuper
                ? true
                : (service.hasPermission(_simulatorRole, item.key) &&
                   service.canViewRoute(_simulatorRole, item.route));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: visible ? 1.0 : 0.35,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: visible ? roleColor.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 16,
                          color: visible ? roleColor : CRMColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: CRMTypography.caption.copyWith(
                              color: visible ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                              fontWeight: visible ? FontWeight.w600 : FontWeight.normal,
                              decoration: visible ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (item.hasChildren)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: visible ? roleColor : CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        Icon(
                          visible ? Icons.check_circle_rounded : Icons.visibility_off_rounded,
                          size: 14,
                          color: visible ? CRMColors.success : CRMColors.textSecondaryOf(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // Indented Subpages (if any)
                if (item.hasChildren)
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0, top: 2.0, bottom: 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Column(
                        children: item.children.map((child) {
                          final childVisible = isSuper
                              ? true
                              : (visible &&
                                 service.hasPermission(_simulatorRole, child.key) &&
                                 service.canViewRoute(_simulatorRole, child.route));

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: childVisible ? 1.0 : 0.35,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: childVisible ? roleColor.withValues(alpha: 0.05) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    child.icon,
                                    size: 13,
                                    color: childVisible ? roleColor : CRMColors.textSecondaryOf(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      child.title,
                                      style: CRMTypography.caption.copyWith(
                                        fontSize: 11.5,
                                        color: childVisible ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                                        fontWeight: childVisible ? FontWeight.w500 : FontWeight.normal,
                                        decoration: childVisible ? null : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    childVisible ? Icons.check_circle_rounded : Icons.visibility_off_rounded,
                                    size: 13,
                                    color: childVisible ? CRMColors.success : CRMColors.textSecondaryOf(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoutePermissionsTable(
    BuildContext context,
    bool isDark,
    List<AppNavItem> navTree,
    PermissionMatrixService service,
    Color roleColor,
    int totalRoutesAndSubpages,
  ) {
    final isSuper = _simulatorRole == 'Super Admin';
    final primary = ThemeManager().primaryColor;

    return CRMCard(
      title: 'App Shell Routes Access Matrix ($_simulatorRole)',
      subtitle: 'Dynamic routing status for current matrix configuration ($totalRoutesAndSubpages routes & subpages)',
      child: Column(
        children: navTree.map((item) {
          final isParentAllowed = isSuper
              ? true
              : (service.hasPermission(_simulatorRole, item.key) &&
                 service.canViewRoute(_simulatorRole, item.route));

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isParentAllowed ? CRMColors.success.withValues(alpha: 0.04) : CRMColors.danger.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(CRMBorderRadius.card),
              border: Border.all(
                color: isParentAllowed ? CRMColors.success.withValues(alpha: 0.25) : CRMColors.danger.withValues(alpha: 0.25),
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top-Level Item Row
                Row(
                  children: [
                    Icon(
                      isParentAllowed ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                      size: 20,
                      color: isParentAllowed ? CRMColors.success : CRMColors.danger,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.title,
                                style: CRMTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: CRMColors.textOf(context),
                                ),
                              ),
                              if (item.hasChildren) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: primary.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    '${item.children.length} SUBPAGES',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Route: ${item.route} • Metric: ${item.key}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isSuper)
                      Switch(
                        value: service.hasPermission(_simulatorRole, item.key),
                        activeThumbColor: roleColor,
                        onChanged: (val) {
                          setState(() {
                            service.setPermission(_simulatorRole, item.key, val);
                          });
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PERMANENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                  ],
                ),

                // Children / Subpages list
                if (item.hasChildren) ...[
                  const Divider(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      children: item.children.map((child) {
                        final isChildAllowed = isSuper
                            ? true
                            : (isParentAllowed && service.hasPermission(_simulatorRole, child.key));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                child.icon,
                                size: 15,
                                color: isChildAllowed ? roleColor : CRMColors.textSecondaryOf(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          child.title,
                                          style: CRMTypography.captionBold.copyWith(
                                            color: isChildAllowed ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                                            decoration: isChildAllowed ? null : TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'SUBPAGE',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Route: ${child.route} • Metric: ${child.key}',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontFamily: 'monospace',
                                        color: CRMColors.textSecondaryOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isSuper)
                                Switch(
                                  value: isParentAllowed && service.hasPermission(_simulatorRole, child.key),
                                  activeThumbColor: roleColor,
                                  onChanged: isParentAllowed
                                      ? (val) {
                                          setState(() {
                                            service.setPermission(_simulatorRole, child.key, val);
                                          });
                                        }
                                      : null,
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PERMANENT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Dialogs & State Helpers ─────────────────────────────────

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: CRMColors.danger),
            const SizedBox(width: 8),
            const Text('Reset Permission Matrix?'),
          ],
        ),
        content: const Text(
          'This will restore all permissions for Admin, Telecaller, and Sales back to the standard PropKart system defaults. Custom modifications will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await PermissionMatrixService.instance.resetToDefaults();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permissions restored to system defaults successfully.'),
                    backgroundColor: CRMColors.success,
                  ),
                );
              }
            },
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    final jsonStr = PermissionMatrixService.instance.exportJson();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_object_rounded, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            const Text('Export Permission Matrix'),
          ],
        ),
        content: SizedBox(
          width: CRMBreakpoints.adaptiveWidth(context, 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Current active matrix configuration in JSON format:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permission Matrix JSON copied to clipboard!'),
                  backgroundColor: CRMColors.success,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CRMCard(
      padding: const EdgeInsets.all(CRMSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: CRMColors.textSecondaryOf(context)),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'No permissions match your filter',
              style: CRMTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: CRMColors.textOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing your search query or selecting a different category.',
              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: CRMSpacing.m),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }


  Color _getRoleColor(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('super')) return const Color(0xFFF59E0B);
    if (r == 'admin') return const Color(0xFF3B82F6);
    if (r == 'telecaller') return const Color(0xFF10B981);
    return const Color(0xFF8B5CF6);
  }

  IconData _getRoleIcon(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('super')) return Icons.shield_rounded;
    if (r == 'admin') return Icons.admin_panel_settings_rounded;
    if (r == 'telecaller') return Icons.support_agent_rounded;
    return Icons.trending_up_rounded;
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'Admin':
        return 'Operational manager with privileges over properties, leads, reports, and staff management.';
      case 'Telecaller':
        return 'Inbound and outbound inquiry desk handling calls, initial triage, and lead intake.';
      case 'Sales':
        return 'Field and closing agent handling client viewings, negotiations, and closed deals.';
      default:
        return 'Standard organization member.';
    }
  }
}


class _AdminDrilldownPageConfig {
  final String key;
  final String title;
  final String description;
  final String route;
  final IconData icon;
  final List<_AdminDrilldownPageConfig> subItems;

  const _AdminDrilldownPageConfig({
    required this.key,
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    this.subItems = const [],
  });
}
