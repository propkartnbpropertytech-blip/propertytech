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
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(color: gold.withValues(alpha: 0.32), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: gold.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.18),
          child: Image.asset(
            'assets/branding/brand_mark.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.apartment_rounded,
              color: gold,
              size: size * 0.55,
            ),
          ),
        ),
        if (expanded) ...[
          SizedBox(width: compact ? CRMSpacing.s : CRMSpacing.m),
          Flexible(
            child: Text(
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
          ),
        ],
      ],
    );
  }
}
