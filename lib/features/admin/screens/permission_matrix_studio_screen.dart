import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/security/access_control_bloc.dart';
import '../../settings/widgets/permission_matrix_card.dart';

class PermissionMatrixStudioScreen extends StatefulWidget {
  const PermissionMatrixStudioScreen({super.key});

  @override
  State<PermissionMatrixStudioScreen> createState() =>
      _PermissionMatrixStudioScreenState();
}

class _PermissionMatrixStudioScreenState
    extends State<PermissionMatrixStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  // Role Matrix Data
  List<dynamic> _controls = [];
  Map<String, dynamic> _roleAssignments = {};
  final String _searchQuery = '';
  final String _selectedModule = 'All';

  // Specific User Overrides Data
  List<dynamic> _usersList = [];
  Map<String, dynamic>? _selectedUser;
  Map<String, bool> _userOverrides = {};
  bool _isLoadingUserOverrides = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatrixData();
    _loadUsersList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatrixData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await DioClient.dio.get('/permissions/matrix/roles');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _controls = data['controls'] as List<dynamic>? ?? [];
          _roleAssignments =
              Map<String, dynamic>.from(data['assignments'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load permissions matrix: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsersList() async {
    try {
      final res = await DioClient.dio.get('/users');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'];
        if (data is List) {
          setState(() {
            _usersList = data;
          });
        } else if (data is Map && data['users'] is List) {
          setState(() {
            _usersList = data['users'] as List;
          });
        }
      }
    } catch (e) {
      debugPrint('[PermissionStudio] Error fetching users: $e');
    }
  }

  Future<void> _loadUserOverrides(String userId) async {
    setState(() => _isLoadingUserOverrides = true);
    try {
      final res = await DioClient.dio.get('/permissions/overrides/users/$userId');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data['data'] as List<dynamic>? ?? [];
        final map = <String, bool>{};
        for (final item in list) {
          if (item is Map && item['control_key'] != null) {
            map[item['control_key'].toString()] = item['is_enabled'] == true;
          }
        }
        setState(() {
          _userOverrides = map;
          _isLoadingUserOverrides = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingUserOverrides = false);
      _showSnackbar('Error loading user overrides: $e', isError: true);
    }
  }

  Future<void> _toggleUserOverride(
      String userId, String controlKey, bool effectiveValue) async {
    final newEnabled = !effectiveValue;
    setState(() {
      _userOverrides[controlKey] = newEnabled;
    });

    try {
      await DioClient.dio.post('/permissions/overrides/user-control', data: {
        'userId': userId,
        'controlKey': controlKey,
        'isEnabled': newEnabled,
        'reason': 'Special access updated via Permission Studio',
      });
      _showSnackbar('Special override updated successfully.');
      AccessControlBloc.instance.add(const RefreshAccessControlsEvent());
    } catch (e) {
      _showSnackbar('Failed to update override: $e', isError: true);
    }
  }

  Future<void> _removeUserOverride(String userId, String controlKey) async {
    try {
      await DioClient.dio
          .delete('/permissions/overrides/users/$userId/control/$controlKey');
      setState(() {
        _userOverrides.remove(controlKey);
      });
      _showSnackbar('Reverted to role default.');
      AccessControlBloc.instance.add(const RefreshAccessControlsEvent());
    } catch (e) {
      _showSnackbar('Failed to remove override: $e', isError: true);
    }
  }

  Future<void> _resetAllUserOverrides(String userId) async {
    try {
      await DioClient.dio
          .delete('/permissions/overrides/users/$userId/reset');
      setState(() {
        _userOverrides.clear();
      });
      _showSnackbar('All overrides cleared. User reverted to role defaults.');
      AccessControlBloc.instance.add(const RefreshAccessControlsEvent());
    } catch (e) {
      _showSnackbar('Failed to reset overrides: $e', isError: true);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? CRMColors.danger : CRMColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<dynamic> get _filteredControls {
    return _controls.where((c) {
      final module = (c['module'] ?? '').toString();
      final title = (c['title'] ?? '').toString().toLowerCase();
      final key = (c['control_key'] ?? '').toString().toLowerCase();
      final desc = (c['description'] ?? '').toString().toLowerCase();

      final matchesModule =
          _selectedModule == 'All' || module.toLowerCase() == _selectedModule.toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          q.isEmpty || title.contains(q) || key.contains(q) || desc.contains(q);

      return matchesModule && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111418) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Access & Permission Matrix Studio'),
        backgroundColor: isDark ? const Color(0xFF1A1F26) : Colors.white,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: CRMColors.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
          indicatorColor: CRMColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Role Permission Matrix'),
            Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Specific User Access'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMatrixData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoleMatrixTab(isDark),
                    _buildSpecificUserTab(isDark),
                  ],
                ),
    );
  }

  // ── Tab 1: Role Permission Matrix ──────────────────────────────────────────
  Widget _buildRoleMatrixTab(bool isDark) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(CRMSpacing.m),
      child: PermissionMatrixCard(),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = Colors.blue;
    if (type == 'page') color = Colors.purple;
    if (type == 'action') color = Colors.teal;
    if (type == 'engine') color = Colors.orange;
    if (type == 'filter') color = Colors.indigo;
    if (type == 'data_visibility') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ── Tab 2: Specific User Access ───────────────────────────────────────────
  Widget _buildSpecificUserTab(bool isDark) {
    return Column(
      children: [
        _buildUserSelector(isDark),
        if (_selectedUser == null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Select an employee above to configure their individual special access.',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (_isLoadingUserOverrides)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(CRMSpacing.m),
              itemCount: _filteredControls.length,
              separatorBuilder: (_, __) => const SizedBox(height: CRMSpacing.xs),
              itemBuilder: (context, index) {
                final control = _filteredControls[index];
                return _buildUserOverrideRow(control, isDark);
              },
            ),
          ),
      ],
    );
  }

  String _roleOf(Map? u) {
    final roles = u?['roles'];
    final role = (roles is Map ? roles['name'] : null) ?? u?['role'] ?? u?['role_name'];
    final s = role?.toString().trim() ?? '';
    return s.isEmpty ? 'Sales' : s;
  }

  Widget _buildUserSelector(bool isDark) {
    final userRole = _roleOf(_selectedUser);
    final seenIds = <String>{};
    final userItems = <DropdownMenuItem<String>>[];
    for (final raw in _usersList) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString() ?? '';
      if (id.isEmpty || !seenIds.add(id)) continue;
      final name = raw['full_name'] ?? raw['email'] ?? 'User';
      userItems.add(DropdownMenuItem<String>(value: id, child: Text('$name (${_roleOf(raw)})')));
    }
    final selectedId = _selectedUser?['id']?.toString();

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      color: isDark ? const Color(0xFF1E242C) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('user_select_${userItems.length}'),
                  initialValue: seenIds.contains(selectedId) ? selectedId : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Employee / User',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: userItems,
                  onChanged: (id) {
                    if (id == null) return;
                    Map? raw;
                    for (final u in _usersList) {
                      if (u is Map && u['id']?.toString() == id) {
                        raw = u;
                        break;
                      }
                    }
                    if (raw == null) return;
                    setState(() {
                      _selectedUser = Map<String, dynamic>.from(raw!);
                      _userOverrides = {};
                    });
                    _loadUserOverrides(id);
                  },
                ),
              ),
              if (_selectedUser != null && _userOverrides.isNotEmpty) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset to Role Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _resetAllUserOverrides(_selectedUser!['id'].toString()),
                ),
              ],
            ],
          ),
          if (_selectedUser != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CRMColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Configuring user overrides for: ${_selectedUser!['full_name'] ?? _selectedUser!['email']} (Base Role: $userRole). Overrides take priority over standard role permissions.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.blue[300] : Colors.blue[800],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserOverrideRow(dynamic control, bool isDark) {
    final key = (control['control_key'] ?? '').toString();
    final title = (control['title'] ?? '').toString();
    final type = (control['control_type'] ?? 'action').toString();
    final desc = (control['description'] ?? '').toString();

    final userRole = _roleOf(_selectedUser);

    final roleDefaultEnabled = _roleAssignments[userRole]?[key] == true;
    final hasOverride = _userOverrides.containsKey(key);
    final effectiveEnabled =
        hasOverride ? (_userOverrides[key] == true) : roleDefaultEnabled;

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242C) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasOverride
              ? Colors.amber
              : (isDark ? const Color(0xFF2E3844) : const Color(0xFFE9ECEF)),
          width: hasOverride ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildTypeBadge(type),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (hasOverride) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber, width: 0.8),
                        ),
                        child: const Text(
                          'SPECIAL OVERRIDE',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  key,
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                if (desc.isNotEmpty)
                  Text(
                    desc,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Switch(
                value: effectiveEnabled,
                activeThumbColor: hasOverride ? Colors.amber : CRMColors.success,
                onChanged: (_) => _toggleUserOverride(
                  _selectedUser!['id'].toString(),
                  key,
                  effectiveEnabled,
                ),
              ),
              if (hasOverride)
                InkWell(
                  onTap: () => _removeUserOverride(
                    _selectedUser!['id'].toString(),
                    key,
                  ),
                  child: const Text(
                    'Revert to Default',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                        decoration: TextDecoration.underline),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
