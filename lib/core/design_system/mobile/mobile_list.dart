import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';
import 'mobile_states.dart';

/// Lazy list with the standard mobile states. Items are built on demand by
/// [ListView.separated] and keyed by [keyOf] so rows keep identity.
///
/// [onLoadMore] is only a UI hook: it fires near the end of the list. It does
/// not imply server pagination; callers decide what "more" means.
class MobileList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Object Function(T item) keyOf;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;
  final Widget? emptyState;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;
  final double itemSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Widget? header;

  /// Distance from the end (in px) at which [onLoadMore] fires.
  final double loadMoreThreshold;

  const MobileList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.keyOf,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
    this.emptyState,
    this.onRefresh,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.itemSpacing = CRMSpacing.s,
    this.padding,
    this.controller,
    this.header,
    this.loadMoreThreshold = 400,
  });

  @override
  Widget build(BuildContext context) {
    final horizontal = MobileLayout.horizontalPaddingOf(context);
    final bottomSafe = MobileShellScope.isInShell(context)
        ? 0.0
        : MediaQuery.paddingOf(context).bottom;
    final resolvedPadding =
        padding ??
        EdgeInsets.fromLTRB(
          horizontal,
          CRMSpacing.m,
          horizontal,
          CRMSpacing.m + bottomSafe,
        );

    Widget stateList(Widget? state) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: resolvedPadding,
      children: [?header, ?state],
    );

    Widget content;
    if (isLoading && items.isEmpty) {
      content = stateList(const MobileLoadingState());
    } else if (hasError && items.isEmpty) {
      content = stateList(MobileErrorState(onRetry: onRetry));
    } else if (items.isEmpty) {
      content = stateList(emptyState);
    } else {
      final headerOffset = header != null ? 1 : 0;
      final footerCount = isLoadingMore ? 1 : 0;
      final total = headerOffset + items.length + footerCount;
      content = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (onLoadMore != null &&
              hasMore &&
              !isLoadingMore &&
              notification.metrics.extentAfter < loadMoreThreshold) {
            onLoadMore!();
          }
          return false;
        },
        child: ListView.separated(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: resolvedPadding,
          itemCount: total,
          separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
          itemBuilder: (context, index) {
            if (index < headerOffset) return header!;
            final itemIndex = index - headerOffset;
            if (itemIndex >= items.length) {
              return const MobileLoadingState(
                mode: MobileLoadingMode.loadingMore,
              );
            }
            final item = items[itemIndex];
            return KeyedSubtree(
              key: ValueKey<Object>(keyOf(item)),
              child: itemBuilder(context, item),
            );
          },
        ),
      );
    }

    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }
    return content;
  }
}

/// Row for More, settings, and stats lists. Min height 64, 48+ hit area.
class MobileListItem extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;
  final int badgeCount;

  const MobileListItem({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final primary = CRMColors.primaryOf(context);
    final label = [
      title,
      if (subtitle != null && subtitle!.isNotEmpty) subtitle!,
      if (badgeCount > 0) '$badgeCount new',
    ].join(', ');

    return Semantics(
      button: onTap != null,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.xs,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 24, color: primary),
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.s),
                ],
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: CRMTypography.cardTitle.copyWith(
                            color: enabled
                                ? CRMColors.textOf(context)
                                : CRMColors.textMutedOf(context),
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  ExcludeSemantics(
                    child: Badge(
                      label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                    ),
                  ),
                ?trailing,
                if (showChevron && onTap != null)
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: CRMColors.textSecondaryOf(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header (18/600) with an optional trailing action.
class MobileSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const MobileSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(
      CRMSpacing.m,
      CRMSpacing.l,
      CRMSpacing.m,
      CRMSpacing.xs,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: CRMTypography.sectionTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
