import '../../../core/api/api_exception.dart';
import '../models/super_admin_platform_overview.dart';
import '../services/super_admin_dashboard_service.dart';

class SuperAdminDashboardLoadException implements Exception {
  final String message;

  SuperAdminDashboardLoadException(this.message);

  @override
  String toString() => message;
}

class SuperAdminDashboardRepository {
  final SuperAdminDashboardService? _service;

  SuperAdminDashboardRepository({SuperAdminDashboardService? service}) : _service = service;

  Future<SuperAdminPlatformOverview> fetch({String? organizationId}) async {
    try {
      final service = _service ?? SuperAdminDashboardService();
      return await service.fetchOverview(organizationId: organizationId);
    } on ApiException catch (e) {
      throw SuperAdminDashboardLoadException(e.message);
    } catch (e) {
      throw SuperAdminDashboardLoadException(e.toString());
    }
  }
}
