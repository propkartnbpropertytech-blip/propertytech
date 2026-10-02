import 'package:flutter/material.dart';

/// Clean, modern animated floating SnackBar for status updates and non-blocking notifications.
class AppStatusSnackBar {
  static void showWithMessenger(
    ScaffoldMessengerState messenger, {
    required String message,
    bool isSuccess = true,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    messenger.hideCurrentSnackBar();

    final bgColor = backgroundColor ?? (isSuccess ? const Color(0xFF0F766E) : const Color(0xFFEF4444));
    final iconData = icon ?? (isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        backgroundColor: bgColor,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    showWithMessenger(
      messenger,
      message: message,
      isSuccess: isSuccess,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }
}
