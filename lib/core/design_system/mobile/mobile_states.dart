import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import '../widgets/skeletons.dart';
import 'mobile_layout.dart';

/// Which loading surface to show (Step 2.6 §13).
enum MobileLoadingMode {
  /// First load with no data: skeletons shaped like the content.
  initial,

  /// Pull-to-refresh or background refresh: thin progress bar, content stays.
  refreshing,

  /// Next page / "load more": inline spinner at the list end.
  loadingMore,

  /// A button action is running: button-sized spinner.
  action,
}

/// Card-shaped skeleton block.
class MobileSkeleton extends StatelessWidget {
  final double height;
  final double? width;

  const MobileSkeleton({super.key, this.height = 96, this.width});

  @override
  Widget build(BuildContext context) {
    return CRMSkeleton(
      width: width ?? double.infinity,
      height: height,
      borderRadius: CRMBorderRadius.card,
    );
  }
}

/// 24px spinner with an optional caption, announced as a live region.
class MobileInlineLoader extends StatelessWidget {
  final String? label;

  const MobileInlineLoader({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final text = label ?? 'Loading';
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (label != null) ...[
              const SizedBox(width: CRMSpacing.xs),
              Text(
                label!,
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 20px spinner sized to sit inside a 48px button.
class MobileButtonLoader extends StatelessWidget {
  final Color? color;

  const MobileButtonLoader({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}

/// Single entry point for the four loading modes.
class MobileLoadingState extends StatelessWidget {
  final MobileLoadingMode mode;
  final int skeletonCount;
  final double skeletonHeight;

  const MobileLoadingState({
    super.key,
    this.mode = MobileLoadingMode.initial,
    this.skeletonCount = 3,
    this.skeletonHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case MobileLoadingMode.initial:
        return Semantics(
          label: 'Loading',
          liveRegion: true,
          child: Column(
            children: [
              for (var i = 0; i < skeletonCount; i++) ...[
                if (i > 0) const SizedBox(height: CRMSpacing.s),
                MobileSkeleton(height: skeletonHeight),
              ],
            ],
          ),
        );
      case MobileLoadingMode.refreshing:
        return Semantics(
          label: 'Refreshing',
          liveRegion: true,
          child: const LinearProgressIndicator(minHeight: 2),
        );
      case MobileLoadingMode.loadingMore:
        return const MobileInlineLoader(label: 'Loading more');
      case MobileLoadingMode.action:
        return const MobileButtonLoader();
    }
  }
}

/// Empty state with a primary and optional secondary action.
class MobileEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const MobileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: CRMColors.textSecondaryOf(context),
      title: title,
      description: description,
      primaryLabel: actionLabel,
      onPrimary: onAction,
      secondaryLabel: secondaryActionLabel,
      onSecondary: onSecondaryAction,
    );
  }
}

/// User-safe error state. It only renders the copy it is given; exceptions
/// go to [logTechnical], never to the screen.
class MobileErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const MobileErrorState({
    super.key,
    this.title = 'Something went wrong.',
    this.message = 'Please try again.',
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  /// Logging hook for the technical detail behind an error state.
  static void logTechnical(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[MobileErrorState] $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: Icons.error_outline_rounded,
      iconColor: CRMColors.danger,
      title: title,
      description: message,
      primaryLabel: onRetry == null ? null : retryLabel,
      onPrimary: onRetry,
    );
  }
}

/// Compact retry prompt (e.g. a failed section inside a loaded screen).
class MobileRetryState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const MobileRetryState({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(
            Icons.refresh_rounded,
            size: 20,
            color: CRMColors.textSecondaryOf(context),
          ),
          const SizedBox(width: CRMSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: CRMTypography.body.copyWith(
                color: CRMColors.textOf(context),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(
                MobileLayout.minTouchTarget,
                MobileLayout.minTouchTarget,
              ),
            ),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? description;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.description,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size(144, MobileLayout.minTouchTarget);
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: MobileLayout.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CRMSpacing.m,
            vertical: CRMSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 32, color: iconColor)),
              const SizedBox(height: CRMSpacing.s),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: CRMTypography.title.copyWith(
                    fontSize: 20,
                    color: CRMColors.textOf(context),
                  ),
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: CRMSpacing.xs),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: CRMTypography.body.copyWith(
                    fontSize: 16,
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
              ],
              if (primaryLabel != null && onPrimary != null) ...[
                const SizedBox(height: CRMSpacing.l),
                FilledButton(
                  onPressed: onPrimary,
                  style: FilledButton.styleFrom(minimumSize: buttonSize),
                  child: Text(primaryLabel!),
                ),
              ],
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: CRMSpacing.xs),
                TextButton(
                  onPressed: onSecondary,
                  style: TextButton.styleFrom(minimumSize: buttonSize),
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
