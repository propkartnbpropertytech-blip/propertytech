import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class UsersService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> getUsers({
    String? search,
    String? roleId,
    String? status,
  }) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final sessionUser = _supabase.auth.currentUser;
        if (sessionUser == null) throw Exception("Unauthenticated");

        // Fetch user profile of requester to get role name
        final requesterProfile = await _supabase
            .from('users')
            .select('*, roles(name)')
            .eq('id', sessionUser.id)
            .maybeSingle();

        final requesterRole = requesterProfile != null && requesterProfile['roles'] != null
            ? requesterProfile['roles']['name']?.toString()
            : null;

        var query = _supabase
            .from('users')
            .select('*, roles(id, name, description)')
            .isFilter('deleted_at', null);

        // Apply RBAC filters based on role
        if (requesterRole == 'Admin') {
          // Admins only see themselves and users they manage (admin_id = current user's ID)
          query = query.or('id.eq.${sessionUser.id},admin_id.eq.${sessionUser.id}');
        } else if (requesterRole == 'Sales') {
          // Sales users only see themselves
          query = query.eq('id', sessionUser.id);
        } else if (requesterRole == 'Super Admin') {
          // Super Admins see all users in organization (enforced by RLS anyway)
          if (requesterProfile != null && requesterProfile['organization_id'] != null) {
            query = query.eq('organization_id', requesterProfile['organization_id']);
          }
        }

        if (status != null && status != 'All') {
          query = query.eq('is_active', status == 'Active');
        }
        if (roleId != null && roleId.isNotEmpty) {
          query = query.eq('role_id', roleId);
        }
        if (search != null && search.isNotEmpty) {
          query = query.or('full_name.ilike.%$search%,email.ilike.%$search%,mobile.ilike.%$search%');
        }

        final response = await query.order('created_at', ascending: false);
        final list = List<Map<String, dynamic>>.from(response);

        return {
          'success': true,
          'message': 'Users fetched successfully.',
          'data': {
            'users': list,
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
  }

  Future<Map<String, dynamic>> getRoles() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase.from('roles').select('*');
        final list = List<Map<String, dynamic>>.from(response);
        return {
          'success': true,
          'message': 'Roles fetched successfully.',
          'data': {
            'roles': list,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) throw Exception('Unauthorized user.');

        // Fetch creator's profile to obtain organization_id and role
        final creatorProfile = await _supabase
            .from('users')
            .select('organization_id, roles(name)')
            .eq('id', currentUserId)
            .single();

        final creatorOrgId = creatorProfile['organization_id'];
        final creatorRole = creatorProfile['roles'] != null
            ? creatorProfile['roles']['name']?.toString()
            : null;

        // If creator is Admin, they are the parent admin of this user
        final String? adminId = creatorRole == 'Admin' ? currentUserId : userData['admin_id'];
        final String? orgId = creatorOrgId ?? userData['organization_id'];

        final response = await _supabase.rpc(
          'admin_create_user',
          params: {
            'p_email': userData['email'],
            'p_password': userData['password'],
            'p_full_name': userData['full_name'] ?? '',
            'p_role_id': userData['role_id'],
            'p_organization_id': orgId,
            'p_admin_id': adminId,
          },
        );

        if (response != null && response['success'] == true) {
          final userId = response['user']['id'];
          final joinedUser = await _supabase
              .from('users')
              .select('*, roles(id, name, description)')
              .eq('id', userId)
              .single();

          return {
            'success': true,
            'message': 'User created successfully.',
            'data': {'user': joinedUser}
          };
        }
        throw ApiException(message: response?['message'] ?? 'Failed to create user via RPC.');
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('users_email_partial_key') || errStr.contains('Key (email)')) {
          throw ApiException(message: 'A user with this email address already exists. Please use a different email.');
        }
        if (errStr.contains('users_mobile_key') || errStr.contains('Key (mobile)')) {
          throw ApiException(message: 'A sales user with this mobile number already exists.');
        }
        throw ApiException(message: errStr);
      }
    } else {
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
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> userData,
  ) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final cleanData = Map<String, dynamic>.from(userData)
          ..remove('id')
          ..remove('email')
          ..remove('role')
          ..remove('roles');

        // If password is provided, update it via RPC in auth.users
        if (cleanData.containsKey('password') && cleanData['password'] != null && cleanData['password'].toString().isNotEmpty) {
          final newPassword = cleanData['password'].toString();
          await _supabase.rpc(
            'admin_update_password',
            params: {
              'p_user_id': id,
              'p_new_password': newPassword,
            },
          );
        }
        cleanData.remove('password');

        final response = await _supabase
            .from('users')
            .update(cleanData)
            .eq('id', id)
            .select('*, roles(id, name)')
            .single();

        return {
          'success': true,
          'message': 'User updated successfully.',
          'data': {
            'user': response,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
  }

  Future<Map<String, dynamic>> toggleUserStatus(
    String id,
    bool isActive,
  ) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('users')
            .update({'is_active': isActive})
            .eq('id', id)
            .select('*, roles(id, name)')
            .single();

        return {
          'success': true,
          'message': 'User status updated successfully.',
          'data': {
            'user': response,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('users')
            .update({ 'deleted_at': DateTime.now().toIso8601String() })
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'User deleted successfully.',
          'data': response
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
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
}
