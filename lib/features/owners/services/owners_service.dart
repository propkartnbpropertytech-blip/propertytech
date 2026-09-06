import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class OwnersService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getOwners({String? search}) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _apiClient.get(
        '/owners',
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

  Future<Map<String, dynamic>> createOwner(Map<String, dynamic> ownerData) async {
    try {
      final response = await _apiClient.post('/owners', ownerData);
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

  Future<Map<String, dynamic>> updateOwner(String id, Map<String, dynamic> ownerData) async {
    try {
      final response = await _apiClient.put('/owners/$id', ownerData);
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

  Future<Map<String, dynamic>> deleteOwner(String id) async {
    try {
      final response = await _apiClient.delete('/owners/$id');
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
