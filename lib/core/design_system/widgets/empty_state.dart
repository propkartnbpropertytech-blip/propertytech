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
    this.description = '',
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
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: CRMColors.groupedBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CRMColors.borderOf(context),
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                color: CRMColors.textSecondaryOf(context),
                size: 28,
              ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Text(
              title,
              style: CRMTypography.sectionTitle.copyWith(
                color: CRMColors.textOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: CRMSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  description,
                  style: CRMTypography.benefit.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
