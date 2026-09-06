import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class UsersService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? roleId,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (roleId != null && roleId.isNotEmpty) {
        queryParameters['roleId'] = roleId;
      }
      if (status != null && status != 'All') {
        queryParameters['status'] = status;
      }

      final response = await _apiClient.get(
        '/users',
        queryParameters: queryParameters,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getRoles() async {
    try {
      final response = await _apiClient.get('/users/roles');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post('/users', userData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _apiClient.put('/users/$id', userData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(
    String id,
    bool isActive,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/users/$id/status',
        {'isActive': isActive},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final response = await _apiClient.delete('/users/$id');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
