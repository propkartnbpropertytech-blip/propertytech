import 'package:flutter/foundation.dart';

class PlatformNotifier {
  static Future<bool> requestPermission() async {
    return false;
  }

  static Future<bool> isPermissionGranted() async {
    return false;
  }

  static void showNotification({
    required String title,
    required String body,
    String? icon,
    VoidCallback? onClick,
    dynamic data,
  }) {}
}
