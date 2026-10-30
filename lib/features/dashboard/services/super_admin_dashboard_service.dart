import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';
import '../models/super_admin_platform_overview.dart';

class SuperAdminDashboardService {
  final ApiClient _apiClient;

  SuperAdminDashboardService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<SuperAdminPlatformOverview> fetchOverview({String? organizationId}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.superAdminPlatformOverview,
        queryParameters: {
          if (organizationId != null && organizationId.isNotEmpty)
            'organizationId': organizationId,
        },
      );
      final body = response.data;
      if (body is Map<String, dynamic> &&
          body['success'] == true &&
          body['data'] is Map<String, dynamic>) {
        return SuperAdminPlatformOverview.fromJson(body['data'] as Map<String, dynamic>);
      }
      final message = body is Map ? body['message']?.toString() : null;
      throw ApiException(message: message ?? 'Failed to fetch the platform overview.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
