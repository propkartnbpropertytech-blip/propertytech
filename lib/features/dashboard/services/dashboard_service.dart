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
}
