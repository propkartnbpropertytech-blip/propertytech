import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class AiSearchResult {
  final Map<String, dynamic> data;
  final bool failed;
  final bool offline;

  const AiSearchResult({
    required this.data,
    this.failed = false,
    this.offline = false,
  });

  bool get hasRows {
    const keys = ['properties', 'requirements', 'owners', 'clients', 'leads'];
    return keys.any((key) {
      final rows = data[key];
      return rows is List && rows.isNotEmpty;
    });
  }
}

class AiSearchService {
  AiSearchService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AiSearchResult> search({
    required String query,
    Map<String, dynamic>? filters,
    String? entity,
    String? sort,
    String? category,
    int page = 1,
    int limit = 8,
    bool filtersEdited = false,
  }) async {
    final body = <String, dynamic>{
      'query': query,
      'page': page,
      'limit': limit,
      'filters_edited': filtersEdited,
      'entity': ?entity,
      'filters': ?filters,
      'sort': ?sort,
      'category': ?category,
    };
    try {
      final response = await _apiClient.post('/search/ai', body);
      return AiSearchResult(data: _dataOf(response.data));
    } catch (error) {
      try {
        final interpreted = await _apiClient.get('/search', queryParameters: {
          'query': query,
          'interpret': '1',
          'page': page,
          'limit': limit,
          'category': ?category,
        });
        return AiSearchResult(data: _dataOf(interpreted.data));
      } catch (fallback) {
        return AiSearchResult(
          data: const {},
          failed: true,
          offline: _isOffline(error) || _isOffline(fallback),
        );
      }
    }
  }

  Map<String, dynamic> _dataOf(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return {};
  }

  bool _isOffline(Object error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown ||
        error.response == null;
  }
}
