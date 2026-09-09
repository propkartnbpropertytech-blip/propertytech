import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../users/models/user_model.dart';
import '../../users/repository/users_repository.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/storage/model_mappers.dart';
import '../models/report_configuration.dart';
import '../models/report_date_range.dart';
import '../models/report_filter_state.dart';
import '../models/report_data.dart';
import '../services/report_data_engine.dart';

class ReportsRepository {
  final RequirementsRepository _requirementsRepository = RequirementsRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  static const String _kpiPrefsKey = 'reports_kpi_configuration_v1';
  static const String _sectionsPrefsKey = 'reports_sections_configuration_v1';
  static const String _dateRangePrefsKey = 'reports_date_range_preference_v1';
  static const String _filtersPrefsKey = 'reports_filters_preference_v1';

  /// Load persisted KPI, section, date range, and filter configuration or fallback to defaults
  Future<ReportConfiguration> loadConfiguration() async {
    var config = ReportConfiguration.initial();
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Date Range preference
      final savedDateRangeJson = prefs.getString(_dateRangePrefsKey);
      if (savedDateRangeJson != null && savedDateRangeJson.isNotEmpty) {
        try {
          final map = jsonDecode(savedDateRangeJson) as Map<String, dynamic>;
          config = config.copyWith(dateRange: ReportDateRange.fromJson(map));
        } catch (_) {}
      }

      // 2. Global Filters preference
      final savedFiltersJson = prefs.getString(_filtersPrefsKey);
      if (savedFiltersJson != null && savedFiltersJson.isNotEmpty) {
        try {
          final map = jsonDecode(savedFiltersJson) as Map<String, dynamic>;
          config = config.copyWith(filters: ReportFilterState.fromJson(map));
        } catch (_) {}
      }

      // 3. KPI Preferences (order, enabled, count/percentage preference)
      final savedKpiJson = prefs.getString(_kpiPrefsKey);
      final savedKpis = ReportConfiguration.deserializeKpiPreferences(savedKpiJson);
      if (savedKpis != null && savedKpis.isNotEmpty) {
        config = config.copyWith(kpiConfigs: savedKpis);
      }

      // 4. Section Visibilities
      final savedSectionsJson = prefs.getString(_sectionsPrefsKey);
      if (savedSectionsJson != null && savedSectionsJson.isNotEmpty) {
        final map = jsonDecode(savedSectionsJson) as Map<String, dynamic>;
        config = config.copyWith(
          showGrowthComparison: map['showGrowthComparison'] as bool? ?? config.showGrowthComparison,
          showLeadSourceAnalysis: map['showLeadSourceAnalysis'] as bool? ?? config.showLeadSourceAnalysis,
          showTrendAnalysis: map['showTrendAnalysis'] as bool? ?? config.showTrendAnalysis,
          showLeadStatusPipeline: map['showLeadStatusPipeline'] as bool? ?? config.showLeadStatusPipeline,
          showConversionFunnel: map['showConversionFunnel'] as bool? ?? config.showConversionFunnel,
          showFollowupAnalysis: map['showFollowupAnalysis'] as bool? ?? config.showFollowupAnalysis,
          showTeamRanking: map['showTeamRanking'] as bool? ?? config.showTeamRanking,
          showBusinessInsights: map['showBusinessInsights'] as bool? ?? config.showBusinessInsights,
        );
      }
    } catch (_) {}
    return config;
  }

  /// Persist date range preference
  Future<void> saveDateRangePreference(ReportDateRange dateRange) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dateRangePrefsKey, jsonEncode(dateRange.toJson()));
    } catch (_) {}
  }

  /// Persist global filters preference
  Future<void> saveFiltersPreference(ReportFilterState filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filtersPrefsKey, jsonEncode(filters.toJson()));
    } catch (_) {}
  }

  /// Persist KPI order, enabled status, and metric toggles
  Future<void> saveKpiConfiguration(List<ReportKpiConfig> configs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = ReportConfiguration(
        dateRange: ReportConfiguration.initial().dateRange,
        kpiConfigs: configs,
      ).serializeKpiPreferences();
      await prefs.setString(_kpiPrefsKey, serialized);
    } catch (_) {}
  }

  /// Persist section visibilities
  Future<void> saveSectionVisibilities({
    required bool showGrowthComparison,
    required bool showLeadSourceAnalysis,
    required bool showTrendAnalysis,
    bool? showLeadStatusPipeline,
    bool? showConversionFunnel,
    bool? showFollowupAnalysis,
    bool? showTeamRanking,
    bool? showBusinessInsights,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        'showGrowthComparison': showGrowthComparison,
        'showLeadSourceAnalysis': showLeadSourceAnalysis,
        'showTrendAnalysis': showTrendAnalysis,
        'showLeadStatusPipeline': ?showLeadStatusPipeline,
        'showConversionFunnel': ?showConversionFunnel,
        'showFollowupAnalysis': ?showFollowupAnalysis,
        'showTeamRanking': ?showTeamRanking,
        'showBusinessInsights': ?showBusinessInsights,
      };
      await prefs.setString(_sectionsPrefsKey, jsonEncode(map));
    } catch (_) {}
  }

  /// Fetch leads, users, properties, and followups, and compute aggregated report
  Future<ReportOverallData> getReportData(ReportConfiguration config) async {
    // 1. Fetch leads
    List<RequirementModel> leads = [];
    try {
      leads = await _requirementsRepository.getRequirements(refreshFromServer: false);
    } catch (_) {
      final localList = await _coordinator.requirementLocal.getRequirements();
      leads = localList.map((r) => r.toModel()).toList();
    }

    // 2. Fetch users
    List<UserModel> users = [];
    try {
      users = await _usersRepository.getUsers();
    } catch (_) {}

    // 3. Fetch properties
    List<PropertyModel> properties = [];
    try {
      properties = await _propertiesRepository.getProperties(refreshFromServer: false);
    } catch (_) {}

    // 4. Fetch followups
    List<FollowupLocal> followups = [];
    try {
      followups = await _coordinator.followupLocal.getAllFollowups();
    } catch (_) {}

    // 5. Gather dynamic statuses from lookups & system
    List<String> dynamicStatuses = [];
    try {
      final statusLookups = await _coordinator.lookupLocal.getLookupsByCategory('lead_status');
      dynamicStatuses = statusLookups.map((s) => s.name).toList();
    } catch (_) {}

    // Seed standard CRM statuses from Leads module if missing
    final standardLeadStatuses = [
      'New',
      'Not Started',
      'Call Attempted',
      'Call Attempted (Picked Up)',
      'Call Attempted (Open)',
      'Follow-up',
      'Interested',
      'Site Visit',
      'Site Visit Done',
      'Negotiation',
      'Won',
      'Rejected',
      'Rejected (Not Answering)',
      'Rejected (No Requirement)',
      'Rejected (Budget Mismatch)',
      'Rejected (Locality Mismatch)',
      'Rejected (Broker)',
      'Rejected (Already rented)',
      'Rejected (Want Ready-To-Move)',
      'Rejected (Negotiation Failed)',
      'Rejected (Others)',
    ];
    for (final s in standardLeadStatuses) {
      if (!dynamicStatuses.any((d) => d.toLowerCase() == s.toLowerCase())) {
        dynamicStatuses.add(s);
      }
    }

    return ReportDataEngine.computeReport(
      allLeads: leads,
      allUsers: users,
      allProperties: properties,
      allFollowups: followups,
      systemStatuses: dynamicStatuses,
      config: config,
    );
  }
}
