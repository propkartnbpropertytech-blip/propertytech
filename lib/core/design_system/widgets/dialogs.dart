import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/app_blur.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'buttons.dart';

class CRMDialogs {
  static Widget _glassDialog({
    required BuildContext ctx,
    required Widget child,
  }) {
    final reduce = MediaQuery.disableAnimationsOf(ctx);
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: reduce ? CRMBlur.reduced : CRMBlur.dialog,
        sigmaY: reduce ? CRMBlur.reduced : CRMBlur.dialog,
      ),
      child: Dialog(
        backgroundColor: CRMColors.surfaceElevatedOf(ctx).withOpacity(0.94),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
          side: BorderSide(
            color: CRMColors.borderOf(ctx).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.l),
            child: child,
          ),
        ),
      ),
    );
  }

  static Future<bool?> showUnsavedChangesDialog(BuildContext context) async {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Unsaved',
      barrierColor: CRMColors.overlayOf(context),
      transitionDuration: CRMMotion.dialog,
      pageBuilder: (ctx, anim, _) => _glassDialog(
        ctx: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unsaved Changes',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              'You have unsaved form details. Are you sure you want to discard your changes and leave?',
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CRMButton(
                  label: 'Keep Editing',
                  variant: CRMButtonVariant.outline,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                const SizedBox(width: CRMSpacing.s),
                CRMButton(
                  label: 'Discard',
                  variant: CRMButtonVariant.danger,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: CRMMotion.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: CRMMotion.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> showSuccessDialog(
    BuildContext context,
    String message, {
    VoidCallback? onClose,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success',
      barrierColor: CRMColors.overlayOf(context),
      transitionDuration: CRMMotion.dialog,
      pageBuilder: (ctx, anim, _) => _glassDialog(
        ctx: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: CRMColors.success, size: 40),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Success',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.l),
            CRMButton(
              label: 'OK',
              width: double.infinity,
              onPressed: () {
                Navigator.of(ctx).pop();
                onClose?.call();
              },
            ),
          ],
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(anim),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> showErrorDialog(BuildContext context, String error) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Error',
      barrierColor: CRMColors.overlayOf(context),
      transitionDuration: CRMMotion.dialog,
      pageBuilder: (ctx, anim, _) => _glassDialog(
        ctx: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 40),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Error',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              error,
              textAlign: TextAlign.center,
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.l),
            CRMButton(
              label: 'Close',
              variant: CRMButtonVariant.outline,
              width: double.infinity,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  static Future<bool?> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete',
      barrierColor: CRMColors.overlayOf(context),
      transitionDuration: CRMMotion.dialog,
      pageBuilder: (ctx, anim, _) => _glassDialog(
        ctx: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 28),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: Text(
                    title,
                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              content,
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CRMButton(
                  label: 'Cancel',
                  variant: CRMButtonVariant.outline,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                const SizedBox(width: CRMSpacing.s),
                CRMButton(
                  label: 'Delete',
                  variant: CRMButtonVariant.danger,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(anim),
            child: child,
          ),
        );
      },
    );
  }

  static Future<bool?> showExitAppDialog(BuildContext context) async {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Exit',
      barrierColor: CRMColors.overlayOf(context),
      transitionDuration: CRMMotion.dialog,
      pageBuilder: (ctx, anim, _) => _glassDialog(
        ctx: ctx,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exit PropKart?',
              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              'Are you sure you want to exit?',
              style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
            ),
            const SizedBox(height: CRMSpacing.l),
            Row(
              children: [
                Expanded(
                  child: CRMButton(
                    label: 'Cancel',
                    variant: CRMButtonVariant.outline,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Expanded(
                  child: CRMButton(
                    label: 'Exit',
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: CRMMotion.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: CRMMotion.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
