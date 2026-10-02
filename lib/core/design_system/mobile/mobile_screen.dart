import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../tokens/app_colors.dart';
import 'mobile_layout.dart';
import 'mobile_top_bar.dart';

/// Back behavior for mobile screens, on top of the existing navigators.
///
/// Pops the nearest route when one can be popped (respecting `PopScope`);
/// otherwise goes to [fallback] through GoRouter. Never creates a navigator.
class MobileBackNavigation {
  MobileBackNavigation._();

  static Future<void> back(
    BuildContext context, {
    String fallback = '/dashboard',
  }) async {
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      await navigator.maybePop();
      return;
    }
    GoRouter.maybeOf(context)?.go(fallback);
  }
}

/// Supplies a custom title to the shell top bar while mounted (detail pages,
/// record names). Outside the shell it renders [child] only.
///
/// Root tabs and More-owned pages should not use it; their titles come from
/// `MobileNavConfig.resolve()`.
class MobileShellTitle extends StatefulWidget {
  final String title;
  final Widget child;

  const MobileShellTitle({super.key, required this.title, required this.child});

  @override
  State<MobileShellTitle> createState() => _MobileShellTitleState();
}

class _MobileShellTitleState extends State<MobileShellTitle> {
  MobileTitleController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = MobileShellScope.titleControllerOf(context);
    if (!identical(next, _controller)) {
      _release(_controller);
      _controller = next;
      _claim();
    }
  }

  @override
  void didUpdateWidget(MobileShellTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) _claim();
  }

  @override
  void dispose() {
    _release(_controller);
    super.dispose();
  }

  void _claim() {
    final controller = _controller;
    if (controller == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(controller, _controller)) {
        controller.claim(this, widget.title);
      }
    });
  }

  void _release(MobileTitleController? controller) {
    if (controller == null) return;
    // Disposal runs while the tree is locked; notify after the frame.
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => controller.release(this),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Layout-only page frame for migrated mobile screens.
///
/// ```text
/// MobileScreenScaffold
///  ├── banner   (e.g. MobileOfflineBanner)       pinned
///  ├── header   (e.g. MobileSearch field, chips)  pinned
///  ├── body     (MobileContent or MobileList)     scrolls
///  └── bottomAction (MobileStickyActionBar)       above keyboard
/// ```
///
/// Inside `MobileAppShell` it draws no top bar (the shell owns it; [title]
/// becomes a [MobileShellTitle]) and adds no bottom-nav clearance. Outside
/// the shell it draws a [MobileTopBar] with Back and applies the bottom safe
/// area through [MobileContent] / [bottomAction].
///
/// It never fetches data and knows nothing about roles, records, or statuses.
class MobileScreenScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? banner;
  final Widget? header;
  final Widget? bottomAction;
  final Widget? floatingAction;

  /// Wraps [body] in a scrolling [MobileContent]. Set false when [body]
  /// scrolls itself (e.g. [MobileList]).
  final bool scrollable;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;
  final bool centered;
  final ScrollController? controller;

  /// Top-bar actions; only used outside the shell.
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final String backFallback;

  const MobileScreenScaffold({
    super.key,
    required this.body,
    this.title,
    this.banner,
    this.header,
    this.bottomAction,
    this.floatingAction,
    this.scrollable = true,
    this.onRefresh,
    this.padding,
    this.centered = true,
    this.controller,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.backFallback = '/dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final inShell = MobileShellScope.isInShell(context);

    final content = scrollable
        ? MobileContent(
            onRefresh: onRefresh,
            padding: padding,
            centered: centered,
            controller: controller,
            child: body,
          )
        : body;

    Widget scaffold = Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      appBar: inShell
          ? null
          : MobileTopBar(
              title: title ?? '',
              leading: showBack
                  ? MobileTopBar.backAction(
                      context,
                      onPressed:
                          onBack ??
                          () => MobileBackNavigation.back(
                            context,
                            fallback: backFallback,
                          ),
                    )
                  : null,
              actions: actions,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?banner,
          ?header,
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: bottomAction,
      floatingActionButton: floatingAction,
    );

    if (inShell && title != null) {
      scaffold = MobileShellTitle(title: title!, child: scaffold);
    }
    return scaffold;
  }
}
