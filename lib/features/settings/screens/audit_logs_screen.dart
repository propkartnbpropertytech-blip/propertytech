import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../models/audit_log_model.dart';
import '../services/audit_logs_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AuditLogsService _service = AuditLogsService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _isLoadingHierarchy = true;
  String? _errorMessage;

  AuditLogsResponse? _logsResponse;
  UsersHierarchyResponse _hierarchy = const UsersHierarchyResponse();

  // Filters
  String _selectedRole = 'All'; // 'All', 'Admin', 'Telecaller', 'Sales'
  String _selectedAdminId = 'All';
  String _selectedUserId = 'All';
  String _selectedAction = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  static const int _pageSize = 40;

  @override
  void initState() {
    super.initState();
    _loadHierarchy();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHierarchy() async {
    setState(() => _isLoadingHierarchy = true);
    try {
      final res = await _service.fetchUsersHierarchy();
      if (mounted) {
        setState(() {
          _hierarchy = res;
          _isLoadingHierarchy = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHierarchy = false);
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.fetchAuditLogs(
        role: _selectedRole,
        userId: _selectedUserId,
        adminId: _selectedAdminId,
        action: _selectedAction,
        search: _searchController.text,
        startDate: _startDate,
        endDate: _endDate,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _logsResponse = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      _selectedAdminId = 'All';
      _selectedUserId = 'All';
      _currentPage = 1;
    });
    _loadLogs();
  }

  void _onAdminFilterChanged(String? adminId) {
    setState(() {
      _selectedAdminId = adminId ?? 'All';
      _selectedUserId = 'All';
      _currentPage = 1;
    });
    _loadLogs();
  }

  void _onUserFilterChanged(String? userId) {
    setState(() {
      _selectedUserId = userId ?? 'All';
      _currentPage = 1;
    });
    _loadLogs();
  }

  void _onActionCategoryChanged(String action) {
    setState(() {
      _selectedAction = action;
      _currentPage = 1;
    });
    _loadLogs();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _currentPage = 1);
      _loadLogs();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        _currentPage = 1;
      });
      _loadLogs();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = CRMColors.primaryOf(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'User Audit & Behavioral Logs',
          style: CRMTypography.sectionTitle.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: CRMColors.cardBgOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: CRMColors.shadow,
        iconTheme: IconThemeData(color: CRMColors.textOf(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Logs',
            onPressed: () {
              _loadHierarchy();
              _loadLogs();
            },
          ),
          const SizedBox(width: CRMSpacing.m),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadHierarchy();
          await _loadLogs();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Super Administrator Telemetry Intelligence',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Individual User Audit Trails & Granular Telemetry',
                style: CRMTypography.pageTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              _buildRoleTabBar(context, isDark, primaryColor),
              const SizedBox(height: CRMSpacing.m),
              _buildUserHierarchySelector(context, isDark, primaryColor),
              const SizedBox(height: CRMSpacing.m),
              _buildActionCategoryChips(context, isDark, primaryColor),
              const SizedBox(height: CRMSpacing.m),
              _buildSearchAndDateControls(context, isDark, primaryColor),
              const SizedBox(height: CRMSpacing.l),
              if (_logsResponse?.stats != null) ...[
                _buildMetricsBanner(context, _logsResponse!.stats, isDark),
                const SizedBox(height: CRMSpacing.l),
              ],
              if (_isLoading)
                _buildLoadingSkeleton()
              else if (_errorMessage != null)
                _buildErrorState(_errorMessage!)
              else if (_logsResponse?.logs.isEmpty ?? true)
                _buildEmptyState()
              else
                _buildLogsList(context, _logsResponse!.logs, isDark),
              const SizedBox(height: CRMSpacing.l),
              if (_logsResponse != null && _logsResponse!.totalPages > 1)
                _buildPaginationControls(context, _logsResponse!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTabBar(BuildContext context, bool isDark, Color primaryColor) {
    final roles = [
      {'key': 'All', 'label': 'All Roles', 'icon': Icons.group_work_outlined},
      {'key': 'Admin', 'label': 'Admins', 'icon': Icons.admin_panel_settings_outlined},
      {'key': 'Telecaller', 'label': 'Telecallers', 'icon': Icons.headset_mic_outlined},
      {'key': 'Sales', 'label': 'Sales Executives', 'icon': Icons.badge_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((r) {
          final isSelected = _selectedRole == r['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                r['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
              ),
              label: Text(r['label'] as String),
              selected: isSelected,
              onSelected: (_) => _onRoleChanged(r['key'] as String),
              selectedColor: primaryColor,
              backgroundColor: CRMColors.cardBgOf(context),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : CRMColors.textOf(context),
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? primaryColor : CRMColors.borderOf(context).withOpacity(0.6),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserHierarchySelector(BuildContext context, bool isDark, Color primaryColor) {
    return CRMCard(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_search_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  _getUserSelectorTitle(),
                  style: CRMTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: CRMColors.textOf(context),
                  ),
                ),
                const Spacer(),
                if (_selectedUserId != 'All' || _selectedAdminId != 'All')
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedAdminId = 'All';
                        _selectedUserId = 'All';
                        _currentPage = 1;
                      });
                      _loadLogs();
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Reset Users'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: CRMSpacing.s),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_selectedRole == 'Telecaller' || _selectedRole == 'Sales')
                  SizedBox(
                    width: 260,
                    child: _buildAdminTeamDropdown(context),
                  ),
                SizedBox(
                  width: 320,
                  child: _buildSpecificUserDropdown(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getUserSelectorTitle() {
    switch (_selectedRole) {
      case 'Admin':
        return 'Filter by Specific Admin';
      case 'Telecaller':
        return 'Filter Telecaller & Managing Admin';
      case 'Sales':
        return 'Filter Sales Executive & Managing Admin';
      case 'All':
      default:
        return 'Target User Activity Filter';
    }
  }

  Widget _buildAdminTeamDropdown(BuildContext context) {
    final admins = _hierarchy.admins;
    return DropdownButtonFormField<String>(
      value: _selectedAdminId,
      decoration: InputDecoration(
        labelText: 'Managing Admin Team',
        labelStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: CRMColors.cardBgOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CRMColors.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.7)),
        ),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: 'All', child: Text('All Admin Teams')),
        ...admins.map((a) => DropdownMenuItem(
              value: a.id,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: _onAdminFilterChanged,
    );
  }

  Widget _buildSpecificUserDropdown(BuildContext context) {
    List<UserHierarchyItem> users;
    String label;

    if (_selectedRole == 'Admin') {
      users = _hierarchy.admins;
      label = 'Select Admin';
    } else if (_selectedRole == 'Telecaller') {
      users = _hierarchy.telecallers;
      if (_selectedAdminId != 'All') {
        users = users.where((t) => t.adminId == _selectedAdminId).toList();
      }
      label = 'Select Telecaller';
    } else if (_selectedRole == 'Sales') {
      users = _hierarchy.salesUsers;
      if (_selectedAdminId != 'All') {
        users = users.where((s) => s.adminId == _selectedAdminId).toList();
      }
      label = 'Select Sales User';
    } else {
      users = _hierarchy.allUsers;
      label = 'Select Any Team Member';
    }

    final hasCurrent = _selectedUserId == 'All' || users.any((u) => u.id == _selectedUserId);
    final safeValue = hasCurrent ? _selectedUserId : 'All';

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: CRMColors.cardBgOf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CRMColors.borderOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.7)),
        ),
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem(value: 'All', child: Text('All ( members)')),
        ...users.map((u) {
          final subtitle = u.adminName != null && u.adminName!.isNotEmpty && u.adminName != 'Unassigned'
              ? ' • Under '
              : '';
          return DropdownMenuItem(
            value: u.id,
            child: Text(
              ' ()',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: _onUserFilterChanged,
    );
  }

  Widget _buildActionCategoryChips(BuildContext context, bool isDark, Color primaryColor) {
    final categories = [
      {'key': 'All', 'label': 'All Activities', 'icon': Icons.all_inclusive_rounded},
      {'key': 'PAGE_VIEW', 'label': 'Page Visits', 'icon': Icons.explore_outlined},
      {'key': 'PROPERTY_TOUCH', 'label': 'Property Touches', 'icon': Icons.touch_app_outlined},
      {'key': 'PROPERTY_SHARE', 'label': 'Property Shares', 'icon': Icons.share_outlined},
      {'key': 'BUTTON_CLICK', 'label': 'Button Presses', 'icon': Icons.smart_button_outlined},
      {'key': 'SEARCH', 'label': 'Searches', 'icon': Icons.search_rounded},
      {'key': 'HOVER_DWELL', 'label': 'Hover & Dwell', 'icon': Icons.timer_outlined},
      {'key': 'MUTATION', 'label': 'Data Changes', 'icon': Icons.edit_note_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedAction == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              avatar: Icon(
                cat['icon'] as IconData,
                size: 15,
                color: isSelected ? primaryColor : CRMColors.textSecondaryOf(context),
              ),
              label: Text(cat['label'] as String),
              selected: isSelected,
              onSelected: (_) => _onActionCategoryChanged(cat['key'] as String),
              selectedColor: primaryColor.withOpacity(0.15),
              backgroundColor: CRMColors.cardBgOf(context),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : CRMColors.textOf(context),
              ),
              side: BorderSide(
                color: isSelected ? primaryColor : CRMColors.borderOf(context).withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndDateControls(BuildContext context, bool isDark, Color primaryColor) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final hasDateFilter = _startDate != null && _endDate != null;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search description, path, user, IP, action payload...',
              hintStyle: TextStyle(fontSize: 13, color: CRMColors.textMutedOf(context)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadLogs();
                      },
                    )
                  : null,
              filled: true,
              fillColor: CRMColors.cardBgOf(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: CRMColors.borderOf(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: CRMSpacing.m),
        OutlinedButton.icon(
          onPressed: _pickDateRange,
          icon: Icon(Icons.date_range_outlined, size: 18, color: hasDateFilter ? primaryColor : null),
          label: Text(
            hasDateFilter
                ? ' - '
                : 'Date Range',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: hasDateFilter ? FontWeight.bold : FontWeight.normal,
              color: hasDateFilter ? primaryColor : CRMColors.textOf(context),
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            backgroundColor: hasDateFilter ? primaryColor.withOpacity(0.08) : CRMColors.cardBgOf(context),
            side: BorderSide(color: hasDateFilter ? primaryColor : CRMColors.borderOf(context)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (hasDateFilter) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Clear Date Filter',
            onPressed: _clearDateRange,
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsBanner(BuildContext context, AuditTelemetryStats stats, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 900
            ? (constraints.maxWidth - (5 * 12)) / 6
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard(context, 'Total Events', stats.total, Icons.analytics_outlined, const Color(0xFF6366F1), cardWidth),
            _buildMetricCard(context, 'Page Views', stats.pageViews, Icons.explore_outlined, const Color(0xFF3B82F6), cardWidth),
            _buildMetricCard(context, 'Property Touches', stats.propertyTouches, Icons.touch_app_outlined, const Color(0xFF10B981), cardWidth),
            _buildMetricCard(context, 'Property Shares', stats.propertyShares, Icons.share_outlined, const Color(0xFF14B8A6), cardWidth),
            _buildMetricCard(context, 'Searches', stats.searches, Icons.search_rounded, const Color(0xFFF59E0B), cardWidth),
            _buildMetricCard(context, 'Hover Dwells', stats.dwells, Icons.timer_outlined, const Color(0xFFEC4899), cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, int count, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: CRMColors.textSecondaryOf(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<AuditLogModel> logs, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: CRMSpacing.s),
      itemBuilder: (context, index) => _buildLogCard(context, logs[index], isDark),
    );
  }

  Widget _buildLogCard(BuildContext context, AuditLogModel log, bool isDark) {
    final roleColor = _getRoleBadgeColor(log.userRole);
    final actionStyle = _getActionBadgeStyle(log.action, log.dwellMs);
    final formattedDate = DateFormat.yMMMd().add_jm().format(log.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: roleColor.withOpacity(0.15),
                child: Text(
                  (log.userName != null && log.userName!.isNotEmpty)
                      ? log.userName![0].toUpperCase()
                      : '?',
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            log.userName ?? 'System / Anonymous',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.userRole ?? 'Unknown Role',
                            style: TextStyle(color: roleColor, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (log.userEmail != null && log.userEmail!.isNotEmpty)
                      Text(
                        log.userEmail!,
                        style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                      ),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 11.5, color: CRMColors.textMutedOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionStyle.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionStyle.icon, size: 14, color: actionStyle.color),
                    const SizedBox(width: 5),
                    Text(
                      actionStyle.label,
                      style: TextStyle(
                        color: actionStyle.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: CRMColors.borderOf(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.module,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
              ),
              if (log.path != null && log.path!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.path!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      color: CRMColors.textMutedOf(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.description ?? ' on ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: CRMColors.textOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (log.ipAddress != null && log.ipAddress!.isNotEmpty) ...[
                Icon(Icons.language_rounded, size: 13, color: CRMColors.textMutedOf(context)),
                const SizedBox(width: 4),
                Text(
                  log.ipAddress!,
                  style: TextStyle(fontSize: 11, color: CRMColors.textMutedOf(context)),
                ),
                const SizedBox(width: 12),
              ],
              if (log.userAgent != null && log.userAgent!.isNotEmpty) ...[
                Icon(Icons.devices_rounded, size: 13, color: CRMColors.textMutedOf(context)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _formatUserAgent(log.userAgent!),
                    style: TextStyle(fontSize: 11, color: CRMColors.textMutedOf(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              if (log.details != null || log.oldData != null || log.newData != null)
                TextButton.icon(
                  onPressed: () => _showLogDetailsDialog(context, log),
                  icon: const Icon(Icons.code_rounded, size: 14),
                  label: const Text('View Raw Payload'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 11.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, AuditLogsResponse res) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page  of   •   total activities',
          style: TextStyle(fontSize: 12.5, color: CRMColors.textSecondaryOf(context)),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: res.page > 1
                  ? () {
                      setState(() => _currentPage--);
                      _loadLogs();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Previous'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: res.page < res.totalPages
                  ? () {
                      setState(() => _currentPage++);
                      _loadLogs();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogDetailsDialog(BuildContext context, AuditLogModel log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_object_rounded, size: 20),
            const SizedBox(width: 8),
            Text('Telemetry Payload: ', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPayloadSection('Event Name', log.eventName ?? 'N/A'),
                _buildPayloadSection('Record Type & ID', ' #'),
                if (log.dwellMs > 0)
                  _buildPayloadSection('Dwell Duration', ' seconds ( ms)'),
                if (log.details != null)
                  _buildJsonBlock('Details Payload', log.details!),
                if (log.oldData != null)
                  _buildJsonBlock('Previous State (old_data)', log.oldData),
                if (log.newData != null)
                  _buildJsonBlock('New State (new_data)', log.newData),
                if (log.sessionId != null)
                  _buildPayloadSection('Session ID', log.sessionId!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPayloadSection(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(val, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildJsonBlock(String title, dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    final formatted = encoder.convert(data);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: SelectableText(
              formatted,
              style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleBadgeColor(String? role) {
    final r = (role ?? '').toLowerCase();
    if (r.contains('super')) return const Color(0xFF2563EB);
    if (r.contains('admin')) return const Color(0xFF7C3AED);
    if (r.contains('telecaller')) return const Color(0xFF0D9488);
    if (r.contains('sales')) return const Color(0xFFEA580C);
    return const Color(0xFF64748B);
  }

  _ActionStyle _getActionBadgeStyle(String action, int dwellMs) {
    switch (action) {
      case 'PAGE_VIEW':
      case 'Navigation':
        return _ActionStyle('Page Visit', Icons.explore_outlined, const Color(0xFF2563EB));
      case 'PROPERTY_TOUCH':
      case 'Property Click':
      case 'View Details':
      case 'Inspect Photos':
        return _ActionStyle('Property Touch', Icons.touch_app_outlined, const Color(0xFF10B981));
      case 'PROPERTY_SHARE':
      case 'WhatsApp Share':
      case 'Share':
        return _ActionStyle('Property Share', Icons.share_outlined, const Color(0xFF059669));
      case 'BUTTON_CLICK':
      case 'Button Click':
      case 'Action Pressed':
        return _ActionStyle('Button Press', Icons.smart_button_outlined, const Color(0xFF9333EA));
      case 'SEARCH':
      case 'Search':
        return _ActionStyle('Search Query', Icons.search_rounded, const Color(0xFF0284C7));
      case 'HOVER_DWELL':
        final sec = (dwellMs / 1000).toStringAsFixed(1);
        return _ActionStyle('Dwell s', Icons.timer_outlined, const Color(0xFFD97706));
      case 'Create':
        return _ActionStyle('Created Record', Icons.add_circle_outline, const Color(0xFF16A34A));
      case 'Update':
        return _ActionStyle('Updated Record', Icons.edit_outlined, const Color(0xFFCA8A04));
      case 'Delete':
        return _ActionStyle('Deleted Record', Icons.delete_outline, const Color(0xFFDC2626));
      default:
        return _ActionStyle(action, Icons.history_rounded, const Color(0xFF64748B));
    }
  }

  String _formatUserAgent(String ua) {
    if (ua.contains('Chrome')) return 'Chrome / Web';
    if (ua.contains('Safari')) return 'Safari';
    if (ua.contains('Firefox')) return 'Firefox';
    if (ua.contains('Edge')) return 'Edge';
    if (ua.contains('Dart') || ua.contains('Flutter')) return 'Mobile / App';
    return ua.length > 25 ? '...' : ua;
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: CRMSpacing.m),
          child: CRMSkeletonCard(height: 90),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Failed to load audit logs', style: CRMTypography.sectionTitle),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: CRMColors.textSecondaryOf(context))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadLogs, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 54, color: CRMColors.textMutedOf(context)),
            const SizedBox(height: 12),
            Text(
              'No telemetry logs match this filter',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing the role tab, selecting a different team member, or clearing your search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CRMColors.textSecondaryOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionStyle {
  final String label;
  final IconData icon;
  final Color color;
  _ActionStyle(this.label, this.icon, this.color);
}
