import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_manager.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/models/kpi_models.dart';
import '../../dashboard/services/dashboard_service.dart';

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

  // Filter States
  String _searchQuery = '';
  String _selectedPageFilter = 'All';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  // Add / Edit Wizard State
  int _wizardStep = 0;
  bool _isEditing = false;
  String? _editingKpiId;
  final _formKey = GlobalKey<FormState>();

  // Wizard Field Controllers & Values
  final _nameController = TextEditingController();
  final _keyController = TextEditingController();
  final _whyController = TextEditingController();
  final _descController = TextEditingController();
  final _orderController = TextEditingController(text: '10');
  final _relationshipsController = TextEditingController();
  final _filterJsonController = TextEditingController();
  final _dbMappingDescController = TextEditingController();
  final _drilldownDescController = TextEditingController();

  String _dataSource = 'leads';
  String _entityTable = 'leads';
  String _primaryField = 'id';
  String _aggregation = 'COUNT';
  String _dateField = 'created_at';
  final List<String> _selectedPages = ['Admin Dashboard'];
  String _uiComponent = 'Dashboard KPI Card';
  String _displayFormat = 'Count';
  String _selectedIcon = 'insights_rounded';
  bool _isClickable = true;
  String _drilldownType = 'Modal';
  String? _drilldownRoute = '/leads';
  String? _drilldownApi = '/api/v1/dashboard/leads-breakdown';
  bool _secondLevelEnabled = false;

  bool _adminVisible = true;
  bool _telecallerVisible = false;
  bool _salesVisible = false;
  bool _isEnabled = true;

  // Available options
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

  final List<String> _dataSources = [
    'properties',
    'leads',
    'integration_leads',
    'users',
    'site_visits',
    'requirements',
    'custom',
  ];

  final List<String> _aggregations = [
    'COUNT',
    'COUNT_DISTINCT',
    'SUM',
    'AVG',
    'MIN',
    'MAX',
    'RATIO',
  ];

  final List<String> _uiComponents = [
    'Dashboard KPI Card',
    'Summary Metric',
    'Table Metric',
    'Status Chip',
    'Map Metric',
    'Modal KPI',
    'Lifecycle KPI',
  ];

  final List<String> _displayFormats = [
    'Count',
    'Percentage',
    'Currency',
    'Decimal',
    'Duration',
  ];

  final List<String> _drilldownTypes = [
    'Modal',
    'Drawer',
    'Existing Page',
    'Filtered List',
    'Detail Page',
  ];

  final Map<String, IconData> _iconCatalog = {
    'home_work_rounded': Icons.home_work_rounded,
    'assignment_rounded': Icons.assignment_rounded,
    'support_agent_rounded': Icons.support_agent_rounded,
    'assignment_ind_rounded': Icons.assignment_ind_rounded,
    'history_toggle_off_rounded': Icons.history_toggle_off_rounded,
    'badge_rounded': Icons.badge_rounded,
    'location_on_rounded': Icons.location_on_rounded,
    'cancel_presentation_rounded': Icons.cancel_presentation_rounded,
    'emoji_events_rounded': Icons.emoji_events_rounded,
    'groups_rounded': Icons.groups_rounded,
    'phone_disabled_rounded': Icons.phone_disabled_rounded,
    'map_rounded': Icons.map_rounded,
    'trending_up_rounded': Icons.trending_up_rounded,
    'compare_arrows_rounded': Icons.compare_arrows_rounded,
    'bar_chart_rounded': Icons.bar_chart_rounded,
    'pie_chart_rounded': Icons.pie_chart_rounded,
    'insights_rounded': Icons.insights_rounded,
    'analytics_rounded': Icons.analytics_rounded,
    'inventory_2_rounded': Icons.inventory_2_rounded,
    'person_search_rounded': Icons.person_search_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRegistry();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _keyController.dispose();
    _whyController.dispose();
    _descController.dispose();
    _orderController.dispose();
    _relationshipsController.dispose();
    _filterJsonController.dispose();
    _dbMappingDescController.dispose();
    _drilldownDescController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    return _iconCatalog[iconName] ?? Icons.insights_rounded;
  }

  Future<void> _loadRegistry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await _service.getKpiRegistry(
        search: _searchQuery,
        page: _selectedPageFilter,
        role: _selectedRoleFilter,
        status: _selectedStatusFilter,
      );
      if (mounted) {
        setState(() {
          _kpiList = list;
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

  Future<void> _onToggleStatus(KpiRegistryItem kpi, bool isEnabled) async {
    setState(() => _isSaving = true);
    final ok = await _service.toggleKpiRegistryStatus(kpi.id, isEnabled);
    if (ok) {
      // Notify DashboardBloc so main dashboard updates reactively
      if (mounted) {
        context.read<DashboardBloc>().add(
              ToggleKpiConfig(kpiKey: kpi.kpiKey, isEnabled: isEnabled),
            );
      }
      _loadRegistry();
      _showFeedback(
        'KPI "${kpi.kpiLabel}" ${isEnabled ? "enabled" : "disabled"}.',
        isSuccess: true,
      );
    } else {
      _showFeedback('Failed to update status.', isSuccess: false);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _onToggleRole(
    KpiRegistryItem kpi, {
    bool? admin,
    bool? telecaller,
    bool? sales,
  }) async {
    final newAdmin = admin ?? kpi.adminVisible;
    final newTele = telecaller ?? kpi.telecallerVisible;
    final newSales = sales ?? kpi.salesVisible;

    if (!newAdmin && !newTele && !newSales) {
      _showFeedback('At least one role must remain visible.', isSuccess: false);
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
      _loadRegistry();
    } catch (e) {
      _showFeedback('Failed to update role visibility: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteKpi(KpiRegistryItem kpi) async {
    if (kpi.isSystem) {
      _showFeedback(
        'System canonical KPIs cannot be deleted. You can disable them instead.',
        isSuccess: false,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Custom KPI?'),
        content: Text(
          'Are you sure you want to delete "${kpi.kpiLabel}" (${kpi.kpiKey})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await _service.deleteKpiRegistryItem(kpi.id);
        _showFeedback('KPI deleted successfully.', isSuccess: true);
        _loadRegistry();
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

  void _resetWizard() {
    _isEditing = false;
    _editingKpiId = null;
    _wizardStep = 0;
    _nameController.clear();
    _keyController.clear();
    _whyController.clear();
    _descController.clear();
    _orderController.text = '10';
    _relationshipsController.clear();
    _filterJsonController.clear();
    _dbMappingDescController.clear();
    _drilldownDescController.clear();
    _dataSource = 'leads';
    _entityTable = 'leads';
    _primaryField = 'id';
    _aggregation = 'COUNT';
    _dateField = 'created_at';
    _selectedPages.clear();
    _selectedPages.add('Admin Dashboard');
    _uiComponent = 'Dashboard KPI Card';
    _displayFormat = 'Count';
    _selectedIcon = 'insights_rounded';
    _isClickable = true;
    _drilldownType = 'Modal';
    _drilldownRoute = '/leads';
    _drilldownApi = '/api/v1/dashboard/leads-breakdown';
    _secondLevelEnabled = false;
    _adminVisible = true;
    _telecallerVisible = false;
    _salesVisible = false;
    _isEnabled = true;
  }

  void _initEditWizard(KpiRegistryItem kpi) {
    _isEditing = true;
    _editingKpiId = kpi.id;
    _wizardStep = 0;
    _nameController.text = kpi.kpiLabel;
    _keyController.text = kpi.kpiKey;
    _whyController.text = kpi.whyDoWeHaveIt;
    _descController.text = kpi.description ?? '';
    _orderController.text = kpi.displayOrder.toString();
    _relationshipsController.text = kpi.relationships ?? '';
    _filterJsonController.text =
        kpi.conditionsJson.isNotEmpty ? kpi.conditionsJson.toString() : '';
    _dbMappingDescController.text = kpi.databaseMappingDescription;
    _drilldownDescController.text = kpi.drilldownMappingDescription ?? '';
    _dataSource = kpi.dataSource;
    _entityTable = kpi.entityTable;
    _primaryField = kpi.primaryField;
    _aggregation = kpi.aggregation;
    _dateField = kpi.dateField;
    _selectedPages.clear();
    _selectedPages.addAll(kpi.pages);
    _uiComponent = kpi.uiComponent;
    _displayFormat = kpi.displayFormat;
    _selectedIcon = kpi.icon;
    _isClickable = kpi.isClickable;
    _drilldownType = kpi.drilldownType;
    _drilldownRoute = kpi.drilldownRoute;
    _drilldownApi = kpi.drilldownApi;
    _secondLevelEnabled = kpi.secondLevelEnabled;
    _adminVisible = kpi.adminVisible;
    _telecallerVisible = kpi.telecallerVisible;
    _salesVisible = kpi.salesVisible;
    _isEnabled = kpi.isEnabled;
    _tabController.animateTo(1);
  }

  void _duplicateKpi(KpiRegistryItem kpi) {
    _resetWizard();
    _nameController.text = '${kpi.kpiLabel} (Copy)';
    _keyController.text = '${kpi.kpiKey}_copy';
    _whyController.text = kpi.whyDoWeHaveIt;
    _descController.text = kpi.description ?? '';
    _orderController.text = (kpi.displayOrder + 1).toString();
    _relationshipsController.text = kpi.relationships ?? '';
    _dbMappingDescController.text = kpi.databaseMappingDescription;
    _drilldownDescController.text = kpi.drilldownMappingDescription ?? '';
    _dataSource = kpi.dataSource;
    _entityTable = kpi.entityTable;
    _primaryField = kpi.primaryField;
    _aggregation = kpi.aggregation;
    _dateField = kpi.dateField;
    _selectedPages.clear();
    _selectedPages.addAll(kpi.pages);
    _uiComponent = kpi.uiComponent;
    _displayFormat = kpi.displayFormat;
    _selectedIcon = kpi.icon;
    _isClickable = kpi.isClickable;
    _drilldownType = kpi.drilldownType;
    _drilldownRoute = kpi.drilldownRoute;
    _drilldownApi = kpi.drilldownApi;
    _secondLevelEnabled = kpi.secondLevelEnabled;
    _adminVisible = kpi.adminVisible;
    _telecallerVisible = kpi.telecallerVisible;
    _salesVisible = kpi.salesVisible;
    _isEnabled = true;
    _tabController.animateTo(1);
    _showFeedback('Pre-filled new KPI from "${kpi.kpiLabel}".', isSuccess: true);
  }

  void _onNameChanged(String val) {
    if (!_isEditing) {
      final generatedKey = val
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      _keyController.text = generatedKey;
    }
  }

  Future<void> _submitWizard() async {
    if (_nameController.text.trim().isEmpty) {
      _showFeedback('KPI Name is required.', isSuccess: false);
      setState(() => _wizardStep = 0);
      return;
    }
    if (_whyController.text.trim().isEmpty) {
      _showFeedback("Business purpose ('Why do we have it?') is required.", isSuccess: false);
      setState(() => _wizardStep = 0);
      return;
    }
    if (_selectedPages.isEmpty) {
      _showFeedback('At least one page must be selected.', isSuccess: false);
      setState(() => _wizardStep = 2);
      return;
    }
    if (!_adminVisible && !_telecallerVisible && !_salesVisible) {
      _showFeedback('At least one role must be enabled.', isSuccess: false);
      setState(() => _wizardStep = 5);
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'kpi_name': _nameController.text.trim(),
      'kpi_label': _nameController.text.trim(),
      'kpi_key': _keyController.text.trim(),
      'why_do_we_have_it': _whyController.text.trim(),
      'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      'data_source': _dataSource,
      'entity_table': _entityTable,
      'primary_field': _primaryField,
      'aggregation': _aggregation,
      'date_field': _dateField,
      'relationships': _relationshipsController.text.trim().isEmpty ? null : _relationshipsController.text.trim(),
      'database_mapping_description': _dbMappingDescController.text.trim().isNotEmpty
          ? _dbMappingDescController.text.trim()
          : '$_dataSource.$_primaryField ($_aggregation)',
      'pages': _selectedPages,
      'ui_component': _uiComponent,
      'display_format': _displayFormat,
      'icon': _selectedIcon,
      'is_clickable': _isClickable,
      'drilldown_type': _drilldownType,
      'drilldown_route': _drilldownRoute,
      'drilldown_api': _drilldownApi,
      'second_level_enabled': _secondLevelEnabled,
      'drilldown_mapping_description': _drilldownDescController.text.trim().isEmpty
          ? null
          : _drilldownDescController.text.trim(),
      'admin_visible': _adminVisible,
      'telecaller_visible': _telecallerVisible,
      'sales_visible': _salesVisible,
      'is_enabled': _isEnabled,
      'display_order': int.tryParse(_orderController.text.trim()) ?? 10,
    };

    try {
      if (_isEditing && _editingKpiId != null) {
        await _service.updateKpiRegistryItem(_editingKpiId!, payload);
        _showFeedback('KPI updated successfully!', isSuccess: true);
      } else {
        await _service.createKpiRegistryItem(payload);
        _showFeedback('KPI registered successfully!', isSuccess: true);
      }
      _resetWizard();
      _tabController.animateTo(0);
      _loadRegistry();
    } catch (e) {
      _showFeedback('Error saving KPI: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDetailModal(KpiRegistryItem kpi) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cardBg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750, maxHeight: 800),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeManager().primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIconData(kpi.icon), color: ThemeManager().primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                kpi.kpiLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kpi.isSystem
                                      ? Colors.blue.withValues(alpha: 0.15)
                                      : Colors.purple.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  kpi.isSystem ? 'System Canonical' : 'Custom Registered',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kpi.isSystem ? Colors.blue : Colors.purple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Key: ${kpi.kpiKey}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Why do we have it
                        _buildDetailSection(
                          title: 'Why Do We Have It? (Business Purpose)',
                          icon: Icons.lightbulb_outline_rounded,
                          child: Text(
                            kpi.whyDoWeHaveIt,
                            style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
                          ),
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 14),

                        // Database Mapping Flow
                        _buildDetailSection(
                          title: 'Database Architecture & Calculation',
                          icon: Icons.dns_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKeyValueRow('Data Source', kpi.dataSource, textColor, subColor),
                              _buildKeyValueRow('Table / Entity', kpi.entityTable, textColor, subColor),
                              _buildKeyValueRow('Primary Field', kpi.primaryField, textColor, subColor),
                              _buildKeyValueRow('Aggregation', kpi.aggregation, textColor, subColor),
                              _buildKeyValueRow('Date Field', kpi.dateField, textColor, subColor),
                              if (kpi.relationships != null && kpi.relationships!.isNotEmpty)
                                _buildKeyValueRow('Relationships', kpi.relationships!, textColor, subColor),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  kpi.databaseMappingDescription,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 14),

                        // UI Placement & Drill-Down
                        _buildDetailSection(
                          title: 'Placement, UI & Drill-Down Behavior',
                          icon: Icons.dashboard_customize_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildKeyValueRow('Pages / Locations', kpi.pages.join(', '), textColor, subColor),
                              _buildKeyValueRow('UI Component', kpi.uiComponent, textColor, subColor),
                              _buildKeyValueRow('Display Format', kpi.displayFormat, textColor, subColor),
                              _buildKeyValueRow('Clickable', kpi.isClickable ? 'Yes' : 'No', textColor, subColor),
                              if (kpi.isClickable) ...[
                                _buildKeyValueRow('Drilldown Type', kpi.drilldownType, textColor, subColor),
                                if (kpi.drilldownRoute != null)
                                  _buildKeyValueRow('Route', kpi.drilldownRoute!, textColor, subColor),
                                if (kpi.drilldownApi != null)
                                  _buildKeyValueRow('API Endpoint', kpi.drilldownApi!, textColor, subColor),
                                _buildKeyValueRow('Second-Level Drilldown', kpi.secondLevelEnabled ? 'Enabled' : 'Disabled', textColor, subColor),
                              ],
                            ],
                          ),
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 14),

                        // Role Visibility Matrix
                        _buildDetailSection(
                          title: 'Role Visibility & Enforcement',
                          icon: Icons.shield_rounded,
                          child: Row(
                            children: [
                              _buildRoleChip('Admin', kpi.adminVisible),
                              const SizedBox(width: 8),
                              _buildRoleChip('Telecaller', kpi.telecallerVisible),
                              const SizedBox(width: 8),
                              _buildRoleChip('Sales User', kpi.salesVisible),
                            ],
                          ),
                          cardBg: cardBg,
                          borderColor: borderColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Duplicate'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _duplicateKpi(kpi);
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Mapping'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _initEditWizard(kpi);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Widget child,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ThemeManager().primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value, Color textColor, Color subColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              key,
              style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, bool isVisible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVisible ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVisible ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVisible ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isVisible ? const Color(0xFF10B981) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVisible ? const Color(0xFF10B981) : Colors.grey,
            ),
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
        title: const Text('KPI Registry & Configuration'),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Registry',
            onPressed: _loadRegistry,
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
            Tab(
              icon: const Icon(Icons.table_chart_rounded, size: 18),
              text: 'KPI Registry (${_kpiList.length})',
            ),
            Tab(
              icon: Icon(_isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded, size: 18),
              text: _isEditing ? 'Edit KPI' : 'Add KPI',
            ),
            const Tab(
              icon: Icon(Icons.security_rounded, size: 18),
              text: 'Role Visibility Matrix',
            ),
            const Tab(
              icon: Icon(Icons.account_tree_rounded, size: 18),
              text: 'Architecture Flow',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: KPI Registry Master Table
          _buildRegistryTab(cardBg, textColor, subColor, borderColor),

          // Tab 2: Add / Edit Wizard
          _buildWizardTab(cardBg, textColor, subColor, borderColor),

          // Tab 3: Role Visibility Matrix
          _buildRoleMatrixTab(cardBg, textColor, subColor, borderColor),

          // Tab 4: Architecture Flow & Documentation
          _buildArchitectureTab(cardBg, textColor, subColor, borderColor),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: KPI REGISTRY MASTER TABLE
  // ==========================================
  Widget _buildRegistryTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    final isDark = ThemeManager().isDarkMode;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load KPI registry: $_errorMessage'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadRegistry, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search field
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, key, purpose...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _loadRegistry();
                  },
                ),
              ),

              // Page filter
              DropdownButton<String>(
                value: _selectedPageFilter,
                underline: const SizedBox(),
                items: ['All', ..._allPages].map((p) {
                  return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPageFilter = val);
                    _loadRegistry();
                  }
                },
              ),

              // Role filter
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
                    _loadRegistry();
                  }
                },
              ),

              // Status filter
              DropdownButton<String>(
                value: _selectedStatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Status', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'active', child: Text('Active Only', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive Only', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedStatusFilter = val);
                    _loadRegistry();
                  }
                },
              ),

              const Spacer(),

              // Add KPI Button
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add KPI'),
                onPressed: () {
                  _resetWizard();
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
                constraints: const BoxConstraints(minWidth: 1200),
                child: DataTable(
                  columnSpacing: 18,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KPI Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KPI Key', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Why Do We Have It?', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Database Mapping', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Page / Location', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('UI Mapping', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Drill-down Mapping', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Sales User', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(_kpiList.length, (index) {
                    final kpi = _kpiList[index];
                    return DataRow(
                      cells: [
                        // #
                        DataCell(Text('${index + 1}', style: TextStyle(color: subColor, fontSize: 13))),

                        // KPI Name
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getIconData(kpi.icon), size: 18, color: ThemeManager().primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                kpi.kpiLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
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

                        // KPI Key
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              kpi.kpiKey,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),

                        // Why Do We Have It?
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Tooltip(
                              message: kpi.whyDoWeHaveIt,
                              child: Text(
                                kpi.whyDoWeHaveIt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: subColor),
                              ),
                            ),
                          ),
                        ),

                        // Database Mapping
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Tooltip(
                              message: kpi.databaseMappingDescription,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${kpi.dataSource} (${kpi.aggregation})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    kpi.entityTable,
                                    style: TextStyle(fontSize: 11, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Page / Location
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: kpi.pages.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: ThemeManager().primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.replaceAll(' Dashboard', ''),
                                    style: TextStyle(fontSize: 10, color: ThemeManager().primaryColor),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // UI Mapping
                        DataCell(
                          Text(
                            kpi.uiComponent,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),

                        // Drill-down Mapping
                        DataCell(
                          kpi.isClickable
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      kpi.drilldownType,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                                    ),
                                    if (kpi.secondLevelEnabled) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_right_alt_rounded, size: 14, color: Colors.grey),
                                      const Text('2-Lvl', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ],
                                )
                              : const Text('None', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),

                        // Admin Checkbox
                        DataCell(
                          Checkbox(
                            value: kpi.adminVisible,
                            onChanged: (val) => _onToggleRole(kpi, admin: val),
                          ),
                        ),

                        // Telecaller Checkbox
                        DataCell(
                          Checkbox(
                            value: kpi.telecallerVisible,
                            onChanged: (val) => _onToggleRole(kpi, telecaller: val),
                          ),
                        ),

                        // Sales User Checkbox
                        DataCell(
                          Checkbox(
                            value: kpi.salesVisible,
                            onChanged: (val) => _onToggleRole(kpi, sales: val),
                          ),
                        ),

                        // Status Switch
                        DataCell(
                          Switch(
                            value: kpi.isEnabled,
                            activeThumbColor: ThemeManager().primaryColor,
                            onChanged: (val) => _onToggleStatus(kpi, val),
                          ),
                        ),

                        // Actions Menu
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_rounded, size: 18),
                                tooltip: 'View Full Architecture & Mapping',
                                onPressed: () => _showDetailModal(kpi),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                tooltip: 'Edit KPI',
                                onPressed: () => _initEditWizard(kpi),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                tooltip: 'Duplicate KPI',
                                onPressed: () => _duplicateKpi(kpi),
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
  // TAB 2: ADD / EDIT WIZARD
  // ==========================================
  Widget _buildWizardTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wizard Header
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                        color: ThemeManager().primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Edit KPI Definition' : 'Add New KPI to Registry',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Configure identity, secure database mapping, dashboard placement, and role visibility.',
                              style: TextStyle(fontSize: 13, color: subColor),
                            ),
                          ],
                        ),
                      ),
                      if (_isEditing)
                        TextButton(
                          onPressed: _resetWizard,
                          child: const Text('Cancel Edit'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Wizard Stepper
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: ThemeManager().primaryColor,
                          ),
                    ),
                    child: Stepper(
                      currentStep: _wizardStep,
                      onStepTapped: (step) => setState(() => _wizardStep = step),
                      onStepContinue: () {
                        if (_wizardStep < 5) {
                          setState(() => _wizardStep += 1);
                        } else {
                          _submitWizard();
                        }
                      },
                      onStepCancel: () {
                        if (_wizardStep > 0) {
                          setState(() => _wizardStep -= 1);
                        }
                      },
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(_wizardStep == 5 ? (_isEditing ? 'Update KPI' : 'Register KPI') : 'Next Step'),
                              ),
                              if (_wizardStep > 0) ...[
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Previous'),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      steps: [
                        // STEP 1: Basic Information
                        Step(
                          title: const Text('Basic Information'),
                          subtitle: const Text('Identity, name & purpose'),
                          isActive: _wizardStep >= 0,
                          state: _wizardStep > 0 ? StepState.complete : StepState.indexed,
                          content: Column(
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
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _keyController,
                                enabled: !_isEditing,
                                decoration: InputDecoration(
                                  labelText: 'KPI Key * (snake_case)',
                                  hintText: 'e.g. site_visits_done',
                                  border: const OutlineInputBorder(),
                                  helperText: _isEditing ? 'System Key cannot be changed after creation' : 'Auto-generated from name. Must be unique.',
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _whyController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Why Do We Have It? * (Business Purpose)',
                                  hintText: 'e.g. Tracks active, marketable properties ready for immediate tenant or buyer placement.',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _descController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Optional)',
                                  hintText: 'Additional developer/admin context',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // STEP 2: Database Mapping
                        Step(
                          title: const Text('Database Mapping'),
                          subtitle: const Text('Source, table, field & aggregation'),
                          isActive: _wizardStep >= 1,
                          state: _wizardStep > 1 ? StepState.complete : StepState.indexed,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.security_rounded, color: Colors.blue, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Arbitrary SQL execution is prevented. Calculations use secure parameterized query builders scoped to the tenant organization.',
                                        style: TextStyle(fontSize: 12, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _dataSource,
                                      decoration: const InputDecoration(labelText: 'Data Source', border: OutlineInputBorder()),
                                      items: _dataSources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _dataSource = val;
                                            _entityTable = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _entityTable,
                                      decoration: const InputDecoration(labelText: 'Database Table / Entity', border: OutlineInputBorder()),
                                      onChanged: (val) => _entityTable = val,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _primaryField,
                                      decoration: const InputDecoration(labelText: 'Primary Field', border: OutlineInputBorder()),
                                      onChanged: (val) => _primaryField = val,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _aggregation,
                                      decoration: const InputDecoration(labelText: 'Aggregation', border: OutlineInputBorder()),
                                      items: _aggregations.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                                      onChanged: (val) => val != null ? setState(() => _aggregation = val) : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _dateField,
                                      decoration: const InputDecoration(labelText: 'Date Field for Filter', border: OutlineInputBorder()),
                                      onChanged: (val) => _dateField = val,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _relationshipsController,
                                      decoration: const InputDecoration(labelText: 'Relationships / Joins', hintText: 'e.g. leads -> telecallers', border: OutlineInputBorder()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _dbMappingDescController,
                                decoration: const InputDecoration(
                                  labelText: 'Database Mapping Description',
                                  hintText: 'e.g. properties JOIN property_status WHERE status = Available',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // STEP 3: Page Mapping
                        Step(
                          title: const Text('Page Mapping'),
                          subtitle: const Text('Where should this KPI appear?'),
                          isActive: _wizardStep >= 2,
                          state: _wizardStep > 2 ? StepState.complete : StepState.indexed,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Select all target pages / dashboards where this KPI should appear:',
                                style: TextStyle(fontSize: 13, color: subColor),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _allPages.map((page) {
                                  final isSelected = _selectedPages.contains(page);
                                  return FilterChip(
                                    label: Text(page),
                                    selected: isSelected,
                                    selectedColor: ThemeManager().primaryColor.withValues(alpha: 0.18),
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
                            ],
                          ),
                        ),

                        // STEP 4: UI Mapping
                        Step(
                          title: const Text('UI Mapping'),
                          subtitle: const Text('Component, format & icon'),
                          isActive: _wizardStep >= 3,
                          state: _wizardStep > 3 ? StepState.complete : StepState.indexed,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _uiComponent,
                                      decoration: const InputDecoration(labelText: 'UI Component', border: OutlineInputBorder()),
                                      items: _uiComponents.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (val) => val != null ? setState(() => _uiComponent = val) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _displayFormat,
                                      decoration: const InputDecoration(labelText: 'Display Format', border: OutlineInputBorder()),
                                      items: _displayFormats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                                      onChanged: (val) => val != null ? setState(() => _displayFormat = val) : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _orderController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Display Order', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _iconCatalog.containsKey(_selectedIcon) ? _selectedIcon : 'insights_rounded',
                                      decoration: const InputDecoration(labelText: 'Icon', border: OutlineInputBorder()),
                                      items: _iconCatalog.entries.map((entry) {
                                        return DropdownMenuItem(
                                          value: entry.key,
                                          child: Row(
                                            children: [
                                              Icon(entry.value, size: 20),
                                              const SizedBox(width: 8),
                                              Text(entry.key.replaceAll('_rounded', '')),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => val != null ? setState(() => _selectedIcon = val) : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // STEP 5: Drill-down Mapping
                        Step(
                          title: const Text('Drill-down Mapping'),
                          subtitle: const Text('Navigation, breakdown & route'),
                          isActive: _wizardStep >= 4,
                          state: _wizardStep > 4 ? StepState.complete : StepState.indexed,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwitchListTile(
                                title: const Text('Is This KPI Clickable?'),
                                subtitle: const Text('Enables interactive drill-down popup or detail page navigation'),
                                value: _isClickable,
                                onChanged: (val) => setState(() => _isClickable = val),
                              ),
                              if (_isClickable) ...[
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _drilldownType,
                                  decoration: const InputDecoration(labelText: 'Drill-down Type', border: OutlineInputBorder()),
                                  items: _drilldownTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                  onChanged: (val) => val != null ? setState(() => _drilldownType = val) : null,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _drilldownRoute,
                                        decoration: const InputDecoration(labelText: 'Drill-down Route', hintText: '/leads', border: OutlineInputBorder()),
                                        onChanged: (val) => _drilldownRoute = val,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _drilldownApi,
                                        decoration: const InputDecoration(labelText: 'Drill-down API Endpoint', hintText: '/api/v1/dashboard/leads-breakdown', border: OutlineInputBorder()),
                                        onChanged: (val) => _drilldownApi = val,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SwitchListTile(
                                  title: const Text('Second-level Drill-down Enabled'),
                                  subtitle: const Text('e.g. KPI -> Breakdown List -> Individual Property/Lead Detail'),
                                  value: _secondLevelEnabled,
                                  onChanged: (val) => setState(() => _secondLevelEnabled = val),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _drilldownDescController,
                                  decoration: const InputDecoration(
                                    labelText: 'Drill-down Flow Description',
                                    hintText: 'e.g. Total Leads -> Source Breakdown -> Filtered Lead List -> Lead Details',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // STEP 6: Role Visibility & Status
                        Step(
                          title: const Text('Role Visibility & Status'),
                          subtitle: const Text('Admin, Telecaller, Sales enforcement'),
                          isActive: _wizardStep >= 5,
                          state: StepState.indexed,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Select which user roles have permission to view and evaluate this KPI:',
                                style: TextStyle(fontSize: 13, color: subColor),
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                title: const Text('Admin'),
                                subtitle: const Text('Visible to Administrator accounts across administrative screens'),
                                value: _adminVisible,
                                onChanged: (val) => setState(() => _adminVisible = val ?? false),
                              ),
                              CheckboxListTile(
                                title: const Text('Telecaller'),
                                subtitle: const Text('Visible to Telecallers on Telecaller workspace & performance views'),
                                value: _telecallerVisible,
                                onChanged: (val) => setState(() => _telecallerVisible = val ?? false),
                              ),
                              CheckboxListTile(
                                title: const Text('Sales User'),
                                subtitle: const Text('Visible to Sales Closers on Sales dashboard & closing pipelines'),
                                value: _salesVisible,
                                onChanged: (val) => setState(() => _salesVisible = val ?? false),
                              ),
                              const Divider(height: 24),
                              SwitchListTile(
                                title: const Text('Active Status'),
                                subtitle: const Text('If inactive, this KPI is hidden and calculations are skipped'),
                                value: _isEnabled,
                                onChanged: (val) => setState(() => _isEnabled = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeManager().primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: ThemeManager().primaryColor, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Centralized Role Visibility Matrix',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enforce role-based access control. Unauthorized roles will never receive KPI data from the backend or see widgets on the frontend.',
                            style: TextStyle(fontSize: 13, color: subColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KPI Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pages', style: TextStyle(fontWeight: FontWeight.bold))),
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
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getIconData(kpi.icon), size: 16, color: ThemeManager().primaryColor),
                              const SizedBox(width: 8),
                              Text(kpi.kpiLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        DataCell(Text(kpi.pages.join(', '), style: TextStyle(fontSize: 12, color: subColor))),
                        DataCell(
                          Checkbox(
                            value: kpi.adminVisible,
                            onChanged: (val) => _onToggleRole(kpi, admin: val),
                          ),
                        ),
                        DataCell(
                          Checkbox(
                            value: kpi.telecallerVisible,
                            onChanged: (val) => _onToggleRole(kpi, telecaller: val),
                          ),
                        ),
                        DataCell(
                          Checkbox(
                            value: kpi.salesVisible,
                            onChanged: (val) => _onToggleRole(kpi, sales: val),
                          ),
                        ),
                        DataCell(
                          Switch(
                            value: kpi.isEnabled,
                            onChanged: (val) => _onToggleStatus(kpi, val),
                          ),
                        ),
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
  // TAB 4: ARCHITECTURE FLOW & DOCUMENTATION
  // ==========================================
  Widget _buildArchitectureTab(Color cardBg, Color textColor, Color subColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PropKart Dynamic KPI Architecture Flow',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
              ),
              const SizedBox(height: 6),
              Text(
                'How the registry powers calculations, secure backend translations, and multi-dashboard rendering.',
                style: TextStyle(fontSize: 13, color: subColor),
              ),
              const SizedBox(height: 20),

              _buildArchitectureCard(
                step: '1',
                title: 'KPI Definition & Registration',
                subtitle: 'Stored in database table `admin_kpi_config` with metadata: key, label, business purpose, data source, aggregations, and role permissions.',
                icon: Icons.app_registration_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildArchitectureCard(
                step: '2',
                title: 'Backend Security & Query Translation',
                subtitle: 'KpiService translates registered configs into safe, parameterized PostgreSQL queries. Multi-tenant isolation is enforced via `organization_id` checks, soft-delete exclusions, and allowlisted tables.',
                icon: Icons.shield_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildArchitectureCard(
                step: '3',
                title: 'Role-Based API Enforcement',
                subtitle: '`getKpiConfig` and `getKpiRegistry` verify caller role. Telecallers receive only telecaller-visible KPIs; Sales Users receive only sales-visible KPIs.',
                icon: Icons.lock_person_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildArchitectureCard(
                step: '4',
                title: 'Frontend Dynamic Rendering',
                subtitle: 'DashboardBloc and Page widgets query `KpiConfigItem` to display enabled cards, their UI components, icons, and 2-level drilldown dialogs.',
                icon: Icons.desktop_windows_rounded,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchitectureCard({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ThemeManager().primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: ThemeManager().primaryColor),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(fontSize: 13, color: subColor, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
