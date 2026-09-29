import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/campaign_connection_model.dart';

class CampaignConnectionsService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all configured campaign connections for the current organization
  Future<List<CampaignConnectionModel>> getConnections() async {
    try {
      final response = await _apiClient.get('/campaign-connections');
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final rawList = map['connections'] ?? map['data'];
        final list = rawList is List ? rawList : [];
        return list
            .map((item) => CampaignConnectionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to fetch campaign connections.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Toggle connection active/disabled state
  Future<CampaignConnectionModel> toggleConnection(String id, bool isActive) async {
    try {
      final response = await _apiClient.patch(
        '/campaign-connections/$id/toggle',
        {'is_active': isActive},
      );
      if (response.data is Map<String, dynamic>) {
        final conn = (response.data['connection'] ?? response.data['data']) as Map<String, dynamic>;
        return CampaignConnectionModel.fromJson(conn);
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to toggle connection.');
    }
  }

  /// Test connectivity and credentials calculation
  Future<Map<String, dynamic>> testConnection(String id) async {
    try {
      final response = await _apiClient.post(
        '/campaign-connections/$id/test',
        {},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Test passed'};
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Test connection failed.');
    }
  }

  /// Trigger on-demand lead sync
  Future<Map<String, dynamic>> syncConnection(String id) async {
    try {
      final response = await _apiClient.post(
        '/campaign-connections/$id/sync',
        {},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Sync completed'};
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Lead sync failed.');
    }
  }

  /// Create or update connection
  Future<CampaignConnectionModel> saveConnection(Map<String, dynamic> data) async {
    try {
      final id = data['id'];
      final Response response;
      if (id != null && id.toString().isNotEmpty) {
        response = await _apiClient.put(
          '/campaign-connections/$id',
          data,
        );
      } else {
        response = await _apiClient.post(
          '/campaign-connections',
          data,
        );
      }
      if (response.data is Map<String, dynamic>) {
        final conn = (response.data['connection'] ?? response.data['data']) as Map<String, dynamic>;
        return CampaignConnectionModel.fromJson(conn);
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to save connection.');
    }
  }
}
