class PushNotificationService {
  static Future<void> initialize() async {}

  static Future<void> registerCurrentUser() async {}

  static Future<void> showOsNotification({
    required String title,
    required String body,
    String? payload,
    String? type,
  }) async {}
}
