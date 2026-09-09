import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Shared page header matching the shell/dashboard brand language.
class CRMPageHeader extends StatelessWidget {
  final String title;
  final String? benefit;
  final String? eyebrow;
  final Widget? trailing;
  final List<Widget>? breadcrumbs;

  const CRMPageHeader({
    super.key,
    required this.title,
    this.benefit,
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
            fontWeight: FontWeight.w700,
          ),
        ),
        if (benefit != null && benefit!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            benefit!,
            style: CRMTypography.caption.copyWith(
              color: CRMColors.textSecondaryOf(context),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );

    if (trailing == null) {
      return titleBlock;
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            width: double.infinity,
            child: trailing!,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: CRMSpacing.s),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: trailing!,
          ),
        ),
      ],
    );
  }
}
