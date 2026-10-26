import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_notifier_service.dart';

@pragma('vm:entry-point')
void _notificationActionBackgroundHandler(NotificationResponse notificationResponse) {
  // Handled on app resume via notification payload
}

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
      onDidReceiveBackgroundNotificationResponse: _notificationActionBackgroundHandler,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'propkart_messages_v2',
        'Messages',
        description: 'Incoming team messages and direct alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'propkart_notifications',
        'PropKart notifications',
        description: 'Lead assignments, follow-ups, and important CRM alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 600), () {
            AppNotifierService.handleNotificationTap({'route': payload});
          });
        }
      }
    } catch (_) {}

    _ready = true;
  }

  static Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    return granted;
  }

  static Future<bool> isPermissionGranted() async {
    await _ensureReady();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await android?.areNotificationsEnabled();
    return enabled ?? true;
  }

  static void showNotification({
    required String title,
    required String body,
    String? icon,
    VoidCallback? onClick,
    dynamic data,
  }) {
    _ensureReady().then((_) {
      final route = data is Map ? data['route']?.toString() : null;
      final type = data is Map ? data['type']?.toString() : null;
      final isMessage = type == 'team_message' || type == 'message' || (route != null && route.startsWith('/messages'));
      final actions = <AndroidNotificationAction>[];
      if (isMessage) {
        actions.add(
          const AndroidNotificationAction(
            'view_message',
            'View Message',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        );
      }

      final notifId = (DateTime.now().millisecondsSinceEpoch % 2147483647).abs();
      final channelId = isMessage ? 'propkart_messages_v2' : 'propkart_notifications';
      final channelName = isMessage ? 'Messages' : 'PropKart notifications';
      final importance = isMessage ? Importance.max : Importance.high;
      final priority = isMessage ? Priority.max : Priority.high;

      _plugin.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: isMessage ? 'Incoming team messages' : 'Real-time CRM notifications',
            importance: importance,
            priority: priority,
            icon: '@mipmap/ic_launcher',
            actions: actions.isNotEmpty ? actions : null,
            playSound: true,
            enableVibration: true,
            ticker: title,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: route,
      );
    }).catchError((e) {
      debugPrint('[PlatformNotifier] native notification failed: $e');
    });
  }
}
