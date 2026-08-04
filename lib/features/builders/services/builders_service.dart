import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class BuildersService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> getBuilders({String? search, String? tier}) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        var query = _supabase
            .from('builders')
            .select('*')
            .isFilter('deleted_at', null);

        if (tier != null && tier != 'All') {
          query = query.eq('tier', tier);
        }
        if (search != null && search.isNotEmpty) {
          query = query.or('company_name.ilike.%$search%,contact_person.ilike.%$search%,email.ilike.%$search%');
        }

        final response = await query.order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(response);

        return {
          'success': true,
          'message': 'Builders retrieved successfully',
          'data': {
            'builders': list,
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
        if (tier != null && tier != 'All') {
          queryParameters['tier'] = tier;
        }

        final response = await _apiClient.get(
          '/builders',
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

  Future<Map<String, dynamic>> createBuilder(Map<String, dynamic> builderData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase.from('builders').insert(builderData).select().single();
        return {
          'success': true,
          'message': 'Builder created successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post('/builders', builderData);
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

  Future<Map<String, dynamic>> updateBuilder(String id, Map<String, dynamic> builderData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final cleanData = Map<String, dynamic>.from(builderData)
          ..remove('id');

        final response = await _supabase.from('builders').update(cleanData).eq('id', id).select().single();
        return {
          'success': true,
          'message': 'Builder updated successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.put('/builders/$id', builderData);
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

  Future<Map<String, dynamic>> deleteBuilder(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('builders')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'Builder deleted successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.delete('/builders/$id');
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
