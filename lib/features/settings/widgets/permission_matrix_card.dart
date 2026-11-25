import 'page_control_settings_card.dart';
import '../../../core/navigation/app_nav_registry.dart';
import '../../../core/navigation/navigation_pages_service.dart';
import '../../../core/security/role_guard.dart';
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
  final Set<String> _expandedAdminRows = {};
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
    NavigationPagesService.instance.addListener(_onServiceChanged);
    _syncNavigationPages();
  }

  void _syncNavigationPages() {
    NavigationPagesService.instance.syncAndLoad(
      canSync: RoleGuard.isSuperAdmin(RoleGuard.currentUser?.role),
    );
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    PermissionMatrixService.instance.removeListener(_onServiceChanged);
    NavigationPagesService.instance.removeListener(_onServiceChanged);
    super.dispose();
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
                      label: 'Under Dev Page',
                      icon: Icons.developer_mode_outlined,
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
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.properties.add',
          title: '+ Add Property',
          description: 'Show the + Add Property button on the Properties page.',
          route: '/properties#add',
          icon: Icons.add_home_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.export',
          title: 'Export Properties',
          description: 'Show the Export Properties button.',
          route: '/properties#export',
          icon: Icons.download_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.edit',
          title: 'Edit Property',
          description: 'Show Edit in the property actions menu.',
          route: '/properties#edit',
          icon: Icons.edit_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.delete',
          title: 'Delete Property',
          description: 'Show Delete in the property actions menu.',
          route: '/properties#delete',
          icon: Icons.delete_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.message',
          title: 'Message',
          description: 'Show Message in the property actions menu.',
          route: '/properties#message',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.share',
          title: 'Share Property',
          description: 'Show Share Property in the actions menu and the bulk selection toolbar.',
          route: '/properties#share',
          icon: Icons.share_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.archive',
          title: 'Archive Property',
          description: 'Show Archive Property in the actions menu. When off, the Archive tab is hidden too.',
          route: '/properties#archive',
          icon: Icons.archive_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.visibility_controls',
          title: 'Manage Property Visibility Settings',
          description:
              'Allow Admin (and their team) to access and change the Rent/Resale sharing toggles and the per-property "Share with Other Admins" toggles. When off, these controls are hidden and locked.',
          route: '/properties#visibility_controls',
          icon: Icons.admin_panel_settings_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'group.properties.cross_admin',
          title: 'Admin Internal Property Visibility – All Admins',
          description:
              'Let Admins and their employees view other Admins\' properties. The owner Admin must also share Rent/Resale properties, and the individual property must be shared.',
          route: '/properties#cross_admin',
          icon: Icons.visibility_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.properties.cross_admin.rent',
              title: 'Rent Properties',
              description: 'Allow viewing shared Rent properties of other Admins.',
              route: '/properties#cross_admin_rent',
              icon: Icons.key_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.properties.cross_admin.resale',
              title: 'Resale Properties',
              description: 'Allow viewing shared Resale properties of other Admins.',
              route: '/properties#cross_admin_resale',
              icon: Icons.sell_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.properties.notes',
              title: 'Add Notes',
              description:
                  'Allow Admins and their employees to add, view and delete property notes. When off, the Add Notes option is hidden.',
              route: '/properties#notes',
              icon: Icons.sticky_note_2_outlined,
            ),
          ],
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.leads',
      title: 'Leads & Pipeline',
      description: 'Manage real estate leads, customer requirements, stage transitions, and pipeline status.',
      route: '/requirements',
      icon: Icons.assignment_outlined,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.add',
          title: '+ Add Lead',
          description: 'Show the + Add Lead button.',
          route: '/requirements#add',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.add_notes',
          title: '+ Add Notes',
          description: 'Show + Add Notes on individual leads.',
          route: '/requirements#notes',
          icon: Icons.note_add_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.export',
          title: 'Export Requirements',
          description: 'Show the Export Requirements button.',
          route: '/requirements#export',
          icon: Icons.download_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.view_details',
          title: 'View Details',
          description: 'Client Leads 3-dot menu: View Details.',
          route: '/requirements#view_details',
          icon: Icons.info_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.add_requirement',
          title: 'Add Another Requirement',
          description: 'Client Leads 3-dot menu: Add Another Requirement.',
          route: '/requirements#add_another',
          icon: Icons.add_circle_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.share',
          title: 'Share Properties',
          description: 'Client Leads 3-dot menu: Share Properties.',
          route: '/requirements#share',
          icon: Icons.share_outlined,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.leads.share.multiple',
              title: 'Multiple Properties',
              description: 'Allow selecting more than one property to share.',
              route: '/requirements#share_multiple',
              icon: Icons.library_add_check_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.leads.share.pdf',
              title: 'Share PDF',
              description: 'Show the Share PDF option.',
              route: '/requirements#share_pdf',
              icon: Icons.picture_as_pdf_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.leads.share.link',
              title: 'Generate Link',
              description: 'Show the Generate Link option.',
              route: '/requirements#share_link',
              icon: Icons.link_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.leads.share.whatsapp',
              title: 'Share on WhatsApp',
              description: 'Show the Share on WhatsApp option.',
              route: '/requirements#share_whatsapp',
              icon: Icons.chat_outlined,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.run_matches',
          title: 'Run Matches',
          description: 'Show the Run Matches button.',
          route: '/requirements#run_matches',
          icon: Icons.handshake_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.edit',
          title: 'Edit',
          description: 'Client Leads 3-dot menu: Edit.',
          route: '/requirements#edit',
          icon: Icons.edit_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.delete',
          title: 'Delete',
          description: 'Client Leads 3-dot menu: Delete.',
          route: '/requirements#delete',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'group.leads.followups',
      title: 'Leads – Follow-ups Tab',
      description: 'Follow-ups tab actions on the Leads page.',
      route: '/requirements?tab=Follow-ups',
      icon: Icons.phone_callback_rounded,
      isGroup: true,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.followups.select',
          title: 'Select Multiple Follow-ups',
          description: 'Allow selecting multiple follow-up clients.',
          route: '/requirements#followups_select',
          icon: Icons.checklist_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.followups.delete',
          title: 'Delete Follow-ups',
          description: 'Allow deleting follow-up clients.',
          route: '/requirements#followups_delete',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'group.leads.site_visits',
      title: 'Leads – Site Visit Tab',
      description: 'Site Visit tab actions on the Leads page.',
      route: '/requirements?tab=Site Visits',
      icon: Icons.location_city_rounded,
      isGroup: true,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.site_visits.select',
          title: 'Select Multiple Site Visits',
          description: 'Allow selecting multiple site visit clients.',
          route: '/requirements#site_visits_select',
          icon: Icons.checklist_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.site_visits.delete',
          title: 'Delete Site Visits',
          description: 'Allow deleting site visit clients.',
          route: '/requirements#site_visits_delete',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'group.leads.rejected',
      title: 'Leads – Rejected Tab',
      description: 'Rejected tab actions on the Leads page.',
      route: '/requirements?tab=Rejected',
      icon: Icons.block_rounded,
      isGroup: true,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.rejected.view_details',
          title: 'View Details',
          description: 'Rejected tab 3-dot menu: View Details.',
          route: '/requirements#rejected_view_details',
          icon: Icons.info_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.rejected.delete',
          title: 'Delete',
          description: 'Rejected tab 3-dot menu: Delete.',
          route: '/requirements#rejected_delete',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.employees',
      title: 'Employees',
      description: 'Team member directory, staff invitations, assignment settings, and user role management.',
      route: '/users',
      icon: Icons.people_outline_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.employees.add',
          title: '+ Add Employee',
          description: 'Show the + Add Employee button.',
          route: '/users#add',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.employees.tree',
          title: 'Employee Tree',
          description: 'Show the Employee Tree button and page.',
          route: '/users/tree',
          icon: Icons.account_tree_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.employees.delete',
          title: 'Delete Employee',
          description: 'Allow deleting employees.',
          route: '/users#delete',
          icon: Icons.delete_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.employees.edit',
          title: 'Edit Employee',
          description: 'Allow editing employees.',
          route: '/users#edit',
          icon: Icons.edit_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.employees.details',
          title: 'Individual Employee Details',
          description: 'Allow opening an individual employee page.',
          route: '/users/:id',
          icon: Icons.badge_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.employees.active_toggle',
          title: 'Active Login ON/OFF',
          description: 'Allow turning an employee login on or off.',
          route: '/users#active_login',
          icon: Icons.toggle_on_outlined,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.reports',
      title: 'Reports',
      description: 'View analytical reports, conversion ratios, sales performance metrics, and activity logs.',
      route: '/reports',
      icon: Icons.bar_chart_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.reports.export',
          title: 'Export Option',
          description: 'Show the report Export option.',
          route: '/reports#export',
          icon: Icons.download_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.filters',
          title: 'Filters',
          description: 'Show the report filters.',
          route: '/reports#filters',
          icon: Icons.filter_alt_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.campaign_kpis',
          title: 'Campaign Performance KPIs',
          description: 'Show the Campaign Performance KPIs section.',
          route: '/reports#campaign_kpis',
          icon: Icons.campaign_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.leads_kpis',
          title: 'Leads Page KPIs',
          description: 'Show the Leads Page KPIs section.',
          route: '/reports#leads_kpis',
          icon: Icons.assignment_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.executive',
          title: 'Executive Operational KPIs & Pipeline Breakdown',
          description: 'Show the Executive Operational KPIs section.',
          route: '/reports#executive',
          icon: Icons.insights_rounded,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.reports.executive.all',
              title: 'All Modules',
              description: 'Show the All Modules view.',
              route: '/reports#executive_all',
              icon: Icons.dashboard_customize_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.reports.executive.sourcing',
              title: 'Inventory Sourcing',
              description: 'Show the Inventory Sourcing module.',
              route: '/reports#executive_sourcing',
              icon: Icons.add_home_work_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.reports.executive.manual',
              title: 'Manual & Direct Leads',
              description: 'Show the Manual & Direct Leads module.',
              route: '/reports#executive_manual',
              icon: Icons.person_add_alt_1_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.reports.executive.pipeline',
              title: 'Sales Pipeline',
              description: 'Show the Sales Pipeline module.',
              route: '/reports#executive_pipeline',
              icon: Icons.workspace_premium_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.reports.executive.qualified',
              title: 'Qualified Leads',
              description: 'Show the Qualified Leads module.',
              route: '/reports#executive_qualified',
              icon: Icons.verified_user_rounded,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.telecaller',
          title: 'Telecaller Report',
          description: 'Show the Telecaller Report tab.',
          route: '/reports/leads/telecaller',
          icon: Icons.headset_mic_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.sales',
          title: 'Sales Report',
          description: 'Show the Sales Report tab.',
          route: '/reports/leads/sales',
          icon: Icons.trending_up_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.lead_metrics',
          title: 'Lead Metrics',
          description: 'Show the Lead Metrics tab.',
          route: '/reports/leads/metrics',
          icon: Icons.analytics_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.reports.properties',
          title: 'Property Reports',
          description: 'Show the Property Reports tab.',
          route: '/reports/properties',
          icon: Icons.home_work_outlined,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.campaign',
      title: 'Campaign',
      description: 'Run and track lead generation campaigns, marketing channels, and inbound ad sources.',
      route: '/campaign',
      icon: Icons.campaign_outlined,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.campaign.add_integration',
          title: '+ Add Integration',
          description: 'Connections: show + Add Integration.',
          route: '/campaign/connections',
          icon: Icons.add_link_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.lead_allocation',
      title: 'Lead Allocation',
      description: 'Automated routing rules, round-robin assignments, and direct lead distribution engine.',
      route: '/lead-allocation',
      icon: Icons.alt_route_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.lead_allocation.configure',
          title: 'Configure Page Access',
          description: 'Allow opening and saving the Configure page.',
          route: '/admin/lead-allocation/configure',
          icon: Icons.tune_rounded,
        ),
      ],
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
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'group.settings.profile',
          title: 'Profile',
          description: 'When off, the field stays visible but cannot be edited.',
          route: '/profile',
          icon: Icons.person_outline_rounded,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.settings.profile.name',
              title: 'Name',
              description: 'Allow editing the profile name.',
              route: '/profile#name',
              icon: Icons.badge_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.profile.mobile',
              title: 'Mobile Number',
              description: 'Allow editing the profile mobile number.',
              route: '/profile#mobile',
              icon: Icons.phone_iphone_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.profile.email',
              title: 'Email Address',
              description: 'Allow editing the profile email address.',
              route: '/profile#email',
              icon: Icons.alternate_email_rounded,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'page.settings.themes.change',
          title: 'Themes',
          description: 'Allow changing the application theme.',
          route: '/settings#themes',
          icon: Icons.palette_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'group.settings.appearance',
          title: 'Appearance',
          description: 'Appearance options.',
          route: '/settings#appearance',
          icon: Icons.brightness_6_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.settings.appearance.dark',
              title: 'Dark Mode',
              description: 'Allow switching to Dark Mode.',
              route: '/settings#dark_mode',
              icon: Icons.dark_mode_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.appearance.light',
              title: 'Light Mode',
              description: 'Allow switching to Light Mode.',
              route: '/settings#light_mode',
              icon: Icons.light_mode_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.appearance.match_criteria',
              title: 'Run Match Criteria',
              description: 'Allow saving Run Match Criteria changes.',
              route: '/settings#match_criteria',
              icon: Icons.handshake_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.appearance.sync_diagnostics',
              title: 'Sync Diagnostics',
              description: 'Show the Sync Diagnostics option.',
              route: '/settings#sync_diagnostics',
              icon: Icons.sync_problem_rounded,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'group.settings.location',
          title: 'Location',
          description: 'Location configuration actions.',
          route: '/settings/location-config',
          icon: Icons.location_on_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.settings.location.add_city',
              title: '+ Add City',
              description: 'Allow adding cities.',
              route: '/settings/location-config#city',
              icon: Icons.location_city_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.location.add_area',
              title: '+ Add New Area',
              description: 'Allow adding areas.',
              route: '/settings/location-config#area',
              icon: Icons.map_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.location.add_zone',
              title: '+ Add New Zone',
              description: 'Allow adding zones.',
              route: '/settings/location-config#zone',
              icon: Icons.layers_outlined,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'page.settings.upload_limits.save',
          title: 'Upload Limit',
          description: 'Allow saving or updating upload limits.',
          route: '/settings#upload_limits',
          icon: Icons.cloud_upload_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.settings.support_contacts.save',
          title: 'Support Contacts',
          description: 'Allow saving Support page WhatsApp, phone, and email.',
          route: '/settings#support_contacts',
          icon: Icons.support_agent_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'group.settings.kpi',
          title: 'KPI Configuration',
          description: 'KPI configuration actions.',
          route: '/settings/kpi-config',
          icon: Icons.speed_rounded,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.settings.kpi.add',
              title: '+ Add New KPI',
              description: 'Allow adding KPIs.',
              route: '/settings/kpi-config#add',
              icon: Icons.add_chart_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.kpi.active',
              title: 'Active KPI',
              description: 'Allow turning KPIs active or inactive.',
              route: '/settings/kpi-config#active',
              icon: Icons.toggle_on_outlined,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.settings.kpi.actions',
              title: 'Action Buttons',
              description: 'Show KPI action buttons (edit, delete, role visibility).',
              route: '/settings/kpi-config#actions',
              icon: Icons.more_horiz_rounded,
            ),
          ],
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.support',
      title: 'Support',
      description: 'Contact technical support, submit helpdesk inquiries, and review ticket resolutions.',
      route: '/support',
      icon: Icons.support_agent_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.support.report_issue',
          title: '+ Report an Issue',
          description: 'Allow creating and submitting new issue reports.',
          route: '/support#report',
          icon: Icons.add_comment_outlined,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.recycle_bin',
      title: 'Recycle Bin',
      description: 'View and restore soft-deleted properties, archived requirements, and removed assets.',
      route: '/bin',
      icon: Icons.delete_outline_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.recycle_bin.auto_delete',
          title: 'Auto Delete Option',
          description: 'Allow changing the Auto Delete period.',
          route: '/bin#auto_delete',
          icon: Icons.timer_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.recycle_bin.empty_bin',
          title: 'Empty Bin Option',
          description: 'Allow emptying the Recycle Bin.',
          route: '/bin#empty',
          icon: Icons.delete_sweep_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'group.recycle_bin.properties',
          title: 'Properties Tab',
          description: 'Actions on deleted properties.',
          route: '/bin#properties',
          icon: Icons.home_work_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.properties_restore',
              title: 'Restore',
              description: 'Allow restoring deleted properties.',
              route: '/bin#properties_restore',
              icon: Icons.restore_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.properties_delete',
              title: 'Delete',
              description: 'Allow permanently deleting properties.',
              route: '/bin#properties_delete',
              icon: Icons.delete_forever_outlined,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'group.recycle_bin.requirements',
          title: 'Requirements Tab',
          description: 'Actions on deleted requirements.',
          route: '/bin#requirements',
          icon: Icons.assignment_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.requirements_restore',
              title: 'Restore',
              description: 'Allow restoring deleted requirements.',
              route: '/bin#requirements_restore',
              icon: Icons.restore_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.requirements_delete',
              title: 'Delete',
              description: 'Allow permanently deleting requirements.',
              route: '/bin#requirements_delete',
              icon: Icons.delete_forever_outlined,
            ),
          ],
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.audit_logs',
      title: 'Security & Administration',
      description: 'Security audit logs, chronological activity trail, and administrative system safeguards.',
      route: '/settings/audit-logs',
      icon: Icons.admin_panel_settings_outlined,
    ),
  ];

  static const _AdminDrilldownPageConfig _roleLeadsShareConfig = _AdminDrilldownPageConfig(
    key: 'page.leads.share',
    title: 'Share Properties',
    description: 'Lead 3-dot menu: Share Properties.',
    route: '/requirements#share',
    icon: Icons.share_outlined,
    subItems: [
      _AdminDrilldownPageConfig(
        key: 'page.leads.share.multiple',
        title: 'Multiple Properties',
        description: 'Allow selecting more than one property to share.',
        route: '/requirements#share_multiple',
        icon: Icons.library_add_check_outlined,
      ),
      _AdminDrilldownPageConfig(
        key: 'page.leads.share.pdf',
        title: 'Share PDF',
        description: 'Show the Share PDF option.',
        route: '/requirements#share_pdf',
        icon: Icons.picture_as_pdf_outlined,
      ),
      _AdminDrilldownPageConfig(
        key: 'page.leads.share.link',
        title: 'Generate Link',
        description: 'Show the Generate Link option.',
        route: '/requirements#share_link',
        icon: Icons.link_rounded,
      ),
      _AdminDrilldownPageConfig(
        key: 'page.leads.share.whatsapp',
        title: 'Share on WhatsApp',
        description: 'Show the Share on WhatsApp option.',
        route: '/requirements#share_whatsapp',
        icon: Icons.chat_outlined,
      ),
    ],
  );

  static const _AdminDrilldownPageConfig _roleSettingsConfig = _AdminDrilldownPageConfig(
    key: 'page.settings',
    title: 'Setting',
    description: 'Settings page and the sections available to this role.',
    route: '/settings',
    icon: Icons.settings_outlined,
    subItems: [
      _AdminDrilldownPageConfig(
        key: 'page.settings.profile',
        title: 'Profile',
        description: 'Show the Profile section. When a field is off, it stays visible but cannot be edited.',
        route: '/profile',
        icon: Icons.person_outline_rounded,
        subItems: [
          _AdminDrilldownPageConfig(
            key: 'page.settings.profile.name',
            title: 'Name',
            description: 'Allow editing the profile name.',
            route: '/profile#name',
            icon: Icons.badge_outlined,
          ),
          _AdminDrilldownPageConfig(
            key: 'page.settings.profile.mobile',
            title: 'Mobile Number',
            description: 'Allow editing the profile mobile number.',
            route: '/profile#mobile',
            icon: Icons.phone_iphone_rounded,
          ),
        ],
      ),
      _AdminDrilldownPageConfig(
        key: 'page.settings.themes',
        title: 'Themes',
        description: 'Show the Themes section.',
        route: '/settings?section=themes',
        icon: Icons.palette_outlined,
        subItems: [
          _AdminDrilldownPageConfig(
            key: 'page.settings.themes.change',
            title: 'Change Theme',
            description: 'Allow changing the application theme.',
            route: '/settings#themes',
            icon: Icons.color_lens_outlined,
          ),
        ],
      ),
      _AdminDrilldownPageConfig(
        key: 'page.settings.appearance',
        title: 'Appearance',
        description: 'Show the Appearance section.',
        route: '/settings?section=appearance',
        icon: Icons.brightness_6_outlined,
        subItems: [
          _AdminDrilldownPageConfig(
            key: 'page.settings.appearance.dark',
            title: 'Dark Mode',
            description: 'Allow switching to Dark Mode.',
            route: '/settings#dark_mode',
            icon: Icons.dark_mode_outlined,
          ),
          _AdminDrilldownPageConfig(
            key: 'page.settings.appearance.light',
            title: 'Light Mode',
            description: 'Allow switching to Light Mode.',
            route: '/settings#light_mode',
            icon: Icons.light_mode_outlined,
          ),
        ],
      ),
      _AdminDrilldownPageConfig(
        key: 'page.settings.locations',
        title: 'Locations',
        description: 'Show the Locations section.',
        route: '/settings/location-config',
        icon: Icons.location_on_outlined,
        subItems: [
          _AdminDrilldownPageConfig(
            key: 'page.settings.location.add_city',
            title: '+ Add City',
            description: 'Allow adding cities.',
            route: '/settings/location-config#city',
            icon: Icons.location_city_rounded,
          ),
          _AdminDrilldownPageConfig(
            key: 'page.settings.location.add_area',
            title: '+ Add New Area',
            description: 'Allow adding areas.',
            route: '/settings/location-config#area',
            icon: Icons.map_outlined,
          ),
        ],
      ),
      _AdminDrilldownPageConfig(
        key: 'page.settings.system',
        title: 'System',
        description: 'Show the System section.',
        route: '/settings?section=system',
        icon: Icons.info_outline_rounded,
      ),
    ],
  );

  static const _AdminDrilldownPageConfig _roleSupportConfig = _AdminDrilldownPageConfig(
    key: 'page.support',
    title: 'Support',
    description: 'Contact technical support, submit helpdesk inquiries, and review ticket resolutions.',
    route: '/support',
    icon: Icons.support_agent_rounded,
    subItems: [
      _AdminDrilldownPageConfig(
        key: 'page.support.report_issue',
        title: '+ Report an Issue',
        description: 'Allow creating and submitting new issue reports.',
        route: '/support#report',
        icon: Icons.add_comment_outlined,
      ),
    ],
  );

  static const _AdminDrilldownPageConfig _roleLibraryConfig = _AdminDrilldownPageConfig(
    key: 'page.library',
    title: 'Library',
    description: 'Access shared templates, marketing collateral, brochures, agreements, and document repository.',
    route: '/library',
    icon: Icons.folder_shared_outlined,
  );

  static const List<_AdminDrilldownPageConfig> _telecallerPages = [
    _AdminDrilldownPageConfig(
      key: 'page.dashboard',
      title: 'Dashboard',
      description: 'Telecaller dashboard with calling KPIs, follow-ups and recent activity (/dashboard).',
      route: '/dashboard',
      icon: Icons.grid_view_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.properties',
      title: 'Property Inventory',
      description: 'Browse, filter, add and manage property listings.',
      route: '/properties',
      icon: Icons.home_work_outlined,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.properties.add',
          title: '+ Add Property',
          description: 'Show the + Add Property button on the Properties page.',
          route: '/properties#add',
          icon: Icons.add_home_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.export',
          title: 'Export Properties',
          description: 'Show the Export Properties button.',
          route: '/properties#export',
          icon: Icons.download_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.edit',
          title: 'Edit Property',
          description: 'Show Edit in the actions menu of own properties.',
          route: '/properties#edit',
          icon: Icons.edit_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.delete',
          title: 'Delete Property',
          description: 'Show Delete in the actions menu of own properties.',
          route: '/properties#delete',
          icon: Icons.delete_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.message',
          title: 'Message',
          description: 'Show Message in the property actions menu.',
          route: '/properties#message',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.share',
          title: 'Share Property',
          description: 'Show Share Property in the actions menu and the bulk selection toolbar.',
          route: '/properties#share',
          icon: Icons.share_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.archive',
          title: 'Archive Property',
          description: 'Show Archive Property in the actions menu. When off, the Archive tab is hidden too.',
          route: '/properties#archive',
          icon: Icons.archive_outlined,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.telecaller_leads',
      title: 'My Calling Leads',
      description: 'Leads allocated to the signed-in Telecaller for calling.',
      route: '/campaign/leads',
      icon: Icons.phone_in_talk_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.callbacks',
      title: 'Callbacks',
      description: 'Callbacks owned by the signed-in Telecaller.',
      route: '/telecaller/callbacks',
      icon: Icons.event_repeat,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.cnr',
      title: 'CNR / Retry',
      description: 'Call-not-received retry desk owned by the signed-in Telecaller.',
      route: '/telecaller/cnr',
      icon: Icons.phone_missed_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.leads',
      title: 'All Leads (Track)',
      description: 'Track buyer and tenant leads, requirements and their pipeline status.',
      route: '/requirements',
      icon: Icons.assignment_outlined,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.add',
          title: '+ Add Lead',
          description: 'Show the + Add Lead button.',
          route: '/requirements#add',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.add_notes',
          title: '+ Add Notes',
          description: 'Show + Add Notes on individual leads.',
          route: '/requirements#notes',
          icon: Icons.note_add_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.export',
          title: 'Export Requirements',
          description: 'Show the Export Requirements button.',
          route: '/requirements#export',
          icon: Icons.download_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.view_details',
          title: 'View Details',
          description: 'Lead 3-dot menu: View Details.',
          route: '/requirements#view_details',
          icon: Icons.info_outline_rounded,
        ),
        _roleLeadsShareConfig,
        _AdminDrilldownPageConfig(
          key: 'page.leads.run_matches',
          title: 'Run Matches',
          description: 'Show the Run Matches button.',
          route: '/requirements#run_matches',
          icon: Icons.handshake_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.edit',
          title: 'Edit',
          description: 'Lead 3-dot menu: Edit.',
          route: '/requirements#edit',
          icon: Icons.edit_outlined,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'group.leads.rejected',
      title: 'Leads – Rejected Tab',
      description: 'Rejected tab actions on the All Leads (Track) page.',
      route: '/requirements?tab=Rejected',
      icon: Icons.block_rounded,
      isGroup: true,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.rejected.view_details',
          title: 'View Details',
          description: 'Rejected tab 3-dot menu: View Details.',
          route: '/requirements#rejected_view_details',
          icon: Icons.info_outline_rounded,
        ),
      ],
    ),
    _roleLibraryConfig,
    _roleSettingsConfig,
    _roleSupportConfig,
    _AdminDrilldownPageConfig(
      key: 'page.recycle_bin',
      title: 'Recycle Bin',
      description: 'View and restore deleted properties and requirements.',
      route: '/bin',
      icon: Icons.delete_outline_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.recycle_bin.auto_delete',
          title: 'Auto Delete Option',
          description: 'Allow changing the Auto Delete period.',
          route: '/bin#auto_delete',
          icon: Icons.timer_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.recycle_bin.empty_bin',
          title: 'Empty Bin Option',
          description: 'Allow emptying the Recycle Bin.',
          route: '/bin#empty',
          icon: Icons.delete_sweep_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'group.recycle_bin.properties',
          title: 'Properties Tab',
          description: 'Actions on deleted properties.',
          route: '/bin#properties',
          icon: Icons.home_work_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.properties_restore',
              title: 'Restore',
              description: 'Allow restoring deleted properties.',
              route: '/bin#properties_restore',
              icon: Icons.restore_rounded,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'group.recycle_bin.requirements',
          title: 'Requirements Tab',
          description: 'Actions on deleted requirements.',
          route: '/bin#requirements',
          icon: Icons.assignment_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.requirements_restore',
              title: 'Restore',
              description: 'Allow restoring deleted requirements.',
              route: '/bin#requirements_restore',
              icon: Icons.restore_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.requirements_delete',
              title: 'Delete',
              description: 'Allow deleting requirements from the Recycle Bin.',
              route: '/bin#requirements_delete',
              icon: Icons.delete_forever_outlined,
            ),
          ],
        ),
      ],
    ),
  ];

  static const List<_AdminDrilldownPageConfig> _salesPages = [
    _AdminDrilldownPageConfig(
      key: 'page.dashboard',
      title: 'Dashboard',
      description: 'Sales dashboard with pipeline KPIs, site visits and deal outcomes (/dashboard).',
      route: '/dashboard',
      icon: Icons.grid_view_rounded,
    ),
    _AdminDrilldownPageConfig(
      key: 'page.properties',
      title: 'Property Inventory',
      description: 'Browse, filter, add and manage property listings.',
      route: '/properties',
      icon: Icons.home_work_outlined,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.properties.add',
          title: '+ Add Property',
          description: 'Show the + Add Property button on the Properties page.',
          route: '/properties#add',
          icon: Icons.add_home_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.edit',
          title: 'Edit Property',
          description: 'Show Edit in the actions menu of own properties.',
          route: '/properties#edit',
          icon: Icons.edit_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.delete',
          title: 'Delete Property',
          description: 'Show Delete in the actions menu of own properties.',
          route: '/properties#delete',
          icon: Icons.delete_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.message',
          title: 'Message',
          description: 'Show Message in the property actions menu.',
          route: '/properties#message',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.share',
          title: 'Share Property',
          description: 'Show Share Property in the actions menu and the bulk selection toolbar.',
          route: '/properties#share',
          icon: Icons.share_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.properties.archive',
          title: 'Archive Property',
          description: 'Show Archive Property in the actions menu. When off, the Archive tab is hidden too.',
          route: '/properties#archive',
          icon: Icons.archive_outlined,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.leads',
      title: 'Leads',
      description: 'Buyer and tenant leads, follow-ups, won and rejected leads. Lead actions below also apply on Campaign Leads.',
      route: '/requirements',
      icon: Icons.assignment_outlined,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.add',
          title: '+ Add Lead',
          description: 'Show the + Add Lead button.',
          route: '/requirements#add',
          icon: Icons.person_add_alt_1_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.add_notes',
          title: '+ Add Notes',
          description: 'Show + Add Notes on individual leads.',
          route: '/requirements#notes',
          icon: Icons.note_add_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.view_details',
          title: 'View Details',
          description: 'Lead 3-dot menu: View Details.',
          route: '/requirements#view_details',
          icon: Icons.info_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.add_requirement',
          title: 'Add Another Requirement',
          description: 'Lead 3-dot menu: Add Another Requirement.',
          route: '/requirements#add_another',
          icon: Icons.add_circle_outline_rounded,
        ),
        _roleLeadsShareConfig,
        _AdminDrilldownPageConfig(
          key: 'page.leads.run_matches',
          title: 'Run Matches',
          description: 'Show the Run Matches button.',
          route: '/requirements#run_matches',
          icon: Icons.handshake_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.edit',
          title: 'Edit',
          description: 'Lead 3-dot menu: Edit.',
          route: '/requirements#edit',
          icon: Icons.edit_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.delete',
          title: 'Delete',
          description: 'Lead 3-dot menu: Delete (own leads).',
          route: '/requirements#delete',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    ),
    _AdminDrilldownPageConfig(
      key: 'page.my_campaign_leads',
      title: 'Campaign Leads',
      description: 'Campaign leads assigned to the salesperson (Property Listing and Requirement). Also needs Leads access.',
      route: '/my-campaign-leads',
      icon: Icons.campaign_outlined,
    ),
    _AdminDrilldownPageConfig(
      key: 'group.leads.rejected',
      title: 'Leads – Rejected Tab',
      description: 'Rejected tab actions on the Leads page.',
      route: '/requirements?tab=Rejected',
      icon: Icons.block_rounded,
      isGroup: true,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.leads.rejected.view_details',
          title: 'View Details',
          description: 'Rejected tab 3-dot menu: View Details.',
          route: '/requirements#rejected_view_details',
          icon: Icons.info_outline_rounded,
        ),
        _AdminDrilldownPageConfig(
          key: 'page.leads.rejected.delete',
          title: 'Delete',
          description: 'Rejected tab 3-dot menu: Delete.',
          route: '/requirements#rejected_delete',
          icon: Icons.delete_outline_rounded,
        ),
      ],
    ),
    _roleLibraryConfig,
    _roleSettingsConfig,
    _roleSupportConfig,
    _AdminDrilldownPageConfig(
      key: 'page.recycle_bin',
      title: 'Recycle Bin',
      description: 'View and restore deleted properties and requirements.',
      route: '/bin',
      icon: Icons.delete_outline_rounded,
      subItems: [
        _AdminDrilldownPageConfig(
          key: 'page.recycle_bin.auto_delete',
          title: 'Auto Delete Option',
          description: 'Allow changing the Auto Delete period.',
          route: '/bin#auto_delete',
          icon: Icons.timer_outlined,
        ),
        _AdminDrilldownPageConfig(
          key: 'group.recycle_bin.properties',
          title: 'Properties Tab',
          description: 'Actions on deleted properties.',
          route: '/bin#properties',
          icon: Icons.home_work_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.properties_restore',
              title: 'Restore',
              description: 'Allow restoring deleted properties.',
              route: '/bin#properties_restore',
              icon: Icons.restore_rounded,
            ),
          ],
        ),
        _AdminDrilldownPageConfig(
          key: 'group.recycle_bin.requirements',
          title: 'Requirements Tab',
          description: 'Actions on deleted requirements.',
          route: '/bin#requirements',
          icon: Icons.assignment_outlined,
          isGroup: true,
          subItems: [
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.requirements_restore',
              title: 'Restore',
              description: 'Allow restoring deleted requirements.',
              route: '/bin#requirements_restore',
              icon: Icons.restore_rounded,
            ),
            _AdminDrilldownPageConfig(
              key: 'page.recycle_bin.requirements_delete',
              title: 'Delete',
              description: 'Allow deleting requirements.',
              route: '/bin#requirements_delete',
              icon: Icons.delete_forever_outlined,
            ),
          ],
        ),
      ],
    ),
  ];

  static List<_AdminDrilldownPageConfig> _drilldownPagesFor(String role) => switch (role) {
        'Telecaller' => _telecallerPages,
        'Sales' => _salesPages,
        _ => _adminPages,
      };

  /// Key used to remember an expanded row; Admin keeps the plain page key.
  String _expandedRowKey(String role, String key) => role == 'Admin' ? key : '$role:$key';

  List<String> _adminToggleKeys(_AdminDrilldownPageConfig c) => [
        if (!c.isGroup) c.key,
        for (final s in c.subItems) ..._adminToggleKeys(s),
      ];

  List<String> _adminSubToggleKeys(_AdminDrilldownPageConfig c) => [
        for (final s in c.subItems) ..._adminToggleKeys(s),
      ];

  bool _adminConfigMatches(_AdminDrilldownPageConfig c, String search) =>
      c.title.toLowerCase().contains(search) ||
      c.description.toLowerCase().contains(search) ||
      c.route.toLowerCase().contains(search) ||
      c.key.toLowerCase().contains(search);

  bool _adminSubMatches(_AdminDrilldownPageConfig c, String search) =>
      c.subItems.any((s) => _adminConfigMatches(s, search) || _adminSubMatches(s, search));

  int _totalDrilldownPerms(String role) =>
      _drilldownPagesFor(role).fold(0, (n, p) => n + _adminToggleKeys(p).length);

  int _getDrilldownActiveCount(PermissionMatrixService service, String role) {
    int count = 0;
    for (final p in _drilldownPagesFor(role)) {
      for (final k in _adminToggleKeys(p)) {
        if (service.hasPermission(role, k)) count++;
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
    final service = PermissionMatrixService.instance;
    final role = _selectedRoleForDrilldown;
    final roleColor = _getRoleColor(role);
    final activeCount = _getDrilldownActiveCount(service, role);
    final totalPerms = _totalDrilldownPerms(role);

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
              final count = _getDrilldownActiveCount(service, role);
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
                  '$activeCount / $totalPerms Active',
                  style: CRMTypography.captionBold.copyWith(color: roleColor),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: CRMSpacing.m),

        _buildAdminDrilldownView(context, isDark, primary, roleColor, service, isMobile, role),
      ],
    );
  }

  /// Page tree with page, feature and action toggles for [role] (Admin, Telecaller or Sales).
  /// Every toggle reads and writes only [role]'s own value.
  Widget _buildAdminDrilldownView(
    BuildContext context,
    bool isDark,
    Color primary,
    Color roleColor,
    PermissionMatrixService service,
    bool isMobile,
    String role,
  ) {
    final pages = _drilldownPagesFor(role);
    final search = _searchQuery.trim().toLowerCase();
    final filtered = pages.where((p) {
      if (search.isEmpty) return true;
      return _adminConfigMatches(p, search) || _adminSubMatches(p, search);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(context);
    }

    final allRoleKeys = [
      for (final p in pages) ..._adminToggleKeys(p)
    ];
    final allActive = allRoleKeys.every((k) => service.hasPermission(role, k));

    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: CRMCard(
        title: '$role Role Pages & Permissions',
        headerAction: TextButton.icon(
          onPressed: () {
            setState(() {
              for (final k in allRoleKeys) {
                service.setPermission(role, k, !allActive);
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
            if (p.subItems.isNotEmpty) {
              return Column(
                children: [
                  _buildAdminExpandableRow(context, p, isDark, primary, roleColor, service, search, role),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }

            final allowed = service.hasPermission(role, p.key);
            return Column(
              children: [
                SwitchListTile(
                  value: allowed,
                  activeThumbColor: roleColor,
                  onChanged: (val) {
                    setState(() {
                      service.setPermission(role, p.key, val);
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

  Widget _buildAdminExpandableRow(
    BuildContext context,
    _AdminDrilldownPageConfig config,
    bool isDark,
    Color primary,
    Color roleColor,
    PermissionMatrixService service,
    String search,
    String role,
  ) {
    final isAllowed = service.hasPermission(role, config.key);
    final autoExpand = search.isNotEmpty && _adminSubMatches(config, search);
    final expandKey = _expandedRowKey(role, config.key);
    final isExpanded = _expandedAdminRows.contains(expandKey) || autoExpand;

    final subKeys = _adminSubToggleKeys(config);
    final activeSubCount = subKeys.where((k) => service.hasPermission(role, k)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (!_expandedAdminRows.remove(expandKey)) {
                _expandedAdminRows.add(expandKey);
              }
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
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
                              '$activeSubCount/${subKeys.length} sub-options',
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
                if (!config.isGroup)
                  Switch(
                    value: isAllowed,
                    activeThumbColor: roleColor,
                    onChanged: (val) {
                      setState(() {
                        service.setPermission(role, config.key, val);
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
                          Expanded(
                            child: Text(
                              '${config.isGroup ? config.title : config.title.split(' ').first} Sub-Permissions & Component Controls',
                              style: CRMTypography.captionBold.copyWith(
                                color: CRMColors.textSecondaryOf(context),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      ...config.subItems.map((sub) {
                        final isSubAllowed = service.hasPermission(role, sub.key);
                        final isLastSub = sub == config.subItems.last;
                        return Column(
                          children: [
                            _buildAdminSubToggle(context, sub, isSubAllowed, primary, roleColor, service, role),
                            if (sub.subItems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 40, bottom: 4),
                                child: Column(
                                  children: sub.subItems
                                      .map((child) => _buildAdminSubToggle(
                                            context,
                                            child,
                                            service.hasPermission(role, child.key),
                                            primary,
                                            roleColor,
                                            service,
                                            role,
                                          ))
                                      .toList(),
                                ),
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

  Widget _buildAdminSubToggle(
    BuildContext context,
    _AdminDrilldownPageConfig sub,
    bool isSubAllowed,
    Color primary,
    Color roleColor,
    PermissionMatrixService service,
    String role,
  ) {
    if (sub.isGroup) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(sub.icon, color: roleColor, size: 17),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.title,
                    style: CRMTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CRMColors.textOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub.description,
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SwitchListTile(
                              value: isSubAllowed,
                              activeThumbColor: roleColor,
                              onChanged: (val) {
                                setState(() {
                                  service.setPermission(role, sub.key, val);
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
                                  Flexible(
                                    child: Text(
                                      sub.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: CRMTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: CRMColors.textOf(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        sub.route,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                          color: primary,
                                        ),
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

    // Page structure stored in the database (synced from AppNavigationRegistry)
    final navPages = NavigationPagesService.instance;
    var navTree = navPages.treeForRole(_simulatorRole);

    // Dynamic search filtering across routes, keys, and nested subpages
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      bool matches(AppNavItem i) =>
          i.title.toLowerCase().contains(q) ||
          i.route.toLowerCase().contains(q) ||
          i.key.toLowerCase().contains(q) ||
          i.children.any(matches);
      navTree = navTree.where(matches).toList();
    }

    final totalRoutesAndSubpages = navTree.fold<int>(
      0,
      (sum, item) => sum + 1 + item.descendantCount,
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
              const SizedBox(height: CRMSpacing.s),
              _buildNavigationSourceStatus(context, navPages),
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

  Widget _buildNavigationSourceStatus(BuildContext context, NavigationPagesService navPages) {
    final String label;
    final Color color;
    if (navPages.isLoading && !navPages.hasDatabasePages) {
      label = 'Loading page structure from the database...';
      color = CRMColors.textSecondaryOf(context);
    } else if (navPages.hasDatabasePages) {
      final at = navPages.loadedAt;
      final time = at == null
          ? ''
          : ' at ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
      label = 'Page structure from database: ${navPages.pages!.length} pages, synced$time'
          '${navPages.error != null ? ' (latest sync failed, showing stored pages)' : ''}';
      color = navPages.error != null ? const Color(0xFFD97706) : CRMColors.success;
    } else {
      label = 'Database page structure unavailable, showing the in-app page registry.';
      color = const Color(0xFFD97706);
    }
    return Row(
      children: [
        Icon(Icons.storage_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: CRMTypography.caption.copyWith(color: color, fontSize: 11.5)),
        ),
        IconButton(
          tooltip: 'Refresh page structure',
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          onPressed: navPages.isLoading ? null : _syncNavigationPages,
          icon: navPages.isLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  /// Nested pages of [item] at every depth (parents first) with their depth below [item].
  List<(AppNavItem, int)> _nestedPagesOf(AppNavItem item) {
    final out = <(AppNavItem, int)>[];
    void walk(AppNavItem node, int depth) {
      for (final c in node.children) {
        out.add((c, depth));
        walk(c, depth + 1);
      }
    }
    walk(item, 1);
    return out;
  }

  /// Permission keys of [item] and its ancestors down to (excluding) [child], used to spot
  /// nested pages that are gated by an ancestor's permission rather than their own.
  bool _inheritsAncestorPermission(AppNavItem root, AppNavItem child) {
    final byKey = {root.key: root, for (final (n, _) in _nestedPagesOf(root)) n.key: n};
    var parentKey = child.parentKey;
    while (parentKey != null) {
      final parent = byKey[parentKey];
      if (parent == null) break;
      if (parent.effectivePermissionKey == child.effectivePermissionKey) return true;
      parentKey = parent.parentKey;
    }
    return false;
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
                : (service.hasPermission(_simulatorRole, item.effectivePermissionKey) &&
                   service.canViewRoute(_simulatorRole, item.route));
            final visibleByKey = <String, bool>{item.key: visible};

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
                        children: _nestedPagesOf(item).map((entry) {
                          final (child, depth) = entry;
                          final childVisible = isSuper
                              ? true
                              : ((visibleByKey[child.parentKey] ?? visible) &&
                                 service.hasPermission(_simulatorRole, child.effectivePermissionKey) &&
                                 service.canViewRoute(_simulatorRole, child.route));
                          visibleByKey[child.key] = childVisible;

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: childVisible ? 1.0 : 0.35,
                            child: Container(
                              margin: EdgeInsets.only(bottom: 2, left: 14.0 * (depth - 1)),
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
              : (service.hasPermission(_simulatorRole, item.effectivePermissionKey) &&
                 service.canViewRoute(_simulatorRole, item.route));
          final allowedByKey = <String, bool>{item.key: isParentAllowed};

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
                                    '${item.descendantCount} SUBPAGES',
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
                            'Route: ${item.route} • Metric: ${item.effectivePermissionKey}',
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
                        value: service.hasPermission(_simulatorRole, item.effectivePermissionKey),
                        activeThumbColor: roleColor,
                        onChanged: (val) {
                          setState(() {
                            service.setPermission(_simulatorRole, item.effectivePermissionKey, val);
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
                      children: _nestedPagesOf(item).map((entry) {
                        final (child, depth) = entry;
                        final isAncestorAllowed = allowedByKey[child.parentKey] ?? isParentAllowed;
                        final isChildAllowed = isSuper
                            ? true
                            : (isAncestorAllowed &&
                               service.hasPermission(_simulatorRole, child.effectivePermissionKey));
                        allowedByKey[child.key] = isChildAllowed;
                        final inheritsPermission = _inheritsAncestorPermission(item, child);

                        return Container(
                          margin: EdgeInsets.only(bottom: 4, left: 16.0 * (depth - 1)),
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
                                      'Route: ${child.route} • Metric: ${child.effectivePermissionKey}',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontFamily: 'monospace',
                                        color: CRMColors.textSecondaryOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isSuper && inheritsPermission)
                                Tooltip(
                                  message: 'Controlled by the parent page permission',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'INHERITED',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                )
                              else if (!isSuper)
                                Switch(
                                  value: isAncestorAllowed &&
                                      service.hasPermission(_simulatorRole, child.effectivePermissionKey),
                                  activeThumbColor: roleColor,
                                  onChanged: isAncestorAllowed
                                      ? (val) {
                                          setState(() {
                                            service.setPermission(_simulatorRole, child.effectivePermissionKey, val);
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


/// Toggle keys shown in the Role Drill-down tree of [role] (group headings excluded).
@visibleForTesting
List<String> roleDrilldownToggleKeys(String role) {
  List<String> collect(_AdminDrilldownPageConfig c) => [
        if (!c.isGroup) c.key,
        for (final s in c.subItems) ...collect(s),
      ];
  return [for (final p in _PermissionMatrixCardState._drilldownPagesFor(role)) ...collect(p)];
}

class _AdminDrilldownPageConfig {
  final String key;
  final String title;
  final String description;
  final String route;
  final IconData icon;
  final List<_AdminDrilldownPageConfig> subItems;

  /// A heading-only row (no toggle of its own) that groups its [subItems].
  final bool isGroup;

  const _AdminDrilldownPageConfig({
    required this.key,
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    this.subItems = const [],
    this.isGroup = false,
  });
}
