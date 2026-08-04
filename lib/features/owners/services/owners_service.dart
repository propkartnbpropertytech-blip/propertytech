import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class OwnersService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> getOwners({String? search}) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        var query = _supabase
            .from('owners')
            .select('*')
            .isFilter('deleted_at', null);

        if (search != null && search.isNotEmpty) {
          query = query.or('name.ilike.%$search%,mobile.ilike.%$search%,email.ilike.%$search%');
        }

        final response = await query.order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(response);

        return {
          'success': true,
          'message': 'Owners fetched successfully.',
          'data': {
            'owners': list,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
  }

  Future<Map<String, dynamic>> createOwner(Map<String, dynamic> ownerData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) throw Exception('Unauthorized user.');

        final userProfile = await _supabase.from('users').select('organization_id, admin_id').eq('id', currentUserId).single();
        final orgId = userProfile['organization_id'];
        final adminId = userProfile['admin_id'];

        final cleanData = Map<String, dynamic>.from(ownerData);
        cleanData['created_by'] = currentUserId;
        cleanData['organization_id'] = orgId;
        cleanData['admin_id'] = adminId;

        final response = await _supabase.from('owners').insert(cleanData).select().single();

        return {
          'success': true,
          'message': 'Owner created successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
  }

  Future<Map<String, dynamic>> updateOwner(String id, Map<String, dynamic> ownerData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final cleanData = Map<String, dynamic>.from(ownerData)
          ..remove('id')
          ..remove('created_by')
          ..remove('organization_id')
          ..remove('admin_id');

        final response = await _supabase.from('owners').update(cleanData).eq('id', id).select().single();

        return {
          'success': true,
          'message': 'Owner updated successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
  }

  Future<Map<String, dynamic>> deleteOwner(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('owners')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'Owner deleted successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
}
