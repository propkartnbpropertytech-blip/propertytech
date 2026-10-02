import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import 'mobile_layout.dart';
import 'mobile_states.dart';

/// One button in a [MobileStickyActionBar] or [MobileFormActions].
@immutable
class MobileAction {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool enabled;

  const MobileAction({
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
  });

  bool get isActive => enabled && !loading && onPressed != null;
}

/// Bottom-pinned action bar for detail and form screens. Place it in
/// `Scaffold.bottomNavigationBar` (or below the scroll view) so it stays
/// above the keyboard; the bottom safe area is dropped while typing.
class MobileStickyActionBar extends StatelessWidget {
  final MobileAction primary;
  final MobileAction? secondary;

  const MobileStickyActionBar({
    super.key,
    required this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe =
        keyboardOpen ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: CRMColors.surfaceOf(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
        ),
        padding: EdgeInsets.fromLTRB(
          CRMSpacing.m,
          CRMSpacing.s,
          CRMSpacing.m,
          CRMSpacing.s + bottomSafe,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: MobileLayout.contentMaxWidth),
            child: Row(
              children: [
                if (secondary != null) ...[
                  Expanded(child: MobileActionButton.secondary(secondary!)),
                  const SizedBox(width: CRMSpacing.s),
                ],
                Expanded(child: MobileActionButton.primary(primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width 48px button that shows an inline loader while [MobileAction.loading].
class MobileActionButton extends StatelessWidget {
  final MobileAction action;
  final bool isPrimary;

  const MobileActionButton.primary(this.action, {super.key})
      : isPrimary = true;

  const MobileActionButton.secondary(this.action, {super.key})
      : isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final onPressed = action.isActive ? action.onPressed : null;
    final child = action.loading
        ? MobileButtonLoader(
            color: isPrimary ? CRMColors.onStrongOf(context) : null,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.icon != null) ...[
                Icon(action.icon, size: 20),
                const SizedBox(width: CRMSpacing.xs),
              ],
              Flexible(
                child: Text(action.label, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
    const minSize = Size.fromHeight(MobileLayout.minTouchTarget);

    return Semantics(
      button: true,
      enabled: action.isActive,
      label: action.loading ? '${action.label}, in progress' : action.label,
      excludeSemantics: true,
      child: isPrimary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(minimumSize: minSize),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(minimumSize: minSize),
              child: child,
            ),
    );
  }
}
