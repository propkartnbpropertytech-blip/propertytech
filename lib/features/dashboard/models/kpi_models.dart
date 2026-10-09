/// ============================================================================
/// ⚠️ PROPKART MASTER KPI GOVERNANCE RULE:
/// All data models and JSON serializations in this file MUST conform to the
/// Master KPI Rulebook: `lib/core/constants/kpi_rulebook.dart` and `docs/KPIs.docx`.
/// ============================================================================
class KpiConfigItem {
  final String? id;
  final String kpiKey;
  final String kpiLabel;
  final bool isEnabled;
  final int displayOrder;
  final bool isSystem;
  final String icon;
  final bool isClickable;
  final List<String> pages;
  final String uiComponent;
  final String displayFormat;
  final Map<String, dynamic> drilldownConfig;

  const KpiConfigItem({
    this.id,
    required this.kpiKey,
    required this.kpiLabel,
    required this.isEnabled,
    required this.displayOrder,
    this.isSystem = false,
    this.icon = 'insights_rounded',
    this.isClickable = true,
    this.pages = const ['Admin Dashboard'],
    this.uiComponent = 'KPI Card',
    this.displayFormat = 'Count',
    this.drilldownConfig = const {'layout': 'default', 'components': []},
  });

  factory KpiConfigItem.fromJson(Map<String, dynamic> json) {
    return KpiConfigItem(
      id: json['id']?.toString(),
      kpiKey: json['kpi_key']?.toString() ?? '',
      kpiLabel: json['kpi_label']?.toString() ?? json['kpi_key']?.toString() ?? '',
      isEnabled: json['is_enabled'] != false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      isSystem: json['is_system'] == true,
      icon: json['icon']?.toString() ?? 'insights_rounded',
      isClickable: json['is_clickable'] != false,
      pages: (json['pages'] as List?)?.map((p) => p.toString()).toList() ?? const ['Admin Dashboard'],
      uiComponent: json['ui_component']?.toString() ?? 'KPI Card',
      displayFormat: json['display_format']?.toString() ?? 'Count',
      drilldownConfig: json['drilldown_config'] is Map
          ? Map<String, dynamic>.from(json['drilldown_config'])
          : const {'layout': 'default', 'components': []},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'kpi_key': kpiKey,
      'kpi_label': kpiLabel,
      'is_enabled': isEnabled,
      'display_order': displayOrder,
      'is_system': isSystem,
      'icon': icon,
      'is_clickable': isClickable,
      'pages': pages,
      'ui_component': uiComponent,
      'display_format': displayFormat,
      'drilldown_config': drilldownConfig,
    };
  }

  KpiConfigItem copyWith({
    String? id,
    String? kpiKey,
    String? kpiLabel,
    bool? isEnabled,
    int? displayOrder,
    bool? isSystem,
    String? icon,
    bool? isClickable,
    List<String>? pages,
    String? uiComponent,
    String? displayFormat,
    Map<String, dynamic>? drilldownConfig,
  }) {
    return KpiConfigItem(
      id: id ?? this.id,
      kpiKey: kpiKey ?? this.kpiKey,
      kpiLabel: kpiLabel ?? this.kpiLabel,
      isEnabled: isEnabled ?? this.isEnabled,
      displayOrder: displayOrder ?? this.displayOrder,
      isSystem: isSystem ?? this.isSystem,
      icon: icon ?? this.icon,
      isClickable: isClickable ?? this.isClickable,
      pages: pages ?? this.pages,
      uiComponent: uiComponent ?? this.uiComponent,
      displayFormat: displayFormat ?? this.displayFormat,
      drilldownConfig: drilldownConfig ?? this.drilldownConfig,
    );
  }
}

