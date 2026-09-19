import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/dio_client.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_typography.dart';
import '../navigation/app_router.dart';
import 'notification_center.dart';
import 'platform_notifier/platform_notifier.dart';

class AppNotifierService {
  static final AppNotifierService _instance = AppNotifierService._internal();
  factory AppNotifierService() => _instance;
  AppNotifierService._internal();

  static const String _kWelcomeShownKey = 'propkart_welcome_notification_sent';
  static OverlayEntry? _currentToastEntry;
  static Timer? _dismissTimer;

  /// Request browser notification permission on platforms that support it (Web)
  /// and automatically dispatch the welcome notification when granted.
  static Future<bool> requestPermission({bool forceWelcome = false}) async {
    try {
      final wasGranted = await PlatformNotifier.isPermissionGranted();
      final granted = await PlatformNotifier.requestPermission();

      if (granted) {
        final prefs = await SharedPreferences.getInstance();
        final alreadyWelcomed = prefs.getBool(_kWelcomeShownKey) ?? false;

        // If newly allowed (wasn't granted before), or never welcomed yet, or forced:
        if (!wasGranted || !alreadyWelcomed || forceWelcome) {
          await prefs.setBool(_kWelcomeShownKey, true);
          sendWelcomeNotification();
        }
      } else {
        // If permission was revoked or blocked, reset flag so next time allowed it welcomes again
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kWelcomeShownKey, false);
      }
      return granted;
    } catch (e) {
      debugPrint('[AppNotifierService] requestPermission error: $e');
      return false;
    }
  }

  /// Initialize notifier on app launch
  static Future<void> init() async {
    try {
      await requestPermission();
    } catch (_) {}
  }

  /// Checks if permission was granted externally (e.g. browser site settings lock icon)
  /// and triggers welcome notification if not yet shown.
  static Future<void> checkAndTriggerWelcomeIfNewlyGranted() async {
    try {
      final isGranted = await PlatformNotifier.isPermissionGranted();
      final prefs = await SharedPreferences.getInstance();
      final alreadyWelcomed = prefs.getBool(_kWelcomeShownKey) ?? false;

      if (isGranted) {
        if (!alreadyWelcomed) {
          await prefs.setBool(_kWelcomeShownKey, true);
          sendWelcomeNotification();
        }
      } else {
        if (alreadyWelcomed) {
          await prefs.setBool(_kWelcomeShownKey, false);
        }
      }
    } catch (_) {}
  }

  /// Sends the official "Welcome to PropKart" notification across browser & in-app toast
  static void sendWelcomeNotification() {
    const title = 'Welcome to PropKart! 🎉';
    const message =
        'Notifications are enabled! You will receive real-time updates for leads, follow-ups, and site visits.';
    final notifId = 'welcome_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Add to local NotificationCenter without duplicate toast
    NotificationCenter.addNotification(
      id: notifId,
      title: title,
      message: message,
      type: 'welcome',
      route: '/requirements',
      notifyToast: false,
    );

    // 2. Dispatch OS/Browser Notification and In-App floating toast banner
    notify(
      title: title,
      message: message,
      type: 'welcome',
      route: '/requirements',
      data: {'id': notifId},
    );
  }

  /// Deep link and handle click on any notification
  static void handleNotificationTap(dynamic notification) {
    if (notification == null) return;

    final String id = (notification['id'] ?? '').toString();
    String type = (notification['type'] ?? '').toString().toLowerCase();
    final String title = (notification['title'] ?? '').toString().toLowerCase();
    final payload = <String, dynamic>{};
    void mergeMap(dynamic value) {
      if (value is Map) {
        payload.addAll(Map<String, dynamic>.from(value));
      }
    }
    mergeMap(notification['payload']);
    mergeMap(notification['data']);
    for (final key in ['requirementId', 'followupId', 'campaignLeadId', 'route', 'type', 'clientName']) {
      final value = notification[key];
      if (value != null && (payload[key] == null || payload[key].toString().isEmpty)) {
        payload[key] = value;
      }
    }
    if (type.isEmpty) {
      type = (payload['type'] ?? '').toString().toLowerCase();
    }
    if (type.isEmpty && title.contains('assigned')) {
      type = 'lead_assigned';
    }
    final String? explicitRoute = notification['route']?.toString() ?? payload['route']?.toString();

    // Mark as read in background
    if (id.isNotEmpty) {
      if (id.startsWith('local_') || id.startsWith('due_')) {
        NotificationCenter.markAsRead(id);
      } else {
        DioClient.dio
            .patch('/notifications/$id/read')
            .then<dynamic>((_) => null)
            .catchError((_) => null);
      }
    }

    // Resolve target route
    String targetRoute = '/requirements';
    if (explicitRoute != null && explicitRoute.trim().isNotEmpty) {
      targetRoute = explicitRoute.trim();
    } else {
      final openId = (payload['requirementId'] ?? notification['requirementId'] ?? '').toString();
      switch (type) {
        case 'lead_assigned':
          targetRoute = openId.isNotEmpty
              ? '/requirements?openId=${Uri.encodeComponent(openId)}'
              : '/requirements?group=assigned';
          break;
        case 'lead_created':
        case 'new_lead':
          targetRoute = openId.isNotEmpty
              ? '/requirements?openId=${Uri.encodeComponent(openId)}'
              : '/requirements';
          break;
        case 'property_created':
          final propertyId = (payload['propertyId'] ?? notification['propertyId'] ?? '').toString();
          targetRoute = propertyId.isNotEmpty
              ? '/properties?openId=${Uri.encodeComponent(propertyId)}'
              : '/properties';
          break;
        case 'meta_lead':
          targetRoute = '/campaign/leads';
          break;
        case 'due_followup':
        case 'followup':
        case 'site_visit':
          if ((payload['campaignLeadId'] ?? '').toString().isNotEmpty) {
            targetRoute = '/campaign/leads';
          } else {
            targetRoute = openId.isNotEmpty
                ? '/requirements?openId=${Uri.encodeComponent(openId)}&tab=follow-ups&subTab=Today'
                : '/requirements?tab=follow-ups&subTab=Today';
          }
          break;
        case 'team_message':
        case 'message':
          targetRoute = '/messages';
          break;
        default:
          targetRoute = '/requirements';
          break;
      }
    }

    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext != null) {
      try {
        navContext.go(targetRoute);
      } catch (e) {
        debugPrint('[AppNotifierService] Navigation failed: $e');
      }
    }
  }

  static Future<void> notifyLeadAdded({
    required String clientName,
    required String requirementId,
  }) async {
    final name = clientName.trim().isEmpty ? 'a client' : clientName.trim();
    final id = 'lead_created_$requirementId';
    if (NotificationCenter.containsId(id)) return;
    final title = 'Lead added';
    final message = 'You successfully added client "$name".';
    final route = requirementId.isNotEmpty
        ? '/requirements?openId=${Uri.encodeComponent(requirementId)}'
        : '/requirements';
    final payload = {
      'requirementId': requirementId,
      'clientName': name,
      'audience': 'creator',
    };
    await NotificationCenter.addNotification(
      id: id,
      title: title,
      message: message,
      type: 'lead_created',
      route: route,
      payload: payload,
    );
  }

  static Future<void> notifyPropertyAdded({
    required String propertyName,
    required String propertyId,
  }) async {
    final name = propertyName.trim().isEmpty ? 'a property' : propertyName.trim();
    final id = 'property_created_$propertyId';
    if (NotificationCenter.containsId(id)) return;
    final title = 'Property added';
    final message = 'You successfully added property "$name".';
    final route = propertyId.isNotEmpty
        ? '/properties?openId=${Uri.encodeComponent(propertyId)}'
        : '/properties';
    final payload = {
      'propertyId': propertyId,
      'propertyName': name,
      'audience': 'creator',
    };
    await NotificationCenter.addNotification(
      id: id,
      title: title,
      message: message,
      type: 'property_created',
      route: route,
      payload: payload,
    );
  }

  /// Dispatches both Web/Platform OS notification and an In-App floating toast banner
  static void notify({
    required String title,
    required String message,
    String type = 'general',
    String? route,
    dynamic data,
  }) {
    final notifData = {
      'id': data?['id'] ?? 'toast_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'route': route,
      'data': data,
    };

    // 1. Dispatch platform HTML5 notification with PropKart logo
    PlatformNotifier.showNotification(
      title: title,
      body: message,
      icon: 'assets/assets/logo.png',
      onClick: () => handleNotificationTap(notifData),
      data: notifData,
    );

    // 2. Suppressed intrusive 390px overlay popup to avoid blocking user interactions.
    // OS / browser platform notifications are dispatched above.
  }

  /// Displays an animated in-app toast banner (suppressed to prevent blocking top-right UI).
  static void showInAppToast({
    required String title,
    required String message,
    String type = 'general',
    VoidCallback? onTap,
  }) {
    // Dismiss any existing overlay to ensure screen is completely unblocked
    dismissToast();
  }

  static void dismissToast() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentToastEntry != null) {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    }
  }
}
