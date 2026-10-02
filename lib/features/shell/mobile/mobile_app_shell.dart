import 'package:flutter/material.dart';

import '../../../core/design_system/mobile/mobile_bottom_nav.dart';
import '../../../core/design_system/mobile/mobile_layout.dart';
import '../../../core/design_system/mobile/mobile_list.dart';
import '../../../core/design_system/mobile/mobile_sheets.dart';
import '../../../core/design_system/mobile/mobile_top_bar.dart';
import '../../../core/design_system/mobile/mobile_touch.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/security/role_guard.dart';
import 'mobile_nav_config.dart';

/// Existing badge counts made available to routed mobile pages (e.g. More)
/// without another fetch.
class MobileShellBadges extends InheritedWidget {
  final int unreadNotifications;
  final int unreadMessages;

  const MobileShellBadges({
    super.key,
    required this.unreadNotifications,
    required this.unreadMessages,
    required super.child,
  });

  static MobileShellBadges? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MobileShellBadges>();

  @override
  bool updateShouldNotify(MobileShellBadges oldWidget) =>
      unreadNotifications != oldWidget.unreadNotifications ||
      unreadMessages != oldWidget.unreadMessages;
}

/// Mobile chrome for widths below [CRMBreakpoints.tablet]: top bar (Back,
/// title, role control, Search, Notifications, More actions), routed content,
/// and bottom navigation.
///
/// Owns layout and navigation presentation only. Every action is a callback
/// into existing `CRMAppShell` behavior (search overlay, notifications panel,
/// quick-actions sheet, router).
class MobileAppShell extends StatefulWidget {
  /// Below this width a Telecaller's Search moves into More actions so the
  /// availability toggle, title, and 48px actions fit.
  static const double telecallerCompactWidth = 412;

  final Widget child;
  final String role;
  final String location;
  final RouteVisibility? canView;

  final ValueChanged<String> onNavigate;
  final ValueChanged<String> onBack;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onQuickActions;
  final VoidCallback onMessages;
  final int unreadNotifications;
  final int unreadMessages;
  final Widget? roleControl;

  /// When non-null, replaces the top bar (search mode).
  final PreferredSizeWidget? searchBar;

  const MobileAppShell({
    super.key,
    required this.child,
    required this.role,
    required this.location,
    required this.onNavigate,
    required this.onBack,
    required this.onSearch,
    required this.onNotifications,
    required this.onQuickActions,
    required this.onMessages,
    this.canView,
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
    this.roleControl,
    this.searchBar,
  });

  @override
  State<MobileAppShell> createState() => _MobileAppShellState();
}

class _MobileAppShellState extends State<MobileAppShell> {
  final MobileTitleController _titleController = MobileTitleController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final location = widget.location;
    final canView = widget.canView;
    final onSearch = widget.onSearch;
    final onQuickActions = widget.onQuickActions;
    final onMessages = widget.onMessages;
    final unreadMessages = widget.unreadMessages;
    final width = CRMBreakpoints.widthOf(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final tabs = MobileNavConfig.tabsForRole(role, canView: canView);
    final info = MobileNavConfig.resolve(role, location, canView: canView);
    final showNav = tabs.isNotEmpty && !keyboardOpen;
    final clearance = showNav
        ? CRMBreakpoints.mobileNavClearance(context)
        : 0.0;
    final searchInOverflow =
        RoleGuard.isTelecaller(role) && width < MobileAppShell.telecallerCompactWidth;

    final overflow = <_OverflowAction>[
      if (searchInOverflow)
        _OverflowAction('search', 'Search', Icons.search_rounded, onSearch),
      _OverflowAction(
        'quick_actions',
        'Quick actions',
        Icons.add_circle_outline_rounded,
        onQuickActions,
      ),
      _OverflowAction(
        'messages',
        'Messages',
        Icons.chat_bubble_outline_rounded,
        onMessages,
        badgeCount: unreadMessages,
      ),
    ];

    final topBar =
        widget.searchBar ??
        PreferredSize(
          preferredSize: const Size.fromHeight(MobileLayout.topBarHeight),
          child: ListenableBuilder(
            listenable: _titleController,
            builder: (context, _) => MobileTopBar(
              title: _titleController.title ?? info.title,
              leading: info.isSecondary
                  ? MobileTopBar.backAction(
                      context,
                      onPressed: () => widget.onBack(info.backFallback),
                    )
                  : null,
              roleControl: widget.roleControl,
              actions: [
                if (!searchInOverflow)
                  MobileIconAction(
                    key: const Key('mobile_search_action'),
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onPressed: onSearch,
                  ),
                MobileIconAction(
                  key: const Key('mobile_notifications_action'),
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  badgeCount: widget.unreadNotifications,
                  onPressed: widget.onNotifications,
                ),
                MobileIconAction(
                  key: const Key('mobile_more_actions'),
                  icon: Icons.more_vert_rounded,
                  label: 'More actions',
                  badgeCount: unreadMessages,
                  onPressed: () => _openOverflow(context, overflow),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      extendBody: true,
      appBar: topBar,
      // The shell owns bottom clearance (K1): content gets the nav clearance
      // once, and its MediaQuery carries no bottom padding/view padding, so
      // routed screens' SafeArea(bottom) does not add a second copy.
      body: Builder(
        builder: (bodyContext) => MediaQuery(
          data: MediaQuery.of(bodyContext)
              .removePadding(removeBottom: true)
              .removeViewPadding(removeBottom: true),
          child: MobileShellScope(
            titleController: _titleController,
            child: MobileShellBadges(
              unreadNotifications: widget.unreadNotifications,
              unreadMessages: unreadMessages,
              child: Padding(
                padding: EdgeInsets.only(bottom: clearance),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: showNav
          ? MobileBottomNav(
              items: tabs,
              selectedIndex: info.selectedIndex,
              onSelected: (index) {
                final route = tabs[index].route;
                if (location != route) widget.onNavigate(route);
              },
            )
          : null,
    );
  }

  Future<void> _openOverflow(
    BuildContext context,
    List<_OverflowAction> actions,
  ) async {
    final id = await MobileSheet.show<String>(
      context,
      title: 'More actions',
      maxHeightFactor: 0.6,
      child: Builder(
        builder: (sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in actions)
              MobileListItem(
                key: ValueKey('overflow_${a.id}'),
                icon: a.icon,
                title: a.label,
                badgeCount: a.badgeCount,
                showChevron: false,
                onTap: () => Navigator.of(sheetContext).pop(a.id),
              ),
          ],
        ),
      ),
    );
    if (id == null) return;
    for (final a in actions) {
      if (a.id == id) {
        a.onSelected();
        return;
      }
    }
  }
}

class _OverflowAction {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final int badgeCount;

  const _OverflowAction(
    this.id,
    this.label,
    this.icon,
    this.onSelected, {
    this.badgeCount = 0,
  });
}
