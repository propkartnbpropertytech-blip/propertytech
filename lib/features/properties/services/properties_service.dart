import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class PropertiesService {
  final ApiClient _apiClient = ApiClient();
  SupabaseClient get _supabase => Supabase.instance.client;

  String? _extractPropertyMediaPath(String url) {
    if (url.contains('storage/v1/object/public/property-media/')) {
      return url.split('storage/v1/object/public/property-media/').last;
    }
    return null;
  }

  static const String _propertySelect = '''
            *,
            category:property_categories(id, name),
            property_type:property_types(id, name),
            configuration:configurations(id, name),
            listing_type:listing_types(id, name),
            property_status:property_status(id, name),
            city:cities(id, city_name),
            area:areas(id, area_name, pincode),
            furnishing_type:furnishing_types(id, name),
            facing_type:facing_types(id, name),
            ownership_type:ownership_types(id, name),
            brokerage_type:brokerage_types(id, name),
            creator:users!created_by(id, full_name),
            property_images(*),
            property_videos(*),
            property_amenities(amenity:amenities(*))
        ''';

  /// Fetches a single property by id (avoids downloading the full inventory).
  Future<Map<String, dynamic>?> getPropertyById(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('properties')
            .select(_propertySelect)
            .eq('id', id)
            .maybeSingle();
        if (response == null) return null;
        return Map<String, dynamic>.from(response as Map);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.get('/properties/$id');
        if (response.data is Map<String, dynamic>) {
          final body = response.data as Map<String, dynamic>;
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            if (data['property'] is Map<String, dynamic>) {
              return data['property'] as Map<String, dynamic>;
            }
            return data;
          }
          return body;
        }
        return null;
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    }
  }

  Future<Map<String, dynamic>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
    bool? includeDeleted,
  }) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        var query = _supabase.from('properties').select(_propertySelect);

        // Include deleted or active filter
        if (includeDeleted == true) {
          query = query.not('deleted_at', 'is', null);
        } else {
          query = query.isFilter('deleted_at', null);
        }

        // Apply filters
        if (categoryId != null && categoryId.isNotEmpty) {
          query = query.eq('category_id', categoryId);
        }
        if (areaId != null && areaId.isNotEmpty) {
          query = query.eq('area_id', areaId);
        }
        if (listingTypeId != null && listingTypeId.isNotEmpty) {
          query = query.eq('listing_type_id', listingTypeId);
        }
        if (createdBy != null && createdBy.isNotEmpty) {
          query = query.eq('created_by', createdBy);
        }
        if (isVerified != null) {
          query = query.eq('is_verified', isVerified);
        }

        // Default order
        final response = await query.order('created_at', ascending: false);
        var properties = (response as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();

        // Universal client-side search (simulating universal keyword match)
        if (search != null && search.isNotEmpty) {
          final searchLower = search.toLowerCase();
          properties = properties.where((p) {
            final title = (p['title'] ?? '').toString().toLowerCase();
            final code = (p['property_code'] ?? '').toString().toLowerCase();
            final owner = (p['owner_name'] ?? '').toString().toLowerCase();
            final address = (p['address'] ?? '').toString().toLowerCase();
            final remarks = (p['remarks'] ?? '').toString().toLowerCase();
            
            return title.contains(searchLower) ||
                code.contains(searchLower) ||
                owner.contains(searchLower) ||
                address.contains(searchLower) ||
                remarks.contains(searchLower);
          }).toList();
        }

        return {
          'success': true,
          'message': 'Properties retrieved successfully',
          'data': {
            'properties': properties,
            'count': properties.length,
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
        if (categoryId != null && categoryId.isNotEmpty) {
          queryParameters['categoryId'] = categoryId;
        }
        if (areaId != null && areaId.isNotEmpty) {
          queryParameters['areaId'] = areaId;
        }
        if (listingTypeId != null && listingTypeId.isNotEmpty) {
          queryParameters['listingTypeId'] = listingTypeId;
        }
        if (createdBy != null && createdBy.isNotEmpty) {
          queryParameters['createdBy'] = createdBy;
        }
        if (isVerified != null) {
          queryParameters['isVerified'] = isVerified.toString();
        }
        if (includeDeleted != null) {
          queryParameters['includeDeleted'] = includeDeleted.toString();
        }

        final response = await _apiClient.get(
          '/properties',
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

  Future<Map<String, dynamic>> getPropertyMetadata() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final results = await Future.wait([
          _supabase.from('cities').select('*').order('city_name'),
          _supabase.from('areas').select('*').order('area_name'),
          _supabase.from('property_categories').select('*').order('name'),
          _supabase.from('property_types').select('*').order('name'),
          _supabase.from('configurations').select('*').order('name'),
          _supabase.from('listing_types').select('*').order('name'),
          _supabase.from('property_status').select('*').order('name'),
          _supabase.from('furnishing_types').select('*').order('name'),
          _supabase.from('facing_types').select('*').order('name'),
          _supabase.from('ownership_types').select('*').order('name'),
          _supabase.from('brokerage_types').select('*').order('name'),
          _supabase.from('amenities').select('*').order('name'),
        ]);

        return {
          'success': true,
          'message': 'Lookup metadata retrieved successfully',
          'data': {
            'metadata': {
              'cities': results[0],
              'areas': results[1],
              'categories': results[2],
              'types': results[3],
              'configurations': results[4],
              'listingTypes': results[5],
              'statuses': results[6],
              'furnishings': results[7],
              'facings': results[8],
              'ownerships': results[9],
              'brokerages': results[10],
              'amenities': results[11],
            }
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.get('/properties/metadata');
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

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> propertyData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) throw Exception('Unauthorized user.');

        // Get user profile details for tenant/org context
        final userProfile = await _supabase.from('users').select('organization_id, admin_id').eq('id', currentUserId).single();
        final orgId = userProfile['organization_id'];
        final adminId = userProfile['admin_id'];

        // Generate property_code: PR-XXXX
        int nextNumber = 1001;
        final latestCodeRes = await _supabase
            .from('properties')
            .select('property_code')
            .like('property_code', 'PR-%')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (latestCodeRes != null && latestCodeRes['property_code'] != null) {
          final codeStr = latestCodeRes['property_code'] as String;
          final match = RegExp(r'\d+').firstMatch(codeStr);
          if (match != null) {
            nextNumber = int.parse(match.group(0)!) + 1;
          }
        }
        final String propertyCode = 'PR-$nextNumber';

        // Extract child records from input payload
        final List<dynamic> amenities = List.from(propertyData['amenities'] ?? []);
        final List<dynamic> images = List.from(propertyData['images'] ?? []);
        final List<dynamic> videos = List.from(propertyData['videos'] ?? []);

        // Prepare property row - keep only valid database columns
        final List<String> validColumns = [
          'title',
          'description',
          'category_id',
          'property_type_id',
          'configuration_id',
          'listing_type_id',
          'property_status_id',
          'city_id',
          'area_id',
          'address',
          'landmark',
          'latitude',
          'longitude',
          'super_builtup_area',
          'carpet_area',
          'plot_area',
          'price',
          'deposit',
          'maintenance',
          'furnishing_type_id',
          'facing_type_id',
          'ownership_type_id',
          'bedrooms',
          'bathrooms',
          'balconies',
          'parking',
          'floor_no',
          'total_floor',
          'age_of_property',
          'possession_date',
          'owner_name',
          'owner_mobile',
          'broker_name',
          'remarks',
          'block_wing',
          'flat_no',
          'google_place_id',
          'brokerage_type_id',
          'admin_id',
          'organization_id',
          'additional_details',
          'is_verified',
        ];

        final cleanProperty = <String, dynamic>{};
        propertyData.forEach((key, value) {
          if (validColumns.contains(key)) {
            cleanProperty[key] = value;
          }
        });

        cleanProperty['property_code'] = propertyCode;
        cleanProperty['created_by'] = currentUserId;
        cleanProperty['organization_id'] = orgId;
        cleanProperty['admin_id'] = adminId;
        cleanProperty['is_verified'] = false;

        // Insert Property
        final insertedProperty = await _supabase.from('properties').insert(cleanProperty).select().single();
        final String propertyId = insertedProperty['id'];

        // Insert Amenities
        if (amenities.isNotEmpty) {
          final amData = amenities.map((id) => {
            'property_id': propertyId,
            'amenity_id': id,
          }).toList();
          await _supabase.from('property_amenities').insert(amData);
        }

        // Insert Images
        if (images.isNotEmpty) {
          final imgData = images.asMap().entries.map((entry) {
            final idx = entry.key;
            final img = entry.value;
            final String url = (img is Map) ? (img['imageUrl'] ?? '') : img.toString();
            final bool cover = (img is Map) ? (img['isCover'] ?? false) : (idx == 0);
            return {
              'property_id': propertyId,
              'image_url': url,
              'image_order': idx,
              'is_cover': cover,
            };
          }).toList();
          await _supabase.from('property_images').insert(imgData);
        }

        // Insert Videos
        if (videos.isNotEmpty) {
          final vidData = videos.asMap().entries.map((entry) {
            final idx = entry.key;
            final vid = entry.value;
            final String url = (vid is Map) ? (vid['videoUrl'] ?? '') : vid.toString();
            return {
              'property_id': propertyId,
              'video_url': url,
              'video_order': idx,
            };
          }).toList();
          await _supabase.from('property_videos').insert(vidData);
        }

        // Fetch fully populated property details to match backend structure
        final populatedProperty = await _supabase.from('properties').select('''
          *,
          category:property_categories(id, name),
          property_type:property_types(id, name),
          configuration:configurations(id, name),
          listing_type:listing_types(id, name),
          property_status:property_status(id, name),
          city:cities(id, city_name),
          area:areas(id, area_name, pincode),
          furnishing_type:furnishing_types(id, name),
          facing_type:facing_types(id, name),
          ownership_type:ownership_types(id, name),
          brokerage_type:brokerage_types(id, name),
          property_images(*),
          property_videos(*),
          property_amenities(amenity:amenities(*)),
          creator:users!created_by(id, full_name, mobile, email),
          assignee:users!assigned_to(id, full_name, mobile, email)
        ''').eq('id', propertyId).single();

        return {
          'success': true,
          'message': 'Property created successfully',
          'data': {
            'property': populatedProperty,
          },
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post('/properties', propertyData);
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

  Future<Map<String, dynamic>> updateProperty(String id, Map<String, dynamic> propertyData) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        // Extract child lists
        final List<dynamic> amenities = List.from(propertyData['amenities'] ?? []);
        final List<dynamic> images = List.from(propertyData['images'] ?? []);
        final List<dynamic> videos = List.from(propertyData['videos'] ?? []);

        // Prepare property row updates - keep only valid database columns
        final List<String> validColumns = [
          'title',
          'description',
          'category_id',
          'property_type_id',
          'configuration_id',
          'listing_type_id',
          'property_status_id',
          'city_id',
          'area_id',
          'address',
          'landmark',
          'latitude',
          'longitude',
          'super_builtup_area',
          'carpet_area',
          'plot_area',
          'price',
          'deposit',
          'maintenance',
          'furnishing_type_id',
          'facing_type_id',
          'ownership_type_id',
          'bedrooms',
          'bathrooms',
          'balconies',
          'parking',
          'floor_no',
          'total_floor',
          'age_of_property',
          'possession_date',
          'owner_name',
          'owner_mobile',
          'broker_name',
          'remarks',
          'block_wing',
          'flat_no',
          'google_place_id',
          'brokerage_type_id',
          'additional_details',
          'is_verified',
        ];

        final cleanProperty = <String, dynamic>{};
        propertyData.forEach((key, value) {
          if (validColumns.contains(key)) {
            cleanProperty[key] = value;
          }
        });
        
        cleanProperty['updated_at'] = DateTime.now().toIso8601String();

        // 1. Update Property details
        final updatedProperty = await _supabase.from('properties').update(cleanProperty).eq('id', id).select().single();

        // 2. Update Amenities
        await _supabase.from('property_amenities').delete().eq('property_id', id);
        if (amenities.isNotEmpty) {
          final amData = amenities.map((amenityId) => {
            'property_id': id,
            'amenity_id': amenityId,
          }).toList();
          await _supabase.from('property_amenities').insert(amData);
        }

        // 3. Update Images (Delete orphans from storage and database)
        final existingImages = await _supabase.from('property_images').select('image_url').eq('property_id', id);
        final incomingImageUrls = Set<String>.from(images.map((img) => (img is Map) ? (img['imageUrl'] ?? '') : img.toString()));
        final orphanImagePaths = existingImages
            .map((img) => img['image_url'].toString())
            .where((url) => !incomingImageUrls.contains(url))
            .map((url) => _extractPropertyMediaPath(url))
            .where((path) => path != null)
            .cast<String>()
            .toList();

        if (orphanImagePaths.isNotEmpty) {
          await _supabase.storage.from('property-media').remove(orphanImagePaths);
        }

        await _supabase.from('property_images').delete().eq('property_id', id);
        if (images.isNotEmpty) {
          final imgData = images.asMap().entries.map((entry) {
            final idx = entry.key;
            final img = entry.value;
            final String url = (img is Map) ? (img['imageUrl'] ?? '') : img.toString();
            final bool cover = (img is Map) ? (img['isCover'] ?? false) : (idx == 0);
            return {
              'property_id': id,
              'image_url': url,
              'image_order': idx,
              'is_cover': cover,
            };
          }).toList();
          await _supabase.from('property_images').insert(imgData);
        }

        // 4. Update Videos (Delete orphans from storage and database)
        final existingVideos = await _supabase.from('property_videos').select('video_url').eq('property_id', id);
        final incomingVidUrls = Set<String>.from(videos.map((vid) => (vid is Map) ? (vid['videoUrl'] ?? '') : vid.toString()));
        final orphanVidPaths = existingVideos
            .map((vid) => vid['video_url'].toString())
            .where((url) => !incomingVidUrls.contains(url))
            .map((url) => _extractPropertyMediaPath(url))
            .where((path) => path != null)
            .cast<String>()
            .toList();

        if (orphanVidPaths.isNotEmpty) {
          await _supabase.storage.from('property-media').remove(orphanVidPaths);
        }

        await _supabase.from('property_videos').delete().eq('property_id', id);
        if (videos.isNotEmpty) {
          final vidData = videos.asMap().entries.map((entry) {
            final idx = entry.key;
            final vid = entry.value;
            final String url = (vid is Map) ? (vid['videoUrl'] ?? '') : vid.toString();
            return {
              'property_id': id,
              'video_url': url,
              'video_order': idx,
            };
          }).toList();
          await _supabase.from('property_videos').insert(vidData);
        }

        // Fetch fully populated property details to match backend structure
        final populatedProperty = await _supabase.from('properties').select('''
          *,
          category:property_categories(id, name),
          property_type:property_types(id, name),
          configuration:configurations(id, name),
          listing_type:listing_types(id, name),
          property_status:property_status(id, name),
          city:cities(id, city_name),
          area:areas(id, area_name, pincode),
          furnishing_type:furnishing_types(id, name),
          facing_type:facing_types(id, name),
          ownership_type:ownership_types(id, name),
          brokerage_type:brokerage_types(id, name),
          property_images(*),
          property_videos(*),
          property_amenities(amenity:amenities(*)),
          creator:users!created_by(id, full_name, mobile, email),
          assignee:users!assigned_to(id, full_name, mobile, email)
        ''').eq('id', id).single();

        return {
          'success': true,
          'message': 'Property updated successfully',
          'data': {
            'property': populatedProperty,
          },
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.put('/properties/$id', propertyData);
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

  Future<Map<String, dynamic>> togglePropertyVerification(String id, bool isVerified) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase
            .from('properties')
            .update({'is_verified': isVerified, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', id)
            .select()
            .single();

        return {
          'success': true,
          'message': 'Property verification updated successfully',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.patch(
          '/properties/$id/verify',
          {'isVerified': isVerified},
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

  Future<Map<String, dynamic>> softDeleteProperty(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase.rpc(
          'move_property_to_bin',
          params: {'p_property_id': id},
        );

        return {
          'success': true,
          'message': 'Property moved to bin successfully',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.delete('/properties/$id');
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

  Future<Map<String, dynamic>> restoreProperty(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase.rpc(
          'restore_property_from_bin',
          params: {'p_property_id': id},
        );

        return {
          'success': true,
          'message': 'Property restored successfully',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.patch('/properties/$id/restore', {});
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

  Future<Map<String, dynamic>> createCity(String name) async {
    try {
      final response = await _apiClient.post('/properties/cities', {'city_name': name});
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

  Future<Map<String, dynamic>> createArea(String cityId, String name, String pincode) async {
    try {
      final response = await _apiClient.post('/properties/areas', {
        'city_id': cityId,
        'area_name': name,
        'pincode': pincode,
      });
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

  Future<Map<String, dynamic>> createAmenity(String name) async {
    try {
      final response = await _apiClient.post('/properties/amenities', {
        'name': name,
      });
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

  Future<Map<String, dynamic>> createLookup(String masterType, Map<String, dynamic> payload) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase.from(masterType).insert(payload).select().single();
        return {
          'success': true,
          'message': '$masterType lookup item created successfully',
          'data': response,
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post('/lookup/$masterType', payload);
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

  Future<Map<String, dynamic>> checkDuplicate(Map<String, dynamic> checkParams) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final flatNo = checkParams['flat_no'];
        final blockWing = checkParams['block_wing'];
        final areaId = checkParams['area_id'];
        final currentId = checkParams['id'];

        var query = _supabase
            .from('properties')
            .select('id')
            .eq('flat_no', flatNo)
            .eq('block_wing', blockWing)
            .eq('area_id', areaId)
            .isFilter('deleted_at', null);

        if (currentId != null) {
          query = query.neq('id', currentId);
        }

        final response = await query;
        final list = List.from(response);

        return {
          'success': true,
          'data': {
            'isDuplicate': list.isNotEmpty,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.post('/properties/check-duplicate', checkParams);
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

  Future<void> deleteCity(String id) async {
    try {
      await _apiClient.delete('/properties/cities/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> deleteArea(String id) async {
    try {
      await _apiClient.delete('/properties/areas/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateCity(String id, String name, {String state = "Gujarat", String country = "India"}) async {
    try {
      final response = await _apiClient.put('/properties/cities/$id', {
        'city_name': name,
        'state': state,
        'country': country,
      });
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

  Future<Map<String, dynamic>> updateArea(String id, String cityId, String name, String pincode) async {
    try {
      final response = await _apiClient.put('/properties/areas/$id', {
        'city_id': cityId,
        'area_name': name,
        'pincode': pincode,
      });
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

  Future<Map<String, dynamic>> getBinProperties() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        final response = await _supabase.from('deleted_properties').select('''
            *,
            category:property_categories(id, name),
            property_type:property_types(id, name),
            configuration:configurations(id, name),
            listing_type:listing_types(id, name),
            property_status:property_status(id, name),
            city:cities(id, city_name),
            area:areas(id, area_name, pincode),
            furnishing_type:furnishing_types(id, name),
            facing_type:facing_types(id, name),
            ownership_type:ownership_types(id, name),
            brokerage_type:brokerage_types(id, name),
            creator:users!created_by(id, full_name),
            property_images:deleted_property_images(*),
            property_videos:deleted_property_videos(*),
            property_amenities:deleted_property_amenities(amenity:amenities(*))
        ''').order('created_at', ascending: false);

        final properties = (response as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();

        return {
          'success': true,
          'message': 'Bin properties retrieved successfully',
          'data': {
            'properties': properties,
            'count': properties.length,
          }
        };
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        final response = await _apiClient.get(
          '/properties',
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

  Future<void> permanentDeleteProperty(String id) async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        // Fetch media URLs from deleted shadow tables to delete files from Storage bucket
        final images = await _supabase.from('deleted_property_images').select('image_url').eq('property_id', id);
        final imagePaths = images
            .map((img) => _extractPropertyMediaPath(img['image_url'].toString()))
            .where((path) => path != null)
            .cast<String>()
            .toList();

        final videos = await _supabase.from('deleted_property_videos').select('video_url').eq('property_id', id);
        final videoPaths = videos
            .map((vid) => _extractPropertyMediaPath(vid['video_url'].toString()))
            .where((path) => path != null)
            .cast<String>()
            .toList();

        // Remove media files
        if (imagePaths.isNotEmpty) await _supabase.storage.from('property-media').remove(imagePaths);
        if (videoPaths.isNotEmpty) await _supabase.storage.from('property-media').remove(videoPaths);

        // Delete from DB using secure RPC function
        await _supabase.rpc('permanent_delete_property_from_bin', params: {'p_property_id': id});
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        await _apiClient.delete('/properties/$id/permanent');
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
        // Fetch all deleted properties from deleted_properties table
        final deletedProps = await _supabase.from('deleted_properties').select('id');
        for (var prop in deletedProps) {
          final id = prop['id'].toString();
          await permanentDeleteProperty(id);
        }
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    } else {
      try {
        await _apiClient.delete('/properties/bin/empty');
      } on DioException catch (e) {
        throw ApiException.fromDioException(e);
      } catch (e) {
        throw ApiException(message: e.toString());
      }
    }
  }
}
