import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';

/// One bottom-navigation destination. Role/permission filtering happens
/// before items reach [MobileBottomNav] (see `MobileNavConfig`).
@immutable
class MobileNavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;

  /// Extra location prefixes that select this tab (e.g. `/reports`).
  final List<String> matchPrefixes;
  final int badgeCount;
  final bool visible;
  final VoidCallback? onTap;

  const MobileNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.selectedIcon,
    this.matchPrefixes = const [],
    this.badgeCount = 0,
    this.visible = true,
    this.onTap,
  });

  bool matchesLocation(String location) {
    bool match(String p) => location == p || location.startsWith('$p/');
    return match(route) || matchPrefixes.any(match);
  }

  MobileNavItem copyWith({int? badgeCount, bool? visible, VoidCallback? onTap}) {
    return MobileNavItem(
      id: id,
      label: label,
      icon: icon,
      route: route,
      selectedIcon: selectedIcon,
      matchPrefixes: matchPrefixes,
      badgeCount: badgeCount ?? this.badgeCount,
      visible: visible ?? this.visible,
      onTap: onTap ?? this.onTap,
    );
  }
}

/// 64px bottom navigation with 12px labels, 24px icons, ≥48px cells, badges,
/// selected semantics, and an optional center slot (no default action).
class MobileBottomNav extends StatelessWidget {
  static const int maxItems = 5;

  final List<MobileNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Reserved center slot. Step 3.0 provides the slot only.
  final Widget? centerSlot;

  const MobileBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.centerSlot,
  });

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.visible).take(maxItems).toList();
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    final cells = <Widget>[
      for (var i = 0; i < visible.length; i++)
        Expanded(
          child: _MobileNavCell(
            item: visible[i],
            selected: i == selectedIndex,
            onTap: () {
              final item = visible[i];
              if (item.onTap != null) {
                item.onTap!();
              } else {
                onSelected(i);
              }
            },
          ),
        ),
    ];
    if (centerSlot != null) {
      cells.insert(cells.length ~/ 2, Expanded(child: Center(child: centerSlot)));
    }

    return Material(
      color: CRMColors.surfaceOf(context),
      child: Container(
        padding: EdgeInsets.only(bottom: bottomSafe),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
        ),
        child: SizedBox(
          height: MobileLayout.bottomNavHeight,
          child: Row(children: cells),
        ),
      ),
    );
  }
}

class _MobileNavCell extends StatelessWidget {
  final MobileNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MobileNavCell({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CRMColors.primaryOf(context)
        : CRMColors.textSecondaryOf(context);
    final icon = selected ? (item.selectedIcon ?? item.icon) : item.icon;
    final label = item.badgeCount > 0
        ? '${item.label}, ${item.badgeCount} new'
        : item.label;
    final textStyle =
        (selected ? CRMTypography.captionBold : CRMTypography.caption)
            .copyWith(fontSize: 12, color: color);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: MobileLayout.minTouchTarget,
            minHeight: MobileLayout.minTouchTarget,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: item.badgeCount > 0,
                label: Text(item.badgeCount > 99 ? '99+' : '${item.badgeCount}'),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
