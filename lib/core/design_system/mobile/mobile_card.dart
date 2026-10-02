import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';

/// Generic record card. All text and widgets come from the caller so the same
/// card can later present leads, properties, people, callbacks, or reports.
class MobileCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Third line, e.g. "BHK · area · type". Joined with " · ".
  final List<String> metadata;

  /// Status chip or badge, top-aligned on the trailing edge.
  final Widget? status;

  /// Trailing action (e.g. a [MobileIconAction]); must be ≥48×48 itself.
  final Widget? trailing;
  final Widget? footer;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Overrides the announced label; defaults to title, subtitle, metadata.
  final String? semanticLabel;

  const MobileCard({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.metadata = const [],
    this.status,
    this.trailing,
    this.footer,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = CRMColors.primaryOf(context);
    final meta = metadata.where((m) => m.isNotEmpty).join(' · ');
    final label = semanticLabel ??
        [title, subtitle, meta].where((s) => s != null && s.isNotEmpty).join(', ');

    return Semantics(
      container: true,
      button: onTap != null,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? primary.withValues(alpha: 0.08)
            : CRMColors.surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          side: BorderSide(
            color: selected ? primary : CRMColors.borderOf(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: MobileLayout.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: CRMSpacing.s),
                      ],
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: CRMTypography.cardTitle.copyWith(
                                  color: CRMColors.textOf(context),
                                ),
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty) ...[
                                const SizedBox(height: CRMSpacing.xxs),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CRMTypography.subheadline.copyWith(
                                    color: CRMColors.textOf(context),
                                  ),
                                ),
                              ],
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: CRMSpacing.xxs),
                                Text(
                                  meta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CRMTypography.caption.copyWith(
                                    color: CRMColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: CRMSpacing.xs),
                        status!,
                      ],
                      ?trailing,
                    ],
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: CRMSpacing.s),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
