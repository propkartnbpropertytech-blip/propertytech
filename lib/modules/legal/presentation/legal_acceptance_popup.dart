import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/legal_service.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/theme/app_theme.dart';

class LegalAcceptancePopup extends StatefulWidget {
  final String userId;
  final int latestTermsVersion;
  final int latestPrivacyVersion;
  final String clientVersion;
  final VoidCallback onAccepted;

  const LegalAcceptancePopup({
    super.key,
    required this.userId,
    required this.latestTermsVersion,
    required this.latestPrivacyVersion,
    required this.clientVersion,
    required this.onAccepted,
  });

  @override
  State<LegalAcceptancePopup> createState() => _LegalAcceptancePopupState();
}

class _LegalAcceptancePopupState extends State<LegalAcceptancePopup> {
  bool _isSubmitting = false;
  final LegalService _legalService = LegalService();

  Future<void> _handleAccept() async {
    setState(() {
      _isSubmitting = true;
    });

    final success = await _legalService.saveUserAcceptance(
      userId: widget.userId,
      acceptedTerms: true,
      acceptedPrivacy: true,
      termsVersion: widget.latestTermsVersion,
      privacyVersion: widget.latestPrivacyVersion,
      appVersion: widget.clientVersion,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        widget.onAccepted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save agreement. Please check connection and try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
      ),
      backgroundColor: AppColors.darkSlate,
      elevation: 20,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: AppColors.brandGreenHighlight,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            // Header
            Text(
              'We updated our policies',
              textAlign: TextAlign.center,
              style: CRMTypography.sectionTitle.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            // Subtitle
            Text(
              'Please review and accept our updated terms and privacy policies to continue using the application.',
              textAlign: TextAlign.center,
              style: CRMTypography.body.copyWith(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            // Policy version display list
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandGreen.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  _buildPolicyRow(
                    context,
                    title: 'Terms & Conditions',
                    version: widget.latestTermsVersion,
                    route: '/terms-and-conditions',
                  ),
                  const Divider(color: Colors.white10),
                  _buildPolicyRow(
                    context,
                    title: 'Privacy Policy',
                    version: widget.latestPrivacyVersion,
                    route: '/privacy-policy',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // Accept Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _isSubmitting ? null : _handleAccept,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Accept & Continue',
                      style: CRMTypography.button.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyRow(
    BuildContext context, {
    required String title,
    required int version,
    required String route,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: CRMTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Version $version',
              style: CRMTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: AppColors.brandGreenHighlight),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          onPressed: () {
            context.push(route);
          },
        ),
      ],
    );
  }
}
