import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/dio_client.dart';
import '../security/role_guard.dart';

class NotificationCenter {
  static final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get stream => _controller.stream;

  static final List<Map<String, dynamic>> _localNotifications = [];
  static final Set<String> _deletedIds = {};
  static bool _isInitialized = false;
  static String? _userId;
  static final Set<String> _persistingKeys = {};

  static List<Map<String, dynamic>> get localNotifications =>
      List.unmodifiable(_localNotifications);

  static Set<String> get deletedIds => Set.unmodifiable(_deletedIds);

  static String _cacheKey(String? userId) =>
      'app_local_notifications_cache_${userId ?? 'anon'}';

  static String _deletedKey(String? userId) =>
      'app_deleted_notification_ids_${userId ?? 'anon'}';

  static Future<void> init({String? userId}) async {
    if (_isInitialized && _userId == userId) return;
    final previousUserId = _userId;
    final previousList = List<Map<String, dynamic>>.from(_localNotifications);
    final previousDeleted = Set<String>.from(_deletedIds);
    _userId = userId;
    _isInitialized = true;
    _localNotifications.clear();
    _deletedIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      var jsonStr = prefs.getString(_cacheKey(userId));
      if ((jsonStr == null || jsonStr.isEmpty) && userId != null) {
        jsonStr = prefs.getString('app_local_notifications_cache');
      }
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _localNotifications.add(item);
          } else if (item is Map) {
            _localNotifications.add(Map<String, dynamic>.from(item));
          }
        }
      }
      var delStr = prefs.getString(_deletedKey(userId));
      if ((delStr == null || delStr.isEmpty) && userId != null) {
        delStr = prefs.getString('app_deleted_notification_ids');
      }
      if (delStr != null && delStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(delStr);
        _deletedIds.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
    if (userId != null &&
        _localNotifications.isEmpty &&
        previousList.isNotEmpty &&
        (previousUserId == null || previousUserId == userId)) {
      _localNotifications.addAll(previousList);
      _deletedIds.addAll(previousDeleted);
    }
    await _saveToStorage();
  }

  static Future<void> clearSession() async {
    _localNotifications.clear();
    _deletedIds.clear();
    _isInitialized = false;
    _userId = null;
  }

  static Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(_userId), jsonEncode(_localNotifications));
      await prefs.setString(_deletedKey(_userId), jsonEncode(_deletedIds.toList()));
    } catch (_) {}
  }

  static Future<void> addNotification({
    String? id,
    required String title,
    required String message,
    String type = 'followup',
    String? route,
    Map<String, dynamic>? payload,
    bool notifyToast = true,
  }) async {
    await init(userId: _userId ?? RoleGuard.currentUser?.id);

    final notifKey = '${title}_${message}'.replaceAll(' ', '').toLowerCase();
    if (_deletedIds.contains(notifKey)) {
      return;
    }

    Map<String, dynamic>? existing;
    if (id != null && id.isNotEmpty) {
      try {
        existing = _localNotifications.firstWhere((n) => n['id']?.toString() == id);
      } catch (_) {}
    }
    if (existing == null && _localNotifications.isNotEmpty) {
      final last = _localNotifications.first;
      if (last['title'] == title && last['message'] == message) {
        existing = last;
      }
    }

    final incomingType = type.toLowerCase();
    final incomingTitle = title.toLowerCase();
    final isDueIncoming = _isDueAlert(incomingType, incomingTitle);
    if (isDueIncoming) {
      final client = (payload?['clientName'] ?? '').toString();
      final fuId = (payload?['followupId'] ?? '').toString();
      if (fuId.isNotEmpty && hasDueFollowup(fuId)) return;
      if (client.isNotEmpty && hasDueClientToday(client)) return;
    }

    if (existing != null) {
      if (!isDueIncoming) {
        unawaited(_persistToBackend(existing));
      }
      return;
    }

    final notif = {
      'id': id ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'route': route,
      if (payload != null) 'payload': payload,
      'notifyToast': notifyToast,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };
    _localNotifications.insert(0, notif);
    await _saveToStorage();
    _controller.add(notif);
    final persistNow = incomingType == 'lead_assigned' ||
        incomingType == 'lead_created' ||
        incomingType == 'property_created' ||
        incomingType == 'new_lead';
    if (persistNow) {
      await _persistToBackend(notif);
    } else {
      unawaited(_persistToBackend(notif));
    }
  }

  static Future<void> syncPendingToBackend() async {
    final pending = List<Map<String, dynamic>>.from(_localNotifications);
    for (final n in pending) {
      await _persistToBackend(n);
    }
  }

  static Future<void> _persistToBackend(Map<String, dynamic> notif) async {
    final title = (notif['title'] ?? '').toString();
    final message = (notif['message'] ?? '').toString();
    final type = (notif['type'] ?? 'general').toString();
    if (title.isEmpty || message.isEmpty) return;
    if ((notif['action'] ?? '').toString() == 'refresh') return;
    final localId = (notif['id'] ?? '').toString();
    if (localId.startsWith('due_')) return;
    final persistKey = '${type}_${title}_${message}'.replaceAll(' ', '').toLowerCase();
    if (_persistingKeys.contains(persistKey)) return;
    _persistingKeys.add(persistKey);
    try {
      final payload = notif['payload'] is Map
          ? Map<String, dynamic>.from(notif['payload'] as Map)
          : <String, dynamic>{};
      payload['type'] = type;
      if (notif['route'] != null) payload['route'] = notif['route'];
      final response = await DioClient.dio.post(
        '/notifications',
        data: {
          'title': title,
          'message': message,
          'type': type,
          'route': notif['route'],
          'data': payload,
        },
      );
      final data = response.data;
      dynamic row;
      if (data is Map) {
        row = data['data'] is Map ? data['data']['notification'] : data['notification'];
      }
      if (row is Map && row['id'] != null) {
        notif['id'] = row['id'].toString();
        await _saveToStorage();
      }
    } catch (_) {
    } finally {
      _persistingKeys.remove(persistKey);
    }
  }

  static Future<void> markAsRead(String id) async {
    await init(userId: _userId ?? RoleGuard.currentUser?.id);
    for (final n in _localNotifications) {
      if (n['id'] == id) {
        n['is_read'] = true;
        break;
      }
    }
    await _saveToStorage();
  }

  static Future<void> markAllAsRead() async {
    await init(userId: _userId ?? RoleGuard.currentUser?.id);
    for (final n in _localNotifications) {
      n['is_read'] = true;
    }
    await _saveToStorage();
  }

  static Future<void> deleteNotification(String id, {String? title, String? message}) async {
    await init(userId: _userId ?? RoleGuard.currentUser?.id);
    _localNotifications.removeWhere((n) => n['id'] == id);
    _deletedIds.add(id);
    if (title != null && message != null) {
      final notifKey = '${title}_${message}'.replaceAll(' ', '').toLowerCase();
      _deletedIds.add(notifKey);
    }
    await _saveToStorage();
  }

  static bool containsId(String id) {
    return _localNotifications.any((n) => n['id']?.toString() == id);
  }

  static bool hasDueFollowup(String followupId) {
    if (followupId.trim().isEmpty) return false;
    final id = followupId.trim();
    return _localNotifications.any((n) {
      final existingId = (n['id'] ?? '').toString();
      if (existingId == 'due_$id' ||
          existingId.startsWith('due_${id}_') ||
          existingId.startsWith('due_campaign_${id}_')) {
        return true;
      }
      final type = (n['type'] ?? '').toString();
      final title = (n['title'] ?? '').toString();
      if (!_isDueAlert(type, title)) return false;
      final payload = n['payload'] is Map
          ? Map<String, dynamic>.from(n['payload'] as Map)
          : <String, dynamic>{};
      return (payload['followupId'] ?? '').toString() == id;
    });
  }

  static bool _isDueAlert(String type, String title) {
    final t = type.toLowerCase();
    final titleLower = title.toLowerCase();
    if (titleLower.contains('follow-up scheduled') ||
        titleLower.contains('re-followup scheduled')) {
      return false;
    }
    return t == 'due_followup' ||
        t == 'site_visit' ||
        titleLower.contains('follow-up alert') ||
        titleLower.contains('overdue follow-up') ||
        titleLower.contains('site visit');
  }

  static bool hasDueClientToday(String clientName) {
    final target = clientName.trim().toLowerCase();
    if (target.isEmpty) return false;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _localNotifications.any((n) {
      final type = (n['type'] ?? '').toString().toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      if (!_isDueAlert(type, title)) return false;
      final createdAt = (n['created_at'] ?? '').toString();
      if (!createdAt.startsWith(todayStr)) return false;
      final payload = n['payload'] is Map
          ? Map<String, dynamic>.from(n['payload'] as Map)
          : <String, dynamic>{};
      final payloadClient = (payload['clientName'] ?? '').toString().trim().toLowerCase();
      if (payloadClient == target) return true;
      return (n['message'] ?? '').toString().toLowerCase().contains(target);
    });
  }

  static bool hasNotificationToday(String clientName) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final target = clientName.trim().toLowerCase();
    return _localNotifications.any((n) {
      final msg = (n['message'] ?? '').toString().toLowerCase();
      final createdAt = (n['created_at'] ?? '').toString();
      final isToday = createdAt.startsWith(todayStr);
      return isToday && msg.contains(target);
    });
  }

  static Future<void> removeNotificationsForClient(String clientName) async {
    await init(userId: _userId ?? RoleGuard.currentUser?.id);
    if (clientName.trim().isEmpty) return;
    final String target = clientName.trim().toLowerCase();
    _localNotifications.removeWhere((n) {
      final type = (n['type'] ?? '').toString().toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      if (!_isDueAlert(type, title)) return false;
      final msg = (n['message'] ?? '').toString().toLowerCase();
      return msg.contains(target) || title.contains(target);
    });
    await _saveToStorage();
  }
}
