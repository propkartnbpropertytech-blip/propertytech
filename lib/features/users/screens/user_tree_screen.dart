import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/network/sync_manager.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/security/role_guard.dart';

/// Super Admin view of the employee hierarchy: Administrators → Telecallers / Salespersons.
/// Built from live `/users` records using each employee's `admin_id` (falling back to `created_by`).
class UserTreeScreen extends StatefulWidget {
  const UserTreeScreen({super.key});

  @override
  State<UserTreeScreen> createState() => _UserTreeScreenState();
}

class _TreeUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? adminId;
  final String? createdBy;

  const _TreeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.adminId,
    this.createdBy,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isTelecaller => role.toLowerCase().contains('telecaller');
  bool get isSales => role.toLowerCase() == 'sales' || role.toLowerCase() == 'salesperson';

  factory _TreeUser.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    final role = (roles is Map ? roles['name'] : null) ?? json['role_name'] ?? json['role'] ?? '';
    String? clean(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty || s == 'null' ? null : s;
    }

    return _TreeUser(
      id: json['id']?.toString() ?? '',
      name: clean(json['full_name']) ?? clean(json['email']) ?? 'User',
      email: clean(json['email']) ?? '',
      role: role.toString(),
      isActive: json['is_active'] != false,
      adminId: clean(json['admin_id']),
      createdBy: clean(json['created_by']),
    );
  }
}

class _AdminBranch {
  final _TreeUser admin;
  final List<_TreeUser> telecallers;
  final List<_TreeUser> salespersons;
  _AdminBranch(this.admin, {List<_TreeUser>? telecallers, List<_TreeUser>? salespersons})
    : telecallers = telecallers ?? [],
      salespersons = salespersons ?? [];
}

class _UserTreeScreenState extends State<UserTreeScreen> {
  bool _isLoading = true;
  String? _error;
  List<_AdminBranch> _branches = [];
  List<_TreeUser> _unlinked = [];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Set<String>? _serverMatchIds;
  int _treeSearchRequest = 0;
  Timer? _treeSearchDebounce;
  StreamSubscription<Set<String>>? _treeRefreshSub;
  String _view = 'tree';
  final TransformationController _graphController = TransformationController();
  final GlobalKey _graphContentKey = GlobalKey();
  final GlobalKey _graphViewportKey = GlobalKey();

