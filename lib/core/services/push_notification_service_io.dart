import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/dio_client.dart';
import 'app_notifier_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // If FCM already included a visible notification payload, the OS shows it.
  if (message.notification != null) return;
  await PushNotificationService.showOsNotification(
    title: message.data['title']?.toString() ?? 'New client lead assigned',
    body: message.data['message']?.toString() ?? 'A telecaller assigned a client lead to you.',
    payload: message.data['route']?.toString(),
  );
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'propkart_lead_assigned',
    'Lead assignments',
    description: 'Notifies sales users when a telecaller assigns a client lead',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[PushNotificationService] Firebase init skipped: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        AppNotifierService.handleNotificationTap({
          'route': response.payload,
          'type': 'lead_assigned',
        });
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? message.data['title'] ?? 'New client lead assigned';
        final body = message.notification?.body ?? message.data['message'] ?? '';
        AppNotifierService.notify(
          title: title,
          message: body,
          type: message.data['type']?.toString() ?? 'lead_assigned',
          route: message.data['route']?.toString() ?? '/requirements?group=assigned',
          data: message.data,
        );
        showOsNotification(title: title, body: body, payload: message.data['route']?.toString());
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppNotifierService.handleNotificationTap({
          'id': message.data['id'],
          'type': message.data['type'] ?? 'lead_assigned',
          'route': message.data['route'] ?? '/requirements?group=assigned',
        });
      });
    } catch (e) {
      debugPrint('[PushNotificationService] FCM listeners skipped: $e');
    }

    await registerCurrentUser();
  }

  static Future<void> registerCurrentUser() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await DioClient.dio.post('/notifications/device-token', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      messaging.onTokenRefresh.listen((newToken) {
        DioClient.dio.post('/notifications/device-token', data: {
          'token': newToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }).catchError((_) => null);
      });
    } catch (e) {
      debugPrint('[PushNotificationService] Token register skipped: $e');
    }
  }

  static Future<void> showOsNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Local notification failed: $e');
    }
  }
}
