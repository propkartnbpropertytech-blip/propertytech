import 'package:url_launcher/url_launcher.dart';

class RoakbotService {
  static const String botId = 'bot_84ce2455';
  static const String widgetUrl = 'https://roakbot.web.app/widget?botId=bot_84ce2455';

  static bool get isWebWidgetAvailable => false;

  static Future<void> open() async {
    final uri = Uri.parse(widgetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> toggle() async {
    await open();
  }

  static Future<void> close() async {
    // Non-web no-op
  }
}
