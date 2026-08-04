import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class RequirementsService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  Map<String, dynamic> _mapRequirementTargetAreas(Map<String, dynamic> req) {
    final areasList = List.from(req['requirement_areas'] ?? []);
    final List<String> areaIds = [];
    final List<String> areaNames = [];

    for (var item in areasList) {
      if (item is Map && item['area'] != null) {
        areaIds.add(item['area']['id'].toString());
        areaNames.add(item['area']['area_name'].toString());
      }
    }

    if (areaIds.isEmpty && req['area_id'] != null) {
      areaIds.add(req['area_id'].toString());
      if (req['area'] != null) {
        areaNames.add(req['area']['area_name'].toString());
      }
    }

    // Extract next followup date from nested followups
    final followupsList = List.from(req['followups'] ?? []);
    final pendingFollowups = followupsList
        .where((f) => f['status'] == 'pending' || f['status'] == 'scheduled' || f['status'] == 'Active' || f['status'] == null)
        .toList();
    pendingFollowups.sort((a, b) {
      if (a['followup_date'] == null) return 1;
      if (b['followup_date'] == null) return -1;
      return DateTime.parse(a['followup_date'].toString()).compareTo(DateTime.parse(b['followup_date'].toString()));
    });
    final nextFollowupDate = pendingFollowups.isNotEmpty ? pendingFollowups[0]['followup_date'] : null;

    final creatorName = req['creator'] != null ? req['creator']['full_name'] : null;
    final assigneeName = req['assignee'] != null ? req['assignee']['full_name'] : null;

    return {
      ...req,
      'areaIds': areaIds,
      'areaNames': areaNames,
      'nextFollowupDate': nextFollowupDate,
      'creatorName': creatorName,
      'assigneeName': assigneeName,
    };
  }

  Future<Map<String, dynamic>> getRequirements({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
  }) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        var query = _supabase.from('requirements').select('''
            *,
            category:property_categories(id, name),
            property_type:property_types(id, name),
            configuration:configurations(id, name),
            listing_type:listing_types(id, name),
            city:cities(id, city_name),
            area:areas(id, area_name, pincode),
            requirement_areas(area:areas(id, area_name, pincode)),
            creator:users!created_by(id, full_name),
            assignee:users!assigned_to(id, full_name),
            followups(followup_date, status),
            site_visits(id, status, visit_date),
            share_sessions(id, view_count, status)
        ''');

        // Apply filters
        query = query.isFilter('deleted_at', null);

        if (configurationId != null && configurationId.isNotEmpty) {
          query = query.eq('configuration_id', configurationId);
        }
        if (propertyTypeId != null && propertyTypeId.isNotEmpty) {
          query = query.eq('property_type_id', propertyTypeId);
        }
        if (status != null && status != 'All') {
          query = query.eq('status', status);
        }
        if (listingTypeId != null && listingTypeId.isNotEmpty) {
          query = query.eq('listing_type_id', listingTypeId);
        }

        final response = await query.order('created_at', ascending: false);
        var requirements = List<Map<String, dynamic>>.from(response);

        // Universal client search
        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          requirements = requirements.where((r) {
            final name = (r['customer_name'] ?? '').toString().toLowerCase();
            final mobile = (r['mobile'] ?? '').toString().toLowerCase();
            final remarks = (r['remarks'] ?? '').toString().toLowerCase();
            final email = (r['email'] ?? '').toString().toLowerCase();
            return name.contains(searchLower) ||
                mobile.contains(searchLower) ||
                remarks.contains(searchLower) ||
                email.contains(searchLower);
          }).toList();
        }

        final mapped = requirements.map(_mapRequirementTargetAreas).toList();

        return {
          'success': true,
          'message': 'Requirements fetched successfully.',
          'data': {
            'requirements': mapped,
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
        if (configurationId != null && configurationId.isNotEmpty) {
          queryParameters['configurationId'] = configurationId;
        }
        if (propertyTypeId != null && propertyTypeId.isNotEmpty) {
          queryParameters['propertyTypeId'] = propertyTypeId;
        }
        if (status != null && status != 'All') {
          queryParameters['status'] = status;
        }
        if (listingTypeId != null && listingTypeId.isNotEmpty) {
          queryParameters['listingTypeId'] = listingTypeId;
        }

        final response = await _apiClient.get(
          '/requirements',
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

  Future<Map<String, dynamic>> createRequirement(Map<String, dynamic> requirementData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) throw Exception('Unauthorized user.');

        final userProfile = await _supabase.from('users').select('organization_id, admin_id, roles(name)').eq('id', currentUserId).single();
        final orgId = userProfile['organization_id'];
        final adminId = userProfile['admin_id'];

        String roleName = '';
        if (userProfile['roles'] is Map) {
          roleName = userProfile['roles']['name']?.toString() ?? '';
        } else if (userProfile['roles'] is List && (userProfile['roles'] as List).isNotEmpty) {
          final firstRole = (userProfile['roles'] as List).first;
          if (firstRole is Map) {
            roleName = firstRole['name']?.toString() ?? '';
          }
        }

        final List<dynamic> areaIds = List.from(requirementData['area_ids'] ?? requirementData['areaIds'] ?? []);
        final List<dynamic> furnishingTypeIds = List.from(requirementData['furnishing_type_ids'] ?? []);
        final List<dynamic> facingTypeIds = List.from(requirementData['facing_type_ids'] ?? []);

        final cleanRequirement = Map<String, dynamic>.from(requirementData)
          ..remove('area_ids')
          ..remove('areaIds')
          ..remove('area_names')
          ..remove('areaNames')
          ..remove('furnishing_type_ids')
          ..remove('facing_type_ids');

        cleanRequirement['created_by'] = currentUserId;
        cleanRequirement['organization_id'] = orgId;
        cleanRequirement['admin_id'] = adminId;

        final isCreatorAdminOrSuperAdmin = roleName.toLowerCase() == 'admin' || roleName.toLowerCase() == 'super admin';

        if (!isCreatorAdminOrSuperAdmin) {
          if (cleanRequirement['assigned_to'] == null || cleanRequirement['assigned_to'].toString().isEmpty) {
            cleanRequirement['assigned_to'] = currentUserId;
          }
        } else {
          cleanRequirement['assigned_to'] = null;
        }
        
        // Multi-select sync helper
        if (furnishingTypeIds.isNotEmpty) {
          cleanRequirement['furnishing_type_ids'] = furnishingTypeIds;
          cleanRequirement['furnishing_type_id'] = furnishingTypeIds.first;
        }
        if (facingTypeIds.isNotEmpty) {
          cleanRequirement['facing_type_ids'] = facingTypeIds;
          cleanRequirement['facing_type_id'] = facingTypeIds.first;
        }

        // 1. Insert requirement (only returning id to begin)
        final insertRes = await _supabase.from('requirements').insert(cleanRequirement).select('id').single();
        final String requirementId = insertRes['id'];

        // 2. Insert target areas
        if (areaIds.isNotEmpty) {
          final areaData = areaIds.map((id) => {
            'requirement_id': requirementId,
            'area_id': id,
          }).toList();
          await _supabase.from('requirement_areas').insert(areaData);
        }

        // 3. Fetch the fully joined requirement to match repository expectations
        final response = await _supabase.from('requirements')
            .select('''
                *,
                category:property_categories(id, name),
                property_type:property_types(id, name),
                configuration:configurations(id, name),
                listing_type:listing_types(id, name),
                city:cities(id, city_name),
                area:areas(id, area_name, pincode),
                requirement_areas(area:areas(id, area_name, pincode)),
                creator:users!created_by(id, full_name),
                assignee:users!assigned_to(id, full_name),
                followups(followup_date, status),
                site_visits(id, status, visit_date),
                share_sessions(id, view_count, status)
            ''')
            .eq('id', requirementId)
            .single();

        final mappedResponse = _mapRequirementTargetAreas(response);

        return {
          'success': true,
          'message': 'Requirement created successfully',
          'data': {
            'requirement': mappedResponse,
          },
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post('/requirements', requirementData);
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

  Future<Map<String, dynamic>> updateRequirement(String id, Map<String, dynamic> requirementData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final List<dynamic> areaIds = List.from(requirementData['area_ids'] ?? requirementData['areaIds'] ?? []);
        final List<dynamic> furnishingTypeIds = List.from(requirementData['furnishing_type_ids'] ?? []);
        final List<dynamic> facingTypeIds = List.from(requirementData['facing_type_ids'] ?? []);

        final cleanRequirement = Map<String, dynamic>.from(requirementData)
          ..remove('area_ids')
          ..remove('areaIds')
          ..remove('area_names')
          ..remove('areaNames')
          ..remove('furnishing_type_ids')
          ..remove('facing_type_ids')
          ..remove('id')
          ..remove('created_by')
          ..remove('organization_id')
          ..remove('admin_id');

        cleanRequirement['updated_at'] = DateTime.now().toIso8601String();

        if (cleanRequirement.containsKey('assigned_to') &&
            (cleanRequirement['assigned_to'] == null || cleanRequirement['assigned_to'].toString().isEmpty)) {
          cleanRequirement['assigned_to'] = null;
        }

        if (furnishingTypeIds.isNotEmpty) {
          cleanRequirement['furnishing_type_ids'] = furnishingTypeIds;
          cleanRequirement['furnishing_type_id'] = furnishingTypeIds.first;
        }
        if (facingTypeIds.isNotEmpty) {
          cleanRequirement['facing_type_ids'] = facingTypeIds;
          cleanRequirement['facing_type_id'] = facingTypeIds.first;
        }

        // Update Areas mapping
        await _supabase.from('requirement_areas').delete().eq('requirement_id', id);
        if (areaIds.isNotEmpty) {
          final areaData = areaIds.map((aid) => {
            'requirement_id': id,
            'area_id': aid,
          }).toList();
          await _supabase.from('requirement_areas').insert(areaData);
        }

        // Update main table with full joins selected to return rich object
        final response = await _supabase.from('requirements')
            .update(cleanRequirement)
            .eq('id', id)
            .select('''
                *,
                category:property_categories(id, name),
                property_type:property_types(id, name),
                configuration:configurations(id, name),
                listing_type:listing_types(id, name),
                city:cities(id, city_name),
                area:areas(id, area_name, pincode),
                requirement_areas(area:areas(id, area_name, pincode)),
                creator:users!created_by(id, full_name),
                assignee:users!assigned_to(id, full_name),
                followups(followup_date, status),
                site_visits(id, status, visit_date),
                share_sessions(id, view_count, status)
            ''')
            .single();

        final mappedResponse = _mapRequirementTargetAreas(response);

        return {
          'success': true,
          'message': 'Requirement updated successfully',
          'data': {
            'requirement': mappedResponse,
          },
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.put('/requirements/$id', requirementData);
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

  Future<Map<String, dynamic>> deleteRequirement(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('requirements')
            .update({'deleted_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'Requirement moved to bin successfully',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.delete('/requirements/$id');
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

  Future<Map<String, dynamic>> getBinRequirements() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        var query = _supabase.from('requirements').select('''
            *,
            category:property_categories(id, name),
            property_type:property_types(id, name),
            configuration:configurations(id, name),
            listing_type:listing_types(id, name),
            city:cities(id, city_name),
            area:areas(id, area_name, pincode),
            requirement_areas(area:areas(id, area_name, pincode)),
            creator:users!created_by(id, full_name),
            assignee:users!assigned_to(id, full_name),
            followups(followup_date, status),
            site_visits(id, status, visit_date),
            share_sessions(id, view_count, status)
        ''').not('deleted_at', 'is', null).order('created_at', ascending: false);

        final response = await query;
        final list = List<Map<String, dynamic>>.from(response);
        final mapped = list.map(_mapRequirementTargetAreas).toList();

        return {
          'success': true,
          'message': 'Bin requirements retrieved successfully',
          'data': {
            'requirements': mapped,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.get(
          '/requirements',
          queryParameters: {'includeDeleted': 'true'},
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

  Future<Map<String, dynamic>> restoreRequirement(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('requirements')
            .update({'deleted_at': null, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'Requirement restored successfully',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.patch('/requirements/$id/restore', {});
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

  Future<void> permanentDeleteRequirement(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        // Cascade constraint handles requirement_areas, share_sessions, etc.
        await _supabase.from('requirements').delete().eq('id', id);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        await _apiClient.delete('/requirements/$id/permanent');
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    }
  }

  Future<void> emptyBin() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final deletedList = await _supabase.from('requirements').select('id').not('deleted_at', 'is', null);
        for (var req in deletedList) {
          final id = req['id'].toString();
          await permanentDeleteRequirement(id);
        }
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        await _apiClient.delete('/requirements/bin/empty');
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    }
  }
}
