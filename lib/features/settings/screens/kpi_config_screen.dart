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

class _KpiConfigScreenState extends State<KpiConfigScreen> {
  final DashboardService _service = DashboardService();
  int _activeTabIndex = 0; // 0: Registry, 1: Builder, 2: Role Visibility, 3: Audit History

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  List<KpiRegistryItem> _kpiList = [];
  List<KpiAuditLogItem> _auditLogs = [];

  // Filter States for Registry Table
  String _searchQuery = '';
  String _selectedPageFilter = 'All';
  String _selectedRoleFilter = 'All';
  final String _selectedStatusFilter = 'All';

  // Builder State
  bool _isEditing = false;
  String? _editingKpiId;
  final _nameController = TextEditingController();
  final _whyController = TextEditingController();
  final _keyController = TextEditingController();
  final _orderController = TextEditingController(text: '10');

  // Friendly Data Source Selection
  String _selectedSourceId = 'site_visits';
  String _selectedCountType = 'records'; // 'records', 'unique', 'sum', 'avg'
  List<Map<String, String>> _activeFilters = [
    {'field': 'status', 'operator': '=', 'value': 'DONE'}
  ];

  // Pages & Roles
  final List<String> _selectedPages = ['Admin Dashboard'];
  bool _adminVisible = true;
  bool _telecallerVisible = false;
  bool _salesVisible = false;
  String _uiComponent = 'KPI Card';
  final String _displayFormat = 'Count';
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
    'trending_up_rounded': Icons.trending_up_rounded,
    'check_circle_rounded': Icons.check_circle_rounded,
  };

  final List<Map<String, dynamic>> _dataSources = [
    {
      'id': 'site_visits',
      'label': 'Site Visits',
      'description': 'Customer property visits and in-person tours',
      'icon': Icons.location_on_rounded,
      'defaultField': 'id',
      'defaultDate': 'created_at',
      'filterFields': [
        {'id': 'status', 'label': 'Status', 'values': ['DONE', 'SCHEDULED', 'CANCELLED', 'REJECTED_AFTER_VISIT']},
        {'id': 'outcome', 'label': 'Outcome', 'values': ['INTERESTED', 'REJECTED_AFTER_VISIT', 'OFFER_MADE', 'CANCELLED']},
      ],
    },
    {
      'id': 'properties',
      'label': 'Properties / Inventory',
      'description': 'Marketable units, rentals, and resale listings',
      'icon': Icons.home_work_rounded,
      'defaultField': 'id',
      'defaultDate': 'created_at',
      'filterFields': [
        {'id': 'status', 'label': 'Status', 'values': ['Available', 'Sold', 'Rented', 'Draft']},
        {'id': 'listing_type', 'label': 'Listing Type', 'values': ['Rent', 'Re-sale']},
        {'id': 'property_type', 'label': 'Property Type', 'values': ['Apartment', 'Villa', 'Plot', 'Commercial']},
      ],
    },
    {
      'id': 'leads',
      'label': 'Leads (Direct & Campaigns)',
      'description': 'Inbound prospects from Meta, Housing, and manual entry',
      'icon': Icons.assignment_rounded,
      'defaultField': 'id',
      'defaultDate': 'created_at',
      'filterFields': [
        {'id': 'campaign_status', 'label': 'Campaign Status', 'values': ['NEW', 'CONTACTED', 'INTERESTED', 'NOT_INTERESTED']},
        {'id': 'source', 'label': 'Source', 'values': ['Meta Ads', 'Housing', 'Manual', 'Webhook API']},
        {'id': 'lead_type', 'label': 'Lead Type', 'values': ['Listing', 'Requirement', 'Both']},
      ],
    },
    {
      'id': 'requirements',
      'label': 'Requirements',
      'description': 'Buyer and tenant requirement demands',
      'icon': Icons.badge_rounded,
      'defaultField': 'id',
      'defaultDate': 'created_at',
      'filterFields': [
        {'id': 'status', 'label': 'Status', 'values': ['Active', 'Closed', 'Matched']},
        {'id': 'listing_type', 'label': 'Listing Type', 'values': ['Rent', 'Re-sale']},
      ],
    },
    {
      'id': 'users',
      'label': 'Team Members',
      'description': 'Admins, telecallers, and sales executives',
      'icon': Icons.groups_rounded,
      'defaultField': 'id',
      'defaultDate': 'created_at',
      'filterFields': [
        {'id': 'role', 'label': 'Role', 'values': ['admin', 'telecaller', 'sales']},
        {'id': 'status', 'label': 'Status', 'values': ['active', 'inactive']},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initDefaultDrilldownComponents();
    _loadAll();
  }

  @override
  void dispose() {
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
        'title': 'Recent Records',
        'columns': ['Customer', 'Property', 'Date', 'Status'],
        'data_source': 'site_visits',
      },
    ];
  }

  IconData _getIconData(String iconName) {
    return _iconCatalog[iconName] ?? Icons.insights_rounded;
  }

  Map<String, dynamic> _getCurrentSourceDef() {
    return _dataSources.firstWhere(
      (s) => s['id'] == _selectedSourceId,
      orElse: () => _dataSources.first,
    );
  }

  String get _mappedAggregation {
    switch (_selectedCountType) {
      case 'unique':
        return 'COUNT_DISTINCT';
      case 'sum':
        return 'SUM';
      case 'avg':
        return 'AVG';
      case 'records':
      default:
        return 'COUNT';
    }
  }

  String get _mappedPrimaryField {
    if (_selectedSourceId == 'site_visits' && _selectedCountType == 'unique') {
      return 'lead_id';
    }
    return 'id';
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
      if (mounted) {
        setState(() {
          _kpiList = kpis;
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
      _selectedCountType = 'records';
      _activeFilters = [
        {'field': 'status', 'operator': '=', 'value': 'DONE'}
      ];
      _selectedPages.clear();
      _selectedPages.add('Admin Dashboard');
      _adminVisible = true;
      _telecallerVisible = false;
      _salesVisible = false;
      _uiComponent = 'KPI Card';
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
      if (kpi.aggregation == 'COUNT_DISTINCT') {
        _selectedCountType = 'unique';
      } else if (kpi.aggregation == 'SUM') {
        _selectedCountType = 'sum';
      } else if (kpi.aggregation == 'AVG') {
        _selectedCountType = 'avg';
      } else {
        _selectedCountType = 'records';
      }

      _selectedPages.clear();
      _selectedPages.addAll(kpi.pages);
      _adminVisible = kpi.adminVisible;
      _telecallerVisible = kpi.telecallerVisible;
      _salesVisible = kpi.salesVisible;
      _uiComponent = kpi.uiComponent;
      _selectedIcon = kpi.icon;
      _isClickable = kpi.isClickable;

      if (kpi.conditionsJson.isNotEmpty) {
        _activeFilters = kpi.conditionsJson
            .whereType<Map>()
            .map((c) => {
                  'field': c['field']?.toString() ?? 'status',
                  'operator': c['operator']?.toString() ?? '=',
                  'value': c['value']?.toString() ?? '',
                })
            .toList();
      } else {
        _activeFilters = [];
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
      _activeTabIndex = 1;
    });
  }

  void _duplicate(KpiRegistryItem kpi) {
    _resetBuilder();
    setState(() {
      _nameController.text = '${kpi.kpiLabel} (Copy)';
      _whyController.text = kpi.whyDoWeHaveIt;
      _keyController.text = '${kpi.kpiKey}_copy';
      _selectedSourceId = kpi.dataSource;
      if (kpi.aggregation == 'COUNT_DISTINCT') {
        _selectedCountType = 'unique';
      } else {
        _selectedCountType = 'records';
      }
      _selectedPages.clear();
      _selectedPages.addAll(kpi.pages);
      _adminVisible = kpi.adminVisible;
      _telecallerVisible = kpi.telecallerVisible;
      _salesVisible = kpi.salesVisible;
      _uiComponent = kpi.uiComponent;
      _selectedIcon = kpi.icon;
      _isClickable = kpi.isClickable;
      if (kpi.drilldownConfig.containsKey('components') &&
          kpi.drilldownConfig['components'] is List) {
        _drilldownComponents = List<Map<String, dynamic>>.from(
          (kpi.drilldownConfig['components'] as List)
              .map((c) => Map<String, dynamic>.from(c)),
        );
      }
      _activeTabIndex = 1;
    });
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

    final payload = {
      'kpi_name': name,
      'kpi_label': name,
      'kpi_key': _keyController.text.trim().isNotEmpty
          ? _keyController.text.trim()
          : name.toLowerCase().replaceAll(' ', '_'),
      'why_do_we_have_it': why,
      'data_source': _selectedSourceId,
      'entity_table': _selectedSourceId,
      'primary_field': _mappedPrimaryField,
      'aggregation': _mappedAggregation,
      'conditions_json': _activeFilters,
      'date_field': _getCurrentSourceDef()['defaultDate'] ?? 'created_at',
      'database_mapping_description': '$_selectedSourceId ($_mappedAggregation) ${_activeFilters.isNotEmpty ? "WHERE ${_activeFilters.map((f) => "${f['field']} ${f['operator']} ${f['value']}").join(" AND ")}" : ""}',
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
      setState(() => _activeTabIndex = 0);
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

  // ==========================================
  // DRILLDOWN COMPONENT ADD DIALOGS
  // ==========================================
  void _openAddSubKpiDialog() {
    String subLabel = 'Scheduled';
    String subStatus = 'SCHEDULED';
    String? selectedKpiKey;
    bool isCustom = false;
    bool isSecondaryClickable = true;
    String? nextDrilldownKey;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Sub-KPI to Drilldown'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      label: const Text('Create New Sub-Metric'),
                      selected: isCustom,
                      onSelected: (val) => setDlgState(() => isCustom = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isCustom) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Choose Registered KPI', border: OutlineInputBorder()),
                    items: _kpiList.map((k) {
                      return DropdownMenuItem(value: k.kpiKey, child: Text(k.kpiLabel));
                    }).toList(),
                    onChanged: (val) => selectedKpiKey = val,
                  ),
                ] else ...[
                  TextFormField(
                    initialValue: subLabel,
                    decoration: const InputDecoration(labelText: 'Metric Label', hintText: 'e.g. Scheduled Visits', border: OutlineInputBorder()),
                    onChanged: (val) => subLabel = val,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: subStatus,
                    decoration: const InputDecoration(labelText: 'Target Status Filter', hintText: 'e.g. SCHEDULED', border: OutlineInputBorder()),
                    onChanged: (val) => subStatus = val,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isSecondaryClickable,
                      onChanged: (val) => setDlgState(() => isSecondaryClickable = val ?? true),
                    ),
                    const Text('Make this Sub-KPI clickable (Nested Drilldown)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (isSecondaryClickable) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Target Nested Drilldown', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: 'filtered_records', child: Text('Open Filtered Records List')),
                      ..._kpiList.map((k) => DropdownMenuItem(value: k.kpiKey, child: Text('Open ${k.kpiLabel} Drilldown'))),
                    ],
                    onChanged: (val) => nextDrilldownKey = val,
                  ),
                ],
              ],
            ),
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
                      'id': 'comp_kpis_${DateTime.now().millisecondsSinceEpoch}',
                      'type': 'kpi_group',
                      'title': 'Status Summary',
                      'items': [],
                    };
                    _drilldownComponents.insert(0, kpiGroupComp);
                  }
                  final items = (kpiGroupComp['items'] as List?) ?? [];
                  if (isCustom) {
                    items.add({
                      'label': subLabel,
                      'status': subStatus,
                      'is_clickable': isSecondaryClickable,
                      if (nextDrilldownKey != null) 'next_drilldown_kpi': nextDrilldownKey,
                    });
                  } else if (selectedKpiKey != null) {
                    final matched = _kpiList.firstWhere((k) => k.kpiKey == selectedKpiKey);
                    items.add({
                      'label': matched.kpiLabel,
                      'kpi_key': matched.kpiKey,
                      'is_clickable': isSecondaryClickable,
                      if (nextDrilldownKey != null) 'next_drilldown_kpi': nextDrilldownKey,
                    });
                  }
                  kpiGroupComp['items'] = items;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add to Drilldown'),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
    final Set<String> selectedCols = {'Customer', 'Property', 'Date', 'Status'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Records Table to Drilldown'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: tableTitle,
                decoration: const InputDecoration(labelText: 'Table Title', border: OutlineInputBorder()),
                onChanged: (val) => tableTitle = val,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: dataSource,
                decoration: const InputDecoration(labelText: 'Data Source', border: OutlineInputBorder()),
                items: _dataSources.map((ds) {
                  return DropdownMenuItem(value: ds['id'] as String, child: Text(ds['label'] as String));
                }).toList(),
                onChanged: (val) => setDlgState(() => dataSource = val ?? 'site_visits'),
              ),
              const SizedBox(height: 12),
              const Text('Visible Columns:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ['Customer', 'Property', 'Sales User', 'Date', 'Status', 'Phone'].map((col) {
                  final isSel = selectedCols.contains(col);
                  return FilterChip(
                    label: Text(col),
                    selected: isSel,
                    onSelected: (val) {
                      setDlgState(() {
                        if (val) {
                          selectedCols.add(col);
                        } else {
                          selectedCols.remove(col);
                        }
                      });
                    },
                  );
                }).toList(),
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
                    'columns': selectedCols.toList(),
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddStatusBreakdownDialog() {
    String title = 'Status Breakdown';
    String dimension = 'status';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Status Breakdown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: title,
              decoration: const InputDecoration(labelText: 'Breakdown Title', border: OutlineInputBorder()),
              onChanged: (val) => title = val,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: dimension,
              decoration: const InputDecoration(labelText: 'Dimension', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'status', child: Text('Status')),
                DropdownMenuItem(value: 'stage', child: Text('Stage')),
                DropdownMenuItem(value: 'source', child: Text('Source')),
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
                  'id': 'breakdown_${DateTime.now().millisecondsSinceEpoch}',
                  'type': 'status_breakdown',
                  'title': title,
                  'dimension': dimension,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add Breakdown'),
          ),
        ],
      ),
    );
  }

  void _openAddFilterDialog() {
    String filterTitle = 'Sales User Filter';
    String filterKey = 'sales_user';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Filter to Drilldown'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: filterTitle,
              decoration: const InputDecoration(labelText: 'Filter Label', border: OutlineInputBorder()),
              onChanged: (val) => filterTitle = val,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: filterKey,
              decoration: const InputDecoration(labelText: 'Filter Dimension', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'sales_user', child: Text('Sales User')),
                DropdownMenuItem(value: 'telecaller', child: Text('Telecaller')),
                DropdownMenuItem(value: 'lead_source', child: Text('Lead Source')),
                DropdownMenuItem(value: 'property_type', child: Text('Property Type')),
                DropdownMenuItem(value: 'date_range', child: Text('Date Range')),
              ],
              onChanged: (val) => filterKey = val ?? 'sales_user',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _drilldownComponents.add({
                  'id': 'filter_${DateTime.now().millisecondsSinceEpoch}',
                  'type': 'filter',
                  'title': filterTitle,
                  'filter_key': filterKey,
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add Filter'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROOT BUILD METHOD (STABLE CONTAINER)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header Bar
          _buildTopHeader(cardBg, textColor, subColor, borderColor),

          // 2. Segmented Navigation Bar
          _buildSegmentedTabBar(cardBg, textColor, subColor, borderColor),

          // 3. Tab Body
          Expanded(
            child: _buildCurrentTab(cardBg, textColor, subColor, borderColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ThemeManager().primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.dashboard_customize_outlined, color: ThemeManager().primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KPI Registry & No-Code Builder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  'Centralized registry for metrics, guided database mappings, and visual drilldowns.',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Registry',
            onPressed: _loadAll,
          ),
          if (_activeTabIndex == 0) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('+ Add KPI'),
              onPressed: () {
                _resetBuilder();
                setState(() => _activeTabIndex = 1);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegmentedTabBar(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    final tabs = [
      {'index': 0, 'label': 'KPI Registry (${_kpiList.length})', 'icon': Icons.table_chart_rounded},
      {'index': 1, 'label': _isEditing ? 'Edit KPI' : '+ No-Code Builder', 'icon': _isEditing ? Icons.edit_rounded : Icons.auto_awesome_rounded},
      {'index': 2, 'label': 'Role Visibility Matrix', 'icon': Icons.security_rounded},
      {'index': 3, 'label': 'Audit History', 'icon': Icons.history_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeManager().isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final idx = t['index'] as int;
            final isSelected = _activeTabIndex == idx;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _activeTabIndex = idx;
                    if (_activeTabIndex == 3 && _auditLogs.isEmpty) {
                      _loadAuditLogs();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? ThemeManager().primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        t['icon'] as IconData,
                        size: 15,
                        color: isSelected ? Colors.white : subColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    switch (_activeTabIndex) {
      case 0:
        return _buildRegistryTab(cardBg, textColor, subColor, borderColor);
      case 1:
        return _buildBuilderTab(cardBg, textColor, subColor, borderColor);
      case 2:
        return _buildRoleMatrixTab(cardBg, textColor, subColor, borderColor);
      case 3:
        return _buildAuditHistoryTab(cardBg, textColor, subColor, borderColor);
      default:
        return _buildRegistryTab(cardBg, textColor, subColor, borderColor);
    }
  }

  // ==========================================
  // TAB 1: KPI REGISTRY TABLE
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search KPIs...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    final curSource = _getCurrentSourceDef();

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
                          'Name your metric, choose data source, select dashboards, and visually compose the drilldown.',
                          style: TextStyle(fontSize: 13, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing)
                    TextButton(
                      onPressed: () {
                        _resetBuilder();
                        setState(() => _activeTabIndex = 0);
                      },
                      child: const Text('Cancel Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // STEP 1: What do you want to measure?
              _buildBuilderCard(
                title: '1. What do you want to call it?',
                subtitle: 'Enter the human-readable KPI name and business description.',
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
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key_rounded, size: 14, color: Color(0xFF6366F1)),
                            const SizedBox(width: 6),
                            Text(
                              'Auto-generated KPI Key: ${_keyController.text}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STEP 2: Where does its data come from?
              _buildBuilderCard(
                title: '2. Where does its data come from?',
                subtitle: 'Select from available business entities and friendly filters without writing SQL.',
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
                            items: _dataSources.map((ds) {
                              return DropdownMenuItem(
                                value: ds['id'] as String,
                                child: Row(
                                  children: [
                                    Icon(ds['icon'] as IconData, size: 18, color: ThemeManager().primaryColor),
                                    const SizedBox(width: 8),
                                    Text(ds['label'] as String),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSourceId = val;
                                  _activeFilters.clear();
                                  if (val == 'site_visits') {
                                    _activeFilters.add({'field': 'status', 'operator': '=', 'value': 'DONE'});
                                  } else if (val == 'properties') {
                                    _activeFilters.add({'field': 'status', 'operator': '=', 'value': 'Available'});
                                  } else if (val == 'leads') {
                                    _activeFilters.add({'field': 'campaign_status', 'operator': '=', 'value': 'INTERESTED'});
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCountType,
                            decoration: const InputDecoration(labelText: 'Count Method', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'records', child: Text('Count Records (Total)')),
                              DropdownMenuItem(value: 'unique', child: Text('Count Unique Leads / Users')),
                              DropdownMenuItem(value: 'sum', child: Text('Sum of Value')),
                              DropdownMenuItem(value: 'avg', child: Text('Average of Value')),
                            ],
                            onChanged: (val) => setState(() => _selectedCountType = val ?? 'records'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Active Filters Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Data Filters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        TextButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Filter'),
                          onPressed: () {
                            final filterFields = curSource['filterFields'] as List;
                            final firstField = filterFields.first;
                            setState(() {
                              _activeFilters.add({
                                'field': firstField['id'] as String,
                                'operator': '=',
                                'value': (firstField['values'] as List).first as String,
                              });
                            });
                          },
                        ),
                      ],
                    ),
                    if (_activeFilters.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('No filters applied (All records in $_selectedSourceId will be counted)', style: TextStyle(fontSize: 12, color: subColor)),
                      )
                    else
                      ...List.generate(_activeFilters.length, (idx) {
                        final filter = _activeFilters[idx];
                        final filterFields = curSource['filterFields'] as List;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ThemeManager().isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              DropdownButton<String>(
                                value: filter['field'],
                                underline: const SizedBox(),
                                items: filterFields.map<DropdownMenuItem<String>>((f) {
                                  return DropdownMenuItem(value: f['id'] as String, child: Text(f['label'] as String, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final fDef = filterFields.firstWhere((f) => f['id'] == val);
                                    setState(() {
                                      filter['field'] = val;
                                      filter['value'] = (fDef['values'] as List).first as String;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text('equals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: filter['value'],
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (val) => filter['value'] = val,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                onPressed: () => setState(() => _activeFilters.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 10),
                    // Technical Mapping Accordion
                    ExpansionTile(
                      title: const Text('Advanced / Technical Mapping', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ThemeManager().isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Table: $_selectedSourceId', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                              Text('Field: $_mappedPrimaryField', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                              Text('Aggregation: $_mappedAggregation', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                              Text('Date Field: ${curSource['defaultDate']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                              Text('Filters: ${_activeFilters.toString()}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // STEP 3: Where should it appear?
              _buildBuilderCard(
                title: '3. Where should this KPI appear?',
                subtitle: 'Choose target dashboards and pages for this metric.',
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
                subtitle: 'Enforced at both backend API and frontend role-based access control.',
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

              // STEP 5: Visual Presentation
              _buildBuilderCard(
                title: '5. Visual Presentation',
                subtitle: 'Select component card type and display icon.',
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
                    const SizedBox(height: 12),
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
              ),
              const SizedBox(height: 16),

              // STEP 6: Visual Drilldown Builder
              _buildBuilderCard(
                title: '6. Should users be able to click this KPI?',
                subtitle: 'Visually compose the drilldown view that appears upon tap.',
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
                          Text('What should users see when they click?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 15),
                                label: const Text('KPI'),
                                onPressed: _openAddSubKpiDialog,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.filter_list_rounded, size: 15),
                                label: const Text('Filter'),
                                onPressed: _openAddFilterDialog,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.bar_chart_rounded, size: 15),
                                label: const Text('Chart'),
                                onPressed: _openAddChartDialog,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.table_rows_rounded, size: 15),
                                label: const Text('Table'),
                                onPressed: _openAddTableDialog,
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.pie_chart_outline_rounded, size: 15),
                                label: const Text('Status'),
                                onPressed: _openAddStatusBreakdownDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_drilldownComponents.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('No drilldown components added yet. Use the buttons above to compose.', style: TextStyle(fontSize: 12, color: subColor)),
                        )
                      else
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
                                          : cType == 'filter'
                                              ? Icons.filter_list_rounded
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
                                    tooltip: 'Move Up',
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
                                    tooltip: 'Move Down',
                                    onPressed: () {
                                      setState(() {
                                        final item = _drilldownComponents.removeAt(idx);
                                        _drilldownComponents.insert(idx + 1, item);
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                  tooltip: 'Remove',
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
              const SizedBox(height: 20),

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

              // SAVE ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _resetBuilder();
                      setState(() => _activeTabIndex = 0);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isEditing ? 'Update KPI' : 'Save KPI Definition'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _saveKpi,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRoleCheckbox(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (val) => onChanged(val ?? false),
        ),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
                        DataCell(Text('${index + 1}', style: TextStyle(color: subColor, fontSize: 13))),
                        DataCell(Text(kpi.kpiLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        DataCell(Checkbox(value: kpi.adminVisible, onChanged: (val) => _toggleRole(kpi, admin: val))),
                        DataCell(Checkbox(value: kpi.telecallerVisible, onChanged: (val) => _toggleRole(kpi, telecaller: val))),
                        DataCell(Checkbox(value: kpi.salesVisible, onChanged: (val) => _toggleRole(kpi, sales: val))),
                        DataCell(Switch(value: kpi.isEnabled, onChanged: (val) => _toggleStatus(kpi, val))),
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
                  child: Text('No audit logs recorded yet.', style: TextStyle(color: subColor)),
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
                      DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _auditLogs.map((log) {
                      final actionColor = log.action == 'CREATED'
                          ? Colors.green
                          : log.action == 'DELETED'
                              ? Colors.red
                              : Colors.orange;

                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: actionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(log.action, style: TextStyle(color: actionColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          DataCell(Text(log.kpiLabel ?? log.kpiKey ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                          DataCell(Text(log.performedByName ?? log.performedByEmail ?? 'Admin User', style: TextStyle(fontSize: 12, color: subColor))),
                          DataCell(Text(log.createdAt != null ? '${log.createdAt!.toLocal()}'.split('.')[0] : '-', style: TextStyle(fontSize: 12, color: subColor))),
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
