import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMPermissionDenied extends StatelessWidget {
  final VoidCallback? onGoBack;
  final String title;
  final String message;

  const CRMPermissionDenied({
    super.key,
    this.onGoBack,
    this.title = 'Access Restricted',
    this.message =
        'You do not have the required permissions to view this module. Please contact your system administrator.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: CRMColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CRMColors.danger.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                color: CRMColors.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: CRMSpacing.l),
            Text(
              title,
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                textAlign: TextAlign.center,
              ),
            ),
            if (onGoBack != null) ...[
              const SizedBox(height: CRMSpacing.l),
              CRMButton(
                label: 'Go Back',
                onPressed: onGoBack!,
                variant: CRMButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
