import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../ai_search_suggestions.dart';

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
    const keys = ['properties', 'requirements', 'owners', 'clients', 'leads', 'employees'];
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

  /// Suggestions while typing: own history, popular terms, pages, places, top records.
  Future<({AiSuggestions suggestions, bool failed, bool offline})> suggest(String query) async {
    try {
      final response = await _apiClient.get('/search/suggest', queryParameters: {'q': query});
      return (suggestions: AiSuggestions.fromJson(_dataOf(response.data)), failed: false, offline: false);
    } catch (error) {
      return (suggestions: AiSuggestions.empty, failed: true, offline: _isOffline(error));
    }
  }

  /// Saves a committed search to the caller's own history. Never blocks navigation.
  Future<void> record({
    required String query,
    String source = 'typed',
    int? resultCount,
    String? selectionType,
    String? selectionId,
    String? selectionRoute,
  }) async {
    if (query.trim().isEmpty) return;
    try {
      await _apiClient.post('/search/history', {
        'query': query.trim(),
        'source': source,
        'result_count': ?resultCount,
        if (selectionType != null)
          'selection': {
            'type': selectionType,
            'id': ?selectionId,
            'route': ?selectionRoute,
          },
      });
    } catch (_) {}
  }

  Future<AiSearchHistoryPage?> history({int page = 1, int limit = 20, String? filter}) async {
    try {
      final response = await _apiClient.get('/search/history', queryParameters: {
        'page': page,
        'limit': limit,
        if (filter != null && filter.trim().isNotEmpty) 'q': filter.trim(),
      });
      return AiSearchHistoryPage.fromJson(_dataOf(response.data));
    } catch (_) {
      return null;
    }
  }

  Future<bool> removeHistory(String id) async {
    try {
      await _apiClient.delete('/search/history/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      await _apiClient.delete('/search/history');
      return true;
    } catch (_) {
      return false;
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
