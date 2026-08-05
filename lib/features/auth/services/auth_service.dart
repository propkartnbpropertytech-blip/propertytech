import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> login(String email, String password, {bool rememberMe = false}) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final authResponse = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final userId = authResponse.user?.id;
        if (userId == null) {
          throw ApiException(message: "Auth succeeded but no user ID returned.");
        }

        // Fetch custom user profile from public.users to get role and organization details
        final userRow = await _supabase
            .from('users')
            .select('*, roles(name), admin:users!created_by(id, full_name, email, roles(name))')
            .eq('id', userId)
            .single();

        final sessionToken = authResponse.session?.accessToken;
        return _formatProfileResponse(userRow, sessionToken);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post(
          ApiConstants.login,
          {
            'email': email,
            'password': password,
            'rememberMe': rememberMe,
          },
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

  /// [refreshToken] is required on mobile; on web omit so the HttpOnly cookie is used.
  Future<Map<String, dynamic>> refresh(String? refreshToken) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final session = _supabase.auth.currentSession;
        if (session == null) {
          throw ApiException(message: "No active Supabase session.");
        }
        
        final userId = session.user.id;
        final userRow = await _supabase
            .from('users')
            .select('*, roles(name), admin:users!created_by(id, full_name, email, roles(name))')
            .eq('id', userId)
            .single();

        return _formatProfileResponse(userRow, session.accessToken);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final body = <String, dynamic>{};
        if (refreshToken != null && refreshToken.isNotEmpty) {
          body['refreshToken'] = refreshToken;
        }
        final response = await _apiClient.post(
          ApiConstants.refresh,
          body,
        );
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        throw ApiException(message: "Invalid refresh response.");
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    }
  }

  Future<void> logout({String? refreshToken}) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
    } else {
      try {
        await _apiClient.post(
          ApiConstants.logout,
          {
            if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken': refreshToken,
          },
        );
      } catch (_) {
        // Local teardown still proceeds even if server revoke fails.
      }
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final currentUser = _supabase.auth.currentUser;
        if (currentUser == null) {
          throw ApiException(message: "User not logged in.");
        }

        final userRow = await _supabase
            .from('users')
            .select('*, roles(name), admin:users!created_by(id, full_name, email, roles(name))')
            .eq('id', currentUser.id)
            .single();

        final sessionToken = _supabase.auth.currentSession?.accessToken;
        return _formatProfileResponse(userRow, sessionToken);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.get(ApiConstants.me);
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

  Map<String, dynamic> _formatProfileResponse(Map<String, dynamic> userRow, String? sessionToken) {
    String roleName = 'Sales';
    if (userRow['roles'] is Map) {
      roleName = userRow['roles']['name']?.toString() ?? 'Sales';
    } else if (userRow['roles'] is List && (userRow['roles'] as List).isNotEmpty) {
      final firstRole = (userRow['roles'] as List).first;
      if (firstRole is Map) {
        roleName = firstRole['name']?.toString() ?? 'Sales';
      }
    }

    // Map permissions locally based on client role mapping.
    List<String> permissions = [];
    final common = [
      "users.upload_self_photo",
      "properties.read",
      "properties.create",
      "properties.update",
      "requirements.read",
      "requirements.create",
      "requirements.update",
      "owners.read",
      "owners.create",
      "owners.update",
      "clients.read",
      "clients.create",
      "clients.update",
      "search.read",
      "share.create",
      "share.read",
      "share.revoke",
      "followups.read",
      "followups.write",
      "site_visits.read",
      "site_visits.write",
      "notifications.read",
      "checklist.read",
      "checklist.write",
      "places.read",
      "dashboard.read",
      "builders.read",
      "legal.read",
      "legal.write",
    ];
    final adminExtra = [
      "users.read",
      "users.create",
      "users.update",
      "users.delete",
      "properties.delete",
      "properties.verify",
      "requirements.delete",
      "owners.delete",
      "clients.delete",
    ];
    final superExtra = [
      "users.manage_admins",
      "config.manage",
      "health.detailed",
      "lookup.manage",
      "audit.read",
    ];

    if (roleName == "Super Admin") {
      permissions = [...common, ...adminExtra, ...superExtra];
    } else if (roleName == "Admin" || roleName == "Telecaller") {
      permissions = [...common, ...adminExtra];
    } else {
      // Sales
      permissions = [
        ...common.where((p) => !["owners.delete", "clients.delete"].contains(p)),
        "properties.delete",
        "requirements.delete",
      ];
    }

    Map<String, dynamic>? adminMap;
    if (userRow['admin'] is Map) {
      adminMap = Map<String, dynamic>.from(userRow['admin'] as Map);
    } else if (userRow['admin'] is List && (userRow['admin'] as List).isNotEmpty) {
      final firstAdmin = (userRow['admin'] as List).first;
      if (firstAdmin is Map) {
        adminMap = Map<String, dynamic>.from(firstAdmin);
      }
    }

    final userMap = {
      'id': userRow['id'],
      'email': userRow['email'],
      'full_name': userRow['full_name'],
      'profile_photo': userRow['profile_photo'],
      'mobile': userRow['mobile'],
      'is_active': userRow['is_active'] ?? true,
      'admin_id': userRow['admin_id'],
      'organization_id': userRow['organization_id'],
      'created_at': userRow['created_at'],
      'role': roleName,
      'permissions': permissions,
      'admin': adminMap != null ? {
        'id': adminMap['id'],
        'full_name': adminMap['full_name'],
        'email': adminMap['email'],
        'role': adminMap['roles'] is Map 
            ? (adminMap['roles']['name']?.toString() ?? 'Admin')
            : (adminMap['roles'] is List && (adminMap['roles'] as List).isNotEmpty
                ? ((adminMap['roles'] as List).first['name']?.toString() ?? 'Admin')
                : (adminMap['role']?.toString() ?? 'Admin')),
      } : null,
    };

    return {
      'success': true,
      'message': 'Profile retrieved successfully.',
      'token': sessionToken,
      'data': {
        'user': userMap,
      }
    };
  }
}
