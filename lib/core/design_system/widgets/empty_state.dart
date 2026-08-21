import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const CRMEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.folder_open_rounded,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CRMColors.primaryOf(context).withValues(alpha: 0.16),
                    CRMColors.primaryOf(context).withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CRMColors.primaryOf(context).withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                color: CRMColors.primaryOf(context),
                size: 36,
              ),
            ),
            const SizedBox(height: CRMSpacing.l),
            Text(
              title,
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CRMSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                description,
                style: CRMTypography.benefit.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: CRMSpacing.l),
              CRMButton(
                label: actionLabel!,
                onPressed: onActionPressed!,
                variant: CRMButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
