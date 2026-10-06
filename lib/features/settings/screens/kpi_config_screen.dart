import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_manager.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/models/kpi_models.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/widgets/generic_kpi_drilldown_dialog.dart';

class KpiConfigScreen extends StatefulWidget {
  const KpiConfigScreen({super.key});

  @override
  State<KpiConfigScreen> createState() => _KpiConfigScreenState();
}

class _KpiConfigScreenState extends State<KpiConfigScreen>
    with SingleTickerProviderStateMixin {
  final DashboardService _service = DashboardService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  List<KpiRegistryItem> _kpiList = [];
  List<KpiAuditLogItem> _auditLogs = [];
  // ignore: unused_field
  Map<String, dynamic> _builderMetadata = {};

  // Filter States
  String _searchQuery = '';
  String _selectedPageFilter = 'All';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  // Builder State
  bool _isEditing = false;
  String? _editingKpiId;
  final _nameController = TextEditingController();
  final _whyController = TextEditingController();
  final _keyController = TextEditingController();
  final _orderController = TextEditingController(text: '10');

  // Friendly Data Source Selection
  String _selectedSourceId = 'site_visits';
  String _selectedCountField = 'id';
  String _selectedAggregation = 'COUNT';
  String _selectedConditionField = 'status';
  String _selectedConditionValue = 'DONE';
  String _selectedDateField = 'created_at';
  bool _hasCondition = true;

  // Pages & Roles
  final List<String> _selectedPages = ['Admin Dashboard'];
  bool _adminVisible = true;
  bool _telecallerVisible = false;
  bool _salesVisible = false;
  String _uiComponent = 'KPI Card';
  String _displayFormat = 'Count';
  String _selectedIcon = 'insights_rounded';
  bool _isClickable = true;

  // Drilldown Composer State
  List<Map<String, dynamic>> _drilldownComponents = [];

  // Available Pages
  final List<String> _allPages = [
    'Admin Dashboard',
    'Telecaller Dashboard',
    'Sales Dashboard',
    'Locality Intelligence',
    'Reports',
    'Campaign',
    'Telecaller Performance',
    'Sales Performance',
  ];

  final Map<String, IconData> _iconCatalog = {
    'insights_rounded': Icons.insights_rounded,
    'location_on_rounded': Icons.location_on_rounded,
    'home_work_rounded': Icons.home_work_rounded,
    'assignment_rounded': Icons.assignment_rounded,
    'support_agent_rounded': Icons.support_agent_rounded,
    'badge_rounded': Icons.badge_rounded,
    'emoji_events_rounded': Icons.emoji_events_rounded,
    'groups_rounded': Icons.groups_rounded,
    'phone_disabled_rounded': Icons.phone_disabled_rounded,
    'map_rounded': Icons.map_rounded,
    'bar_chart_rounded': Icons.bar_chart_rounded,
    'pie_chart_rounded': Icons.pie_chart_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 3 && _auditLogs.isEmpty) {
        _loadAuditLogs();
      }
    });
    _initDefaultDrilldownComponents();
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _whyController.dispose();
    _keyController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _initDefaultDrilldownComponents() {
    _drilldownComponents = [
      {
        'id': 'comp_kpis',
        'type': 'kpi_group',
        'title': 'Status Summary',
        'items': [
          {'label': 'Scheduled', 'status': 'SCHEDULED', 'is_clickable': true},
          {'label': 'Completed', 'status': 'DONE', 'is_clickable': true},
          {'label': 'Cancelled', 'status': 'CANCELLED', 'is_clickable': true},
        ],
      },
      {
        'id': 'comp_chart',
        'type': 'chart',
        'title': 'Status Distribution',
        'chart_type': 'donut',
        'dimension': 'status',
      },
      {
        'id': 'comp_breakdown',
        'type': 'status_breakdown',
        'title': 'Status Breakdown',
        'dimension': 'status',
      },
      {
        'id': 'comp_table',
        'type': 'table',
        'title': 'Record Details',
        'columns': ['Customer', 'Property', 'Date', 'Status'],
        'data_source': 'site_visits',
      },
    ];
  }

  IconData _getIconData(String iconName) {
    return _iconCatalog[iconName] ?? Icons.insights_rounded;
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final kpis = await _service.getKpiRegistry(
        search: _searchQuery,
        page: _selectedPageFilter,
        role: _selectedRoleFilter,
        status: _selectedStatusFilter,
      );
      final meta = await _service.getKpiBuilderMetadata();
      if (mounted) {
        setState(() {
          _kpiList = kpis;
          _builderMetadata = meta;
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

  Future<void> _loadAuditLogs() async {
    try {
      final logs = await _service.getKpiAuditLogs();
      if (mounted) setState(() => _auditLogs = logs);
    } catch (_) {}
  }

  void _onNameChanged(String val) {
    if (!_isEditing) {
      final autoKey = val
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      _keyController.text = autoKey;
    }
    setState(() {});
  }

  void _resetBuilder() {
    setState(() {
      _isEditing = false;
      _editingKpiId = null;
      _nameController.clear();
      _whyController.clear();
      _keyController.clear();
      _orderController.text = '10';
      _selectedSourceId = 'site_visits';
      _selectedCountField = 'id';
      _selectedAggregation = 'COUNT';
      _selectedConditionField = 'status';
      _selectedConditionValue = 'DONE';
      _selectedDateField = 'created_at';
      _hasCondition = true;
      _selectedPages.clear();
      _selectedPages.add('Admin Dashboard');
      _adminVisible = true;
      _telecallerVisible = false;
      _salesVisible = false;
      _uiComponent = 'KPI Card';
      _displayFormat = 'Count';
      _selectedIcon = 'insights_rounded';
      _isClickable = true;
      _initDefaultDrilldownComponents();
    });
  }

  void _initEdit(KpiRegistryItem kpi) {
    setState(() {
      _isEditing = true;
      _editingKpiId = kpi.id;
      _nameController.text = kpi.kpiLabel;
      _whyController.text = kpi.whyDoWeHaveIt;
      _keyController.text = kpi.kpiKey;
      _orderController.text = kpi.displayOrder.toString();
      _selectedSourceId = kpi.dataSource;
      _selectedCountField = kpi.primaryField;
      _selectedAggregation = kpi.aggregation;
      _selectedDateField = kpi.dateField;
      _selectedPages.clear();
      _selectedPages.addAll(kpi.pages);
      _adminVisible = kpi.adminVisible;
      _telecallerVisible = kpi.telecallerVisible;
      _salesVisible = kpi.salesVisible;
      _uiComponent = kpi.uiComponent;
      _displayFormat = kpi.displayFormat;
      _selectedIcon = kpi.icon;
      _isClickable = kpi.isClickable;

      if (kpi.conditionsJson.isNotEmpty && kpi.conditionsJson.first is Map) {
        _hasCondition = true;
        _selectedConditionField = kpi.conditionsJson.first['field']?.toString() ?? 'status';
        _selectedConditionValue = kpi.conditionsJson.first['value']?.toString() ?? 'DONE';
      } else {
        _hasCondition = false;
      }

      if (kpi.drilldownConfig.containsKey('components') &&
          kpi.drilldownConfig['components'] is List) {
        _drilldownComponents = List<Map<String, dynamic>>.from(
          (kpi.drilldownConfig['components'] as List)
              .map((c) => Map<String, dynamic>.from(c)),
        );
      } else {
        _initDefaultDrilldownComponents();
      }
    });
    _tabController.animateTo(1);
  }

  void _duplicate(KpiRegistryItem kpi) {
    _resetBuilder();
    setState(() {
      _nameController.text = '${kpi.kpiLabel} (Copy)';
      _whyController.text = kpi.whyDoWeHaveIt;
      _keyController.text = '${kpi.kpiKey}_copy';
      _selectedSourceId = kpi.dataSource;
      _selectedCountField = kpi.primaryField;
      _selectedAggregation = kpi.aggregation;
      _selectedDateField = kpi.dateField;
      _selectedPages.clear();
      _selectedPages.addAll(kpi.pages);
      _adminVisible = kpi.adminVisible;
      _telecallerVisible = kpi.telecallerVisible;
      _salesVisible = kpi.salesVisible;
      _uiComponent = kpi.uiComponent;
      _displayFormat = kpi.displayFormat;
      _selectedIcon = kpi.icon;
      _isClickable = kpi.isClickable;
      if (kpi.drilldownConfig.containsKey('components') &&
          kpi.drilldownConfig['components'] is List) {
        _drilldownComponents = List<Map<String, dynamic>>.from(
          (kpi.drilldownConfig['components'] as List)
              .map((c) => Map<String, dynamic>.from(c)),
        );
      }
    });
    _tabController.animateTo(1);
    _showFeedback('Pre-filled new KPI from "${kpi.kpiLabel}".', isSuccess: true);
  }

  Future<void> _saveKpi() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showFeedback('Please enter a KPI Name.', isSuccess: false);
      return;
    }
    final why = _whyController.text.trim();
    if (why.isEmpty) {
      _showFeedback('Please describe what this KPI represents.', isSuccess: false);
      return;
    }
    if (_selectedPages.isEmpty) {
      _showFeedback('Please choose at least one dashboard where this KPI appears.', isSuccess: false);
      return;
    }
    if (!_adminVisible && !_telecallerVisible && !_salesVisible) {
      _showFeedback('Please enable visibility for at least one user role.', isSuccess: false);
      return;
    }

    setState(() => _isSaving = true);

    final conditions = _hasCondition
        ? [
            {
              'field': _selectedConditionField,
              'operator': '=',
              'value': _selectedConditionValue,
            }
          ]
        : [];

    final payload = {
      'kpi_name': name,
      'kpi_label': name,
      'kpi_key': _keyController.text.trim().isNotEmpty
          ? _keyController.text.trim()
          : name.toLowerCase().replaceAll(' ', '_'),
      'why_do_we_have_it': why,
      'data_source': _selectedSourceId,
      'entity_table': _selectedSourceId,
      'primary_field': _selectedCountField,
      'aggregation': _selectedAggregation,
      'conditions_json': conditions,
      'date_field': _selectedDateField,
      'database_mapping_description': '$_selectedSourceId ($_selectedAggregation) ${conditions.isNotEmpty ? "WHERE $_selectedConditionField = $_selectedConditionValue" : ""}',
      'pages': _selectedPages,
      'ui_component': _uiComponent,
      'display_format': _displayFormat,
      'icon': _selectedIcon,
      'is_clickable': _isClickable,
      'drilldown_type': 'Modal',
      'second_level_enabled': _isClickable,
      'drilldown_config': {
        'layout': 'default',
        'components': _drilldownComponents,
      },
      'admin_visible': _adminVisible,
      'telecaller_visible': _telecallerVisible,
      'sales_visible': _salesVisible,
      'is_enabled': true,
      'display_order': int.tryParse(_orderController.text.trim()) ?? 10,
    };

    try {
      if (_isEditing && _editingKpiId != null) {
        await _service.updateKpiRegistryItem(_editingKpiId!, payload);
        _showFeedback('KPI "$name" updated successfully!', isSuccess: true);
      } else {
        await _service.createKpiRegistryItem(payload);
        _showFeedback('KPI "$name" created successfully!', isSuccess: true);
      }

      // Sync with DashboardBloc
      if (mounted) {
        context.read<DashboardBloc>().add(
              ToggleKpiConfig(
                kpiKey: payload['kpi_key'].toString(),
                isEnabled: true,
              ),
            );
      }

      _resetBuilder();
      _tabController.animateTo(0);
      _loadAll();
    } catch (e) {
      _showFeedback('Failed to save KPI: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleStatus(KpiRegistryItem kpi, bool isEnabled) async {
    setState(() => _isSaving = true);
    final ok = await _service.toggleKpiRegistryStatus(kpi.id, isEnabled);
    if (ok) {
      if (mounted) {
        context.read<DashboardBloc>().add(
              ToggleKpiConfig(kpiKey: kpi.kpiKey, isEnabled: isEnabled),
            );
      }
      _showFeedback('KPI "${kpi.kpiLabel}" ${isEnabled ? "enabled" : "disabled"}.', isSuccess: true);
      _loadAll();
    } else {
      _showFeedback('Failed to toggle KPI status.', isSuccess: false);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _toggleRole(
    KpiRegistryItem kpi, {
    bool? admin,
    bool? telecaller,
    bool? sales,
  }) async {
    final newAdmin = admin ?? kpi.adminVisible;
    final newTele = telecaller ?? kpi.telecallerVisible;
    final newSales = sales ?? kpi.salesVisible;

    if (!newAdmin && !newTele && !newSales) {
      _showFeedback('At least one role must remain enabled.', isSuccess: false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.updateKpiRegistryItem(kpi.id, {
        'admin_visible': newAdmin,
        'telecaller_visible': newTele,
        'sales_visible': newSales,
      });
      _showFeedback('Role visibility updated for "${kpi.kpiLabel}".', isSuccess: true);
      _loadAll();
    } catch (e) {
      _showFeedback('Failed to update roles: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteKpi(KpiRegistryItem kpi) async {
    if (kpi.isSystem) {
      _showFeedback('System canonical KPIs cannot be deleted. You can disable them instead.', isSuccess: false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete KPI?'),
        content: Text('Are you sure you want to delete "${kpi.kpiLabel}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await _service.deleteKpiRegistryItem(kpi.id);
        _showFeedback('KPI deleted successfully.', isSuccess: true);
        _loadAll();
      } catch (e) {
        _showFeedback('Failed to delete KPI: $e', isSuccess: false);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showFeedback(String msg, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Drilldown Component Add Dialogs
  void _openAddSubKpiDialog() {
    String subLabel = 'Scheduled';
    String subStatus = 'SCHEDULED';
    String? selectedKpiKey;
    bool isCustom = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Sub-KPI to Drilldown'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Select Existing KPI'),
                    selected: !isCustom,
                    onSelected: (val) => setDlgState(() => isCustom = !val),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('New Sub-Metric'),
                    selected: isCustom,
                    onSelected: (val) => setDlgState(() => isCustom = val),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!isCustom)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Choose Registered KPI', border: OutlineInputBorder()),
                  items: _kpiList.map((k) {
                    return DropdownMenuItem(value: k.kpiKey, child: Text(k.kpiLabel));
                  }).toList(),
                  onChanged: (val) => selectedKpiKey = val,
                )
              else ...[
                TextFormField(
                  initialValue: subLabel,
                  decoration: const InputDecoration(labelText: 'Metric Label', hintText: 'e.g. Scheduled', border: OutlineInputBorder()),
                  onChanged: (val) => subLabel = val,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: subStatus,
                  decoration: const InputDecoration(labelText: 'Target Status Value', hintText: 'e.g. SCHEDULED', border: OutlineInputBorder()),
                  onChanged: (val) => subStatus = val,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  var kpiGroupComp = _drilldownComponents.firstWhere(
                    (c) => c['type'] == 'kpi_group',
                    orElse: () => <String, dynamic>{},
                  );
                  if (kpiGroupComp.isEmpty) {
                    kpiGroupComp = {
                      'id': 'comp_kpis',
                      'type': 'kpi_group',
                      'title': 'Status Summary',
                      'items': [],
                    };
                    _drilldownComponents.insert(0, kpiGroupComp);
                  }
                  final items = (kpiGroupComp['items'] as List?) ?? [];
                  if (isCustom) {
                    items.add({'label': subLabel, 'status': subStatus, 'is_clickable': true});
                  } else if (selectedKpiKey != null) {
                    final matched = _kpiList.firstWhere((k) => k.kpiKey == selectedKpiKey);
                    items.add({'label': matched.kpiLabel, 'kpi_key': matched.kpiKey, 'is_clickable': true});
                  }
                  kpiGroupComp['items'] = items;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddChartDialog() {
    String chartTitle = 'Status Distribution';
    String chartType = 'donut';
    String dimension = 'status';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Chart to Drilldown'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: chartTitle,
                decoration: const InputDecoration(labelText: 'Chart Title', border: OutlineInputBorder()),
                onChanged: (val) => chartTitle = val,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: chartType,
                decoration: const InputDecoration(labelText: 'Chart Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'donut', child: Text('Donut / Pie Chart')),
                  DropdownMenuItem(value: 'bar', child: Text('Bar Chart')),
                  DropdownMenuItem(value: 'line', child: Text('Trend Line Chart')),
                ],
                onChanged: (val) => chartType = val ?? 'donut',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: dimension,
                decoration: const InputDecoration(labelText: 'Group By (Dimension)', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'status', child: Text('Status')),
                  DropdownMenuItem(value: 'stage', child: Text('Lifecycle Stage')),
                  DropdownMenuItem(value: 'source', child: Text('Source')),
                  DropdownMenuItem(value: 'property_type', child: Text('Property Type')),
                ],
                onChanged: (val) => dimension = val ?? 'status',
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _drilldownComponents.add({
                    'id': 'chart_${DateTime.now().millisecondsSinceEpoch}',
                    'type': 'chart',
                    'title': chartTitle,
                    'chart_type': chartType,
                    'dimension': dimension,
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Chart'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTableDialog() {
    String tableTitle = 'Record Details';
    String dataSource = _selectedSourceId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Records Table to Drilldown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: tableTitle,
              decoration: const InputDecoration(labelText: 'Table Title', border: OutlineInputBorder()),
              onChanged: (val) => tableTitle = val,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: dataSource,
              decoration: const InputDecoration(labelText: 'Data Source', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'site_visits', child: Text('Site Visits')),
                DropdownMenuItem(value: 'properties', child: Text('Properties')),
                DropdownMenuItem(value: 'leads', child: Text('Leads')),
                DropdownMenuItem(value: 'requirements', child: Text('Requirements')),
              ],
              onChanged: (val) => dataSource = val ?? 'site_visits',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _drilldownComponents.add({
                  'id': 'table_${DateTime.now().millisecondsSinceEpoch}',
                  'type': 'table',
                  'title': tableTitle,
                  'data_source': dataSource,
                  'columns': ['Customer', 'Property', 'Date', 'Status'],
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add Table'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic KPI Builder'),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Registry',
            onPressed: _loadAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: ThemeManager().primaryColor,
          unselectedLabelColor: subColor,
          indicatorColor: ThemeManager().primaryColor,
          tabs: [
            Tab(icon: const Icon(Icons.table_chart_rounded, size: 18), text: 'KPI Registry (${_kpiList.length})'),
            Tab(
              icon: Icon(_isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded, size: 18),
              text: _isEditing ? 'Edit KPI' : '+ No-Code Builder',
            ),
            const Tab(icon: Icon(Icons.security_rounded, size: 18), text: 'Role Visibility Matrix'),
            const Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Audit History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. KPI Registry
          _buildRegistryTab(cardBg, textColor, subColor, borderColor),

          // 2. No-Code KPI Builder + Drilldown Composer
          _buildBuilderTab(cardBg, textColor, subColor, borderColor),

          // 3. Role Visibility Matrix
          _buildRoleMatrixTab(cardBg, textColor, subColor, borderColor),

          // 4. Audit History
          _buildAuditHistoryTab(cardBg, textColor, subColor, borderColor),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: KPI REGISTRY
  // ==========================================
  Widget _buildRegistryTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
            const SizedBox(height: 10),
            Text('Failed to load registry: $_errorMessage'),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      );
    }

    final isDark = ThemeManager().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search KPIs...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _loadAll();
                  },
                ),
              ),
              DropdownButton<String>(
                value: _selectedPageFilter,
                underline: const SizedBox(),
                items: ['All', ..._allPages].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPageFilter = val);
                    _loadAll();
                  }
                },
              ),
              DropdownButton<String>(
                value: _selectedRoleFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Roles', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Telecaller', child: Text('Telecaller', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Sales', child: Text('Sales User', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRoleFilter = val);
                    _loadAll();
                  }
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Add KPI'),
                onPressed: () {
                  _resetBuilder();
                  _tabController.animateTo(1);
                },
              ),
            ],
          ),
        ),

        // Registry Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1100),
                child: DataTable(
                  columnSpacing: 18,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KPI Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KPI Key', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Business Purpose', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Data Source', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pages', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Sales User', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Active', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(_kpiList.length, (index) {
                    final kpi = _kpiList[index];
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}', style: TextStyle(color: subColor, fontSize: 13))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getIconData(kpi.icon), size: 18, color: ThemeManager().primaryColor),
                              const SizedBox(width: 8),
                              Text(kpi.kpiLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (kpi.isSystem) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('SYS', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(
                          Text(kpi.kpiKey, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF6366F1))),
                        ),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Tooltip(
                              message: kpi.whyDoWeHaveIt,
                              child: Text(kpi.whyDoWeHaveIt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: subColor)),
                            ),
                          ),
                        ),
                        DataCell(
                          Text('${kpi.dataSource} (${kpi.aggregation})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                        DataCell(
                          Text(kpi.pages.join(', ').replaceAll(' Dashboard', ''), style: TextStyle(fontSize: 12, color: subColor)),
                        ),
                        DataCell(Checkbox(value: kpi.adminVisible, onChanged: (val) => _toggleRole(kpi, admin: val))),
                        DataCell(Checkbox(value: kpi.telecallerVisible, onChanged: (val) => _toggleRole(kpi, telecaller: val))),
                        DataCell(Checkbox(value: kpi.salesVisible, onChanged: (val) => _toggleRole(kpi, sales: val))),
                        DataCell(Switch(value: kpi.isEnabled, onChanged: (val) => _toggleStatus(kpi, val))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                                tooltip: 'Preview Live Drilldown',
                                onPressed: () {
                                  GenericKpiDrilldownDialog.show(
                                    context,
                                    kpiKey: kpi.kpiKey,
                                    kpiLabel: kpi.kpiLabel,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                tooltip: 'Edit in Builder',
                                onPressed: () => _initEdit(kpi),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Duplicate',
                                onPressed: () => _duplicate(kpi),
                              ),
                              if (!kpi.isSystem)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  tooltip: 'Delete KPI',
                                  onPressed: () => _deleteKpi(kpi),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: NO-CODE KPI BUILDER & DRILLDOWN COMPOSER
  // ==========================================
  Widget _buildBuilderTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ThemeManager().primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_note_rounded : Icons.auto_awesome_rounded,
                      color: ThemeManager().primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit KPI Definition' : 'Simple No-Code KPI Builder',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text(
                          'Create and configure a KPI with drilldown in 30–60 seconds without writing code or SQL.',
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    TextButton(onPressed: _resetBuilder, child: const Text('Cancel Edit')),
                ],
              ),
              const SizedBox(height: 20),

              // STEP 1: Basic Information
              _buildBuilderCard(
                title: '1. What do you want to measure?',
                subtitle: 'Enter the human-friendly name and purpose.',
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'KPI Name *',
                        hintText: 'e.g. Site Visits Done',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _onNameChanged,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _whyController,
                      decoration: const InputDecoration(
                        labelText: 'What does this KPI represent? *',
                        hintText: 'e.g. Number of completed physical property visits by clients',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_keyController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Machine Key: ${_keyController.text}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF6366F1)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STEP 2: Map Database Data (NO SQL!)
              _buildBuilderCard(
                title: '2. Where does this data come from?',
                subtitle: 'Select from registered entities and fields. No SQL required.',
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSourceId,
                            decoration: const InputDecoration(labelText: 'Data Source', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'site_visits', child: Text('Site Visits')),
                              DropdownMenuItem(value: 'properties', child: Text('Properties / Inventory')),
                              DropdownMenuItem(value: 'leads', child: Text('Leads (Direct & Campaigns)')),
                              DropdownMenuItem(value: 'requirements', child: Text('Sales Requirements')),
                              DropdownMenuItem(value: 'users', child: Text('Team Members')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSourceId = val;
                                  if (val == 'site_visits') {
                                    _selectedCountField = 'id';
                                    _selectedConditionField = 'status';
                                    _selectedConditionValue = 'DONE';
                                  } else if (val == 'properties') {
                                    _selectedCountField = 'id';
                                    _selectedConditionField = 'status';
                                    _selectedConditionValue = 'Available';
                                  } else if (val == 'leads') {
                                    _selectedCountField = 'id';
                                    _selectedConditionField = 'stage';
                                    _selectedConditionValue = 'INTERESTED';
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedAggregation,
                            decoration: const InputDecoration(labelText: 'What to calculate?', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'COUNT', child: Text('Count Records')),
                              DropdownMenuItem(value: 'COUNT_DISTINCT', child: Text('Count Unique')),
                              DropdownMenuItem(value: 'SUM', child: Text('Sum Value')),
                              DropdownMenuItem(value: 'AVG', child: Text('Average Value')),
                            ],
                            onChanged: (val) => setState(() => _selectedAggregation = val ?? 'COUNT'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasCondition,
                          onChanged: (val) => setState(() => _hasCondition = val ?? false),
                        ),
                        const Text('Add Status Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    if (_hasCondition) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _selectedConditionField,
                              decoration: const InputDecoration(labelText: 'Field', border: OutlineInputBorder()),
                              onChanged: (val) => _selectedConditionField = val,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('equals', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: _selectedConditionValue,
                              decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                              onChanged: (val) => _selectedConditionValue = val,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STEP 3: Where should this KPI appear?
              _buildBuilderCard(
                title: '3. Where should this KPI appear?',
                subtitle: 'Choose target dashboards and pages.',
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allPages.map((page) {
                    final isSelected = _selectedPages.contains(page);
                    return FilterChip(
                      label: Text(page),
                      selected: isSelected,
                      selectedColor: ThemeManager().primaryColor.withValues(alpha: 0.15),
                      checkmarkColor: ThemeManager().primaryColor,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPages.add(page);
                          } else {
                            _selectedPages.remove(page);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // STEP 4: Who can see this KPI?
              _buildBuilderCard(
                title: '4. Who can see this KPI?',
                subtitle: 'Enforced at both backend API and frontend views.',
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                child: Row(
                  children: [
                    _buildRoleCheckbox('Admin', _adminVisible, (v) => setState(() => _adminVisible = v)),
                    const SizedBox(width: 24),
                    _buildRoleCheckbox('Telecaller', _telecallerVisible, (v) => setState(() => _telecallerVisible = v)),
                    const SizedBox(width: 24),
                    _buildRoleCheckbox('Sales User', _salesVisible, (v) => setState(() => _salesVisible = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STEP 5: Display Type & Advanced Settings
              _buildBuilderCard(
                title: '5. How should it appear?',
                subtitle: 'Select component style. Advanced settings optional.',
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      children: ['KPI Card', 'Table Metric', 'Status Metric', 'Chart'].map((style) {
                        final isSel = _uiComponent == style;
                        return ChoiceChip(
                          label: Text(style),
                          selected: isSel,
                          onSelected: (val) => setState(() => _uiComponent = style),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    ExpansionTile(
                      title: const Text('Advanced Settings (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedIcon,
                                decoration: const InputDecoration(labelText: 'Icon', border: OutlineInputBorder()),
                                items: _iconCatalog.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Row(
                                      children: [
                                        Icon(entry.value, size: 18),
                                        const SizedBox(width: 8),
                                        Text(entry.key.replaceAll('_rounded', '')),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedIcon = val ?? 'insights_rounded'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _orderController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Display Order', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STEP 6: Make KPI Clickable & Drilldown Builder
              _buildBuilderCard(
                title: '6. Make this KPI clickable?',
                subtitle: 'Configure interactive drilldown behavior when clicked.',
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('No (Static Card)'),
                          selected: !_isClickable,
                          onSelected: (val) => setState(() => _isClickable = !val),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Yes (Interactive Drilldown)'),
                          selected: _isClickable,
                          onSelected: (val) => setState(() => _isClickable = val),
                        ),
                      ],
                    ),
                    if (_isClickable) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Drilldown Layout Components', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Sub-KPI'),
                                onPressed: _openAddSubKpiDialog,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.bar_chart_rounded, size: 16),
                                label: const Text('Chart'),
                                onPressed: _openAddChartDialog,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.table_rows_rounded, size: 16),
                                label: const Text('Table'),
                                onPressed: _openAddTableDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(_drilldownComponents.length, (idx) {
                        final comp = _drilldownComponents[idx];
                        final cTitle = comp['title']?.toString() ?? 'Component';
                        final cType = comp['type']?.toString() ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cType == 'kpi_group'
                                    ? Icons.space_dashboard_rounded
                                    : cType == 'chart'
                                        ? Icons.bar_chart_rounded
                                        : cType == 'status_breakdown'
                                            ? Icons.pie_chart_outline_rounded
                                            : Icons.table_chart_rounded,
                                size: 18,
                                color: ThemeManager().primaryColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('Type: $cType', style: TextStyle(fontSize: 11, color: subColor)),
                                  ],
                                ),
                              ),
                              if (idx > 0)
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      final item = _drilldownComponents.removeAt(idx);
                                      _drilldownComponents.insert(idx - 1, item);
                                    });
                                  },
                                ),
                              if (idx < _drilldownComponents.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      final item = _drilldownComponents.removeAt(idx);
                                      _drilldownComponents.insert(idx + 1, item);
                                    });
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                onPressed: () {
                                  setState(() => _drilldownComponents.removeAt(idx));
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // LIVE PREVIEW CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ThemeManager().primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_rounded, size: 18, color: ThemeManager().primaryColor),
                        const SizedBox(width: 8),
                        Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                        const Spacer(),
                        if (_isClickable)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded, size: 16),
                            label: const Text('Test Drilldown Preview'),
                            onPressed: () {
                              GenericKpiDrilldownDialog.show(
                                context,
                                kpiKey: _keyController.text.isNotEmpty ? _keyController.text : 'site_visits_done',
                                kpiLabel: _nameController.text.isNotEmpty ? _nameController.text : 'Site Visits Done',
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Simulated Stat Card
                    Container(
                      width: 240,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _nameController.text.isNotEmpty ? _nameController.text : 'Site Visits Done',
                                style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500),
                              ),
                              Icon(_getIconData(_selectedIcon), size: 20, color: ThemeManager().primaryColor),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('87', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                          if (_isClickable) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Click to view drilldown', style: TextStyle(fontSize: 11, color: ThemeManager().primaryColor)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 12, color: ThemeManager().primaryColor),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: _resetBuilder, child: const Text('Reset Form')),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(_isEditing ? 'Update KPI' : 'Save & Publish KPI'),
                    onPressed: _saveKpi,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuilderCard({
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRoleCheckbox(String label, bool isChecked, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (val) => onChanged(val ?? false),
        ),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ==========================================
  // TAB 3: ROLE VISIBILITY MATRIX
  // ==========================================
  Widget _buildRoleMatrixTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KPI Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Sales User', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Active', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(_kpiList.length, (index) {
                    final kpi = _kpiList[index];
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}', style: TextStyle(color: subColor))),
                        DataCell(Text(kpi.kpiLabel, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Checkbox(value: kpi.adminVisible, onChanged: (v) => _toggleRole(kpi, admin: v))),
                        DataCell(Checkbox(value: kpi.telecallerVisible, onChanged: (v) => _toggleRole(kpi, telecaller: v))),
                        DataCell(Checkbox(value: kpi.salesVisible, onChanged: (v) => _toggleRole(kpi, sales: v))),
                        DataCell(Switch(value: kpi.isEnabled, onChanged: (v) => _toggleStatus(kpi, v))),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: AUDIT HISTORY
  // ==========================================
  Widget _buildAuditHistoryTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KPI Audit & Mapping History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadAuditLogs),
                ],
              ),
              const SizedBox(height: 12),
              if (_auditLogs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text('No audit events recorded yet.', style: TextStyle(color: subColor)),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('KPI', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Performed By', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date / Time', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _auditLogs.map((log) {
                      final actionColor = log.action == 'CREATED'
                          ? Colors.green
                          : log.action == 'DELETED'
                              ? Colors.red
                              : Colors.blue;

                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log.action,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: actionColor),
                              ),
                            ),
                          ),
                          DataCell(Text(log.kpiLabel ?? log.kpiKey ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(log.performedByName ?? log.performedByEmail ?? 'Admin', style: TextStyle(color: subColor))),
                          DataCell(Text(log.createdAt?.toLocal().toString().split('.').first ?? '-', style: TextStyle(color: subColor, fontSize: 12))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
