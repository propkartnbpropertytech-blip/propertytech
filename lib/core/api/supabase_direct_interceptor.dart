import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_constants.dart';

class SupabaseDirectInterceptor extends Interceptor {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!ApiConstants.useSupabaseDirect) {
      return super.onRequest(options, handler);
    }

    final path = options.path;
    final method = options.method.toUpperCase();

    try {
      // 1. App Config Endpoint
      if (path.startsWith('/config')) {
        final data = await _supabase.from('app_config').select('*').limit(1).maybeSingle();
        final config = data ?? {
          'maintenance_mode': false,
          'maintenance_message': '',
          'android_link': 'comingsoon',
          'ios_link': 'comingsoon',
          'min_version': '1.0.0',
          'max_version': '1.0.0',
          'latest_terms_version': 1,
          'latest_privacy_version': 1,
          'enable_ai': true,
          'enable_whatsapp': true,
          'enable_notifications': true,
          'release_notes': 'Supabase Direct Mode',
          'versionStatus': 'latest',
        };
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': config},
          statusCode: 200,
        ));
      }

      // 2. Legal Acceptance Endpoints
      if (path.startsWith('/legal/acceptance/')) {
        final userId = path.split('/').last;
        final data = await _supabase.from('legal_acceptances').select('*').eq('user_id', userId).limit(1).maybeSingle();
        final payload = data ?? {
          'accepted_terms_version': 0,
          'accepted_privacy_version': 0,
        };
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': payload},
          statusCode: 200,
        ));
      }

      if (path == '/legal/acceptance' && method == 'POST') {
        final payload = options.data as Map<String, dynamic>;
        final data = await _supabase.from('legal_acceptances').upsert({
          'user_id': payload['userId'],
          'accepted_terms_version': payload['acceptedTermsVersion'],
          'accepted_privacy_version': payload['acceptedPrivacyVersion'],
          'client_version': payload['clientVersion'],
          'accepted_at': DateTime.now().toIso8601String(),
        }).select().single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': data},
          statusCode: 200,
        ));
      }

      // 2b. Dashboard Summary & Lists
      if (path == '/dashboard' && method == 'GET') {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) throw Exception("Unauthenticated");

        Future<List<Map<String, dynamic>>> safeList(
          Future<dynamic> Function() query, {
          required String label,
        }) async {
          try {
            final data = await query();
            return (data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Dashboard $label query failed: $e');
            }
            return <Map<String, dynamic>>[];
          }
        }

        const availableStatusFilter =
            'property_status_id.eq.09521e45-e731-4517-8129-1866f0991ee8,property_status_id.eq.05a73434-e99b-425b-99b2-1825d529ac35';
        const soldStatusId = '33fa8cf3-910d-4f0b-9142-8862974311ab';
        const rentedStatusId = '7c1d9611-8cad-4058-a9fa-3d68b8adb6f6';
        const rentalListingId = '1c1ccfc1-d318-4b66-9a43-c551532d1802';
        const resaleListingId = '9050cd9b-0ebf-41f2-a925-2d4f206b64b1';

        final totalProperties = (await safeList(
          () => _supabase.from('properties').select('id'),
          label: 'totalProperties',
        )).length;
        final available = (await safeList(
          () => _supabase.from('properties').select('id').or(availableStatusFilter),
          label: 'available',
        )).length;
        final sold = (await safeList(
          () => _supabase.from('properties').select('id').eq('property_status_id', soldStatusId),
          label: 'sold',
        )).length;
        final rented = (await safeList(
          () => _supabase.from('properties').select('id').eq('property_status_id', rentedStatusId),
          label: 'rented',
        )).length;
        final requirements =
            (await safeList(() => _supabase.from('requirements').select('id'), label: 'requirements')).length;
        final users = (await safeList(() => _supabase.from('users').select('id'), label: 'users')).length;

        final rentalAvailable = (await safeList(
          () => _supabase
              .from('properties')
              .select('id')
              .or(availableStatusFilter)
              .eq('listing_type_id', rentalListingId),
          label: 'rentalAvailable',
        )).length;
        final resaleAvailable = (await safeList(
          () => _supabase
              .from('properties')
              .select('id')
              .or(availableStatusFilter)
              .eq('listing_type_id', resaleListingId),
          label: 'resaleAvailable',
        )).length;
        final rentalRented = (await safeList(
          () => _supabase
              .from('properties')
              .select('id')
              .eq('property_status_id', rentedStatusId)
              .eq('listing_type_id', rentalListingId),
          label: 'rentalRented',
        )).length;
        final resaleSold = (await safeList(
          () => _supabase
              .from('properties')
              .select('id')
              .eq('property_status_id', soldStatusId)
              .eq('listing_type_id', resaleListingId),
          label: 'resaleSold',
        )).length;
        final rentalRequirements = (await safeList(
          () => _supabase.from('requirements').select('id').eq('listing_type_id', rentalListingId),
          label: 'rentalRequirements',
        )).length;
        final resaleRequirements = (await safeList(
          () => _supabase.from('requirements').select('id').eq('listing_type_id', resaleListingId),
          label: 'resaleRequirements',
        )).length;
        final rentalWonRequirements = (await safeList(
          () => _supabase
              .from('requirements')
              .select('id')
              .eq('status', 'Won')
              .eq('listing_type_id', rentalListingId),
          label: 'rentalWonRequirements',
        )).length;
        final resaleWonRequirements = (await safeList(
          () => _supabase
              .from('requirements')
              .select('id')
              .eq('status', 'Won')
              .eq('listing_type_id', resaleListingId),
          label: 'resaleWonRequirements',
        )).length;

        final recentPropertiesData = await safeList(
          () => _supabase.from('properties').select('''
            id, property_code, title, price, created_at, area_id,
            property_status(name),
            area:areas(area_name),
            listing_type:listing_types(name),
            creator:users!created_by(full_name)
          ''').order('created_at', ascending: false).limit(5),
          label: 'recentProperties',
        );
        final recentProperties = recentPropertiesData.map((p) => {
          'id': p['id'],
          'code': p['property_code'],
          'title': p['title'],
          'area': p['area_id'],
          'price': (p['price'] as num?)?.toDouble() ?? 0.0,
          'status': p['property_status'] is Map ? (p['property_status']['name'] ?? 'N/A') : 'N/A',
          'areaName': p['area'] is Map ? (p['area']['area_name'] ?? 'N/A') : 'N/A',
          'listingType': p['listing_type'] is Map ? (p['listing_type']['name'] ?? 'Sale') : 'Sale',
          'createdBy': p['creator'] is Map ? (p['creator']['full_name'] ?? 'System') : 'System',
          'createdAt': p['created_at'],
        }).toList();

        final checklist = await safeList(
          () => _supabase
              .from('checklist')
              .select('*')
              .eq('user_id', userId)
              .order('due_date', ascending: true)
              .limit(10),
          label: 'checklist',
        );

        final followupsData = await safeList(
          () => _supabase.from('followups').select('''
            id, client_name, mobile, followup_date, notes, status, requirement_id,
            property:properties(property_code, title),
            requirement:requirements(id, customer_name),
            creator:users!created_by(full_name)
          ''').limit(10),
          label: 'followups',
        );
        final followups = followupsData.map((f) => {
          'id': f['id'],
          'client_name': f['client_name'],
          'mobile': f['mobile'],
          'followup_date': f['followup_date'],
          'notes': f['notes'],
          'status': f['status'],
          'property': f['property'],
          'requirement': f['requirement'],
          'creator': f['creator'],
        }).toList();

        // site_visits.scheduled_by -> users (not created_by)
        final siteVisitsData = await safeList(
          () => _supabase.from('site_visits').select('''
            id, visit_date, remarks, status, requirement_id,
            property:properties(property_code, title),
            requirement:requirements(id, customer_name),
            creator:users!scheduled_by(full_name)
          ''').limit(10),
          label: 'siteVisits',
        );
        final siteVisits = siteVisitsData.map((s) => {
          'id': s['id'],
          'visit_date': s['visit_date'],
          'remarks': s['remarks'],
          'status': s['status'],
          'property': s['property'],
          'requirement': s['requirement'],
          'creator': s['creator'],
        }).toList();

        // audit_logs uses description/module (not details JSON)
        final activityData = await safeList(
          () => _supabase.from('audit_logs').select('''
            id, action, description, module, created_at,
            user:users!user_id(full_name)
          ''').order('created_at', ascending: false).limit(10),
          label: 'activity',
        );
        final activity = activityData.map((a) => {
          'id': a['id'],
          'module': a['module'] ?? a['action']?.toString().split('_').first ?? 'System',
          'action': a['action'] ?? 'LOG',
          'description': a['description']?.toString() ?? '',
          'timestamp': a['created_at'],
          'user': a['user'] is Map ? (a['user']['full_name'] ?? 'System') : 'System',
        }).toList();

        final summary = {
          'totalProperties': totalProperties,
          'available': available,
          'sold': sold,
          'rented': rented,
          'requirements': requirements,
          'users': users,
          'rentalAvailable': rentalAvailable,
          'resaleAvailable': resaleAvailable,
          'rentalRented': rentalRented,
          'resaleSold': resaleSold,
          'rentalRequirements': rentalRequirements,
          'resaleRequirements': resaleRequirements,
          'rentalWonRequirements': rentalWonRequirements,
          'resaleWonRequirements': resaleWonRequirements,
          'trends': {
            'totalProperties': 0.0,
            'available': 0.0,
            'sold': 0.0,
            'rented': 0.0,
            'requirements': 0.0,
          },
          'performance': {
            'topBroker': 'N/A',
            'topArea': 'N/A',
            'topProperty': 'N/A',
            'monthlyGrowth': '0.0%',
          }
        };

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'summary': summary,
              'activity': activity,
              'recentProperties': recentProperties,
              'checklist': checklist,
              'followups': followups,
              'siteVisits': siteVisits,
            }
          },
          statusCode: 200,
        ));
      }

      // 3. Sync Status
      if (path.startsWith('/sync/status')) {
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'schemaVersion': 1},
          statusCode: 200,
        ));
      }

      // Notifications Interceptors
      if (path.startsWith('/notifications') && method == 'GET') {
        final sessionUser = _supabase.auth.currentUser;
        if (sessionUser == null) {
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401, data: {'success': false, 'message': 'Unauthorized'}),
          ));
        }
        final page = int.tryParse(options.queryParameters['page']?.toString() ?? '1') ?? 1;
        final limit = int.tryParse(options.queryParameters['limit']?.toString() ?? '5') ?? 5;
        final offset = (page - 1) * limit;

        final countRes = await _supabase
            .from('notifications')
            .select('id')
            .eq('user_id', sessionUser.id);
        final totalItems = countRes.length;
        final totalPages = (totalItems / limit).ceil();

        final notificationsList = await _supabase.from('notifications')
            .select('*')
            .eq('user_id', sessionUser.id)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'notifications': notificationsList,
              'pagination': {
                'page': page,
                'limit': limit,
                'totalItems': totalItems,
                'totalPages': totalPages,
              }
            }
          },
          statusCode: 200,
        ));
      }

      if (path.startsWith('/notifications/') && path.endsWith('/read') && method == 'PATCH') {
        final parts = path.split('/');
        final id = parts[parts.length - 2];
        final updated = await _supabase.from('notifications').update({'is_read': true}).eq('id', id).select().single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': updated},
          statusCode: 200,
        ));
      }

      if (path == '/notifications/read-all' && method == 'PATCH') {
        final sessionUser = _supabase.auth.currentUser;
        if (sessionUser == null) {
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401, data: {'success': false, 'message': 'Unauthorized'}),
          ));
        }
        await _supabase.from('notifications').update({'is_read': true}).eq('user_id', sessionUser.id);
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'message': 'All notifications marked as read'},
          statusCode: 200,
        ));
      }

      if (path.startsWith('/notifications/') && method == 'DELETE') {
        final id = path.split('/').last;
        await _supabase.from('notifications').delete().eq('id', id);
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'message': 'Notification deleted'},
          statusCode: 200,
        ));
      }

      // 4. Properties Detail Retrieval
      if (path.startsWith('/properties/')) {
        final id = path.split('/').last;
        final data = await _supabase.from('properties').select('''
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
        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {'property': data}
          },
          statusCode: 200,
        ));
      }

      // 5. Requirements Detail Retrieval
      if (path.startsWith('/requirements/')) {
        final id = path.split('/').last;
        final data = await _supabase.from('requirements').select('''
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
          followups(id, followup_date, status, notes, created_at),
          site_visits(id, status, visit_date, remarks, created_at),
          share_sessions(id, view_count, status, created_at)
        ''').eq('id', id).single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {'requirement': data}
          },
          statusCode: 200,
        ));
      }

      // 6. Checklist Items CRUD
      if (path.startsWith('/checklist')) {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) throw Exception("Unauthenticated");

        if (method == 'GET') {
          final data = await _supabase
              .from('checklist')
              .select('*')
              .eq('user_id', userId)
              .order('created_at', ascending: true);
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }

        if (method == 'POST') {
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('checklist').insert({
            'title': payload['title'],
            'is_completed': false,
            'user_id': userId,
          }).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }

        if (path.contains('/toggle') && method == 'PATCH') {
          final id = path.split('/')[2];
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('checklist').update({
            'is_completed': payload['is_completed'],
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }

        if (method == 'DELETE') {
          final id = path.split('/').last;
          await _supabase.from('checklist').delete().eq('id', id);
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'message': 'Deleted successfully'},
            statusCode: 200,
          ));
        }
      }

      // 7. Site Visits CRUD
      if (path.startsWith('/site-visits')) {
        if (method == 'POST') {
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('site_visits').insert(payload).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }

        if (path.contains('/status') && method == 'PATCH') {
          final id = path.split('/')[2];
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('site_visits').update({
            'status': payload['status'],
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }
      }

      // 8. Followups CRUD
      if (path.startsWith('/followups')) {
        if (method == 'POST') {
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('followups').insert(payload).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }

        if (path.contains('/status') && method == 'PATCH') {
          final id = path.split('/')[2];
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('followups').update({
            'status': payload['status'],
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }

        if (method == 'PATCH') {
          final id = path.split('/').last;
          final payload = options.data as Map<String, dynamic>;
          final data = await _supabase.from('followups').update({
            ...payload,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', id).select().single();
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'data': data},
            statusCode: 200,
          ));
        }
      }

      // 9. Share Sessions
      if (path == '/share-sessions' && method == 'POST') {
        final sessionUser = _supabase.auth.currentUser;
        if (sessionUser == null) {
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401, data: {'success': false, 'message': 'Unauthorized'}),
          ));
        }

        final payload = options.data as Map<String, dynamic>;
        final reqId = payload['requirement_id'];
        final List<dynamic> propertyIds = payload['property_ids'] ?? [];
        final expiryDays = int.tryParse(payload['expiry_days']?.toString() ?? '7') ?? 7;

        final newSession = {
          'requirement_id': reqId,
          'property_ids': propertyIds,
          'shared_by': sessionUser.id,
          'status': 'Active',
          'total_properties': propertyIds.length,
          'view_count': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(Duration(days: expiryDays)).toIso8601String(),
        };

        final response = await _supabase.from('share_sessions').insert(newSession).select().single();

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'message': 'Share session created successfully',
            'data': {
              'session': response
            }
          },
          statusCode: 200,
        ));
      }

      if (path.startsWith('/share-sessions/requirement/')) {
        final reqId = path.split('/').last;
        final data = await _supabase.from('share_sessions').select('*').eq('requirement_id', reqId).order('created_at', ascending: false);
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': {'history': data}},
          statusCode: 200,
        ));
      }

      if (path.contains('/revoke') && method == 'POST') {
        final sessionId = path.split('/')[2];
        final data = await _supabase.from('share_sessions').update({
          'status': 'Revoked',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', sessionId).select().single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': data},
          statusCode: 200,
        ));
      }

      if (path.startsWith('/share-sessions/public/')) {
        // Handle public click logging endpoint: /share-sessions/public/:id/click
        if (path.endsWith('/click') && method == 'POST') {
          final parts = path.split('/');
          final sessionId = parts[parts.length - 2];
          final session = await _supabase.from('share_sessions').select('view_count').eq('id', sessionId).single();
          final nextCount = (session['view_count'] as int? ?? 0) + 1;
          await _supabase.from('share_sessions').update({
            'view_count': nextCount,
            'last_viewed': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', sessionId);
          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true},
            statusCode: 200,
          ));
        }

        // Handle fetching public share session details: /share-sessions/public/:id
        final sessionId = path.split('/').last;
        final session = await _supabase.from('share_sessions').select('*').eq('id', sessionId).single();
        
        final sharedBy = session['shared_by'];
        Map<String, dynamic>? agent;
        if (sharedBy != null) {
          agent = await _supabase.from('users').select('*').eq('id', sharedBy).maybeSingle();
        }

        final List<dynamic> propertyIds = session['property_ids'] ?? [];
        List<Map<String, dynamic>> properties = [];
        
        if (propertyIds.isNotEmpty) {
          final dynamicList = await _supabase.from('properties').select('''
            *,
            category:property_categories(id, name),
            property_type:property_types(id, name),
            configuration:configurations(id, name),
            listing_type:listing_types(id, name),
            city:cities(id, city_name),
            area:areas(id, area_name, pincode),
            property_images(*),
            property_videos(*),
            property_amenities(amenity:amenities(*))
          ''').or(propertyIds.map((id) => 'id.eq.$id').join(','));
          
          properties = (dynamicList as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'session': session,
              'properties': properties,
              'agent': agent,
            }
          },
          statusCode: 200,
        ));
      }

      if (path.startsWith('/share-sessions/') && path.endsWith('/view') && method == 'POST') {
        final sessionId = path.split('/')[2];
        final session = await _supabase.from('share_sessions').select('view_count').eq('id', sessionId).single();
        final nextCount = (session['view_count'] as int? ?? 0) + 1;
        await _supabase.from('share_sessions').update({'view_count': nextCount}).eq('id', sessionId);
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true},
          statusCode: 200,
        ));
      }

      // 10. Users stats & lists
      if (path.startsWith('/users/admins/') && path.endsWith('/stats')) {
        final id = path.split('/')[3];
        final propertiesData = await _supabase.from('properties').select('id').eq('created_by', id);
        final requirementsData = await _supabase.from('requirements').select('id').eq('created_by', id);
        final propertiesCount = propertiesData.length;
        final requirementsCount = requirementsData.length;
        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {
              'propertiesCount': propertiesCount,
              'requirementsCount': requirementsCount
            }
          },
          statusCode: 200,
        ));
      }

      if (path == '/users' && method == 'GET') {
        final sessionUser = _supabase.auth.currentUser;
        if (sessionUser == null) {
          return handler.reject(DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401, data: {'success': false, 'message': 'Unauthorized'}),
          ));
        }

        // Fetch user profile of requester to get role name
        final requesterProfile = await _supabase
            .from('users')
            .select('*, roles(name)')
            .eq('id', sessionUser.id)
            .maybeSingle();

        final requesterRole = requesterProfile != null && requesterProfile['roles'] != null
            ? requesterProfile['roles']['name']?.toString()
            : null;

        var query = _supabase.from('users').select('*, roles(id, name, description)').isFilter('deleted_at', null);

        // Apply RBAC filters based on role
        if (requesterRole == 'Admin' || requesterRole == 'Telecaller') {
          // Admins and Telecallers only see themselves and users they manage (admin_id = current user's ID)
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

        final data = await query.order('created_at', ascending: false);

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {'users': data}
          },
          statusCode: 200,
        ));
      }

      if (path == '/users/password-resets' && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {'resets': []}
          },
          statusCode: 200,
        ));
      }

      if (path == '/users' && method == 'POST') {
        final payload = options.data as Map<String, dynamic>;
        
        final sessionUser = _supabase.auth.currentUser;
        if (sessionUser == null) throw Exception("Unauthenticated");

        final requesterProfile = await _supabase
            .from('users')
            .select('*, roles(name)')
            .eq('id', sessionUser.id)
            .maybeSingle();

        final requesterRole = requesterProfile != null && requesterProfile['roles'] != null
            ? requesterProfile['roles']['name']?.toString()
            : null;

        final String? adminId = (requesterRole == 'Admin' || requesterRole == 'Super Admin' || requesterRole == 'Telecaller')
            ? (payload['admin_id'] ?? sessionUser.id)
            : payload['admin_id'];

        final response = await _supabase.rpc(
          'admin_create_user',
          params: {
            'p_email': payload['email'],
            'p_password': payload['password'],
            'p_full_name': payload['full_name'] ?? '',
            'p_role_id': payload['role_id'],
            'p_organization_id': payload['organization_id'],
            'p_admin_id': adminId,
          },
        );

        if (response != null && response['success'] == true) {
          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'success': true,
              'message': 'User created successfully.',
              'data': {'user': response['user']}
            },
            statusCode: 200,
          ));
        }
        throw Exception(response?['message'] ?? 'Failed to create user.');
      }

      if (path.startsWith('/users/') && path.endsWith('/status') && method == 'PATCH') {
        final segments = path.split('/');
        final id = segments[segments.length - 2];
        final payload = options.data as Map<String, dynamic>;
        final data = await _supabase.from('users').update({
          'is_active': payload['isActive'] ?? payload['is_active'],
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id).select().single();

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'message': 'User status updated successfully.',
            'data': {'user': data}
          },
          statusCode: 200,
        ));
      }

      if (path.startsWith('/users/') && method == 'PUT') {
        final id = path.split('/').last;
        final payload = Map<String, dynamic>.from(options.data as Map<String, dynamic>);
        
        if (payload.containsKey('password') && payload['password'] != null && payload['password'].toString().isNotEmpty) {
          final newPassword = payload['password'].toString();
          await _supabase.rpc(
            'admin_update_password',
            params: {
              'p_user_id': id,
              'p_new_password': newPassword,
            },
          );
        }
        payload.remove('password');
        payload.remove('id');
        payload.remove('email');
        payload.remove('role');
        payload.remove('roles');

        final data = await _supabase.from('users').update({
          ...payload,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id).select().single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': data},
          statusCode: 200,
        ));
      }

      // 11. Profile Uploads & Updates
      if (path == '/users/upload-profile' && method == 'POST') {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          final fileField = formData.files.firstWhere((element) => element.key == 'profile_photo');
          final file = fileField.value;
          final bytes = await file.finalize().first;
          final path = 'profiles/${DateTime.now().millisecondsSinceEpoch}_${file.filename ?? 'photo.jpg'}';
          
          await _supabase.storage.from('property-media').uploadBinary(path, Uint8List.fromList(bytes));
          final publicUrl = _supabase.storage.from('property-media').getPublicUrl(path);

          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'success': true,
              'data': {'profile_photo': publicUrl}
            },
            statusCode: 200,
          ));
        }
      }

      if (path == '/auth/me' && method == 'PATCH') {
        final payload = options.data as Map<String, dynamic>;
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) throw Exception("Unauthenticated");

        final data = await _supabase.from('users').update({
          ...payload,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId).select().single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': data},
          statusCode: 200,
        ));
      }

      // 12. Audit sharing
      if (path == '/audit/share' && method == 'POST') {
        final payload = options.data as Map<String, dynamic>;
        final data = await _supabase.from('audit_logs').insert({
          'action': 'share_properties',
          'module': 'share',
          'user_id': _supabase.auth.currentUser?.id,
          'description': payload.toString(),
          'created_at': DateTime.now().toIso8601String(),
        }).select().single();
        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'data': data},
          statusCode: 200,
        ));
      }

      return super.onRequest(options, handler);

    } catch (e) {
      return handler.reject(DioException(
        requestOptions: options,
        error: e,
        type: DioExceptionType.unknown,
        message: "Supabase translation interceptor error: ${e.toString()}",
      ));
    }
  }
}
