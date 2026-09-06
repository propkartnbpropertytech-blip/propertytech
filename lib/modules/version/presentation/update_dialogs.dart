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

  const UpdateDialog({
    super.key,
    required this.isForceUpdate,
    required this.androidLink,
    required this.iosLink,
    required this.onDismiss,
  });

  Future<void> _handleUpdateAction(BuildContext context) async {
    if (kIsWeb) {
      reloadWeb();
      return;
    }

    String storeUrl = "comingsoon";
    if (Platform.isAndroid) storeUrl = androidLink;
    if (Platform.isIOS) storeUrl = iosLink;

    if (storeUrl == "comingsoon") {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch the download page.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
      ),
      backgroundColor: AppColors.darkSlate,
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: (isForceUpdate ? CRMColors.danger : AppColors.brandGreen).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isForceUpdate ? Icons.system_update_rounded : Icons.info_outline_rounded,
                color: isForceUpdate ? CRMColors.danger : AppColors.brandGreenHighlight,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            // Header
            Text(
              isForceUpdate ? 'Critical Update Required' : 'New Update Available',
              textAlign: TextAlign.center,
              style: CRMTypography.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            // Body description
            Text(
              isForceUpdate
                  ? 'A critical update is required to continue using PropKart. Please update to the latest version.'
                  : 'A new version of PropKart is available with performance improvements and bug fixes. Would you like to update now?',
              textAlign: TextAlign.center,
              style: CRMTypography.body.copyWith(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Buttons Row
            Row(
              children: [
                if (!isForceUpdate) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppColors.textMuted.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: onDismiss,
                      child: Text(
                        'Later',
                        style: CRMTypography.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _handleUpdateAction(context),
                    child: Text(
                      'Update Now',
                      style: CRMTypography.button.copyWith(color: Colors.white),
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
