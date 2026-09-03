import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// PropKart brand lockup — logo mark + wordmark for shell surfaces.
class CRMBrandLockup extends StatelessWidget {
  final bool expanded;
  final bool compact;
  final Color? wordmarkColor;
  final double markSize;

  const CRMBrandLockup({
    super.key,
    this.expanded = true,
    this.compact = false,
    this.wordmarkColor,
    this.markSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final gold = CRMColors.primaryOf(context);
    final textColor = wordmarkColor ?? CRMColors.textOf(context);
    final size = compact ? 28.0 : markSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gold.withValues(alpha: 0.22),
                gold.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(CRMBorderRadius.s + 2),
            border: Border.all(color: gold.withValues(alpha: 0.35), width: 0.8),
          ),
          padding: EdgeInsets.all(compact ? 4 : 6),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.apartment_rounded,
              color: gold,
              size: size * 0.7,
            ),
          ),
        ),
        if (expanded) ...[
          SizedBox(width: compact ? CRMSpacing.s : CRMSpacing.m),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PropKart',
                  style: CRMTypography.brandMark.copyWith(
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.2,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact)
                  Text(
                    '',
                    style: CRMTypography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.55),
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
