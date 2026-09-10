import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  /// Shared across every [DashboardService] instance so parallel callers
  /// (bloc, shell, background refresh) hit the network once.
  static Future<Map<String, dynamic>>? _inFlight;

  Future<Map<String, dynamic>> getDashboardData() {
    return _inFlight ??= _fetch().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<Map<String, dynamic>> _fetch() async {
    try {
      final response = await _apiClient.get('/dashboard');
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true && map['data'] is Map<String, dynamic>) {
          return map['data'] as Map<String, dynamic>;
        }
        throw ApiException(
          message: map['message'] ?? 'Failed to fetch dashboard data.',
        );
      }
      throw ApiException(message: 'Invalid response format from server.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardNotes() async {
    try {
      final response = await _apiClient.get('/dashboard/notes');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createDashboardNote(String content) async {
    try {
      final response = await _apiClient.post('/dashboard/notes', {'content': content});
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateDashboardNote(String noteId, {String? content, bool? isCompleted}) async {
    try {
      final response = await _apiClient.patch('/dashboard/notes/$noteId', {
        if (content != null) 'content': content,
        if (isCompleted != null) 'is_completed': isCompleted,
      });
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteDashboardNote(String noteId) async {
    try {
      final response = await _apiClient.delete('/dashboard/notes/$noteId');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
