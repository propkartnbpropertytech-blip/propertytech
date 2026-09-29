import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_notifier_service.dart';

class PlatformNotifier {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        AppNotifierService.handleNotificationTap({
          'route': response.payload,
        });
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'propkart_notifications',
            'PropKart notifications',
            description: 'Lead assignments, follow-ups, and important CRM alerts',
            importance: Importance.high,
          ),
        );
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    return true;
  }

  static Future<bool> isPermissionGranted() async {
    return true;
  }

  static void showNotification({
    required String title,
    required String body,
    String? icon,
    VoidCallback? onClick,
    dynamic data,
  }) {
    _ensureReady().then((_) {
      _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'propkart_notifications',
            'PropKart notifications',
            channelDescription: 'Lead assignments, follow-ups, and important CRM alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: data is Map ? data['route']?.toString() : null,
      );
    }).catchError((e) {
      debugPrint('[PlatformNotifier] native notification failed: $e');
    });
  }
}

