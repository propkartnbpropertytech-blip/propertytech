// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';

class RoakbotService {
  static const String botId = 'bot_fc456356';
  static const String widgetUrl = 'https://roakbot.web.app/widget?botId=bot_fc456356';

  static bool get isWebWidgetAvailable => true;

  static Future<void> open() async {
    final launcher = html.document.getElementById('roakbot-launcher');
    final container = html.document.getElementById('roakbot-container');

    if (launcher != null) {
      if (container != null && !container.classes.contains('roakbot-open')) {
        launcher.click();
        return;
      } else if (container != null && container.classes.contains('roakbot-open')) {
        return;
      } else {
        launcher.click();
        return;
      }
    }

    final uri = Uri.parse(widgetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  static Future<void> toggle() async {
    final launcher = html.document.getElementById('roakbot-launcher');
    if (launcher != null) {
      launcher.click();
      return;
    }

    await open();
  }

  static Future<void> close() async {
    final launcher = html.document.getElementById('roakbot-launcher');
    final container = html.document.getElementById('roakbot-container');
    if (launcher != null && container != null && container.classes.contains('roakbot-open')) {
      launcher.click();
    }
  }
}
