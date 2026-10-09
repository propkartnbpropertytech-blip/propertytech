import 'package:flutter/material.dart';

import '../tokens/app_breakpoints.dart';
import '../tokens/app_spacing.dart';

/// Width bands inside and around the mobile shell. All boundaries come from
/// [CRMBreakpoints]; no other breakpoint values are allowed in mobile code.
enum MobileWidthClass {
  /// Below [CRMBreakpoints.phone] (e.g. 320).
  compact,

  /// [CRMBreakpoints.phone] up to [CRMBreakpoints.phablet].
  phone,

  /// [CRMBreakpoints.phablet] up to [CRMBreakpoints.tablet].
  phablet,

  /// [CRMBreakpoints.tablet] and above — existing tablet/desktop shell.
  shell,
}

/// Layout contract for the mobile foundation (DR-001).
class MobileLayout {
  MobileLayout._();

  /// Minimum effective hit area for every interactive mobile control.
  static const double minTouchTarget = 48;

  /// Bottom navigation bar height, excluding the bottom safe area.
  static const double bottomNavHeight = 64;

  /// Top bar height, excluding the status bar.
  static const double topBarHeight = 56;

  /// Max width for centered phone content between 430 and 767.
  static const double contentMaxWidth = 560;

  /// True when [width] must render the mobile shell.
  static bool isMobileShell(double width) => width < CRMBreakpoints.tablet;

  static MobileWidthClass widthClassFor(double width) {
    if (width < CRMBreakpoints.phone) return MobileWidthClass.compact;
    if (width < CRMBreakpoints.phablet) return MobileWidthClass.phone;
    if (width < CRMBreakpoints.tablet) return MobileWidthClass.phablet;
    return MobileWidthClass.shell;
  }

  static MobileWidthClass widthClassOf(BuildContext context) =>
      widthClassFor(CRMBreakpoints.widthOf(context));

  /// Horizontal page padding: 12 below 360, 16 from 360.
  static double horizontalPaddingFor(double width) =>
      width < CRMBreakpoints.phone ? CRMSpacing.s : CRMSpacing.m;

  static double horizontalPaddingOf(BuildContext context) =>
      horizontalPaddingFor(CRMBreakpoints.widthOf(context));
}

/// Marks the subtree rendered inside [MobileAppShell]. The shell already
/// reserves [CRMBreakpoints.mobileNavClearance] below its content and removes
/// the bottom padding/view padding from the content's [MediaQuery], so
/// descendants must not add bottom-nav padding again.
///
/// This is the only shell-awareness mechanism for mobile screens.
class MobileShellScope extends InheritedWidget {
  /// Lets routed screens override the shell's route-derived title.
  final MobileTitleController? titleController;

  const MobileShellScope({
    super.key,
    this.titleController,
    required super.child,
  });

  static bool isInShell(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MobileShellScope>() != null;

  static MobileTitleController? titleControllerOf(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<MobileShellScope>()
          ?.titleController;

  @override
  bool updateShouldNotify(MobileShellScope oldWidget) =>
      titleController != oldWidget.titleController;
}

/// Screen-supplied title for the shell top bar. The most recent claim wins;
/// a release only clears the title if the releasing owner still holds it, so
/// an outgoing page cannot clear the incoming page's title.
class MobileTitleController extends ChangeNotifier {
  Object? _owner;
  String? _title;
  bool _showBack = false;
  VoidCallback? _onBack;
  bool _disposed = false;

  String? get title => _title;
  bool get showBack => _showBack;
  VoidCallback? get onBack => _onBack;

  /// Claims and releases arrive after a frame, possibly after the shell is
  /// gone; they are ignored once disposed.
  void claim(
    Object owner,
    String title, {
    bool showBack = false,
    VoidCallback? onBack,
  }) {
    if (_disposed ||
        (identical(_owner, owner) &&
            _title == title &&
            _showBack == showBack &&
            _onBack == onBack)) return;
    _owner = owner;
    _title = title;
    _showBack = showBack;
    _onBack = onBack;
    notifyListeners();
  }

  void release(Object owner) {
    if (_disposed || !identical(_owner, owner)) return;
    _owner = null;
    _title = null;
    _showBack = false;
    _onBack = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Chooses between the mobile shell and the existing shell by width.
/// Exactly one builder runs, so the two navigations can never coexist.
class MobileShellSwitch extends StatelessWidget {
  final bool enabled;
  final WidgetBuilder mobileBuilder;
  final WidgetBuilder existingBuilder;

  const MobileShellSwitch({
    super.key,
    required this.enabled,
    required this.mobileBuilder,
    required this.existingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final useMobile =
        enabled && MobileLayout.isMobileShell(CRMBreakpoints.widthOf(context));
    return useMobile ? mobileBuilder(context) : existingBuilder(context);
  }
}

/// Standard page body for mobile screens: horizontal padding, optional
/// centered max width, optional scrolling and pull-to-refresh.
///
/// Bottom clearance: inside [MobileAppShell] the shell already reserves the
/// nav clearance, so nothing is added. Outside it (full-screen pushed pages)
/// the bottom safe area from [MediaQuery.padding] is applied; a `Scaffold`
/// with a bottom bar and an open keyboard both already zero that padding.
class MobileContent extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final Future<void> Function()? onRefresh;
  final bool centered;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const MobileContent({
    super.key,
    required this.child,
    this.scrollable = true,
    this.onRefresh,
    this.centered = true,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = MobileLayout.horizontalPaddingOf(context);
    final inShell = MobileShellScope.isInShell(context);
    final bottomSafe = inShell ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          horizontal,
          CRMSpacing.m,
          horizontal,
          CRMSpacing.m + bottomSafe,
        );

    Widget body = Padding(padding: resolvedPadding, child: child);
    if (centered) {
      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MobileLayout.contentMaxWidth,
          ),
          child: body,
        ),
      );
    }

    if (!scrollable) return body;

    Widget scroll = SingleChildScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: body,
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }
    return scroll;
  }
}
