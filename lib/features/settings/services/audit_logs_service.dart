import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/audit_log_model.dart';

class AuditLogsService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch paginated and filtered audit & telemetry logs
  Future<AuditLogsResponse> fetchAuditLogs({
    String? role,
    String? userId,
    String? adminId,
    String? action,
    String? module,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (role != null && role != 'All') 'role': role,
        if (userId != null && userId != 'All') 'userId': userId,
        if (adminId != null && adminId != 'All') 'adminId': adminId,
        if (action != null && action != 'All') 'action': action,
        if (module != null && module != 'All') 'module': module,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      };

      final response = await _apiClient.get('/audit/logs', queryParameters: queryParams);

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true && map['data'] != null) {
          return AuditLogsResponse.fromJson(Map<String, dynamic>.from(map['data'] as Map));
        }
        throw ApiException(message: map['message'] ?? 'Failed to fetch audit logs.');
      }
      throw ApiException(message: 'Invalid response structure received.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetch user hierarchy with admin links for Super Admin dropdowns
  Future<UsersHierarchyResponse> fetchUsersHierarchy() async {
    try {
      final response = await _apiClient.get('/audit/users-hierarchy');
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true && map['data'] != null) {
          return UsersHierarchyResponse.fromJson(Map<String, dynamic>.from(map['data'] as Map));
        }
        throw ApiException(message: map['message'] ?? 'Failed to fetch users hierarchy.');
      }
      return const UsersHierarchyResponse();
    } catch (_) {
      return const UsersHierarchyResponse();
    }
  }
}
