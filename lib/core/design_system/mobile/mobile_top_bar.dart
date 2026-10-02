import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';
import 'mobile_touch.dart';

/// 56px mobile top bar: leading, page title, role-control slot, actions.
///
/// [roleControl] hosts role-specific controls such as the existing
/// `TelecallerAvailabilityToggle(compact: true)`; it scales down rather than
/// overflowing. Actions keep their 48×48 targets — callers move extra actions
/// into an overflow instead of shrinking them.
class MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? roleControl;

  const MobileTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.roleControl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(MobileLayout.topBarHeight);

  /// Standard back action for pushed screens.
  static Widget backAction(BuildContext context, {VoidCallback? onPressed}) {
    return MobileIconAction(
      icon: Icons.arrow_back_rounded,
      label: 'Back',
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MobileBarFrame(
      child: Row(
        children: [
          if (leading != null)
            leading!
          else
            const SizedBox(width: CRMSpacing.m),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CRMTypography.title.copyWith(
                  fontSize: 20,
                  color: CRMColors.textOf(context),
                ),
              ),
            ),
          ),
          if (roleControl != null) ...[
            const SizedBox(width: CRMSpacing.xs),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: roleControl,
              ),
            ),
          ],
          ...actions,
          const SizedBox(width: CRMSpacing.xxs),
        ],
      ),
    );
  }
}

/// Search mode of the mobile top bar: Back, a 48px field, and Clear.
///
/// The field is driven by the caller's controller/focus node and existing
/// search handlers; [layerLink] anchors the caller's results overlay.
class MobileSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClose;
  final VoidCallback onClear;
  final LayerLink? layerLink;
  final String hintText;

  const MobileSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClose,
    required this.onClear,
    this.focusNode,
    this.onSubmitted,
    this.layerLink,
    this.hintText = 'Search properties, leads, or locations',
  });

  @override
  Size get preferredSize => const Size.fromHeight(MobileLayout.topBarHeight);

  @override
  Widget build(BuildContext context) {
    Widget field = SizedBox(
      height: MobileLayout.minTouchTarget,
      child: Semantics(
        textField: true,
        label: 'Search',
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: CRMTypography.body.copyWith(
            fontSize: 16,
            color: CRMColors.textOf(context),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.s,
              vertical: CRMSpacing.s,
            ),
          ),
        ),
      ),
    );
    if (layerLink != null) {
      field = CompositedTransformTarget(link: layerLink!, child: field);
    }

    return _MobileBarFrame(
      child: Row(
        children: [
          MobileIconAction(
            icon: Icons.arrow_back_rounded,
            label: 'Close search',
            onPressed: onClose,
          ),
          Expanded(child: field),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox(width: CRMSpacing.xs)
                : MobileIconAction(
                    icon: Icons.close_rounded,
                    label: 'Clear search',
                    iconSize: 20,
                    onPressed: onClear,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobileBarFrame extends StatelessWidget {
  final Widget child;

  const _MobileBarFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Material(
      color: CRMColors.surfaceOf(context),
      child: Container(
        padding: EdgeInsets.only(top: topInset),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CRMColors.borderOf(context)),
          ),
        ),
        child: SizedBox(height: MobileLayout.topBarHeight, child: child),
      ),
    );
  }
}
