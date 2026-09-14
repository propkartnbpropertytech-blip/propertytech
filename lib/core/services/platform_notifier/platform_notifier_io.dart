import 'package:flutter/foundation.dart';

class PlatformNotifier {
  static Future<bool> requestPermission() async {
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
    // On native mobile & desktop, notifications are surfaced cleanly via in-app toast overlays
    // and can be hooked into native OS notification center as needed.
  }
}
