import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class ClientsService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> getClients({String? search, String? stage, String? source}) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        var query = _supabase
            .from('clients')
            .select('*')
            .isFilter('deleted_at', null);

        if (stage != null && stage != 'All') {
          query = query.eq('stage', stage);
        }
        if (source != null && source != 'All') {
          query = query.eq('source', source);
        }
        if (search != null && search.isNotEmpty) {
          query = query.or('name.ilike.%$search%,mobile.ilike.%$search%,email.ilike.%$search%');
        }

        final response = await query.order('created_at', ascending: false);
        final list = (response as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();

        return {
          'success': true,
          'message': 'Clients fetched successfully.',
          'data': {
            'clients': list,
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
        if (stage != null && stage != 'All') {
          queryParameters['stage'] = stage;
        }
        if (source != null && source != 'All') {
          queryParameters['source'] = source;
        }

        final response = await _apiClient.get(
          '/clients',
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

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> clientData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) throw Exception('Unauthorized user.');

        final userProfile = await _supabase.from('users').select('organization_id, admin_id').eq('id', currentUserId).single();
        final orgId = userProfile['organization_id'];
        final adminId = userProfile['admin_id'];

        final cleanData = Map<String, dynamic>.from(clientData);
        cleanData['created_by'] = currentUserId;
        cleanData['organization_id'] = orgId;
        cleanData['admin_id'] = adminId;

        final response = await _supabase.from('clients').insert(cleanData).select().single();

        return {
          'success': true,
          'message': 'Client created successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post('/clients', clientData);
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

  Future<Map<String, dynamic>> updateClient(String id, Map<String, dynamic> clientData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final cleanData = Map<String, dynamic>.from(clientData)
          ..remove('id')
          ..remove('created_by')
          ..remove('organization_id')
          ..remove('admin_id');

        final response = await _supabase.from('clients').update(cleanData).eq('id', id).select().single();

        return {
          'success': true,
          'message': 'Client updated successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.put('/clients/$id', clientData);
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

  Future<Map<String, dynamic>> deleteClient(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('clients')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'Client deleted successfully.',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.delete('/clients/$id');
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
