import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import 'web_reload.dart';

class UpdateDialog extends StatelessWidget {
  final bool isForceUpdate;
  final String androidLink;
  final String iosLink;
  final VoidCallback onDismiss;
  final String? newVersion;
  final String? releaseNotes;

  static const String defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.nbpropertytech.propkart';
  static const String defaultPlayStoreMarketUri =
      'market://details?id=com.nbpropertytech.propkart';

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    required this.androidLink,
    required this.iosLink,
    required this.onDismiss,
    this.newVersion,
    this.releaseNotes,
  });

  Future<void> _handleUpdateAction(BuildContext context) async {
    if (kIsWeb) {
      reloadWeb();
      return;
    }

    String storeUrl = defaultPlayStoreUrl;
    if (Platform.isAndroid) {
      storeUrl = (androidLink.isNotEmpty && androidLink != 'comingsoon')
          ? androidLink
          : defaultPlayStoreUrl;

      // On Android mobile devices, try opening directly in Google Play Store app first
      final marketUri = Uri.parse(defaultPlayStoreMarketUri);
      try {
        if (await canLaunchUrl(marketUri)) {
          await launchUrl(marketUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    } else if (Platform.isIOS) {
      storeUrl = iosLink;
    }

    if (storeUrl == 'comingsoon') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.hourglass_empty_rounded, color: AppColors.brandGreenHighlight),
              const SizedBox(width: AppSpacing.s),
              const Text(
                'Coming Soon on App Store / Play Store!',
              ),
            ],
          ),
          backgroundColor: AppColors.darkSlate,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final Uri url = Uri.parse(storeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the Google Play Store page.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const playStoreGreen = Color(0xFF01875F);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xFF1E293B),
      elevation: 20,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning/Store Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isForceUpdate ? CRMColors.danger : playStoreGreen).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isForceUpdate ? CRMColors.danger : playStoreGreen).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isForceUpdate ? Icons.system_update_rounded : Icons.shop_two_rounded,
                color: isForceUpdate ? CRMColors.danger : const Color(0xFF10B981),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              isForceUpdate ? 'Critical Update Required' : 'New Update Available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),

            // Version tag if provided
            if (newVersion != null && newVersion!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF01875F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF01875F).withOpacity(0.4)),
                ),
                child: Text(
                  'v$newVersion on Google Play',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Body description
            Text(
              isForceUpdate
                  ? 'A critical update is required to continue using PropKart. Please update to the latest version on the Google Play Store.'
                  : (releaseNotes != null && releaseNotes!.isNotEmpty)
                      ? releaseNotes!
                      : 'A new version of PropKart is available with performance improvements and bug fixes. Would you like to update now?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons Row: Cancel and Update Now
            Row(
              children: [
                if (!isForceUpdate) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onDismiss,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF01875F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleUpdateAction(context),
                    child: const Text(
                      'Update Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
