import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/api/dio_client.dart';

class TierPlansStudioScreen extends StatefulWidget {
  const TierPlansStudioScreen({super.key});

  @override
  State<TierPlansStudioScreen> createState() => _TierPlansStudioScreenState();
}

class _TierPlansStudioScreenState extends State<TierPlansStudioScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _plans = [];
  List<dynamic> _allControls = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plansFuture = DioClient.dio.get('/subscriptions/plans?includeInactive=true');
      final controlsFuture = DioClient.dio.get('/permissions/controls');

      final results = await Future.wait([plansFuture, controlsFuture]);

      final plansRes = results[0];
      final controlsRes = results[1];

      setState(() {
        if (plansRes.statusCode == 200 && plansRes.data != null) {
          _plans = plansRes.data['data'] as List<dynamic>? ?? [];
        }
        if (controlsRes.statusCode == 200 && controlsRes.data != null) {
          _allControls = controlsRes.data['data'] as List<dynamic>? ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load subscription plans: $e';
        _isLoading = false;
      });
    }
  }

  void _openPlanEditor({Map<String, dynamic>? existingPlan}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PlanEditorDialog(
        existingPlan: existingPlan,
        allControls: _allControls,
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildPlansList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CRMSpacing.xl,
        vertical: CRMSpacing.l,
      ),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        border: Border(bottom: BorderSide(color: CRMColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dynamic Subscription Tier Studio',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CRMColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Define plans, dynamic pricing, and feature selection packages with zero hardcoding.',
                style: TextStyle(
                  fontSize: 13,
                  color: CRMColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CRMColors.text,
                  side: BorderSide(color: CRMColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              ElevatedButton.icon(
                onPressed: () => _openPlanEditor(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create New Tier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CRMColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 48),
          const SizedBox(height: CRMSpacing.m),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(color: CRMColors.text),
          ),
          const SizedBox(height: CRMSpacing.m),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    if (_plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 64, color: CRMColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No Subscription Plans Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CRMColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "+ Create New Tier" to create your first dynamic subscription package.',
              style: TextStyle(color: CRMColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return GridView.builder(
          padding: const EdgeInsets.all(CRMSpacing.xl),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 1,
            crossAxisSpacing: CRMSpacing.l,
            mainAxisSpacing: CRMSpacing.l,
            childAspectRatio: isWide ? 0.85 : 1.4,
          ),
          itemCount: _plans.length,
          itemBuilder: (context, index) {
            final plan = _plans[index] as Map<String, dynamic>;
            return _buildPlanCard(plan);
          },
        );
      },
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] ?? 'Unnamed Plan';
    final price = plan['price']?.toString() ?? '0';
    final billing = plan['billing_cycle'] ?? 'monthly';
    final currency = plan['currency'] ?? 'INR';
    final currencySymbol = currency == 'INR' ? '₹' : '\$';
    final isActive = plan['is_active'] == true;
    final includedControls = (plan['included_controls'] as List<dynamic>? ?? []);
    final limits = plan['limits'] as Map<String, dynamic>? ?? {};

    Color badgeColor;
    if (name.toString().toLowerCase().contains('silver')) {
      badgeColor = const Color(0xFF94A3B8);
    } else if (name.toString().toLowerCase().contains('gold')) {
      badgeColor = const Color(0xFFF59E0B);
    } else if (name.toString().toLowerCase().contains('platinum')) {
      badgeColor = const Color(0xFF6366F1);
    } else {
      badgeColor = CRMColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? CRMColors.border : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.all(CRMSpacing.l),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: CRMColors.border.withOpacity(0.5)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.workspace_premium_rounded, color: badgeColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CRMColors.text,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pricing & Description
          Padding(
            padding: const EdgeInsets.all(CRMSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$currencySymbol$price',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CRMColors.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ $billing',
                      style: TextStyle(
                        fontSize: 13,
                        color: CRMColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (plan['description'] != null && plan['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan['description'],
                    style: TextStyle(fontSize: 12, color: CRMColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: CRMSpacing.m),
                Divider(color: CRMColors.border.withOpacity(0.5)),
                const SizedBox(height: CRMSpacing.s),

                // Features count badge
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${includedControls.length} / ${_allControls.length} Features Included',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CRMColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Limits info
                if (limits.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (limits['max_users'] != null)
                        _buildLimitChip('Users', limits['max_users'].toString()),
                      if (limits['max_leads'] != null)
                        _buildLimitChip('Leads', limits['max_leads'].toString()),
                      if (limits['max_properties'] != null)
                        _buildLimitChip('Inventory', limits['max_properties'].toString()),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Footer Action
          Padding(
            padding: const EdgeInsets.all(CRMSpacing.l),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openPlanEditor(existingPlan: plan),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Edit Plan & Features'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CRMColors.primary,
                  side: BorderSide(color: CRMColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CRMColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CRMColors.border),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11, color: CRMColors.textSecondary),
      ),
    );
  }
}

class _PlanEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? existingPlan;
  final List<dynamic> allControls;
  final VoidCallback onSaved;

  const _PlanEditorDialog({
    this.existingPlan,
    required this.allControls,
    required this.onSaved,
  });

  @override
  State<_PlanEditorDialog> createState() => _PlanEditorDialogState();
}

class _PlanEditorDialogState extends State<_PlanEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _maxUsersController;
  late TextEditingController _maxLeadsController;
  late TextEditingController _maxPropsController;

  String _billingCycle = 'monthly';
  String _currency = 'INR';
  bool _isActive = true;
  bool _isSaving = false;
  String _searchFilter = '';

  // Feature selection map: controlKey -> isEnabled
  final Map<String, bool> _controlsMap = {};

  @override
  void initState() {
    super.initState();
    final p = widget.existingPlan;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _priceController = TextEditingController(text: p?['price']?.toString() ?? '0');
    _descController = TextEditingController(text: p?['description'] ?? '');
    _billingCycle = p?['billing_cycle'] ?? 'monthly';
    _currency = p?['currency'] ?? 'INR';
    _isActive = p?['is_active'] ?? true;

    final limits = p?['limits'] as Map<String, dynamic>? ?? {};
    _maxUsersController = TextEditingController(text: limits['max_users']?.toString() ?? '10');
    _maxLeadsController = TextEditingController(text: limits['max_leads']?.toString() ?? '1000');
    _maxPropsController = TextEditingController(text: limits['max_properties']?.toString() ?? '500');

    // Populate existing controls
    if (p != null && p['included_controls'] is List) {
      for (final item in p['included_controls'] as List) {
        if (item is Map && item['control_key'] != null) {
          _controlsMap[item['control_key'].toString()] = item['is_enabled'] == true;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _maxUsersController.dispose();
    _maxLeadsController.dispose();
    _maxPropsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'billingCycle': _billingCycle,
        'currency': _currency,
        'is_active': _isActive,
        'limits': {
          'max_users': int.tryParse(_maxUsersController.text) ?? 10,
          'max_leads': int.tryParse(_maxLeadsController.text) ?? 1000,
          'max_properties': int.tryParse(_maxPropsController.text) ?? 500,
        },
        'controlsMap': _controlsMap,
      };

      if (widget.existingPlan != null) {
        final planId = widget.existingPlan!['id'];
        await DioClient.dio.put('/subscriptions/plans/$planId', data: payload);
      } else {
        await DioClient.dio.post('/subscriptions/plans', data: payload);
      }

      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save tier plan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleModuleAll(String module, bool selectAll) {
    setState(() {
      for (final ctrl in widget.allControls) {
        if (ctrl['module'] == module) {
          final key = ctrl['control_key'].toString();
          _controlsMap[key] = selectAll;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPlan != null;
    final modules = <String, List<dynamic>>{};
    for (final ctrl in widget.allControls) {
      final mod = ctrl['module']?.toString() ?? 'General';
      final title = ctrl['title']?.toString() ?? '';
      final key = ctrl['control_key']?.toString() ?? '';

      if (_searchFilter.isEmpty ||
          title.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          key.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          mod.toLowerCase().contains(_searchFilter.toLowerCase())) {
        modules.putIfAbsent(mod, () => []).add(ctrl);
      }
    }

    final totalSelected = _controlsMap.values.where((v) => v == true).length;

    return Dialog(
      backgroundColor: CRMColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        height: 700,
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: CRMColors.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Configure Subscription Plan' : 'Create New Subscription Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: CRMColors.text,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),
              Divider(color: CRMColors.border),
              const SizedBox(height: CRMSpacing.m),

              // Form fields
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Basic Details & Limits
                    SizedBox(
                      width: 320,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CRMColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Plan Name *',
                                hintText: 'e.g. Silver, Gold, Enterprise Tier',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Price (₹) *',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _billingCycle,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Cycle',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                      DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                                      DropdownMenuItem(value: 'annually', child: Text('Annually')),
                                    ],
                                    onChanged: (v) => setState(() => _billingCycle = v ?? 'monthly'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Plan Description',
                                hintText: 'Brief summary of features for this tier',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Resource Entitlements',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CRMColors.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _maxUsersController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Users Allowed',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _maxLeadsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Leads Allowed',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _maxPropsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Properties Allowed',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Active Tier'),
                              subtitle: const Text('Available for broker provisioning'),
                              value: _isActive,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: CRMSpacing.l),
                    VerticalDivider(color: CRMColors.border),
                    const SizedBox(width: CRMSpacing.l),

                    // Right Column: Feature Selection Matrix
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Feature Selection Checklist',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: CRMColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalSelected / ${widget.allControls.length} Features Included in this Tier',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CRMColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        for (final c in widget.allControls) {
                                          _controlsMap[c['control_key'].toString()] = true;
                                        }
                                      });
                                    },
                                    child: const Text('Select All'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _controlsMap.clear();
                                      });
                                    },
                                    child: const Text('Clear All'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search features, modules, buttons...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              border: const OutlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (v) => setState(() => _searchFilter = v),
                          ),
                          const SizedBox(height: 10),

                          // Grouped Controls List
                          Expanded(
                            child: modules.isEmpty
                                ? Center(
                                    child: Text(
                                      'No features match filter',
                                      style: TextStyle(color: CRMColors.textSecondary),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: modules.keys.length,
                                    itemBuilder: (context, idx) {
                                      final modName = modules.keys.elementAt(idx);
                                      final items = modules[modName]!;
                                      final allInModSelected = items.every((i) => _controlsMap[i['control_key']] == true);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: CRMColors.border),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ExpansionTile(
                                          initiallyExpanded: true,
                                          title: Text(
                                            '$modName (${items.length})',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: CRMColors.text,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                onPressed: () => _toggleModuleAll(modName, !allInModSelected),
                                                child: Text(allInModSelected ? 'Deselect Mod' : 'Select Mod',
                                                    style: const TextStyle(fontSize: 11)),
                                              ),
                                              const Icon(Icons.expand_more),
                                            ],
                                          ),
                                          children: items.map((ctrl) {
                                            final key = ctrl['control_key'].toString();
                                            final title = ctrl['title']?.toString() ?? key;
                                            final type = ctrl['control_type']?.toString() ?? 'feature';
                                            final isChecked = _controlsMap[key] == true;

                                            return CheckboxListTile(
                                              value: isChecked,
                                              dense: true,
                                              title: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: CRMColors.text,
                                                ),
                                              ),
                                              subtitle: Text(
                                                key,
                                                style: TextStyle(fontSize: 11, color: CRMColors.textSecondary),
                                              ),
                                              secondary: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  type.toUpperCase(),
                                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  _controlsMap[key] = val == true;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: CRMSpacing.m),
              Divider(color: CRMColors.border),
              const SizedBox(height: CRMSpacing.m),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: CRMSpacing.m),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CRMColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Save Changes' : 'Create Tier Plan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
