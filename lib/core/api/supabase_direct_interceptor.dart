import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_constants.dart';
import 'cloudinary_uploader.dart';

String _generateUuidV4() {
  final random = Random.secure();
  final hexDigits = '0123456789abcdef';
  final charCodes = List<int>.generate(36, (index) {
    if (index == 8 || index == 13 || index == 18 || index == 23) return 45;
    if (index == 14) return 52;
    final digit = random.nextInt(16);
    if (index == 19) return hexDigits.codeUnitAt((digit & 0x3) | 0x8);
    return hexDigits.codeUnitAt(digit);
  });
  return String.fromCharCodes(charCodes);
}

class SupabaseDirectInterceptor extends Interceptor {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!ApiConstants.useSupabaseDirect) {
      return super.onRequest(options, handler);
    }

    final path = options.path;
    final method = options.method.toUpperCase();
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    try {
      // 0. Restore Endpoints (Properties & Requirements)
      if (path.contains('/restore')) {
        final parts = path.split('/').where((p) => p.isNotEmpty).toList();
        final restoreIdx = parts.lastIndexOf('restore');
        final id = restoreIdx > 0 ? parts[restoreIdx - 1] : '';

        if (path.contains('/properties')) {
          bool restored = false;
          try {
            await _supabase.rpc('restore_property_from_bin', params: {'p_property_id': id});
            restored = true;
          } catch (_) {}

          if (!restored) {
            try {
              await _supabase.from('properties').update({
                'deleted_at': null,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', id);
              restored = true;
            } catch (_) {}
          }

          if (!restored) {
            try {
              final binRow = await _supabase.from('deleted_properties').select('*').eq('id', id).maybeSingle();
              if (binRow != null) {
                final rowMap = Map<String, dynamic>.from(binRow);
                rowMap.remove('deleted_at');
                await _supabase.from('properties').upsert(rowMap);
                await _supabase.from('deleted_properties').delete().eq('id', id);
                restored = true;
              }
            } catch (_) {}
          }

          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'message': 'Property restored successfully', 'data': {'id': id}},
            statusCode: 200,
          ));
        }

        if (path.contains('/requirements')) {
          bool restored = false;
          try {
            await _supabase.rpc('restore_requirement_from_bin', params: {'p_requirement_id': id});
            restored = true;
          } catch (_) {}

          if (!restored) {
            try {
              await _supabase.from('requirements').update({
                'deleted_at': null,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', id);
              restored = true;
            } catch (_) {}
          }

          if (!restored) {
            try {
              final check = await _supabase.from('requirements').select('id, status').eq('id', id).maybeSingle();
              if (check != null) {
                final newStatus = check['status'] == 'Not Interested' ? 'Interested' : check['status'];
                await _supabase.from('requirements').update({
                  'deleted_at': null,
                  'status': newStatus,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', id);
                restored = true;
              }
            } catch (_) {}
          }

          if (!restored) {
            try {
              final binRow = await _supabase.from('deleted_requirements').select('*').eq('id', id).maybeSingle();
              if (binRow != null) {
                final rowMap = Map<String, dynamic>.from(binRow);
                rowMap.remove('deleted_at');
                await _supabase.from('requirements').upsert(rowMap);
                await _supabase.from('deleted_requirements').delete().eq('id', id);
                restored = true;
              }
            } catch (_) {}
          }

          return handler.resolve(Response(
            requestOptions: options,
            data: {'success': true, 'message': 'Requirement restored successfully', 'data': {'id': id}},
            statusCode: 200,
          ));
        }
      }

      // 1. App Config Endpoint
      if (path.startsWith('/config')) {
        final data = await _supabase.from('app_config').select('*').limit(1).maybeSingle();
        final config = data ?? {
          'maintenance_mode': false,
          'maintenance_message': '',
          'android_link': 'comingsoon',
          'ios_link': 'comingsoon',
          'min_version': '1.1.2',
          'max_version': '1.1.3',
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
          ''').order('created_at', ascending: false).limit(50),
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
      if (path.startsWith('/properties/') && method == 'GET') {
        final id = path.split('/').last;
        if (uuidRegex.hasMatch(id)) {
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
      }

      // 5. Requirements Detail Retrieval
      if (path.startsWith('/requirements/') && method == 'GET') {
        final id = path.split('/').last;
        if (uuidRegex.hasMatch(id)) {
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
          final payload = Map<String, dynamic>.from(options.data as Map);
          if (!payload.containsKey('scheduled_by')) {
            final userId = _supabase.auth.currentUser?.id;
            if (userId != null) {
              payload['scheduled_by'] = userId;
            }
          }
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
          final payload = Map<String, dynamic>.from(options.data as Map);
          if (!payload.containsKey('created_by')) {
            final userId = _supabase.auth.currentUser?.id;
            if (userId != null) {
              payload['created_by'] = userId;
            }
          }
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
        final data = await _supabase.from('share_sessions').select('*, agent:users!shared_by(id, full_name, mobile)').eq('requirement_id', reqId).order('created_at', ascending: false);
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

        var query = _supabase.from('users').select('*, roles(id, name, description)').not('email', 'like', 'deleted_%');

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
        List<Map<String, dynamic>> resetsList = [];
        Set<String> seenIds = {};

        // 1. Fetch from password_reset_requests table
        try {
          final rows = await _supabase
              .from('password_reset_requests')
              .select('*')
              .eq('status', 'pending')
              .order('created_at', ascending: false);

          for (final row in rows) {
            final String id = row['id'].toString();
            final String? uid = row['user_id']?.toString() ?? row['requested_by']?.toString();
            String userName = 'User';
            String userEmail = '';
            String roleName = 'Sales';

            if (uid != null && uid.isNotEmpty) {
              try {
                final uProfile = await _supabase
                    .from('users')
                    .select('full_name, email, roles(name)')
                    .eq('id', uid)
                    .maybeSingle();

                if (uProfile != null) {
                  userName = uProfile['full_name'] ?? uProfile['email'] ?? 'User';
                  userEmail = uProfile['email'] ?? '';
                  if (uProfile['roles'] != null && uProfile['roles']['name'] != null) {
                    roleName = uProfile['roles']['name'].toString();
                  }
                }
              } catch (_) {}
            }

            seenIds.add(id);
            if (uid != null) seenIds.add(uid);

            resetsList.add({
              'id': id,
              'userId': uid ?? id,
              'userName': userName,
              'userEmail': userEmail,
              'roleName': roleName,
              'createdAt': row['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint("Fetch password_reset_requests notice: $e");
        }

        // 2. Fetch from audit_logs table (merge to guarantee requests are never missed)
        try {
          final logs = await _supabase
              .from('audit_logs')
              .select('*')
              .eq('action', 'password_reset_request')
              .order('created_at', ascending: false)
              .limit(50);

          for (final log in logs) {
            final logId = log['id'].toString();
            final desc = log['description']?.toString() ?? '';
            if (desc.startsWith('{')) {
              try {
                final data = jsonDecode(desc);
                final uId = data['userId']?.toString() ?? logId;
                if (data['status'] == 'pending' && !seenIds.contains(logId) && !seenIds.contains(uId)) {
                  seenIds.add(logId);
                  if (uId.isNotEmpty) seenIds.add(uId);
                  resetsList.add({
                    'id': logId,
                    'userId': uId,
                    'userName': data['userName'] ?? data['email'] ?? 'User',
                    'userEmail': data['email'] ?? '',
                    'roleName': data['userRole'] ?? 'User',
                    'createdAt': log['created_at'],
                  });
                }
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint("Fetch audit_logs notice: $e");
        }

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'data': {'resets': resetsList}
          },
          statusCode: 200,
        ));
      }

      if (path == '/users' && method == 'POST') {
        final payload = Map<String, dynamic>.from(options.data as Map<String, dynamic>);
        
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

        final String email = (payload['email'] ?? '').toString().trim();

        // 1. Purge any stale existing row in public.users for this email address
        final existing = await _supabase
            .from('users')
            .select('id, profile_photo')
            .eq('email', email)
            .maybeSingle();

        if (existing != null) {
          final String existingId = existing['id'].toString();
          if (existing['profile_photo'] != null && existing['profile_photo'].toString().isNotEmpty) {
            final photoUrl = existing['profile_photo'].toString();
            if (photoUrl.contains('cloudinary.com')) {
              await CloudinaryUploader.delete(url: photoUrl, resourceType: 'image');
            }
          }
          try {
            await _supabase.from('password_reset_requests').delete().or('user_id.eq.$existingId,requested_by.eq.$existingId');
          } catch (_) {}
          try {
            await _supabase.from('users').delete().eq('id', existingId);
          } catch (_) {}
          for (final paramKey in ['p_user_id', 'p_id', 'p_target_user_id', 'user_id', 'id']) {
            try {
              await _supabase.rpc('admin_delete_user', params: {paramKey: existingId});
              break;
            } catch (_) {}
          }
        }

        // 2. Create via RPC so auth.users and public.users share the same id + password hash
        final rpcResult = await _supabase.rpc(
          'admin_create_user',
          params: {
            'p_email': email,
            'p_password': payload['password'],
            'p_full_name': payload['full_name'] ?? payload['fullName'] ?? '',
            'p_role_id': payload['role_id'] ?? payload['roleId'],
            'p_organization_id': payload['organization_id'] ?? payload['organizationId'],
            'p_admin_id': adminId,
            'p_mobile': payload['mobile'] ?? payload['phone'],
          },
        );

        if (rpcResult is! Map || rpcResult['success'] != true) {
          throw Exception(rpcResult is Map ? (rpcResult['message'] ?? 'Failed to create user') : 'Failed to create user');
        }

        final createdId = rpcResult['user']?['id']?.toString();
        if (createdId == null || createdId.isEmpty) {
          throw Exception('User created but no id returned');
        }

        final photo = payload['profile_photo'] ?? payload['profilePhoto'];
        if (photo != null && photo.toString().isNotEmpty) {
          try {
            await _supabase.from('users').update({'profile_photo': photo}).eq('id', createdId);
          } catch (_) {}
        }

        final createdUser = await _supabase
            .from('users')
            .select('*, roles(id, name, description)')
            .eq('id', createdId)
            .maybeSingle();

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'message': 'User created successfully.',
            'data': {'user': createdUser ?? rpcResult['user']}
          },
          statusCode: 200,
        ));
      }

      if (path.startsWith('/users/') && method == 'DELETE') {
        final id = path.split('/').last;

        // 1. Fetch user profile from public.users to check for Cloudinary photo cleanup
        try {
          final userRow = await _supabase
              .from('users')
              .select('id, profile_photo')
              .eq('id', id)
              .maybeSingle();

          if (userRow != null && userRow['profile_photo'] != null) {
            final photoUrl = userRow['profile_photo'].toString();
            if (photoUrl.contains('cloudinary.com')) {
              await CloudinaryUploader.delete(url: photoUrl, resourceType: 'image');
            }
          }
        } catch (e) {
          debugPrint("Cloudinary photo delete notice: $e");
        }

        // 2. Delete associated password_reset_requests
        try {
          await _supabase
              .from('password_reset_requests')
              .delete()
              .or('user_id.eq.$id,requested_by.eq.$id');
        } catch (_) {}

        // Nullify foreign key references to allow hard delete (without deleting listed properties)
        try {
          await _supabase.from('properties').update({'created_by': null}).eq('created_by', id);
        } catch (e) {
          debugPrint("Nullify properties.created_by error: $e");
        }
        try {
          await _supabase.from('requirements').update({'created_by': null}).eq('created_by', id);
        } catch (e) {
          debugPrint("Nullify requirements.created_by error: $e");
        }
        try {
          await _supabase.from('requirements').update({'admin_id': null}).eq('admin_id', id);
        } catch (e) {
          debugPrint("Nullify requirements.admin_id error: $e");
        }
        try {
          await _supabase.from('site_visits').update({'scheduled_by': null}).eq('scheduled_by', id);
        } catch (e) {
          debugPrint("Nullify site_visits.scheduled_by error: $e");
        }
        try {
          await _supabase.from('tasks').update({'created_by': null}).eq('created_by', id);
        } catch (e) {
          debugPrint("Nullify tasks.created_by error: $e");
        }
        try {
          await _supabase.from('tasks').update({'assigned_to': null}).eq('assigned_to', id);
        } catch (e) {
          debugPrint("Nullify tasks.assigned_to error: $e");
        }
        try {
          await _supabase.from('share_sessions').update({'shared_by': null}).eq('shared_by', id);
        } catch (e) {
          debugPrint("Nullify share_sessions.shared_by error: $e");
        }

        // 3. Try calling RPC to delete user from Supabase Auth & DB
        for (final paramKey in ['p_user_id', 'p_id', 'p_target_user_id', 'user_id', 'id']) {
          try {
            await _supabase.rpc('admin_delete_user', params: {paramKey: id});
            break;
          } catch (_) {}
        }

        // 4. Hard-delete user row permanently from public.users table
        var deletedData = await _supabase
            .from('users')
            .delete()
            .eq('id', id)
            .select()
            .maybeSingle();

        // 5. If RLS blocked .delete(), free up the email address in public.users
        if (deletedData == null) {
          try {
            await _supabase
                .from('users')
                .update({
                  'email': 'deleted_${DateTime.now().millisecondsSinceEpoch}_$id@deleted.local',
                  'full_name': 'Deleted User',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', id);
          } catch (e) {
            debugPrint("Fallback user cleanup notice: $e");
          }
        }

        return handler.resolve(Response(
          requestOptions: options,
          data: {
            'success': true,
            'message': 'User permanently deleted.',
            'data': deletedData ?? {'id': id}
          },
          statusCode: 200,
        ));
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
          // admin_update_password already writes public.users + auth.users — do not
          // re-set password_hash here (would re-salt and desync the two tables).

          // Mark any pending password reset requests for this user as resolved
          try {
            await _supabase
                .from('password_reset_requests')
                .update({
                  'status': 'resolved',
                  'resolved_at': DateTime.now().toIso8601String(),
                })
                .eq('user_id', id)
                .eq('status', 'pending');
          } catch (_) {}
        }
        payload.remove('password');
        payload.remove('password_hash');
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

      // 10.b Service Agent Document Upload Interceptor
      if (path == '/service-agent/upload' && method == 'POST') {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          final fileField = formData.files.firstWhere(
            (element) => element.key == 'file' || element.key == 'document',
          );
          final file = fileField.value;
          // Read ALL chunks — `.first` only keeps the first packet and corrupts PDFs.
          final bytesBuilder = BytesBuilder(copy: false);
          await for (final chunk in file.finalize()) {
            bytesBuilder.add(chunk);
          }
          final bytes = bytesBuilder.takeBytes();

          // Enforce PDF check
          final filename = file.filename ?? 'document.pdf';
          final ext = filename.split('.').last.toLowerCase();
          if (ext != 'pdf') {
            throw Exception("Strict Warning: Only PDF documents are allowed!");
          }

          // Enforce max size 10MB (matches upload UI)
          if (bytes.length > 10 * 1024 * 1024) {
            throw Exception("Strict Warning: File size exceeds the 10MB limit!");
          }

          final String publicUrl = await CloudinaryUploader.uploadServiceAgentPdf(
            bytes: bytes,
            filename: filename,
          );

          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'success': true,
              'data': {
                'url': publicUrl,
                'publicUrl': publicUrl,
              }
            },
            statusCode: 200,
          ));
        }
      }

      // 11. Profile Uploads & Updates
      if (path.startsWith('/users/upload-profile') && method == 'POST') {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          if (formData.files.isNotEmpty) {
            final fileField = formData.files.firstWhere(
              (element) => element.key == 'profile_photo' || element.key == 'file',
              orElse: () => formData.files.first,
            );
            final file = fileField.value;
            List<int> bytes;
            try {
              bytes = await file.finalize().first;
            } catch (_) {
              bytes = await file.finalize().reduce((a, b) => Uint8List.fromList([...a, ...b]));
            }
            
            final String publicUrl = await CloudinaryUploader.upload(
              bytes: bytes,
              filename: file.filename ?? 'photo.jpg',
              mimeType: file.contentType?.toString() ?? 'image/jpeg',
              resourceType: 'image',
              folder: 'profiles',
            );

            return handler.resolve(Response(
              requestOptions: options,
              data: {
                'success': true,
                'data': {
                  'profile_photo': publicUrl,
                  'publicUrl': publicUrl,
                }
              },
              statusCode: 200,
            ));
          }
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

      // 13. Forgot Password
      if ((path == '/auth/forgot-password' || path == '/auth/forgot') && method == 'POST') {
        final payload = options.data is Map ? (options.data as Map) : {};
        final String email = (payload['email'] ?? '').toString().trim();

        if (email.isEmpty) {
          return handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'success': false, 'message': 'Please enter a valid email address.'},
            ),
          ));
        }

        try {
          // Call request_password_reset RPC (this handles verifying the email and inserting the request securely bypassing RLS)
          final bool success = await _supabase.rpc(
            'request_password_reset',
            params: {'p_email': email},
          );

          if (!success) {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 404,
                data: {'success': false, 'message': 'This email address is not registered in our system.'},
              ),
            ));
          }

          // Prefer a stable production URL so email clients open the web reset page.
          // (Must be listed under Supabase Auth → Redirect URLs.)
          try {
            await _supabase.auth.resetPasswordForEmail(
              email,
              redirectTo: ApiConstants.passwordResetRedirectTo,
            );
          } catch (e) {
            debugPrint("Supabase resetPasswordForEmail notice: $e");
          }

          return handler.resolve(Response(
            requestOptions: options,
            data: {
              'success': true,
              'message': 'Password reset request has been sent to your administrator.',
            },
            statusCode: 200,
          ));
        } catch (e) {
          final errorMsg = e.toString().replaceAll('Exception: ', '');
          return handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: {'success': false, 'message': errorMsg},
            ),
          ));
        }
      }

      // 14. Resolve Password Reset Request
      if (path.startsWith('/users/password-resets/') && path.endsWith('/resolve') && method == 'POST') {
        final payload = options.data is Map ? (options.data as Map) : {};
        final newPassword = (payload['newPassword'] ?? '').toString();
        final pathSegments = path.split('/');
        final requestId = pathSegments.length > 3 ? pathSegments[3] : '';

        if (newPassword.isNotEmpty && requestId.isNotEmpty) {
          String? targetUserId;
          String? targetEmail;

          // Prefer explicit userId from request body when the UI provides it
          if (payload['userId'] != null && payload['userId'].toString().isNotEmpty) {
            targetUserId = payload['userId'].toString();
          }
          if (payload['email'] != null && payload['email'].toString().isNotEmpty) {
            targetEmail = payload['email'].toString();
          }

          // 1. Resolve target user from password_reset_requests (no email column on this table)
          try {
            final reqRow = await _supabase
                .from('password_reset_requests')
                .select('user_id, requested_by')
                .eq('id', requestId)
                .maybeSingle();

            if (reqRow != null) {
              targetUserId ??= (reqRow['user_id'] ?? reqRow['requested_by'])?.toString();
            }
          } catch (e) {
            debugPrint("password_reset_requests lookup notice: $e");
          }

          // Fallback: audit_logs legacy payload
          if (targetUserId == null || targetUserId == requestId) {
            try {
              final logRow = await _supabase.from('audit_logs').select('*').eq('id', requestId).maybeSingle();
              if (logRow != null && logRow['description'] != null) {
                final desc = logRow['description'].toString();
                if (desc.startsWith('{')) {
                  final data = jsonDecode(desc);
                  if (data['userId'] != null) {
                    targetUserId = data['userId'].toString();
                  }
                  targetEmail ??= data['email']?.toString();
                }
              }
            } catch (_) {}
          }

          // Resolve email → public.users.id when needed
          if ((targetUserId == null || targetUserId.isEmpty) && targetEmail != null) {
            try {
              final userRow = await _supabase
                  .from('users')
                  .select('id')
                  .ilike('email', targetEmail)
                  .isFilter('deleted_at', null)
                  .maybeSingle();
              if (userRow != null) targetUserId = userRow['id'].toString();
            } catch (_) {}
          }

          if (targetUserId == null || targetUserId.isEmpty || targetUserId == requestId) {
            throw Exception(
              'Could not resolve the user for this password reset request. Refresh and try again.',
            );
          }

          // 2. Update public.users (source of truth) + sync auth.users
          await _supabase.rpc(
            'admin_update_password',
            params: {
              'p_user_id': targetUserId,
              'p_new_password': newPassword,
            },
          );

          // 3. Mark password_reset_requests as resolved
          try {
            await _supabase
                .from('password_reset_requests')
                .update({
                  'status': 'resolved',
                  'resolved_at': DateTime.now().toIso8601String(),
                })
                .eq('id', requestId);

            await _supabase
                .from('password_reset_requests')
                .update({
                  'status': 'resolved',
                  'resolved_at': DateTime.now().toIso8601String(),
                })
                .eq('user_id', targetUserId)
                .eq('status', 'pending');
          } catch (_) {}

          // 4. Update audit_logs fallback
          try {
            final logRow = await _supabase.from('audit_logs').select('*').eq('id', requestId).maybeSingle();
            if (logRow != null && logRow['description'] != null) {
              final desc = logRow['description'].toString();
              if (desc.startsWith('{')) {
                final data = jsonDecode(desc);
                data['status'] = 'resolved';
                await _supabase.from('audit_logs').update({'description': jsonEncode(data)}).eq('id', requestId);
              }
            }
          } catch (_) {}
        }

        return handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'message': 'Password reset request resolved successfully.'},
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
