import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Shared page header matching the shell/dashboard brand language.
class CRMPageHeader extends StatelessWidget {
  final String title;
  final String benefit;
  final String? eyebrow;
  final Widget? trailing;
  final List<Widget>? breadcrumbs;

  const CRMPageHeader({
    super.key,
    required this.title,
    required this.benefit,
    this.eyebrow,
    this.trailing,
    this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumbs != null) ...[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: breadcrumbs!,
          ),
          const SizedBox(height: CRMSpacing.m),
        ],
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: CRMTypography.captionBold.copyWith(
              color: CRMColors.primaryOf(context),
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: CRMSpacing.xs),
        ],
        Text(
          title,
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.textOf(context),
            fontSize: isMobile ? 22 : 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          benefit,
          style: CRMTypography.benefit.copyWith(
            color: CRMColors.textSecondaryOf(context),
            fontSize: isMobile ? 12 : 13,
          ),
        ),
      ],
    );

    if (trailing == null || isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          if (trailing != null) ...[
            const SizedBox(height: CRMSpacing.m),
            trailing!,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: CRMSpacing.m),
        trailing!,
      ],
    );
  }
}
