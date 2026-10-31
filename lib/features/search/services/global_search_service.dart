import '../../../core/api/api_client.dart';

class GlobalSearchService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> search({
    required String query,
    required String category,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get('/search', queryParameters: {
      'query': query,
      'category': category,
      'page': page,
      'limit': limit,
    });
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return {};
  }
}
