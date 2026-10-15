import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../../dashboard/models/kpi_models.dart';
import '../../dashboard/services/dashboard_service.dart';

/// Clean, authoritative, and simplified KPI Configuration screen.
/// Directly maps KPI names, database count source tables, target display pages,
/// and role-wise visibility in a clear and responsive table.
class KpiConfigScreen extends StatefulWidget {
  final bool isEmbedded;
  const KpiConfigScreen({super.key, this.isEmbedded = false});

  @override
  State<KpiConfigScreen> createState() => _KpiConfigScreenState();
}

class _KpiConfigScreenState extends State<KpiConfigScreen> {
  final DashboardService _service = DashboardService();

  bool _isLoading = true;
  String _errorMessage = '';
  List<KpiRegistryItem> _kpiList = [];

  // Filter & Search states
  String _searchQuery = '';
  String _selectedPageFilter = 'All';
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';

  // Available Pages
  static const List<String> kAvailablePages = [
    'Dashboard',
    'Properties',
    'Leads',
    'Reports',
    'Campaign',
    'Locality Intelligence',
  ];

  // Canonical KPI Templates Catalog for Searchable Dropdown
  static final List<Map<String, dynamic>> kCountSourceTemplates = [
    // Leads & Pipeline
    {
      'id': 'total_leads',
      'label': 'Total Inbound Leads',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': 'leads (deleted_at IS NULL)',
      'icon': 'insights_rounded',
      'defaultPages': ['Dashboard', 'Leads', 'Reports'],
      'why': 'Total unique inquiries captured across all marketing channels.'
    },
    {
      'id': 'fresh_uncontacted',
      'label': 'Fresh / Uncontacted Leads',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "stage = 'NEW' & call_disposition IS NULL",
      'icon': 'inbox_rounded',
      'defaultPages': ['Dashboard', 'Leads', 'Campaign'],
      'why': 'New incoming inquiries awaiting first telecaller outbound contact.'
    },
    {
      'id': 'cnr',
      'label': 'Call Not Received (CNR)',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "call_disposition = 'CNR' OR allocation_status = 'CNR'",
      'icon': 'phone_missed_rounded',
      'defaultPages': ['Dashboard', 'Leads', 'Reports'],
      'why': 'Unreachable prospect inquiries scheduled for retry calling cycles.'
    },
    {
      'id': 'callback',
      'label': 'Scheduled Callbacks',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "call_disposition = 'CALLBACK' OR allocation_status = 'CALLBACK'",
      'icon': 'phone_callback_rounded',
      'defaultPages': ['Dashboard', 'Leads'],
      'why': 'Customers requesting follow-up at a specific scheduled time.'
    },
    {
      'id': 'followup',
      'label': 'Active Follow-ups',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "call_disposition = 'FOLLOWUP' OR allocation_status = 'FOLLOWUP'",
      'icon': 'sync_rounded',
      'defaultPages': ['Dashboard', 'Leads', 'Reports'],
      'why': 'Ongoing prospect nurturing conversations requiring regular touchpoints.'
    },
    {
      'id': 'allocated_to_telecaller',
      'label': 'Allocated to Telecallers',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': 'assigned_telecaller_id IS NOT NULL',
      'icon': 'support_agent_rounded',
      'defaultPages': ['Dashboard', 'Leads', 'Campaign'],
      'why': 'Inbound leads distributed to active telecaller calling queues.'
    },
    {
      'id': 'sales_handover',
      'label': 'Qualified Sales Handover',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "stage = 'SALES' & assigned_to IS NOT NULL",
      'icon': 'handshake_rounded',
      'defaultPages': ['Dashboard', 'Leads', 'Reports'],
      'why': 'Budget and locality validated prospects actively assigned to sales reps.'
    },
    {
      'id': 'deal_won',
      'label': 'Deals Won',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "stage = 'WON'",
      'icon': 'verified_rounded',
      'defaultPages': ['Dashboard', 'Reports'],
      'why': 'Executed transactions with finalized client agreements.'
    },
    {
      'id': 'not_interested',
      'label': 'Not Interested / Lost',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "stage = 'LOST' OR rejection_reason IS NOT NULL",
      'icon': 'cancel_outlined',
      'defaultPages': ['Dashboard', 'Leads', 'Reports'],
      'why': 'Prospects that declined, dropped out, or have budget mismatches.'
    },
    {
      'id': 'owner_listing',
      'label': 'Owner Property Listings',
      'category': 'Leads & Pipeline',
      'table': 'leads',
      'rule': "lead_type = 'Property Listing'",
      'icon': 'real_estate_agent_rounded',
      'defaultPages': ['Dashboard', 'Properties'],
      'why': 'Direct property owner submissions offering units for lease or sale.'
    },

    // Properties & Inventory
    {
      'id': 'available_inventory',
      'label': 'Available Inventory',
      'category': 'Properties & Inventory',
      'table': 'properties',
      'rule': "status = 'Available' & deleted_at IS NULL",
      'icon': 'home_work_rounded',
      'defaultPages': ['Dashboard', 'Properties', 'Locality Intelligence'],
      'why': 'Active verified units ready for prospective tenant/buyer site visits.'
    },
    {
      'id': 'total_listed_properties',
      'label': 'Total Listed Properties',
      'category': 'Properties & Inventory',
      'table': 'properties',
      'rule': 'deleted_at IS NULL',
      'icon': 'inventory_2_rounded',
      'defaultPages': ['Properties', 'Reports'],
      'why': 'All registered real estate assets in company database.'
    },
    {
      'id': 'rented_sold_properties',
      'label': 'Rented / Sold Properties',
      'category': 'Properties & Inventory',
      'table': 'properties',
      'rule': "status IN ('Rented', 'Sold')",
      'icon': 'task_alt_rounded',
      'defaultPages': ['Properties', 'Reports'],
      'why': 'Successfully closed properties off active market circulation.'
    },

    // Site Visits & Field Operations
    {
      'id': 'site_visits_done',
      'label': 'Site Visits Done',
      'category': 'Site Visits & Field',
      'table': 'site_visits',
      'rule': "status = 'DONE' & deleted_at IS NULL",
      'icon': 'location_on_rounded',
      'defaultPages': ['Dashboard', 'Reports'],
      'why': 'Physical in-person property tours conducted by sales reps.'
    },
    {
      'id': 'site_visits_scheduled',
      'label': 'Scheduled Upcoming Visits',
      'category': 'Site Visits & Field',
      'table': 'site_visits',
      'rule': "status = 'SCHEDULED'",
      'icon': 'event_available_rounded',
      'defaultPages': ['Dashboard', 'Reports'],
      'why': 'Upcoming confirmed on-site customer inspection appointments.'
    },

    // Campaigns & Ingestion
    {
      'id': 'meta_ads_leads',
      'label': 'Meta Ads Leads',
      'category': 'Campaigns & Ingestion',
      'table': 'integration_leads',
      'rule': "source = 'Meta Ads' (deduplicated)",
      'icon': 'campaign_rounded',
      'defaultPages': ['Campaign', 'Reports'],
      'why': 'Facebook and Instagram Lead Ad form submissions.'
    },
    {
      'id': 'housing_leads',
      'label': 'Housing.com Leads',
      'category': 'Campaigns & Ingestion',
      'table': 'integration_leads',
      'rule': "source = 'Housing'",
      'icon': 'travel_explore_rounded',
      'defaultPages': ['Campaign', 'Reports'],
      'why': 'Inbound direct inquiries from Housing.com portal syndication.'
    },
    {
      'id': 'webhook_api_leads',
      'label': 'Webhook API Leads',
      'category': 'Campaigns & Ingestion',
      'table': 'integration_leads',
      'rule': "source = 'Webhook API'",
      'icon': 'webhook_rounded',
      'defaultPages': ['Campaign'],
      'why': 'Custom API webhook submissions from third-party landing pages.'
    },

    // Team & Capacity
    {
      'id': 'active_telecallers',
      'label': 'Active Telecallers',
      'category': 'Team & Capacity',
      'table': 'users',
      'rule': "role = 'Telecaller' & is_active = true",
      'icon': 'groups_rounded',
      'defaultPages': ['Dashboard', 'Reports'],
      'why': 'Number of active calling personnel logged into allocation queues.'
    },
    {
      'id': 'active_sales_users',
      'label': 'Active Sales Personnel',
      'category': 'Team & Capacity',
      'table': 'users',
      'rule': "role = 'Sales' & is_active = true",
      'icon': 'badge_rounded',
      'defaultPages': ['Dashboard', 'Reports'],
      'why': 'Field executives authorized to receive qualified customer handovers.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchKpiRegistry();
  }

  Future<void> _fetchKpiRegistry() async {
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

  Future<void> _toggleKpiStatus(KpiRegistryItem kpi, bool newStatus) async {
    final originalStatus = kpi.isEnabled;
    setState(() {
      final index = _kpiList.indexWhere((item) => item.id == kpi.id);
      if (index != -1) {
        _kpiList[index] = _kpiList[index].copyWith(isEnabled: newStatus);
      }
    });

    final success = await _service.toggleKpiRegistryStatus(kpi.id, newStatus);
    if (!success && mounted) {
      setState(() {
        final index = _kpiList.indexWhere((item) => item.id == kpi.id);
        if (index != -1) {
          _kpiList[index] = _kpiList[index].copyWith(isEnabled: originalStatus);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status on server.')),
      );
    }
  }

  Future<void> _toggleRoleVisibility(
      KpiRegistryItem kpi, String role, bool currentVal) async {
    final newVal = !currentVal;
    final updatedData = {
      'admin_visible': role == 'admin' ? newVal : kpi.adminVisible,
      'telecaller_visible':
          role == 'telecaller' ? newVal : kpi.telecallerVisible,
      'sales_visible': role == 'sales' ? newVal : kpi.salesVisible,
    };

    setState(() {
      final index = _kpiList.indexWhere((item) => item.id == kpi.id);
      if (index != -1) {
        _kpiList[index] = _kpiList[index].copyWith(
          adminVisible: updatedData['admin_visible'],
          telecallerVisible: updatedData['telecaller_visible'],
          salesVisible: updatedData['sales_visible'],
        );
      }
    });

    try {
      await _service.updateKpiRegistryItem(kpi.id, updatedData);
    } catch (e) {
      _fetchKpiRegistry();
    }
  }

  void _openKpiConfigDialog([KpiRegistryItem? kpi]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _KpiConfigModal(
        kpi: kpi,
        onSave: () => _fetchKpiRegistry(),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'insights_rounded':
        return Icons.insights_rounded;
      case 'inbox_rounded':
        return Icons.inbox_rounded;
      case 'phone_missed_rounded':
        return Icons.phone_missed_rounded;
      case 'phone_callback_rounded':
        return Icons.phone_callback_rounded;
      case 'sync_rounded':
        return Icons.sync_rounded;
      case 'support_agent_rounded':
        return Icons.support_agent_rounded;
      case 'handshake_rounded':
        return Icons.handshake_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'cancel_outlined':
        return Icons.cancel_outlined;
      case 'real_estate_agent_rounded':
        return Icons.real_estate_agent_rounded;
      case 'home_work_rounded':
        return Icons.home_work_rounded;
      case 'inventory_2_rounded':
        return Icons.inventory_2_rounded;
      case 'location_on_rounded':
        return Icons.location_on_rounded;
      case 'campaign_rounded':
        return Icons.campaign_rounded;
      case 'groups_rounded':
        return Icons.groups_rounded;
      case 'badge_rounded':
        return Icons.badge_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(widget.isEmbedded ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          _buildHeaderBar(cardBg, textColor, subColor, borderColor, isDark),
          const SizedBox(height: 14),

          // Filters Toolbar
          _buildFiltersBar(cardBg, textColor, subColor, borderColor, isDark),
          const SizedBox(height: 14),

          // Main KPI Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? _buildErrorView(textColor, subColor)
                    : _buildTableCard(
                        cardBg, textColor, subColor, borderColor, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(Color cardBg, Color textColor, Color subColor,
      Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KPI Configuration & Data Mapping',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Direct table mapping for all KPIs across dashboard, reports, and role dashboards.',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _openKpiConfigDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add New KPI',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(Color cardBg, Color textColor, Color subColor,
      Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Box
          SizedBox(
            width: 280,
            height: 36,
            child: TextField(
              style: TextStyle(fontSize: 12.5, color: textColor),
              decoration: InputDecoration(
                hintText: 'Search KPI name, table or key...',
                hintStyle: TextStyle(fontSize: 12, color: subColor),
                prefixIcon:
                    Icon(Icons.search_rounded, size: 16, color: subColor),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _fetchKpiRegistry();
              },
            ),
          ),

          // Page Filter Dropdown
          _buildFilterDropdown(
            label: 'Page',
            value: _selectedPageFilter,
            options: ['All', ...kAvailablePages],
            textColor: textColor,
            borderColor: borderColor,
            isDark: isDark,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPageFilter = val);
                _fetchKpiRegistry();
              }
            },
          ),

          // Role Filter Dropdown
          _buildFilterDropdown(
            label: 'Role',
            value: _selectedRoleFilter,
            options: const ['All', 'Admin', 'Telecaller', 'Sales'],
            textColor: textColor,
            borderColor: borderColor,
            isDark: isDark,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedRoleFilter = val);
                _fetchKpiRegistry();
              }
            },
          ),

          // Status Filter Dropdown
          _buildFilterDropdown(
            label: 'Status',
            value: _selectedStatusFilter,
            options: const ['All', 'Active', 'Inactive'],
            textColor: textColor,
            borderColor: borderColor,
            isDark: isDark,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatusFilter = val);
                _fetchKpiRegistry();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required Color textColor,
    required Color borderColor,
    required bool isDark,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          onChanged: onChanged,
          items: options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text('$label: $opt'),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTableCard(Color cardBg, Color textColor, Color subColor,
      Color borderColor, bool isDark) {
    if (_kpiList.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_off_rounded, size: 40, color: subColor),
              const SizedBox(height: 8),
              Text('No KPI configurations found matching your filters.',
                  style: TextStyle(color: subColor, fontSize: 13)),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedPageFilter = 'All';
                    _selectedRoleFilter = 'All';
                    _selectedStatusFilter = 'All';
                  });
                  _fetchKpiRegistry();
                },
                child: const Text('Reset Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              headingTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              dataTextStyle: TextStyle(fontSize: 12, color: textColor),
              horizontalMargin: 16,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('KPI Name')),
                DataColumn(label: Text('Which Data Count Table To Fetch')),
                DataColumn(label: Text('Display Pages')),
                DataColumn(label: Text('Role Visibility')),
                DataColumn(label: Text('Active')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _kpiList.map((kpi) {
                final iconData = _getIconData(kpi.icon);
                final tableName = kpi.entityTable.isNotEmpty
                    ? kpi.entityTable
                    : (kpi.dataSource.isNotEmpty ? kpi.dataSource : 'leads');
                final ruleDesc = kpi.databaseMappingDescription.isNotEmpty
                    ? kpi.databaseMappingDescription
                    : '$tableName (canonical)';

                return DataRow(
                  cells: [
                    // KPI Name Column
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(iconData,
                                color: const Color(0xFF3B82F6), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                kpi.kpiLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                              Text(
                                kpi.kpiKey,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: subColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Which Data Count Table To Fetch
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.table_chart_rounded,
                                size: 13, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 5),
                            Text(
                              ruleDesc,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Display Pages Chips
                    DataCell(
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: kpi.pages.map((p) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Role Visibility (Admin, Telecaller, Sales)
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRoleBadge(
                            label: 'Admin',
                            isActive: kpi.adminVisible,
                            activeColor: const Color(0xFFF59E0B),
                            onTap: () => _toggleRoleVisibility(
                                kpi, 'admin', kpi.adminVisible),
                          ),
                          const SizedBox(width: 5),
                          _buildRoleBadge(
                            label: 'Telecaller',
                            isActive: kpi.telecallerVisible,
                            activeColor: const Color(0xFF3B82F6),
                            onTap: () => _toggleRoleVisibility(
                                kpi, 'telecaller', kpi.telecallerVisible),
                          ),
                          const SizedBox(width: 5),
                          _buildRoleBadge(
                            label: 'Sales',
                            isActive: kpi.salesVisible,
                            activeColor: const Color(0xFF10B981),
                            onTap: () => _toggleRoleVisibility(
                                kpi, 'sales', kpi.salesVisible),
                          ),
                        ],
                      ),
                    ),

                    // Active Switch
                    DataCell(
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: kpi.isEnabled,
                          activeTrackColor: const Color(0xFF10B981),
                          onChanged: (val) => _toggleKpiStatus(kpi, val),
                        ),
                      ),
                    ),

                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            tooltip: 'Edit KPI',
                            onPressed: () => _openKpiConfigDialog(kpi),
                          ),
                          if (!kpi.isSystem)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Colors.redAccent),
                              tooltip: 'Delete KPI',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete KPI'),
                                    content: Text(
                                        'Are you sure you want to delete "${kpi.kpiLabel}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _service.deleteKpiRegistryItem(kpi.id);
                                  _fetchKpiRegistry();
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? activeColor
                : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 11,
              color: isActive ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(Color textColor, Color subColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
          const SizedBox(height: 8),
          Text(_errorMessage, style: TextStyle(color: textColor)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _fetchKpiRegistry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Simple modal to add or edit KPI configurations with a searchable dropdown.
class _KpiConfigModal extends StatefulWidget {
  final KpiRegistryItem? kpi;
  final VoidCallback onSave;

  const _KpiConfigModal({this.kpi, required this.onSave});

  @override
  State<_KpiConfigModal> createState() => _KpiConfigModalState();
}

class _KpiConfigModalState extends State<_KpiConfigModal> {
  final DashboardService _service = DashboardService();
  late TextEditingController _labelController;
  late TextEditingController _keyController;
  late TextEditingController _whyController;
  final TextEditingController _templateSearchController =
      TextEditingController();

  Map<String, dynamic>? _selectedTemplate;
  late List<String> _selectedPages;
  late bool _adminVisible;
  late bool _telecallerVisible;
  late bool _salesVisible;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final k = widget.kpi;
    _labelController = TextEditingController(text: k?.kpiLabel ?? '');
    _keyController = TextEditingController(text: k?.kpiKey ?? '');
    _whyController = TextEditingController(text: k?.whyDoWeHaveIt ?? '');
    _selectedPages = k != null ? List<String>.from(k.pages) : ['Dashboard'];
    _adminVisible = k?.adminVisible ?? true;
    _telecallerVisible = k?.telecallerVisible ?? false;
    _salesVisible = k?.salesVisible ?? false;

    if (k != null) {
      _selectedTemplate = _KpiConfigScreenState.kCountSourceTemplates.firstWhere(
        (t) =>
            t['id'] == k.kpiKey ||
            t['table'] == k.entityTable ||
            t['label'] == k.kpiLabel,
        orElse: () => {
          'id': k.kpiKey,
          'label': k.kpiLabel,
          'category': 'Custom',
          'table': k.entityTable.isNotEmpty ? k.entityTable : 'leads',
          'rule': k.databaseMappingDescription.isNotEmpty
              ? k.databaseMappingDescription
              : '${k.entityTable} (custom)',
          'icon': k.icon,
          'defaultPages': k.pages,
          'why': k.whyDoWeHaveIt,
        },
      );
    } else {
      _selectedTemplate = _KpiConfigScreenState.kCountSourceTemplates.first;
      _applyTemplate(_selectedTemplate!);
    }
  }

  void _applyTemplate(Map<String, dynamic> t) {
    if (widget.kpi == null) {
      _labelController.text = t['label'] ?? '';
      _keyController.text = t['id'] ?? '';
      _whyController.text = t['why'] ?? '';
      _selectedPages = List<String>.from(t['defaultPages'] ?? ['Dashboard']);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _keyController.dispose();
    _whyController.dispose();
    _templateSearchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a KPI label.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      'kpi_label': label,
      'kpi_key': _keyController.text.trim().isNotEmpty
          ? _keyController.text.trim()
          : label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
      'why_do_we_have_it': _whyController.text.trim(),
      'entity_table': _selectedTemplate?['table'] ?? 'leads',
      'data_source': _selectedTemplate?['table'] ?? 'leads',
      'database_mapping_description': _selectedTemplate?['rule'] ?? 'leads',
      'pages': _selectedPages,
      'admin_visible': _adminVisible,
      'telecaller_visible': _telecallerVisible,
      'sales_visible': _salesVisible,
      'icon': _selectedTemplate?['icon'] ?? 'insights_rounded',
      'is_enabled': widget.kpi?.isEnabled ?? true,
    };

    try {
      if (widget.kpi != null) {
        await _service.updateKpiRegistryItem(widget.kpi!.id, payload);
      } else {
        await _service.createKpiRegistryItem(payload);
      }
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving KPI: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.kpi != null ? 'Edit KPI Configuration' : 'Configure New KPI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 18),

              // KPI Name
              const Text('KPI Label / Name',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextField(
                controller: _labelController,
                style: TextStyle(fontSize: 13, color: textColor),
                decoration: InputDecoration(
                  hintText: 'e.g. Available Inventory, Fresh Leads, Deals Won',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 14),

              // Searchable Count Source Dropdown
              const Text('Which Data Count Table To Fetch',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              _buildSearchableTemplatePicker(textColor, subColor, borderColor, isDark),
              const SizedBox(height: 14),

              // Display Pages
              const Text('Show In Pages',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _KpiConfigScreenState.kAvailablePages.map((page) {
                  final isSelected = _selectedPages.contains(page);
                  return FilterChip(
                    label: Text(page, style: const TextStyle(fontSize: 11.5)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF10B981),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPages.add(page);
                        } else {
                          _selectedPages.remove(page);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Role Visibility
              const Text('Role-wise Visibility',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Checkbox(
                    value: _adminVisible,
                    activeColor: const Color(0xFFF59E0B),
                    onChanged: (v) =>
                        setState(() => _adminVisible = v ?? true),
                  ),
                  const Text('👑 Admin', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 14),
                  Checkbox(
                    value: _telecallerVisible,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (v) =>
                        setState(() => _telecallerVisible = v ?? false),
                  ),
                  const Text('🎧 Telecaller', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 14),
                  Checkbox(
                    value: _salesVisible,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) =>
                        setState(() => _salesVisible = v ?? false),
                  ),
                  const Text('💼 Sales', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),

              // Description / Why
              const Text('Why Do We Have This KPI? (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextField(
                controller: _whyController,
                maxLines: 2,
                style: TextStyle(fontSize: 12.5, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Brief context explaining how this metric impacts business operations.',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Configuration'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableTemplatePicker(
      Color textColor, Color subColor, Color borderColor, bool isDark) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (bctx) {
            String filter = '';
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                final filtered = _KpiConfigScreenState.kCountSourceTemplates
                    .where((t) =>
                        (t['label']?.toString().toLowerCase() ?? '')
                            .contains(filter.toLowerCase()) ||
                        (t['category']?.toString().toLowerCase() ?? '')
                            .contains(filter.toLowerCase()) ||
                        (t['table']?.toString().toLowerCase() ?? '')
                            .contains(filter.toLowerCase()))
                    .toList();

                return Container(
                  height: 500,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Data Count Table & Formula',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(bctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search data source, table or formula...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setModalState(() => filter = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final item = filtered[index];
                            final isSel = _selectedTemplate?['id'] == item['id'];

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.table_chart_rounded,
                                    color: Color(0xFF3B82F6), size: 18),
                              ),
                              title: Text(item['label'] ?? '',
                                  style: TextStyle(
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13)),
                              subtitle: Text(
                                '${item['category']} • ${item['rule']}',
                                style: TextStyle(
                                    fontSize: 11, color: subColor),
                              ),
                              trailing: isSel
                                  ? const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF10B981), size: 18)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedTemplate = item;
                                  _applyTemplate(item);
                                });
                                Navigator.pop(bctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.table_chart_rounded,
                size: 16, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTemplate?['label'] ?? 'Select Data Count Source',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textColor),
                  ),
                  Text(
                    '${_selectedTemplate?['category'] ?? ''} • ${_selectedTemplate?['rule'] ?? ''}',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: subColor),
          ],
        ),
      ),
    );
  }
}
