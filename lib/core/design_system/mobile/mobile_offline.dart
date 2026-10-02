import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'mobile_layout.dart';

/// Frozen offline/data-state model (DR-021). Presentation only: these
/// widgets display a state the caller already knows; they never read or
/// change the sync engine, the outbox, or campaign outcome behavior.
enum MobileDataStatus {
  /// Showing Isar-cached data while offline.
  cachedRead,

  /// A sync run is in progress.
  syncing,

  /// A write is queued in the existing outbox.
  pendingWrite,

  /// A direct server call (no outbox) is in flight.
  directOperation,

  /// A write failed and needs a retry.
  failedWrite,
}

/// How a write reaches the server, as already implemented by the caller's
/// repository. Presentation input only.
enum MobileWriteChannel {
  /// Queued in the existing offline outbox.
  outbox,

  /// Sent straight to the server (e.g. campaign outcomes, SD-12).
  directServer,
}

/// DR-021 mapping from a write's channel and progress to a status.
class MobileDataStatusRules {
  MobileDataStatusRules._();

  /// Status to show for a write, or null when there is nothing to show.
  /// A [MobileWriteChannel.directServer] write can never be
  /// [MobileDataStatus.pendingWrite] ("Waiting to sync").
  static MobileDataStatus? forWrite(
    MobileWriteChannel channel, {
    bool inProgress = false,
    bool failed = false,
  }) {
    if (failed) return MobileDataStatus.failedWrite;
    if (!inProgress) return null;
    return channel == MobileWriteChannel.outbox
        ? MobileDataStatus.pendingWrite
        : MobileDataStatus.directOperation;
  }
}

/// Default copy for each status (Step 2.6 §14).
class MobileDataStatusCopy {
  MobileDataStatusCopy._();

  static String label(MobileDataStatus status, {String? lastUpdated}) {
    switch (status) {
      case MobileDataStatus.cachedRead:
        return lastUpdated == null
            ? 'Offline'
            : 'Offline · last updated $lastUpdated';
      case MobileDataStatus.syncing:
        return 'Syncing';
      case MobileDataStatus.pendingWrite:
        return 'Waiting to sync';
      case MobileDataStatus.directOperation:
        return 'Saving…';
      case MobileDataStatus.failedWrite:
        return "Couldn't save. Try again.";
    }
  }
}

/// Banner for offline state. With a cache it says the data is cached; without
/// one it says the user is offline. It never claims there is no data.
class MobileOfflineBanner extends StatelessWidget {
  final bool hasCache;
  final String? lastUpdated;
  final VoidCallback? onRetry;

  const MobileOfflineBanner({
    super.key,
    required this.hasCache,
    this.lastUpdated,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final text = hasCache
        ? MobileDataStatusCopy.label(
            MobileDataStatus.cachedRead,
            lastUpdated: lastUpdated,
          )
        : "You're offline";
    return Semantics(
      liveRegion: true,
      label: text,
      excludeSemantics: onRetry == null,
      child: Container(
        width: double.infinity,
        color: CRMColors.warningBg,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m),
        constraints: const BoxConstraints(
          minHeight: MobileLayout.minTouchTarget,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 18,
              color: CRMColors.warning,
            ),
            const SizedBox(width: CRMSpacing.xs),
            Expanded(
              child: Text(
                text,
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textOf(context),
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    MobileLayout.minTouchTarget,
                    MobileLayout.minTouchTarget,
                  ),
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

/// One-line status caption for any [MobileDataStatus]. Not a blocking
/// overlay; the existing sync overlay stays in place until PD-05 is decided.
class MobileSyncIndicator extends StatelessWidget {
  final MobileDataStatus status;
  final String? lastUpdated;
  final VoidCallback? onRetry;

  const MobileSyncIndicator({
    super.key,
    required this.status,
    this.lastUpdated,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failed = status == MobileDataStatus.failedWrite;
    final busy =
        status == MobileDataStatus.syncing ||
        status == MobileDataStatus.directOperation;
    final color = failed
        ? CRMColors.danger
        : CRMColors.textSecondaryOf(context);
    final text = MobileDataStatusCopy.label(status, lastUpdated: lastUpdated);

    return Semantics(
      liveRegion: true,
      label: text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            )
          else
            Icon(_iconFor(status), size: 14, color: color),
          const SizedBox(width: CRMSpacing.xxs),
          Flexible(
            child: ExcludeSemantics(
              child: Text(
                text,
                style: CRMTypography.caption.copyWith(color: color),
              ),
            ),
          ),
          if (failed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  MobileLayout.minTouchTarget,
                  MobileLayout.minTouchTarget,
                ),
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(MobileDataStatus status) {
    switch (status) {
      case MobileDataStatus.cachedRead:
        return Icons.cloud_off_rounded;
      case MobileDataStatus.pendingWrite:
        return Icons.schedule_rounded;
      case MobileDataStatus.failedWrite:
        return Icons.error_outline_rounded;
      case MobileDataStatus.syncing:
      case MobileDataStatus.directOperation:
        return Icons.sync_rounded;
    }
  }
}

/// Small pill for a card whose write sits in the existing outbox.
class MobilePendingSyncBadge extends StatelessWidget {
  const MobilePendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final text = MobileDataStatusCopy.label(MobileDataStatus.pendingWrite);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CRMSpacing.xs,
          vertical: CRMSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: CRMColors.infoBg,
          borderRadius: BorderRadius.circular(CRMBorderRadius.badge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 12, color: CRMColors.info),
            const SizedBox(width: CRMSpacing.xxs),
            Text(
              text,
              style: CRMTypography.caption.copyWith(color: CRMColors.info),
            ),
          ],
        ),
      ),
    );
  }
}
