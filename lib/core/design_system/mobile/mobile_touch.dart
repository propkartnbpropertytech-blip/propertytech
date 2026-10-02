import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import 'mobile_layout.dart';

/// Icon action with a 48×48 hit area, a tooltip, and a semantics label.
/// The visual icon keeps its own size; the hit area comes from constraints.
class MobileIconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? color;
  final int? badgeCount;
  final bool selected;

  const MobileIconAction({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.iconSize = 24,
    this.color,
    this.badgeCount,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final resolvedColor = color ??
        (enabled
            ? CRMColors.textOf(context)
            : CRMColors.textMutedOf(context));
    final count = badgeCount ?? 0;

    Widget glyph = Icon(icon, size: iconSize, color: resolvedColor);
    if (count > 0) {
      glyph = Badge(
        label: Text(count > 99 ? '99+' : '$count'),
        child: glyph,
      );
    }

    final semanticsLabel = count > 0 ? '$label, $count new' : label;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onPressed,
          radius: MobileLayout.minTouchTarget / 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: MobileLayout.minTouchTarget,
              minHeight: MobileLayout.minTouchTarget,
            ),
            child: Center(child: glyph),
          ),
        ),
      ),
    );
  }
}

/// Wraps any child so its effective hit area is at least 48×48 and it is
/// announced as a button with [label].
class MobileTapTarget extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const MobileTapTarget({
    super.key,
    required this.child,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: MobileLayout.minTouchTarget,
            minHeight: MobileLayout.minTouchTarget,
          ),
          child: child,
        ),
      ),
    );
  }
}
