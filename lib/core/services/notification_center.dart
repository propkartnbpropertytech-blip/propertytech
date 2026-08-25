import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationCenter {
  static final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get stream => _controller.stream;

  static final List<Map<String, dynamic>> _localNotifications = [];
  static final Set<String> _deletedIds = {};
  static bool _isInitialized = false;

  static List<Map<String, dynamic>> get localNotifications =>
      List.unmodifiable(_localNotifications);

  static Set<String> get deletedIds => Set.unmodifiable(_deletedIds);

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('app_local_notifications_cache');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _localNotifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _localNotifications.add(item);
          } else if (item is Map) {
            _localNotifications.add(Map<String, dynamic>.from(item));
          }
        }
      }
      final delStr = prefs.getString('app_deleted_notification_ids');
      if (delStr != null && delStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(delStr);
        _deletedIds.clear();
        _deletedIds.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  static Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_localNotifications);
      await prefs.setString('app_local_notifications_cache', jsonStr);
      final delStr = jsonEncode(_deletedIds.toList());
      await prefs.setString('app_deleted_notification_ids', delStr);
    } catch (_) {}
  }

  static Future<void> addNotification({
    required String title,
    required String message,
    String type = 'followup',
  }) async {
    await init();

    final notifKey = '${title}_${message}'.replaceAll(' ', '').toLowerCase();
    if (_deletedIds.contains(notifKey)) {
      return;
    }

    if (_localNotifications.isNotEmpty) {
      final last = _localNotifications.first;
      if (last['title'] == title && last['message'] == message) {
        return;
      }
    }

    final notif = {
      'id': 'local_${DateTime.now().microsecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };
    _localNotifications.insert(0, notif);
    await _saveToStorage();
    _controller.add(notif);
  }

  static Future<void> markAsRead(String id) async {
    await init();
    for (final n in _localNotifications) {
      if (n['id'] == id) {
        n['is_read'] = true;
        break;
      }
    }
    await _saveToStorage();
  }

  static Future<void> markAllAsRead() async {
    await init();
    for (final n in _localNotifications) {
      n['is_read'] = true;
    }
    await _saveToStorage();
  }

  static Future<void> deleteNotification(String id, {String? title, String? message}) async {
    await init();
    _localNotifications.removeWhere((n) => n['id'] == id);
    _deletedIds.add(id);
    if (title != null && message != null) {
      final notifKey = '${title}_${message}'.replaceAll(' ', '').toLowerCase();
      _deletedIds.add(notifKey);
    }
    await _saveToStorage();
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
    await init();
    if (clientName.trim().isEmpty) return;
    final String target = clientName.trim().toLowerCase();
    _localNotifications.removeWhere((n) {
      final msg = (n['message'] ?? '').toString().toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      return (msg.contains(target) || title.contains(target));
    });
    await _saveToStorage();
    _controller.add({'id': 'refresh', 'action': 'refresh'});
  }
}