  static const _adminColor = Color(0xFF7C3AED);
  static const _telecallerColor = Color(0xFF0284C7);
  static const _salesColor = Color(0xFF059669);
  static const _matchColor = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _treeRefreshSub = SyncManager().tableChanges.listen((tables) {
      if (!mounted || _query.isEmpty) return;
      if (tables.contains('users')) _fetchTreeSearch(_query);
    });
    _loadTree();
  }

  @override
  void dispose() {
    _treeSearchDebounce?.cancel();
    _treeRefreshSub?.cancel();
    _searchController.dispose();
    _graphController.dispose();
    super.dispose();
  }

  /// Admins see only their own branch; `/users` is already scoped server-side to the caller's employees.
  bool get _isAdminView => !RoleGuard.isSuperAdmin(RoleGuard.currentUser?.role);

  bool get _isSearching => _query.isNotEmpty;

  bool _matches(_TreeUser u) => _isSearching && (_serverMatchIds?.contains(u.id) ?? false);

  /// Branches visible for the current search: an Administrator whose name matches keeps all
  /// employees; otherwise only matching employees are kept, and empty branches are hidden.
  List<_AdminBranch> get _visibleBranches {
    if (!_isSearching) return _branches;
    final out = <_AdminBranch>[];
    for (final b in _branches) {
      if (_matches(b.admin)) {
        out.add(b);
        continue;
      }
      final tc = b.telecallers.where(_matches).toList();
      final sp = b.salespersons.where(_matches).toList();
      if (tc.isNotEmpty || sp.isNotEmpty) out.add(_AdminBranch(b.admin, telecallers: tc, salespersons: sp));
    }
    return out;
  }

  List<_TreeUser> get _visibleUnlinked => _isSearching ? _unlinked.where(_matches).toList() : _unlinked;

  int get _matchCount {
    var n = 0;
    for (final b in _branches) {
      if (_matches(b.admin)) n++;
      n += b.telecallers.where(_matches).length + b.salespersons.where(_matches).length;
    }
    return n + _unlinked.where(_matches).length;
  }

  void _onSearchChanged(String value) {
    final next = value.trim();
    setState(() => _query = next.toLowerCase());
    _treeSearchDebounce?.cancel();
    _treeSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      _fetchTreeSearch(next);
    });
    if (_view == 'graph') _fitGraph();
  }

  Future<void> _fetchTreeSearch(String raw) async {
    final request = ++_treeSearchRequest;
    if (raw.trim().isEmpty) {
      if (!mounted || request != _treeSearchRequest) return;
      setState(() => _serverMatchIds = null);
      return;
    }
    if (mounted) setState(() => _serverMatchIds = null);
    try {
      final res = await DioClient.dio.get('/users', queryParameters: {'search': raw.trim(), 'limit': '200'});
      if (!mounted || request != _treeSearchRequest) return;
      final data = res.data is Map ? res.data['data'] : null;
      final rawList = data is Map && data['users'] is List ? data['users'] as List : (data is List ? data : const []);
      final ids = rawList
          .whereType<Map>()
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      setState(() => _serverMatchIds = ids);
    } catch (_) {
      if (!mounted || request != _treeSearchRequest) return;
      setState(() => _serverMatchIds = {});
    }
  }

  Future<void> _loadTree() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await DioClient.dio.get('/users');
      final data = res.data is Map ? res.data['data'] : null;
      final rawList = data is Map && data['users'] is List ? data['users'] as List : (data is List ? data : const []);
      final users = rawList
          .whereType<Map>()
          .map((e) => _TreeUser.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.id.isNotEmpty)
          .toList();

      int byName(_TreeUser a, _TreeUser b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());

      if (_isAdminView) {
        final me = RoleGuard.currentUser;
        final myIds = {me?.id, me?.adminId}.whereType<String>().where((s) => s.isNotEmpty).toSet();
        final self = users.firstWhere(
          (u) => u.id == me?.id,
          orElse: () => _TreeUser(
            id: me?.id ?? '',
            name: (me?.fullName.trim().isNotEmpty ?? false) ? me!.fullName.trim() : 'Administrator',
            email: me?.email ?? '',
            role: 'Admin',
            isActive: true,
          ),
        );
        final branch = _AdminBranch(self);
        for (final u in users.where((u) => (u.isTelecaller || u.isSales) && u.id != self.id)) {
          if (myIds.contains(u.adminId) || myIds.contains(u.createdBy)) {
            (u.isTelecaller ? branch.telecallers : branch.salespersons).add(u);
          }
        }
        branch.telecallers.sort(byName);
        branch.salespersons.sort(byName);
        if (!mounted) return;
        setState(() {
          _branches = [branch];
          _unlinked = [];
          _isLoading = false;
        });
        if (_view == 'graph') _fitGraph();
        return;
      }

      final branches = <String, _AdminBranch>{};
      for (final u in users.where((u) => u.isAdmin)) {
        branches[u.id] = _AdminBranch(u);
      }
      final unlinked = <_TreeUser>[];
      for (final u in users.where((u) => u.isTelecaller || u.isSales)) {
        final ownerId = branches.containsKey(u.adminId)
            ? u.adminId
            : (branches.containsKey(u.createdBy) ? u.createdBy : null);
        if (ownerId == null) {
          unlinked.add(u);
          continue;
        }
        final branch = branches[ownerId]!;
        (u.isTelecaller ? branch.telecallers : branch.salespersons).add(u);
      }

      final sorted = branches.values.toList()..sort((a, b) => byName(a.admin, b.admin));
      for (final b in sorted) {
        b.telecallers.sort(byName);
        b.salespersons.sort(byName);
      }
      unlinked.sort(byName);

      if (!mounted) return;
      setState(() {
        _branches = sorted;
        _unlinked = unlinked;
        _isLoading = false;
      });
      if (_view == 'graph') _fitGraph();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load the user tree. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final superAdminName = RoleGuard.currentUser?.fullName.trim().isNotEmpty == true
        ? RoleGuard.currentUser!.fullName.trim()
        : 'Super Admin';

    return RefreshIndicator(
      onRefresh: _loadTree,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: LayoutBuilder(
              builder: (context, constraints) => _buildPageBody(superAdminName, isMobile, constraints.maxWidth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageBody(String superAdminName, bool isMobile, double contentWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CRMPageHeader(
          title: _isAdminView ? 'Employee Tree' : 'User Tree',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isLoading ? null : _loadTree,
                icon: const Icon(Icons.refresh_rounded),
              ),
              TextButton.icon(
                onPressed: () => context.go('/users'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(_isAdminView ? 'Employees' : 'Users'),
              ),
            ],
          ),
        ),
        const SizedBox(height: CRMSpacing.m),
        _buildLegend(),
        const SizedBox(height: CRMSpacing.m),
        _buildToolbar(isMobile),
        const SizedBox(height: CRMSpacing.m),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _buildMessage(_error!, isError: true)
        else if (_isSearching && _visibleBranches.isEmpty && _visibleUnlinked.isEmpty)
          _buildMessage('No user found matching "${_searchController.text.trim()}".')
        else if (_view == 'graph')
          _buildGraphView(superAdminName, isMobile)
        else if (_isAdminView)
          _buildAdminTreeRoot(contentWidth)
        else
          _buildRootCard(superAdminName, contentWidth),
      ],
    );
  }

  Widget _buildAdminTreeRoot(double contentWidth) {
    if (_visibleBranches.isEmpty) return const SizedBox.shrink();
    return _buildAdminNode(_visibleBranches.first, contentWidth: contentWidth, initiallyExpanded: true);
  }

  Widget _buildLegend() {
    Widget item(IconData icon, String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: CRMColors.textMutedOf(context))),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(Icons.admin_panel_settings_rounded, 'Administrator', _adminColor),
        item(Icons.support_agent_rounded, 'Telecaller', _telecallerColor),
        item(Icons.badge_rounded, 'Salesperson', _salesColor),
      ],
    );
  }

  Widget _buildToolbar(bool isMobile) {
    final search = TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search user by name...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    final viewSwitch = SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'tree', icon: Icon(Icons.account_tree_outlined, size: 18), label: Text('Tree')),
        ButtonSegment(value: 'graph', icon: Icon(Icons.hub_outlined, size: 18), label: Text('Graph Tree')),
      ],
      selected: {_view},
      showSelectedIcon: false,
      onSelectionChanged: (s) {
        setState(() => _view = s.first);
        if (_view == 'graph') _fitGraph();
      },
    );
    final matchInfo = _isSearching
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$_matchCount user${_matchCount == 1 ? '' : 's'} found',
              style: TextStyle(fontSize: 12, color: CRMColors.textMutedOf(context)),
            ),
          )
        : const SizedBox.shrink();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          matchInfo,
          const SizedBox(height: 10),
          Center(child: viewSwitch),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 16),
            viewSwitch,
          ],
        ),
        matchInfo,
      ],
    );
  }

  Widget _buildMessage(String text, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: isError ? CRMColors.danger : CRMColors.textMutedOf(context)),
          ),
          if (isError) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadTree, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }

  /// Telecallers and Salespersons groups: side by side on wide (laptop/desktop) screens, stacked on narrow ones.
  Widget _buildGroupsLayout(List<_TreeUser> telecallers, List<_TreeUser> salespersons, double contentWidth) {
    final groups = <Widget>[
      if (!_isSearching || telecallers.isNotEmpty)
        _buildGroup('Telecallers', Icons.support_agent_rounded, _telecallerColor, telecallers),
      if (!_isSearching || salespersons.isNotEmpty)
        _buildGroup('Salespersons', Icons.badge_rounded, _salesColor, salespersons),
    ];
    if (contentWidth >= 900 && groups.length > 1) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < groups.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: groups[i])],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i++) ...[if (i > 0) const SizedBox(height: 6), groups[i]],
      ],
    );
  }

  Widget _buildRootCard(String superAdminName, double contentWidth) {
    return Container(
      decoration: BoxDecoration(
        color: CRMColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      padding: const EdgeInsets.all(CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                child: const Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      superAdminName,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                    ),
                    Text(
                      'Super Admin · ${_branches.length} Administrator${_branches.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: CRMColors.textMutedOf(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          if (_branches.isEmpty && _unlinked.isEmpty)
            _buildMessage('No Administrators found.')
          else
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: CRMColors.borderOf(context), width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final branch in _visibleBranches) _buildAdminNode(branch, contentWidth: contentWidth),
                    if (_visibleUnlinked.isNotEmpty) _buildUnlinkedNode(_visibleUnlinked, contentWidth),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminNode(_AdminBranch branch, {required double contentWidth, bool initiallyExpanded = false}) {
    final total = branch.telecallers.length + branch.salespersons.length;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _adminColor.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(_isSearching ? 'admin_${branch.admin.id}_search_$_query' : 'admin_${branch.admin.id}'),
        initiallyExpanded: initiallyExpanded || _isSearching,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _adminColor.withValues(alpha: 0.12),
          child: const Icon(Icons.admin_panel_settings_rounded, color: _adminColor, size: 18),
        ),
        title: _buildNameLine(branch.admin, fontWeight: FontWeight.bold),
        subtitle: Text(
          'Administrator · ${branch.telecallers.length} Telecaller${branch.telecallers.length == 1 ? '' : 's'} · '
          '${branch.salespersons.length} Salesperson${branch.salespersons.length == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 12, color: CRMColors.textMutedOf(context)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: total == 0
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No employees added yet.',
                    style: TextStyle(fontSize: 12.5, color: CRMColors.textMutedOf(context)),
                  ),
                ),
              ]
            : [_buildGroupsLayout(branch.telecallers, branch.salespersons, contentWidth)],
      ),
    );
  }

  Widget _buildUnlinkedNode(List<_TreeUser> unlinked, double contentWidth) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: CRMColors.borderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(_isSearching ? 'admin_unlinked_search_$_query' : 'admin_unlinked'),
        initiallyExpanded: _isSearching,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.withValues(alpha: 0.15),
          child: const Icon(Icons.help_outline_rounded, color: Colors.grey, size: 18),
        ),
        title: Text(
          'Not linked to an Administrator',
          style: TextStyle(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
        ),
        subtitle: Text(
          '${unlinked.length} employee${unlinked.length == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 12, color: CRMColors.textMutedOf(context)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGroupsLayout(
            unlinked.where((u) => u.isTelecaller).toList(),
            unlinked.where((u) => u.isSales).toList(),
            contentWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String label, IconData icon, Color color, List<_TreeUser> members) {
    if (_isSearching && members.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        dense: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          '$label (${members.length})',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: color),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: members.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('None', style: TextStyle(fontSize: 12.5, color: CRMColors.textMutedOf(context))),
                  ),
                ),
              ]
            : members.map((m) => _buildMemberTile(m, icon, color)).toList(),
      ),
    );
  }

  Widget _buildMemberTile(_TreeUser user, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go('/users/${user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(width: 12, height: 1.5, color: color.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 13,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameLine(user),
                  if (user.email.isNotEmpty)
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: CRMColors.textMutedOf(context)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameLine(_TreeUser user, {FontWeight fontWeight = FontWeight.w600}) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Container(
          padding: _matches(user) ? const EdgeInsets.symmetric(horizontal: 4) : EdgeInsets.zero,
          decoration: _matches(user)
              ? BoxDecoration(color: _matchColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4))
              : null,
          child: Text(
            user.name,
            style: TextStyle(fontWeight: fontWeight, fontSize: 14, color: CRMColors.textOf(context)),
          ),
        ),
        if (!user.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: CRMColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Inactive',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CRMColors.danger),
            ),
          ),
      ],
    );
  }

  // ── Graph Tree view ────────────────────────────────────────────────────────

  Color get _lineColor =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

  Size? _renderSize(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }

  /// Fit the graph to the viewport width (never upscale), top-aligned. The scale never drops below a
  /// readable minimum; wider graphs stay centred on the top node and can be panned.
  void _fitGraph() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final content = _renderSize(_graphContentKey);
      final viewport = _renderSize(_graphViewportKey);
      if (content == null || viewport == null || content.width == 0) return;
      final minReadable = viewport.width < 700 ? 0.6 : 0.75;
      final scale = math.max(minReadable, math.min(1.0, viewport.width / content.width));
      final dx = (viewport.width - content.width * scale) / 2;
      _graphController.value = Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(dx, 0, 0);
    });
  }

  void _zoomGraph(double factor) {
    final viewport = _renderSize(_graphViewportKey);
    if (viewport == null) return;
    final current = _graphController.value;
    final scale = current.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.2, 2.5);
    final k = next / scale;
    final cx = viewport.width / 2;
    final cy = viewport.height / 2;
    final zoom = Matrix4.diagonal3Values(k, k, 1)..setTranslationRaw(cx - k * cx, cy - k * cy, 0);
    _graphController.value = zoom.multiplied(current);
  }

  Widget _buildGraphView(String superAdminName, bool isMobile) {
    final branches = _visibleBranches;
    final unlinked = _visibleUnlinked;
    final subtrees = <Widget>[
      for (final b in branches) _graphAdminSubtree(b),
      if (unlinked.isNotEmpty)
        _graphAdminSubtree(
          _AdminBranch(
            const _TreeUser(id: '', name: 'Not linked to an Administrator', email: '', role: '', isActive: true),
            telecallers: unlinked.where((u) => u.isTelecaller).toList(),
            salespersons: unlinked.where((u) => u.isSales).toList(),
          ),
          isUnlinked: true,
        ),
    ];
    final viewportHeight = math.max(420.0, MediaQuery.of(context).size.height - (isMobile ? 320 : 300));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: _graphViewportKey,
      height: viewportHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _graphController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(600),
              minScale: 0.2,
              maxScale: 2.5,
              child: Padding(
                key: _graphContentKey,
                padding: const EdgeInsets.all(32),
                child: _isAdminView
                    ? (branches.isEmpty ? const SizedBox.shrink() : _graphAdminSubtree(branches.first))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _graphRootCard(superAdminName),
                          if (subtrees.isNotEmpty) ...[
                            _graphStem(),
                            _graphFanOut(subtrees),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'No Administrators found.',
                                style: TextStyle(fontSize: 12.5, color: CRMColors.textMutedOf(context)),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: CRMColors.surfaceOf(context),
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(tooltip: 'Zoom in', icon: const Icon(Icons.add_rounded), onPressed: () => _zoomGraph(1.2)),
                  IconButton(
                    tooltip: 'Zoom out',
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: () => _zoomGraph(1 / 1.2),
                  ),
                  IconButton(
                    tooltip: 'Fit to screen',
                    icon: const Icon(Icons.fit_screen_rounded),
                    onPressed: _fitGraph,
                  ),
                ],
              ),
            ),
          ),
          if (!isMobile)
            Positioned(
              left: 14,
              bottom: 12,
              child: Text(
                'Drag to move · Scroll or pinch to zoom',
                style: TextStyle(fontSize: 11, color: CRMColors.textMutedOf(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _graphStem([double height = 22]) => Container(width: 2, height: height, color: _lineColor);

  /// Lays children side by side under one parent; each child gets a connector segment so the
  /// horizontal bar always spans exactly from the first child's centre to the last child's centre.
  Widget _graphFanOut(List<Widget> children) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 22,
                  child: CustomPaint(
                    painter: _FanConnectorPainter(isFirst: i == 0, isLast: i == children.length - 1, color: _lineColor),
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: children[i]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _graphAdminSubtree(_AdminBranch branch, {bool isUnlinked = false}) {
    final groups = <Widget>[
      if (!_isSearching || branch.telecallers.isNotEmpty)
        _graphGroupSubtree('Telecallers', Icons.support_agent_rounded, _telecallerColor, branch.telecallers),
      if (!_isSearching || branch.salespersons.isNotEmpty)
        _graphGroupSubtree('Salespersons', Icons.badge_rounded, _salesColor, branch.salespersons),
    ];
    final hasEmployees = branch.telecallers.isNotEmpty || branch.salespersons.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _graphAdminCard(branch, isUnlinked: isUnlinked),
        if (!hasEmployees && !isUnlinked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No employees added yet',
              style: TextStyle(fontSize: 11.5, color: CRMColors.textMutedOf(context)),
            ),
          )
        else if (groups.isNotEmpty) ...[
          _graphStem(),
          _graphFanOut(groups),
        ],
      ],
    );
  }

  Widget _graphGroupSubtree(String label, IconData icon, Color color, List<_TreeUser> members) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$label · ${members.length}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        if (members.isEmpty) ...[
          _graphStem(14),
          Text('None', style: TextStyle(fontSize: 11.5, color: CRMColors.textMutedOf(context))),
        ] else
          for (final m in members) ...[_graphStem(14), _graphMemberCard(m, icon, color)],
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  BoxDecoration _graphCardDecoration(Color accent, {required bool highlighted}) {
    return BoxDecoration(
      color: CRMColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: highlighted ? _matchColor : accent.withValues(alpha: 0.35),
        width: highlighted ? 2.2 : 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: highlighted ? _matchColor.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05),
          blurRadius: highlighted ? 14 : 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _graphRootCard(String superAdminName) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD97706).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            child: Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  superAdminName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Super Admin · ${_branches.length} Admin${_branches.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _graphAdminCard(_AdminBranch branch, {bool isUnlinked = false}) {
    final admin = branch.admin;
    final accent = isUnlinked ? Colors.grey : _adminColor;
    Widget countChip(IconData icon, int count, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isUnlinked ? null : () => context.go('/users/${admin.id}'),
      child: Container(
        width: 240,
        decoration: _graphCardDecoration(accent, highlighted: !isUnlinked && _matches(admin)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        child: isUnlinked
                            ? const Icon(Icons.help_outline_rounded, size: 18, color: Colors.grey)
                            : Text(
                                _initials(admin.name),
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: accent),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              admin.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: CRMColors.textOf(context),
                              ),
                            ),
                            Text(
                              isUnlinked ? 'Employees without an Administrator' : 'Administrator',
                              style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (!admin.isActive) _graphInactiveBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      countChip(Icons.support_agent_rounded, branch.telecallers.length, _telecallerColor),
                      const SizedBox(width: 8),
                      countChip(Icons.badge_rounded, branch.salespersons.length, _salesColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _graphMemberCard(_TreeUser user, IconData icon, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/users/${user.id}'),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: _graphCardDecoration(color, highlighted: _matches(user)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                _initials(user.name),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: CRMColors.textOf(context)),
                  ),
                  if (user.email.isNotEmpty)
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: CRMColors.textMutedOf(context)),
                    ),
                ],
              ),
            ),
            if (!user.isActive) _graphInactiveBadge(),
          ],
        ),
      ),
    );
  }

  Widget _graphInactiveBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: CRMColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Inactive',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: CRMColors.danger),
      ),
    );
  }
}

class _FanConnectorPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  const _FanConnectorPainter({required this.isFirst, required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final midX = size.width / 2;
    if (!(isFirst && isLast)) {
      canvas.drawLine(Offset(isFirst ? midX : 0, 1), Offset(isLast ? midX : size.width, 1), paint);
    }
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _FanConnectorPainter old) =>
      old.isFirst != isFirst || old.isLast != isLast || old.color != color;
}
