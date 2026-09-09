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
import '../models/report_data.dart';
import '../services/report_data_engine.dart';

class ReportsRepository {
  final RequirementsRepository _requirementsRepository = RequirementsRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  static const String _kpiPrefsKey = 'reports_kpi_configuration_v1';

  /// Load persisted KPI configuration or fallback to defaults
  Future<ReportConfiguration> loadConfiguration() async {
    final initial = ReportConfiguration.initial();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKpiJson = prefs.getString(_kpiPrefsKey);
      final savedKpis = ReportConfiguration.deserializeKpiPreferences(savedKpiJson);

      if (savedKpis != null && savedKpis.isNotEmpty) {
        return initial.copyWith(kpiConfigs: savedKpis);
      }
    } catch (_) {}
    return initial;
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
