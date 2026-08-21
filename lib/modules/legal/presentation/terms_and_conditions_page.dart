import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/tokens/app_colors.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchInAppBrowser();
    });
  }

  Future<void> _launchInAppBrowser() async {
    final url = Uri.parse('https://propkart.wuaze.com/?i=1#terms-conditions');
    try {
      await launchUrl(url, mode: LaunchMode.inAppWebView);
    } catch (_) {
      // Fail silently
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.background,
      body: Center(
        child: CircularProgressIndicator(color: CRMColors.primary),
      ),
    );
  }
}
