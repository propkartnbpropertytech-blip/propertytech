import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final String title;

  const CRMErrorState({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.title = 'Something went wrong',
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
                Icons.error_outline_rounded,
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
                errorMessage,
                style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: CRMSpacing.l),
              CRMButton(
                label: 'Retry Connection',
                onPressed: onRetry!,
                variant: CRMButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