class KpiRegistryItem {
  final String id;
  final String? organizationId;
  final String kpiKey;
  final String kpiLabel;
  final String whyDoWeHaveIt;
  final String? description;
  final String dataSource;
  final String entityTable;
  final String primaryField;
  final String aggregation;
  final List<dynamic> conditionsJson;
  final String dateField;
  final String? relationships;
  final String databaseMappingDescription;
  final List<String> pages;
  final String uiComponent;
  final String displayFormat;
  final String icon;
  final bool isClickable;
  final String drilldownType;
  final String? drilldownRoute;
  final String? drilldownApi;
  final bool secondLevelEnabled;
  final String? drilldownMappingDescription;
  final Map<String, dynamic> drilldownConfig;
  final String? parentKpiId;
  final String lifecycleStatus;
  final bool adminVisible;
  final bool telecallerVisible;
  final bool salesVisible;
  final bool isSystem;
  final bool isEnabled;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KpiRegistryItem({
    required this.id,
    this.organizationId,
    required this.kpiKey,
    required this.kpiLabel,
    required this.whyDoWeHaveIt,
    this.description,
    this.dataSource = 'leads',
    this.entityTable = 'leads',
    this.primaryField = 'id',
    this.aggregation = 'COUNT',
    this.conditionsJson = const [],
    this.dateField = 'created_at',
    this.relationships,
    this.databaseMappingDescription = '',
    this.pages = const ['Admin Dashboard'],
    this.uiComponent = 'KPI Card',
    this.displayFormat = 'Count',
    this.icon = 'insights_rounded',
    this.isClickable = true,
    this.drilldownType = 'Modal',
    this.drilldownRoute,
    this.drilldownApi,
    this.secondLevelEnabled = false,
    this.drilldownMappingDescription,
    this.drilldownConfig = const {'layout': 'default', 'components': []},
    this.parentKpiId,
    this.lifecycleStatus = 'active',
    this.adminVisible = true,
    this.telecallerVisible = false,
    this.salesVisible = false,
    this.isSystem = false,
    this.isEnabled = true,
    this.displayOrder = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory KpiRegistryItem.fromJson(Map<String, dynamic> json) {
    return KpiRegistryItem(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      kpiKey: json['kpi_key']?.toString() ?? '',
      kpiLabel: json['kpi_label']?.toString() ?? json['kpi_key']?.toString() ?? '',
      whyDoWeHaveIt: json['why_do_we_have_it']?.toString() ?? '',
      description: json['description']?.toString(),
      dataSource: json['data_source']?.toString() ?? 'leads',
      entityTable: json['entity_table']?.toString() ?? 'leads',
      primaryField: json['primary_field']?.toString() ?? 'id',
      aggregation: json['aggregation']?.toString() ?? 'COUNT',
      conditionsJson: json['conditions_json'] is List ? (json['conditions_json'] as List) : const [],
      dateField: json['date_field']?.toString() ?? 'created_at',
      relationships: json['relationships']?.toString(),
      databaseMappingDescription: json['database_mapping_description']?.toString() ?? '',
      pages: (json['pages'] as List?)?.map((p) => p.toString()).toList() ?? const ['Admin Dashboard'],
      uiComponent: json['ui_component']?.toString() ?? 'KPI Card',
      displayFormat: json['display_format']?.toString() ?? 'Count',
      icon: json['icon']?.toString() ?? 'insights_rounded',
      isClickable: json['is_clickable'] != false,
      drilldownType: json['drilldown_type']?.toString() ?? 'Modal',
      drilldownRoute: json['drilldown_route']?.toString(),
      drilldownApi: json['drilldown_api']?.toString(),
      secondLevelEnabled: json['second_level_enabled'] == true,
      drilldownMappingDescription: json['drilldown_mapping_description']?.toString(),
      drilldownConfig: json['drilldown_config'] is Map
          ? Map<String, dynamic>.from(json['drilldown_config'])
          : const {'layout': 'default', 'components': []},
      parentKpiId: json['parent_kpi_id']?.toString(),
      lifecycleStatus: json['lifecycle_status']?.toString() ?? 'active',
      adminVisible: json['admin_visible'] != false,
      telecallerVisible: json['telecaller_visible'] == true,
      salesVisible: json['sales_visible'] == true,
      isSystem: json['is_system'] == true || isCanonicalKey(json['kpi_key']?.toString()),
      isEnabled: json['is_enabled'] != false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'kpi_key': kpiKey,
      'kpi_label': kpiLabel,
      'why_do_we_have_it': whyDoWeHaveIt,
      if (description != null) 'description': description,
      'data_source': dataSource,
      'entity_table': entityTable,
      'primary_field': primaryField,
      'aggregation': aggregation,
      'conditions_json': conditionsJson,
      'date_field': dateField,
      if (relationships != null) 'relationships': relationships,
      'database_mapping_description': databaseMappingDescription,
      'pages': pages,
      'ui_component': uiComponent,
      'display_format': displayFormat,
      'icon': icon,
      'is_clickable': isClickable,
      'drilldown_type': drilldownType,
      if (drilldownRoute != null) 'drilldown_route': drilldownRoute,
      if (drilldownApi != null) 'drilldown_api': drilldownApi,
      'second_level_enabled': secondLevelEnabled,
      if (drilldownMappingDescription != null) 'drilldown_mapping_description': drilldownMappingDescription,
      'drilldown_config': drilldownConfig,
      if (parentKpiId != null) 'parent_kpi_id': parentKpiId,
      'lifecycle_status': lifecycleStatus,
      'admin_visible': adminVisible,
      'telecaller_visible': telecallerVisible,
      'sales_visible': salesVisible,
      'is_enabled': isEnabled,
      'display_order': displayOrder,
    };
  }

  KpiRegistryItem copyWith({
    String? id,
    String? organizationId,
    String? kpiKey,
    String? kpiLabel,
    String? whyDoWeHaveIt,
    String? description,
    String? dataSource,
    String? entityTable,
    String? primaryField,
    String? aggregation,
    List<dynamic>? conditionsJson,
    String? dateField,
    String? relationships,
    String? databaseMappingDescription,
    List<String>? pages,
    String? uiComponent,
    String? displayFormat,
    String? icon,
    bool? isClickable,
    String? drilldownType,
    String? drilldownRoute,
    String? drilldownApi,
    bool? secondLevelEnabled,
    String? drilldownMappingDescription,
    Map<String, dynamic>? drilldownConfig,
    String? parentKpiId,
    String? lifecycleStatus,
    bool? adminVisible,
    bool? telecallerVisible,
    bool? salesVisible,
    bool? isSystem,
    bool? isEnabled,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KpiRegistryItem(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      kpiKey: kpiKey ?? this.kpiKey,
      kpiLabel: kpiLabel ?? this.kpiLabel,
      whyDoWeHaveIt: whyDoWeHaveIt ?? this.whyDoWeHaveIt,
      description: description ?? this.description,
      dataSource: dataSource ?? this.dataSource,
      entityTable: entityTable ?? this.entityTable,
      primaryField: primaryField ?? this.primaryField,
      aggregation: aggregation ?? this.aggregation,
      conditionsJson: conditionsJson ?? this.conditionsJson,
      dateField: dateField ?? this.dateField,
      relationships: relationships ?? this.relationships,
      databaseMappingDescription: databaseMappingDescription ?? this.databaseMappingDescription,
      pages: pages ?? this.pages,
      uiComponent: uiComponent ?? this.uiComponent,
      displayFormat: displayFormat ?? this.displayFormat,
      icon: icon ?? this.icon,
      isClickable: isClickable ?? this.isClickable,
      drilldownType: drilldownType ?? this.drilldownType,
      drilldownRoute: drilldownRoute ?? this.drilldownRoute,
      drilldownApi: drilldownApi ?? this.drilldownApi,
      secondLevelEnabled: secondLevelEnabled ?? this.secondLevelEnabled,
      drilldownMappingDescription: drilldownMappingDescription ?? this.drilldownMappingDescription,
      drilldownConfig: drilldownConfig ?? this.drilldownConfig,
      parentKpiId: parentKpiId ?? this.parentKpiId,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      adminVisible: adminVisible ?? this.adminVisible,
      telecallerVisible: telecallerVisible ?? this.telecallerVisible,
      salesVisible: salesVisible ?? this.salesVisible,
      isSystem: isSystem ?? this.isSystem,
      isEnabled: isEnabled ?? this.isEnabled,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const Set<String> canonicalKeys = {
    'available_inventory',
    'total_leads',
    'telecallers',
    'leads_allocated',
    'old_leads_allocated',
    'assigned_to_sales',
    'site_visits_done',
    'deal_won',
    'sales_users',
    'rejected_after_site_visit',
    'not_interested',
    'cnr',
    'locality_inventory',
    'locality_leads',
    'locality_demand_ratio',
    'lead_sources_reconciliation',
    // Group A – Inventory Sourcing
    'properties_by_sales_available',
    'properties_by_sales_total',
    'properties_by_telecaller_available',
    'properties_by_telecaller_total',
    'properties_by_admin_available',
    'properties_by_admin_total',
    'total_portfolio',
    'rented_out_count',
    'sold_out_count',
    'rental_count',
    'resale_count',
    // Group B – Manual Leads
    'manual_leads_total',
    'manual_leads_by_sales',
    'manual_leads_by_telecaller',
    'manual_leads_by_admin',
    // Group C – Sales Pipeline
    'active_requirements',
    'allocation_telecaller',
    'allocation_self',
    'followup_active',
    'refollowup_active',
    'site_visits_scheduled',
    'site_visits_done_req',
    'sales_rejection_count',
    'deals_won_count',
    // Group D – Qualified Leads
    'qualified_interested',
    'want_rent_count',
    'want_list_count',
    'want_resale_count',
    'active_in_sales_count',
  };


  static bool isCanonicalKey(String? key) =>
      key != null && canonicalKeys.contains(key.trim().toLowerCase());

  static List<KpiRegistryItem> get canonicalDefaults => const [
        KpiRegistryItem(
          id: 'available_inventory',
          kpiKey: 'available_inventory',
          kpiLabel: 'Available Inventory',
          whyDoWeHaveIt: 'Tracks active, marketable properties ready for immediate tenant or buyer placement.',
          dataSource: 'properties',
          entityTable: 'properties',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'home_work_rounded',
          isClickable: true,
          adminVisible: true,
          salesVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 1,
        ),
        KpiRegistryItem(
          id: 'total_leads',
          kpiKey: 'total_leads',
          kpiLabel: 'Total Leads',
          whyDoWeHaveIt: 'Measures total top-of-funnel inbound volume across all advertising & organic channels.',
          dataSource: 'leads',
          entityTable: 'leads',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'assignment_rounded',
          isClickable: true,
          adminVisible: true,
          telecallerVisible: true,
          salesVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 2,
        ),
        KpiRegistryItem(
          id: 'telecallers',
          kpiKey: 'telecallers',
          kpiLabel: 'Telecallers',
          whyDoWeHaveIt: 'Measures telecalling capacity and operational workforce handling intake calls.',
          dataSource: 'users',
          entityTable: 'users',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'support_agent_rounded',
          isClickable: true,
          adminVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 3,
        ),
        KpiRegistryItem(
          id: 'leads_allocated',
          kpiKey: 'leads_allocated',
          kpiLabel: 'New Leads Allocated',
          whyDoWeHaveIt: 'Tracks fresh, first-time leads assigned to telecallers during the period.',
          dataSource: 'leads',
          entityTable: 'leads',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'assignment_ind_rounded',
          isClickable: true,
          adminVisible: true,
          telecallerVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 4,
        ),
        KpiRegistryItem(
          id: 'old_leads_allocated',
          kpiKey: 'old_leads_allocated',
          kpiLabel: 'Old Leads Allocated',
          whyDoWeHaveIt: 'Monitors follow-ups and recycled pipeline leads re-assigned to telecallers.',
          dataSource: 'leads',
          entityTable: 'leads',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'history_rounded',
          isClickable: true,
          adminVisible: true,
          telecallerVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 5,
        ),
        KpiRegistryItem(
          id: 'assigned_to_sales',
          kpiKey: 'assigned_to_sales',
          kpiLabel: 'Assigned to Sales',
          whyDoWeHaveIt: 'Evaluates lead qualification yield transferred from telecallers to field sales.',
          dataSource: 'requirements',
          entityTable: 'requirements',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'badge_rounded',
          isClickable: true,
          adminVisible: true,
          salesVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 6,
        ),
        KpiRegistryItem(
          id: 'site_visits_done',
          kpiKey: 'site_visits_done',
          kpiLabel: 'Site Visits Done',
          whyDoWeHaveIt: 'Tracks physically conducted in-person property walkthroughs.',
          dataSource: 'site_visits',
          entityTable: 'site_visits',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'location_on_rounded',
          isClickable: true,
          adminVisible: true,
          salesVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 7,
        ),
        KpiRegistryItem(
          id: 'deal_won',
          kpiKey: 'deal_won',
          kpiLabel: 'Deal Won',
          whyDoWeHaveIt: 'Measures ultimate commercial conversion and revenue generation.',
          dataSource: 'requirements',
          entityTable: 'requirements',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'emoji_events_rounded',
          isClickable: true,
          adminVisible: true,
          salesVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 8,
        ),
        KpiRegistryItem(
          id: 'sales_users',
          kpiKey: 'sales_users',
          kpiLabel: 'Sales Users',
          whyDoWeHaveIt: 'Tracks active sales managers and closing executives available in the field.',
          dataSource: 'users',
          entityTable: 'users',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'groups_rounded',
          isClickable: true,
          adminVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 9,
        ),
        KpiRegistryItem(
          id: 'rejected_after_site_visit',
          kpiKey: 'rejected_after_site_visit',
          kpiLabel: 'Rejected After Site Visit',
          whyDoWeHaveIt: 'Measures visit fallout to identify mismatched buyer expectations or pricing gaps.',
          dataSource: 'site_visits',
          entityTable: 'site_visits',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'cancel_rounded',
          isClickable: true,
          adminVisible: true,
          salesVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 10,
        ),
        KpiRegistryItem(
          id: 'not_interested',
          kpiKey: 'not_interested',
          kpiLabel: 'Not Interested',
          whyDoWeHaveIt: 'Monitors early campaign lead fallout and disqualified lead volume.',
          dataSource: 'leads',
          entityTable: 'leads',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'phone_disabled_rounded',
          isClickable: true,
          adminVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 11,
        ),
        KpiRegistryItem(
          id: 'cnr',
          kpiKey: 'cnr',
          kpiLabel: 'CNR (No Response)',
          whyDoWeHaveIt: 'Monitors unreached lead volume where client could not be contacted.',
          dataSource: 'leads',
          entityTable: 'leads',
          primaryField: 'id',
          aggregation: 'COUNT',
          icon: 'phone_missed_rounded',
          isClickable: true,
          adminVisible: true,
          telecallerVisible: true,
          isSystem: true,
          isEnabled: true,
          displayOrder: 12,
        ),
      ];
}

class KpiAuditLogItem {
  final String id;
  final String? organizationId;
  final String? kpiId;
  final String? kpiLabel;
  final String? kpiKey;
  final String action;
  final String? performedByName;
  final String? performedByEmail;
  final Map<String, dynamic>? oldConfig;
  final Map<String, dynamic>? newConfig;
  final DateTime? createdAt;

  const KpiAuditLogItem({
    required this.id,
    this.organizationId,
    this.kpiId,
    this.kpiLabel,
    this.kpiKey,
    required this.action,
    this.performedByName,
    this.performedByEmail,
    this.oldConfig,
    this.newConfig,
    this.createdAt,
  });

  factory KpiAuditLogItem.fromJson(Map<String, dynamic> json) {
    return KpiAuditLogItem(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      kpiId: json['kpi_id']?.toString(),
      kpiLabel: json['kpi_label']?.toString(),
      kpiKey: json['kpi_key']?.toString(),
      action: json['action']?.toString() ?? 'UPDATED',
      performedByName: json['performed_by_name']?.toString(),
      performedByEmail: json['performed_by_email']?.toString(),
      oldConfig: json['old_config'] is Map ? Map<String, dynamic>.from(json['old_config']) : null,
      newConfig: json['new_config'] is Map ? Map<String, dynamic>.from(json['new_config']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

class DashboardKpiCounts {
  final int availableInventory;
  final int totalLeads;
  final int allAvailableInventory;
  final int allTotalLeads;
  final int telecallers;
  final int leadsAllocated;
  final int oldLeadsAllocated;
  final int assignedToSales;
  final int siteVisitsDone;
  final int rejectedAfterSiteVisit;
  final int dealWon;
  final int salesUsers;
  final int notInterested;
  final int cnr;

  // ── Group A: Inventory Sourcing (KPIs 1-7) ────────────────────────────────
  final int propertiesBySalesAvailable;
  final int propertiesBySalesTotal;
  final int propertiesByTelecallerAvailable;
  final int propertiesByTelecallerTotal;
  final int propertiesByAdminAvailable;
  final int propertiesByAdminTotal;
  final int totalPortfolio;
  final int rentedOutCount;
  final int soldOutCount;
  final int rentalCount;
  final int resaleCount;

  // ── Group B: Manual / Direct Leads (KPIs 8-11) ────────────────────────────
  final int manualLeadsTotal;
  final int manualLeadsBySales;
  final int manualLeadsByTelecaller;
  final int manualLeadsByAdmin;

  // ── Group C: Sales Team Pipeline (KPIs 12-19) ─────────────────────────────
  final int activeRequirements;
  final int allocationTelecaller;
  final int allocationSelf;
  final int followupActive;
  final int refollowupActive;
  final int siteVisitsScheduled;
  final int siteVisitsDoneReq;
  final int salesRejectionCount;
  final int dealsWonCount;

  // ── Group D: Qualified Interested Leads (KPIs 20-24) ─────────────────────
  final int qualifiedInterested;
  final int wantRentCount;
  final int wantListCount;
  final int wantResaleCount;
  final int activeInSalesCount;

  const DashboardKpiCounts({
    this.availableInventory = 0,
    this.totalLeads = 0,
    this.allAvailableInventory = 0,
    this.allTotalLeads = 0,
    this.telecallers = 0,
    this.leadsAllocated = 0,
    this.oldLeadsAllocated = 0,
    this.assignedToSales = 0,
    this.siteVisitsDone = 0,
    this.rejectedAfterSiteVisit = 0,
    this.dealWon = 0,
    this.salesUsers = 0,
    this.notInterested = 0,
    this.cnr = 0,
    // Group A
    this.propertiesBySalesAvailable = 0,
    this.propertiesBySalesTotal = 0,
    this.propertiesByTelecallerAvailable = 0,
    this.propertiesByTelecallerTotal = 0,
    this.propertiesByAdminAvailable = 0,
    this.propertiesByAdminTotal = 0,
    this.totalPortfolio = 0,
    this.rentedOutCount = 0,
    this.soldOutCount = 0,
    this.rentalCount = 0,
    this.resaleCount = 0,
    // Group B
    this.manualLeadsTotal = 0,
    this.manualLeadsBySales = 0,
    this.manualLeadsByTelecaller = 0,
    this.manualLeadsByAdmin = 0,
    // Group C
    this.activeRequirements = 0,
    this.allocationTelecaller = 0,
    this.allocationSelf = 0,
    this.followupActive = 0,
    this.refollowupActive = 0,
    this.siteVisitsScheduled = 0,
    this.siteVisitsDoneReq = 0,
    this.salesRejectionCount = 0,
    this.dealsWonCount = 0,
    // Group D
    this.qualifiedInterested = 0,
    this.wantRentCount = 0,
    this.wantListCount = 0,
    this.wantResaleCount = 0,
    this.activeInSalesCount = 0,
  });

  factory DashboardKpiCounts.fromJson(Map<String, dynamic> json) {
    return DashboardKpiCounts(
      availableInventory: (json['available_inventory'] as num?)?.toInt() ?? 0,
      totalLeads: (json['total_leads'] as num?)?.toInt() ?? 0,
      allAvailableInventory: (json['all_available_inventory'] as num?)?.toInt() ??
          (json['global_available_inventory'] as num?)?.toInt() ?? 0,
      allTotalLeads: (json['all_total_leads'] as num?)?.toInt() ??
          (json['global_total_leads'] as num?)?.toInt() ?? 0,
      telecallers: (json['telecallers'] as num?)?.toInt() ?? 0,
      leadsAllocated: (json['leads_allocated'] as num?)?.toInt() ?? (json['new_leads_allocated'] as num?)?.toInt() ?? 0,
      oldLeadsAllocated: (json['old_leads_allocated'] as num?)?.toInt() ?? 0,
      assignedToSales: (json['assigned_to_sales'] as num?)?.toInt() ?? 0,
      siteVisitsDone: (json['site_visits_done'] as num?)?.toInt() ?? 0,
      rejectedAfterSiteVisit: (json['rejected_after_site_visit'] as num?)?.toInt() ?? 0,
      dealWon: (json['deal_won'] as num?)?.toInt() ?? 0,
      salesUsers: (json['sales_users'] as num?)?.toInt() ?? 0,
      notInterested: (json['not_interested'] as num?)?.toInt() ?? 0,
      cnr: (json['cnr'] as num?)?.toInt() ?? 0,
      // Group A
      propertiesBySalesAvailable: (json['properties_by_sales_available'] as num?)?.toInt() ?? 0,
      propertiesBySalesTotal: (json['properties_by_sales_total'] as num?)?.toInt() ?? 0,
      propertiesByTelecallerAvailable: (json['properties_by_telecaller_available'] as num?)?.toInt() ?? 0,
      propertiesByTelecallerTotal: (json['properties_by_telecaller_total'] as num?)?.toInt() ?? 0,
      propertiesByAdminAvailable: (json['properties_by_admin_available'] as num?)?.toInt() ?? 0,
      propertiesByAdminTotal: (json['properties_by_admin_total'] as num?)?.toInt() ?? 0,
      totalPortfolio: (json['total_portfolio'] as num?)?.toInt() ?? 0,
      rentedOutCount: (json['rented_out_count'] as num?)?.toInt() ?? 0,
      soldOutCount: (json['sold_out_count'] as num?)?.toInt() ?? 0,
      rentalCount: (json['rental_count'] as num?)?.toInt() ?? 0,
      resaleCount: (json['resale_count'] as num?)?.toInt() ?? 0,
      // Group B
      manualLeadsTotal: (json['manual_leads_total'] as num?)?.toInt() ?? 0,
      manualLeadsBySales: (json['manual_leads_by_sales'] as num?)?.toInt() ?? 0,
      manualLeadsByTelecaller: (json['manual_leads_by_telecaller'] as num?)?.toInt() ?? 0,
      manualLeadsByAdmin: (json['manual_leads_by_admin'] as num?)?.toInt() ?? 0,
      // Group C
      activeRequirements: (json['active_requirements'] as num?)?.toInt() ?? 0,
      allocationTelecaller: (json['allocation_telecaller'] as num?)?.toInt() ?? 0,
      allocationSelf: (json['allocation_self'] as num?)?.toInt() ?? 0,
      followupActive: (json['followup_active'] as num?)?.toInt() ?? 0,
      refollowupActive: (json['refollowup_active'] as num?)?.toInt() ?? 0,
      siteVisitsScheduled: (json['site_visits_scheduled'] as num?)?.toInt() ?? 0,
      siteVisitsDoneReq: (json['site_visits_done_req'] as num?)?.toInt() ?? 0,
      salesRejectionCount: (json['sales_rejection_count'] as num?)?.toInt() ?? 0,
      dealsWonCount: (json['deals_won_count'] as num?)?.toInt() ?? 0,
      // Group D
      qualifiedInterested: (json['qualified_interested'] as num?)?.toInt() ?? 0,
      wantRentCount: (json['want_rent_count'] as num?)?.toInt() ?? 0,
      wantListCount: (json['want_list_count'] as num?)?.toInt() ?? 0,
      wantResaleCount: (json['want_resale_count'] as num?)?.toInt() ?? 0,
      activeInSalesCount: (json['active_in_sales_count'] as num?)?.toInt() ?? 0,
    );
  }
}


class DashboardKpisResponse {
  final List<KpiConfigItem> config;
  final DashboardKpiCounts counts;
  final Map<String, dynamic> rawCounts;
  final Map<String, dynamic> filters;
  final String? dateRangeDisplay;
  final Map<String, dynamic>? dateRange;

  const DashboardKpisResponse({
    this.config = const [],
    this.counts = const DashboardKpiCounts(),
    this.rawCounts = const {},
    this.filters = const {},
    this.dateRangeDisplay,
    this.dateRange,
  });

  int getDynamicCount(String key) {
    final val = rawCounts[key];
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  factory DashboardKpisResponse.fromJson(Map<String, dynamic> json) {
    final cfgList = (json['config'] as List?)
            ?.map((c) => KpiConfigItem.fromJson(Map<String, dynamic>.from(c)))
            .toList() ??
        [];
    final countsMap = json['counts'] is Map
        ? Map<String, dynamic>.from(json['counts'])
        : <String, dynamic>{};
    final dateRangeMap = json['date_range'] is Map
        ? Map<String, dynamic>.from(json['date_range'])
        : null;
    return DashboardKpisResponse(
      config: cfgList,
      counts: DashboardKpiCounts.fromJson(countsMap),
      rawCounts: countsMap,
      filters: json['filters'] is Map ? Map<String, dynamic>.from(json['filters']) : {},
      dateRangeDisplay: dateRangeMap?['display']?.toString(),
      dateRange: dateRangeMap,
    );
  }

  bool isKpiEnabled(String key) {
    if (config.isEmpty) return true;
    final item = config.firstWhere(
      (c) => c.kpiKey == key,
      orElse: () => KpiConfigItem(kpiKey: key, kpiLabel: key, isEnabled: true, displayOrder: 99),
    );
    return item.isEnabled;
  }
}

class InventoryBreakdownData {
  final int available;
  final int rentedOut;
  final int toBeAvailable;
  final int soldOut;
  final int total;

  const InventoryBreakdownData({
    this.available = 0,
    this.rentedOut = 0,
    this.toBeAvailable = 0,
    this.soldOut = 0,
    this.total = 0,
  });

  factory InventoryBreakdownData.fromJson(Map<String, dynamic> json) {
    return InventoryBreakdownData(
      available: (json['available'] as num?)?.toInt() ?? 0,
      rentedOut: (json['rented_out'] as num?)?.toInt() ?? 0,
      toBeAvailable: (json['to_be_available'] as num?)?.toInt() ?? 0,
      soldOut: (json['sold_out'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class InventoryPropertyItem {
  final String id;
  final String propertyCode;
  final String title;
  final num price;
  final num? superBuiltupArea;
  final int? bedrooms;
  final int? bathrooms;
  final String? createdAt;
  final String status;
  final String listingType;
  final String? areaName;
  final String? createdByName;

  const InventoryPropertyItem({
    required this.id,
    required this.propertyCode,
    required this.title,
    required this.price,
    this.superBuiltupArea,
    this.bedrooms,
    this.bathrooms,
    this.createdAt,
    required this.status,
    required this.listingType,
    this.areaName,
    this.createdByName,
  });

  factory InventoryPropertyItem.fromJson(Map<String, dynamic> json) {
    num parsedPrice = 0;
    if (json['price'] is num) {
      parsedPrice = json['price'] as num;
    } else if (json['price'] != null) {
      parsedPrice = num.tryParse(json['price'].toString()) ?? 0;
    }

    num? parsedArea;
    if (json['super_builtup_area'] is num) {
      parsedArea = json['super_builtup_area'] as num;
    } else if (json['super_builtup_area'] != null) {
      parsedArea = num.tryParse(json['super_builtup_area'].toString());
    }

    int? parsedBedrooms;
    if (json['bedrooms'] is num) {
      parsedBedrooms = (json['bedrooms'] as num).toInt();
    } else if (json['bedrooms'] != null) {
      parsedBedrooms = int.tryParse(json['bedrooms'].toString());
    }

    int? parsedBathrooms;
    if (json['bathrooms'] is num) {
      parsedBathrooms = (json['bathrooms'] as num).toInt();
    } else if (json['bathrooms'] != null) {
      parsedBathrooms = int.tryParse(json['bathrooms'].toString());
    }

    return InventoryPropertyItem(
      id: json['id']?.toString() ?? '',
      propertyCode: json['property_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: parsedPrice,
      superBuiltupArea: parsedArea,
      bedrooms: parsedBedrooms,
      bathrooms: parsedBathrooms,
      createdAt: json['created_at']?.toString(),
      status: json['status']?.toString() ?? 'Available',
      listingType: json['listing_type']?.toString() ?? 'Rent',
      areaName: json['area_name']?.toString(),
      createdByName: json['created_by_name']?.toString(),
    );
  }
}

class InventoryPropertiesResponse {
  final List<InventoryPropertyItem> properties;
  final int total;
  final int page;
  final int limit;

  const InventoryPropertiesResponse({
    this.properties = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  factory InventoryPropertiesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['properties'];
    final List<InventoryPropertyItem> list = [];
    if (rawList is List) {
      for (final p in rawList) {
        if (p is Map) {
          list.add(InventoryPropertyItem.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    return InventoryPropertiesResponse(
      properties: list,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 20,
    );
  }
}

class LeadSourceItem {
  final String source;
  final int count;

  const LeadSourceItem({
    required this.source,
    required this.count,
  });

  factory LeadSourceItem.fromJson(Map<String, dynamic> json) {
    return LeadSourceItem(
      source: json['source']?.toString() ?? 'Other',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeadsBreakdownData {
  final int totalLeads;
  final List<LeadSourceItem> sources;

  const LeadsBreakdownData({
    this.totalLeads = 0,
    this.sources = const [],
  });

  factory LeadsBreakdownData.fromJson(Map<String, dynamic> json) {
    final srcList = (json['sources'] as List?)
            ?.map((s) => LeadSourceItem.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    return LeadsBreakdownData(
      totalLeads: (json['total_leads'] as num?)?.toInt() ?? 0,
      sources: srcList,
    );
  }
}

class LeadListItem {
  final String id;
  final String customerName;
  final String phone;
  final String sanitizedPhone;
  final String? email;
  final String? sanitizedEmail;
  final String source;
  final String leadType;
  final String stage;
  final String? allocationStatus;
  final String? callDisposition;
  final String? rejectionReason;
  final String? archiveReason;
  final String? telecallerRemarks;
  final String? transferRemarks;
  final num? budget;
  final num? budgetFrom;
  final num? budgetTo;
  final int callAttemptCount;
  final String? firstCallAt;
  final String? telecallerAssignedAt;
  final String? salesAssignedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? telecallerId;
  final String? telecallerName;
  final String? telecallerEmail;
  final String? telecallerPhone;
  final String? salesUserId;
  final String? salesUserName;
  final String? salesUserEmail;
  final String? salesUserPhone;
  final String? salesStatus;
  final String? salesRemarks;
  final String? latestCallOutcome;
  final String? latestCallRemarks;
  final String? latestCallAt;
  final String? budgetDisplay;
  final String? configuration;
  final String? locality;
  final String? campaignName;
  final String? followupStatus;
  final String? followupScheduledAt;
  final Map<String, dynamic>? rawJson;

  const LeadListItem({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.sanitizedPhone,
    this.email,
    this.sanitizedEmail,
    required this.source,
    required this.leadType,
    required this.stage,
    this.allocationStatus,
    this.callDisposition,
    this.rejectionReason,
    this.archiveReason,
    this.telecallerRemarks,
    this.transferRemarks,
    this.budget,
    this.budgetFrom,
    this.budgetTo,
    this.callAttemptCount = 0,
    this.firstCallAt,
    this.telecallerAssignedAt,
    this.salesAssignedAt,
    this.createdAt,
    this.updatedAt,
    this.telecallerId,
    this.telecallerName,
    this.telecallerEmail,
    this.telecallerPhone,
    this.salesUserId,
    this.salesUserName,
    this.salesUserEmail,
    this.salesUserPhone,
    this.salesStatus,
    this.salesRemarks,
    this.latestCallOutcome,
    this.latestCallRemarks,
    this.latestCallAt,
    this.budgetDisplay,
    this.configuration,
    this.locality,
    this.campaignName,
    this.followupStatus,
    this.followupScheduledAt,
    this.rawJson,
  });

  factory LeadListItem.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val != null) return num.tryParse(val.toString());
      return null;
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val != null) return int.tryParse(val.toString()) ?? fallback;
      return fallback;
    }

    final p = json['phone']?.toString() ?? json['sanitized_phone']?.toString() ?? '';
    final sp = json['sanitized_phone']?.toString() ?? p;

    Map<String, dynamic>? parsedRaw;
    if (json['raw_json'] is Map) {
      parsedRaw = Map<String, dynamic>.from(json['raw_json'] as Map);
    }

    return LeadListItem(
      id: json['id']?.toString() ?? '',
      customerName: () {
        final rawName = json['customer_name']?.toString().trim() ?? '';
        final isPlaceholder = rawName.isEmpty ||
            rawName.toLowerCase() == 'n/a' ||
            RegExp(r'^(meta|housing|webhook|direct|manual)\s*leads?$', caseSensitive: false).hasMatch(rawName);
        if (!isPlaceholder) return rawName;
        if (parsedRaw != null) {
          for (final key in [
            'lead_name',
            'Full Name',
            'full_name',
            'Client Name',
            'Customer Name',
            'Name',
            'name',
            'Owner Name'
          ]) {
            final val = parsedRaw[key]?.toString().trim();
            if (val != null &&
                val.isNotEmpty &&
                !RegExp(r'^(meta|housing|webhook|direct|manual)\s*leads?$', caseSensitive: false).hasMatch(val)) {
              return val;
            }
          }
        }
        return rawName.isNotEmpty && rawName != 'N/A'
            ? rawName
            : (sp.isNotEmpty ? sp : (p.isNotEmpty ? p : 'Client'));
      }(),
      phone: p,
      sanitizedPhone: sp,
      email: json['email']?.toString() ?? json['sanitized_email']?.toString(),
      sanitizedEmail: json['sanitized_email']?.toString() ?? json['email']?.toString(),
      source: json['source']?.toString() ?? 'Other',
      leadType: json['lead_type']?.toString() ?? 'Requirement',
      stage: json['stage']?.toString() ?? 'NEW',
      allocationStatus: json['allocation_status']?.toString(),
      callDisposition: json['call_disposition']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      archiveReason: json['archive_reason']?.toString(),
      telecallerRemarks: json['telecaller_remarks']?.toString() ?? json['notes']?.toString(),
      transferRemarks: json['transfer_remarks']?.toString(),
      budget: parseNum(json['budget']),
      budgetFrom: parseNum(json['budget_from']),
      budgetTo: parseNum(json['budget_to']),
      callAttemptCount: parseInt(json['call_attempt_count'], 0),
      firstCallAt: json['first_call_at']?.toString(),
      telecallerAssignedAt: json['telecaller_assigned_at']?.toString(),
      salesAssignedAt: json['sales_assigned_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      telecallerId: json['telecaller_id']?.toString(),
      telecallerName: json['telecaller_name']?.toString(),
      telecallerEmail: json['telecaller_email']?.toString(),
      telecallerPhone: json['telecaller_phone']?.toString(),
      salesUserId: json['sales_user_id']?.toString(),
      salesUserName: json['sales_user_name']?.toString(),
      salesUserEmail: json['sales_user_email']?.toString(),
      salesUserPhone: json['sales_user_phone']?.toString(),
      salesStatus: json['sales_status']?.toString(),
      salesRemarks: json['sales_remarks']?.toString(),
      latestCallOutcome: json['latest_call_outcome']?.toString(),
      latestCallRemarks: json['latest_call_remarks']?.toString(),
      latestCallAt: json['latest_call_at']?.toString(),
      budgetDisplay: json['budget_display']?.toString(),
      configuration: json['configuration']?.toString(),
      locality: json['locality']?.toString(),
      campaignName: json['campaign_name']?.toString(),
      followupStatus: json['followup_status']?.toString() ?? json['follow_up_status']?.toString(),
      followupScheduledAt: json['followup_scheduled_at']?.toString() ?? json['follow_up_scheduled_at']?.toString(),
      rawJson: parsedRaw,
    );
  }
}

class LeadsListResponse {
  final List<LeadListItem> leads;
  final int total;
  final int page;
  final int limit;
  final int? metaCount;
  final int? housingCount;
  final String? sourceFilter;

  const LeadsListResponse({
    this.leads = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 25,
    this.metaCount,
    this.housingCount,
    this.sourceFilter,
  });

  factory LeadsListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['leads'] as List?)
            ?.map((l) => LeadListItem.fromJson(Map<String, dynamic>.from(l)))
            .toList() ??
        [];
    return LeadsListResponse(
      leads: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 25,
      metaCount: (json['meta_count'] as num?)?.toInt(),
      housingCount: (json['housing_count'] as num?)?.toInt(),
      sourceFilter: json['sourceFilter'] as String?,
    );
  }
}

class TelecallerSummaryItem {
  final String id;
  final String name;
  final String email;
  final String status;
  final int leadsAllocated;
  final int listingLeads;
  final int requirementLeads;

  const TelecallerSummaryItem({
    required this.id,
    required this.name,
    required this.email,
    this.status = 'Active',
    this.leadsAllocated = 0,
    this.listingLeads = 0,
    this.requirementLeads = 0,
  });

  factory TelecallerSummaryItem.fromJson(Map<String, dynamic> json) {
    return TelecallerSummaryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      leadsAllocated: (json['leads_allocated'] as num?)?.toInt() ?? 0,
      listingLeads: (json['listing_leads'] as num?)?.toInt() ?? 0,
      requirementLeads: (json['requirement_leads'] as num?)?.toInt() ?? 0,
    );
  }
}

class TelecallersSummaryResponse {
  final int totalTelecallers;
  final List<TelecallerSummaryItem> telecallers;

  const TelecallersSummaryResponse({
    this.totalTelecallers = 0,
    this.telecallers = const [],
  });

  factory TelecallersSummaryResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['telecallers'] as List?)
            ?.map((t) => TelecallerSummaryItem.fromJson(Map<String, dynamic>.from(t)))
            .toList() ??
        [];
    return TelecallersSummaryResponse(
      totalTelecallers: (json['total_telecallers'] as num?)?.toInt() ?? 0,
      telecallers: list,
    );
  }
}

class SalesBreakdownItem {
  final String salesUserId;
  final String salesUserName;
  final int leadCount;

  const SalesBreakdownItem({
    required this.salesUserId,
    required this.salesUserName,
    required this.leadCount,
  });

  factory SalesBreakdownItem.fromJson(Map<String, dynamic> json) {
    return SalesBreakdownItem(
      salesUserId: json['sales_user_id']?.toString() ?? '',
      salesUserName: json['sales_user_name']?.toString() ?? '',
      leadCount: (json['lead_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TelecallerDrilldownData {
  final String telecallerId;
  final String telecallerName;
  final String telecallerEmail;
  final int totalAllocated;
  final int listingAllocated;
  final int requirementAllocated;
  final int openLeads;
  final int cnr;
  final int callbacks;
  final int followUp;
  final int followUpCurrent;
  final int followUpHistory;
  final int assignedToSales;
  final List<SalesBreakdownItem> salesUserBreakdown;
  final int notInterested;
  final int archived;

  const TelecallerDrilldownData({
    required this.telecallerId,
    required this.telecallerName,
    required this.telecallerEmail,
    this.totalAllocated = 0,
    this.listingAllocated = 0,
    this.requirementAllocated = 0,
    this.openLeads = 0,
    this.cnr = 0,
    this.callbacks = 0,
    this.followUp = 0,
    this.followUpCurrent = 0,
    this.followUpHistory = 0,
    this.assignedToSales = 0,
    this.salesUserBreakdown = const [],
    this.notInterested = 0,
    this.archived = 0,
  });

  factory TelecallerDrilldownData.fromJson(Map<String, dynamic> json) {
    final tc = json['telecaller'] is Map ? Map<String, dynamic>.from(json['telecaller']) : {};
    final salesList = (json['sales_user_breakdown'] as List?)
            ?.map((s) => SalesBreakdownItem.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    return TelecallerDrilldownData(
      telecallerId: tc['id']?.toString() ?? '',
      telecallerName: tc['name']?.toString() ?? '',
      telecallerEmail: tc['email']?.toString() ?? '',
      totalAllocated: (json['total_allocated'] as num?)?.toInt() ?? 0,
      listingAllocated: (json['listing_allocated'] as num?)?.toInt() ?? 0,
      requirementAllocated: (json['requirement_allocated'] as num?)?.toInt() ?? 0,
      openLeads: (json['open_leads'] as num?)?.toInt() ?? 0,
      cnr: (json['cnr'] as num?)?.toInt() ?? 0,
      callbacks: (json['callbacks'] as num?)?.toInt() ?? 0,
      followUp: (json['follow_up'] as num?)?.toInt() ?? 0,
      followUpCurrent: (json['follow_up_current'] as num?)?.toInt() ?? 0,
      followUpHistory: (json['follow_up_history'] as num?)?.toInt() ?? 0,
      assignedToSales: (json['assigned_to_sales'] as num?)?.toInt() ?? 0,
      salesUserBreakdown: salesList,
      notInterested: (json['not_interested'] as num?)?.toInt() ?? 0,
      archived: (json['archived'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeadsAllocatedTelecallerItem {
  final String telecallerId;
  final String telecallerName;
  final int listingCount;
  final int requirementCount;
  final int newCount;
  final int oldCount;
  final int totalCount;

  const LeadsAllocatedTelecallerItem({
    required this.telecallerId,
    required this.telecallerName,
    this.listingCount = 0,
    this.requirementCount = 0,
    this.newCount = 0,
    this.oldCount = 0,
    this.totalCount = 0,
  });

  factory LeadsAllocatedTelecallerItem.fromJson(Map<String, dynamic> json) {
    return LeadsAllocatedTelecallerItem(
      telecallerId: json['telecaller_id']?.toString() ?? '',
      telecallerName: json['telecaller_name']?.toString() ?? '',
      listingCount: (json['listing_count'] as num?)?.toInt() ?? 0,
      requirementCount: (json['requirement_count'] as num?)?.toInt() ?? 0,
      newCount: (json['new_count'] as num?)?.toInt() ?? 0,
      oldCount: (json['old_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeadsAllocatedResponse {
  final int totalAllocated;
  final int newAllocated;
  final int oldAllocated;
  final int listingAllocated;
  final int requirementAllocated;
  final int oldListingAllocated;
  final int oldRequirementAllocated;
  final List<LeadsAllocatedTelecallerItem> telecallers;

  const LeadsAllocatedResponse({
    this.totalAllocated = 0,
    this.newAllocated = 0,
    this.oldAllocated = 0,
    this.listingAllocated = 0,
    this.requirementAllocated = 0,
    this.oldListingAllocated = 0,
    this.oldRequirementAllocated = 0,
    this.telecallers = const [],
  });

  factory LeadsAllocatedResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['telecallers'] as List?)
            ?.map((t) => LeadsAllocatedTelecallerItem.fromJson(Map<String, dynamic>.from(t)))
            .toList() ??
        [];
    return LeadsAllocatedResponse(
      totalAllocated: (json['total_allocated'] as num?)?.toInt() ?? 0,
      newAllocated: (json['new_allocated'] as num?)?.toInt() ?? (json['total_allocated'] as num?)?.toInt() ?? 0,
      oldAllocated: (json['old_allocated'] as num?)?.toInt() ?? 0,
      listingAllocated: (json['listing_allocated'] as num?)?.toInt() ?? 0,
      requirementAllocated: (json['requirement_allocated'] as num?)?.toInt() ?? 0,
      oldListingAllocated: (json['old_listing_allocated'] as num?)?.toInt() ?? 0,
      oldRequirementAllocated: (json['old_requirement_allocated'] as num?)?.toInt() ?? 0,
      telecallers: list,
    );
  }
}

class AssignedToSalesBreakdownItem {
  final String telecallerId;
  final String telecallerName;
  final String salesUserId;
  final String salesUserName;
  final int listingCount;
  final int requirementCount;
  final int totalCount;

  const AssignedToSalesBreakdownItem({
    required this.telecallerId,
    required this.telecallerName,
    required this.salesUserId,
    required this.salesUserName,
    this.listingCount = 0,
    this.requirementCount = 0,
    this.totalCount = 0,
  });

  factory AssignedToSalesBreakdownItem.fromJson(Map<String, dynamic> json) {
    return AssignedToSalesBreakdownItem(
      telecallerId: json['telecaller_id']?.toString() ?? '',
      telecallerName: json['telecaller_name']?.toString() ?? '',
      salesUserId: json['sales_user_id']?.toString() ?? '',
      salesUserName: json['sales_user_name']?.toString() ?? '',
      listingCount: (json['listing_count'] as num?)?.toInt() ?? 0,
      requirementCount: (json['requirement_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AssignedToSalesResponse {
  final int totalAssigned;
  final int listingAssigned;
  final int requirementAssigned;
  final List<AssignedToSalesBreakdownItem> breakdown;

  const AssignedToSalesResponse({
    this.totalAssigned = 0,
    this.listingAssigned = 0,
    this.requirementAssigned = 0,
    this.breakdown = const [],
  });

  factory AssignedToSalesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['breakdown'] as List?)
            ?.map((b) => AssignedToSalesBreakdownItem.fromJson(Map<String, dynamic>.from(b)))
            .toList() ??
        [];
    return AssignedToSalesResponse(
      totalAssigned: (json['total_assigned'] as num?)?.toInt() ?? 0,
      listingAssigned: (json['listing_assigned'] as num?)?.toInt() ?? 0,
      requirementAssigned: (json['requirement_assigned'] as num?)?.toInt() ?? 0,
      breakdown: list,
    );
  }
}

class SalesUserSummaryItem {
  final String id;
  final String name;
  final String email;
  final int leadsCount;

  const SalesUserSummaryItem({
    required this.id,
    required this.name,
    required this.email,
    this.leadsCount = 0,
  });

  factory SalesUserSummaryItem.fromJson(Map<String, dynamic> json) {
    return SalesUserSummaryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      leadsCount: (json['leads_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesUsersSummaryResponse {
  final int totalSalesUsers;
  final List<SalesUserSummaryItem> salesUsers;

  const SalesUsersSummaryResponse({
    this.totalSalesUsers = 0,
    this.salesUsers = const [],
  });

  factory SalesUsersSummaryResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['sales_users'] as List?)
            ?.map((s) => SalesUserSummaryItem.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    return SalesUsersSummaryResponse(
      totalSalesUsers: (json['total_sales_users'] as num?)?.toInt() ?? 0,
      salesUsers: list,
    );
  }
}

class RejectionReasonItem {
  final String reason;
  final String rawStatus;
  final int count;

  const RejectionReasonItem({
    required this.reason,
    required this.rawStatus,
    required this.count,
  });

  factory RejectionReasonItem.fromJson(Map<String, dynamic> json) {
    return RejectionReasonItem(
      reason: json['reason']?.toString() ?? 'Other',
      rawStatus: json['raw_status']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesUserLifecycleStatuses {
  final int callAttempted;
  final int open;
  final int pickedUp;
  final int followUp;
  final int reFollowUp;
  final int interested;
  final int siteVisitScheduled;
  final int siteVisitDone;
  final int dealWon;
  final int rejected;
  final int total;

  const SalesUserLifecycleStatuses({
    this.callAttempted = 0,
    this.open = 0,
    this.pickedUp = 0,
    this.followUp = 0,
    this.reFollowUp = 0,
    this.interested = 0,
    this.siteVisitScheduled = 0,
    this.siteVisitDone = 0,
    this.dealWon = 0,
    this.rejected = 0,
    this.total = 0,
  });

  factory SalesUserLifecycleStatuses.fromJson(Map<String, dynamic> json) {
    return SalesUserLifecycleStatuses(
      callAttempted: (json['call_attempted'] as num?)?.toInt() ?? 0,
      open: (json['open'] as num?)?.toInt() ?? 0,
      pickedUp: (json['picked_up'] as num?)?.toInt() ?? 0,
      followUp: (json['follow_up'] as num?)?.toInt() ?? 0,
      reFollowUp: (json['re_follow_up'] as num?)?.toInt() ?? 0,
      interested: (json['interested'] as num?)?.toInt() ?? 0,
      siteVisitScheduled: (json['site_visit_scheduled'] as num?)?.toInt() ?? 0,
      siteVisitDone: (json['site_visit_done'] as num?)?.toInt() ?? 0,
      dealWon: (json['deal_won'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesUserDrilldownData {
  final String salesUserId;
  final String salesUserName;
  final String salesUserEmail;
  final SalesUserLifecycleStatuses statuses;
  final List<RejectionReasonItem> rejectionBreakdown;

  const SalesUserDrilldownData({
    required this.salesUserId,
    required this.salesUserName,
    required this.salesUserEmail,
    required this.statuses,
    this.rejectionBreakdown = const [],
  });

  factory SalesUserDrilldownData.fromJson(Map<String, dynamic> json) {
    final su = json['sales_user'] is Map ? Map<String, dynamic>.from(json['sales_user']) : {};
    final st = json['statuses'] is Map ? Map<String, dynamic>.from(json['statuses']) : <String, dynamic>{};
    final rejList = (json['rejection_breakdown'] as List?)
            ?.map((r) => RejectionReasonItem.fromJson(Map<String, dynamic>.from(r)))
            .toList() ??
        [];
    return SalesUserDrilldownData(
      salesUserId: su['id']?.toString() ?? '',
      salesUserName: su['name']?.toString() ?? '',
      salesUserEmail: su['email']?.toString() ?? '',
      statuses: SalesUserLifecycleStatuses.fromJson(st),
      rejectionBreakdown: rejList,
    );
  }
}

class KpiFilterParams {
  final String businessType; // 'Rent', 'Re-sale', 'Both'
  final String dateFilter; // 'Today', 'Weekly', 'Monthly', 'Yearly', 'Custom Range'
  final String? startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD
  final String leadType; // 'Listing', 'Requirement', 'Both'
  final String? outcome; // 'INTERESTED', 'REJECTED_AFTER_VISIT', 'DEAL_WON', etc.

  const KpiFilterParams({
    this.businessType = 'Rent',
    this.dateFilter = 'Weekly',
    this.startDate,
    this.endDate,
    this.leadType = 'Both',
    this.outcome,
  });

  KpiFilterParams copyWith({
    String? businessType,
    String? dateFilter,
    String? startDate,
    String? endDate,
    String? leadType,
    String? outcome,
  }) {
    return KpiFilterParams(
      businessType: businessType ?? this.businessType,
      dateFilter: dateFilter ?? this.dateFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      leadType: leadType ?? this.leadType,
      outcome: outcome ?? this.outcome,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'businessType': businessType,
      'dateFilter': dateFilter,
      if (startDate != null && startDate!.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate!.isNotEmpty) 'endDate': endDate,
      'leadType': leadType,
      if (outcome != null && outcome!.isNotEmpty) 'outcome': outcome,
    };
  }

  Map<String, dynamic> toJson() => toQueryParams();
}

class SiteVisitItem {
  final String id;
  final String customerName;
  final String mobile;
  final num? budget;
  final num? budgetFrom;
  final num? budgetTo;
  final String status;
  final String? outcome;
  final String? outcomeAt;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? remarks;
  final String? salesUserId;
  final String? salesUserName;
  final String? salesUserPhone;
  final String? salesUserEmail;
  final String? areaName;
  final String? listingType;
  final String? propertyType;

  const SiteVisitItem({
    required this.id,
    required this.customerName,
    required this.mobile,
    this.budget,
    this.budgetFrom,
    this.budgetTo,
    required this.status,
    this.outcome,
    this.outcomeAt,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.remarks,
    this.salesUserId,
    this.salesUserName,
    this.salesUserPhone,
    this.salesUserEmail,
    this.areaName,
    this.listingType,
    this.propertyType,
  });

  factory SiteVisitItem.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val != null) return num.tryParse(val.toString());
      return null;
    }

    return SiteVisitItem(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'N/A',
      mobile: json['mobile']?.toString() ?? '',
      budget: parseNum(json['budget']),
      budgetFrom: parseNum(json['budget_from']),
      budgetTo: parseNum(json['budget_to']),
      status: json['status']?.toString() ?? 'Site Visit Done',
      outcome: json['outcome']?.toString(),
      outcomeAt: json['outcome_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: json['notes']?.toString(),
      remarks: json['remarks']?.toString(),
      salesUserId: json['sales_user_id']?.toString(),
      salesUserName: json['sales_user_name']?.toString(),
      salesUserPhone: json['sales_user_phone']?.toString(),
      salesUserEmail: json['sales_user_email']?.toString(),
      areaName: json['area_name']?.toString(),
      listingType: json['listing_type']?.toString(),
      propertyType: json['property_type']?.toString(),
    );
  }
}

class SiteVisitsResponse {
  final List<SiteVisitItem> siteVisits;
  final int total;
  final int page;
  final int limit;

  const SiteVisitsResponse({
    this.siteVisits = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 25,
  });

  factory SiteVisitsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['site_visits'] as List?)
            ?.map((v) => SiteVisitItem.fromJson(Map<String, dynamic>.from(v)))
            .toList() ??
        [];
    return SiteVisitsResponse(
      siteVisits: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 25,
    );
  }
}

class DealWonItem {
  final String id;
  final String customerName;
  final String mobile;
  final num? budget;
  final num? budgetFrom;
  final num? budgetTo;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? remarks;
  final String? salesUserId;
  final String? salesUserName;
  final String? salesUserPhone;
  final String? salesUserEmail;
  final String? areaName;
  final String? listingType;
  final String? propertyType;

  const DealWonItem({
    required this.id,
    required this.customerName,
    required this.mobile,
    this.budget,
    this.budgetFrom,
    this.budgetTo,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.remarks,
    this.salesUserId,
    this.salesUserName,
    this.salesUserPhone,
    this.salesUserEmail,
    this.areaName,
    this.listingType,
    this.propertyType,
  });

  factory DealWonItem.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val != null) return num.tryParse(val.toString());
      return null;
    }

    return DealWonItem(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'N/A',
      mobile: json['mobile']?.toString() ?? '',
      budget: parseNum(json['budget']),
      budgetFrom: parseNum(json['budget_from']),
      budgetTo: parseNum(json['budget_to']),
      status: json['status']?.toString() ?? 'Won',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: json['notes']?.toString(),
      remarks: json['remarks']?.toString(),
      salesUserId: json['sales_user_id']?.toString(),
      salesUserName: json['sales_user_name']?.toString(),
      salesUserPhone: json['sales_user_phone']?.toString(),
      salesUserEmail: json['sales_user_email']?.toString(),
      areaName: json['area_name']?.toString(),
      listingType: json['listing_type']?.toString(),
      propertyType: json['property_type']?.toString(),
    );
  }
}

class DealWonResponse {
  final List<DealWonItem> dealsWon;
  final int total;
  final int page;
  final int limit;

  const DealWonResponse({
    this.dealsWon = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 25,
  });

  factory DealWonResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['deals_won'] as List?)
            ?.map((v) => DealWonItem.fromJson(Map<String, dynamic>.from(v)))
            .toList() ??
        [];
    return DealWonResponse(
      dealsWon: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 25,
    );
  }
}

class SalesUserRequirementItem {
  final String id;
  final String customerName;
  final String mobile;
  final num? budget;
  final num? budgetFrom;
  final num? budgetTo;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? remarks;
  final String? areaName;
  final String? listingType;
  final String? propertyType;

  const SalesUserRequirementItem({
    required this.id,
    required this.customerName,
    required this.mobile,
    this.budget,
    this.budgetFrom,
    this.budgetTo,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.remarks,
    this.areaName,
    this.listingType,
    this.propertyType,
  });

  factory SalesUserRequirementItem.fromJson(Map<String, dynamic> json) {
    num? parseNum(dynamic val) {
      if (val is num) return val;
      if (val != null) return num.tryParse(val.toString());
      return null;
    }

    return SalesUserRequirementItem(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'N/A',
      mobile: json['mobile']?.toString() ?? '',
      budget: parseNum(json['budget']),
      budgetFrom: parseNum(json['budget_from']),
      budgetTo: parseNum(json['budget_to']),
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: json['notes']?.toString(),
      remarks: json['remarks']?.toString(),
      areaName: json['area_name']?.toString(),
      listingType: json['listing_type']?.toString(),
      propertyType: json['property_type']?.toString(),
    );
  }
}

class SalesUserRequirementsResponse {
  final List<SalesUserRequirementItem> requirements;
  final int total;
  final int page;
  final int limit;

  const SalesUserRequirementsResponse({
    this.requirements = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 25,
  });

  factory SalesUserRequirementsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['requirements'] as List?)
            ?.map((v) => SalesUserRequirementItem.fromJson(Map<String, dynamic>.from(v)))
            .toList() ??
        [];
    return SalesUserRequirementsResponse(
      requirements: list,
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 25,
    );
  }
}


