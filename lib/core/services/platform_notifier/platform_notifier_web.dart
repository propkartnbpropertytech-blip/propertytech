// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class PlatformNotifier {
  static Future<bool> requestPermission() async {
    try {
      if (!html.Notification.supported) return false;
      if (html.Notification.permission == 'granted') return true;
      if (html.Notification.permission == 'denied') return false;

      final perm = await html.Notification.requestPermission();
      return perm == 'granted';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isPermissionGranted() async {
    try {
      if (!html.Notification.supported) return false;
      return html.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void showNotification({
    required String title,
    required String body,
    String? icon,
    VoidCallback? onClick,
    dynamic data,
  }) {
    try {
      if (!html.Notification.supported) return;
      if (html.Notification.permission != 'granted') return;

      final notifIcon = icon ?? 'assets/assets/logo.png';
      final notif = html.Notification(
        title,
        body: body,
        icon: notifIcon,
      );

      if (onClick != null) {
        notif.onClick.listen((_) {
          try {
            (html.window as dynamic).focus();
          } catch (_) {}
          onClick();
          try {
            notif.close();
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('[PlatformNotifierWeb] Error displaying notification: $e');
    }
  }
}
