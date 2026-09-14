import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/dio_client.dart';
import '../design_system/tokens/app_colors.dart';
import '../design_system/tokens/app_typography.dart';
import '../navigation/app_router.dart';
import 'notification_center.dart';
import 'platform_notifier/platform_notifier.dart';

class AppNotifierService {
  static final AppNotifierService _instance = AppNotifierService._internal();
  factory AppNotifierService() => _instance;
  AppNotifierService._internal();

  static const String _kWelcomeShownKey = 'propkart_welcome_notification_sent';
  static OverlayEntry? _currentToastEntry;
  static Timer? _dismissTimer;

  /// Request browser notification permission on platforms that support it (Web)
  /// and automatically dispatch the welcome notification when granted.
  static Future<bool> requestPermission({bool forceWelcome = false}) async {
    try {
      final wasGranted = await PlatformNotifier.isPermissionGranted();
      final granted = await PlatformNotifier.requestPermission();

      if (granted) {
        final prefs = await SharedPreferences.getInstance();
        final alreadyWelcomed = prefs.getBool(_kWelcomeShownKey) ?? false;

        // If newly allowed (wasn't granted before), or never welcomed yet, or forced:
        if (!wasGranted || !alreadyWelcomed || forceWelcome) {
          await prefs.setBool(_kWelcomeShownKey, true);
          sendWelcomeNotification();
        }
      } else {
        // If permission was revoked or blocked, reset flag so next time allowed it welcomes again
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kWelcomeShownKey, false);
      }
      return granted;
    } catch (e) {
      debugPrint('[AppNotifierService] requestPermission error: $e');
      return false;
    }
  }

  /// Initialize notifier on app launch
  static Future<void> init() async {
    try {
      await requestPermission();
    } catch (_) {}
  }

  /// Checks if permission was granted externally (e.g. browser site settings lock icon)
  /// and triggers welcome notification if not yet shown.
  static Future<void> checkAndTriggerWelcomeIfNewlyGranted() async {
    try {
      final isGranted = await PlatformNotifier.isPermissionGranted();
      final prefs = await SharedPreferences.getInstance();
      final alreadyWelcomed = prefs.getBool(_kWelcomeShownKey) ?? false;

      if (isGranted) {
        if (!alreadyWelcomed) {
          await prefs.setBool(_kWelcomeShownKey, true);
          sendWelcomeNotification();
        }
      } else {
        if (alreadyWelcomed) {
          await prefs.setBool(_kWelcomeShownKey, false);
        }
      }
    } catch (_) {}
  }

  /// Sends the official "Welcome to PropKart" notification across browser & in-app toast
  static void sendWelcomeNotification() {
    const title = 'Welcome to PropKart! 🎉';
    const message =
        'Notifications are enabled! You will receive real-time updates for leads, follow-ups, and site visits.';
    final notifId = 'welcome_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Add to local NotificationCenter without duplicate toast
    NotificationCenter.addNotification(
      id: notifId,
      title: title,
      message: message,
      type: 'welcome',
      route: '/requirements',
      notifyToast: false,
    );

    // 2. Dispatch OS/Browser Notification and In-App floating toast banner
    notify(
      title: title,
      message: message,
      type: 'welcome',
      route: '/requirements',
      data: {'id': notifId},
    );
  }

  /// Deep link and handle click on any notification
  static void handleNotificationTap(dynamic notification) {
    if (notification == null) return;

    final String id = (notification['id'] ?? '').toString();
    final String type = (notification['type'] ?? '').toString().toLowerCase();
    final String? explicitRoute = notification['route']?.toString();

    // Mark as read in background
    if (id.isNotEmpty) {
      if (id.startsWith('local_')) {
        NotificationCenter.markAsRead(id);
      } else {
        DioClient.dio
            .patch('/notifications/$id/read')
            .then<dynamic>((_) => null)
            .catchError((_) => null);
      }
    }

    // Resolve target route
    String targetRoute = '/requirements';
    if (explicitRoute != null && explicitRoute.trim().isNotEmpty) {
      targetRoute = explicitRoute.trim();
    } else {
      switch (type) {
        case 'lead_assigned':
          targetRoute = '/requirements?group=assigned';
          break;
        case 'meta_lead':
          targetRoute = '/campaign/leads';
          break;
        case 'new_lead':
          targetRoute = '/requirements';
          break;
        case 'due_followup':
        case 'followup':
          targetRoute = '/requirements?tab=follow-ups&subTab=Today';
          break;
        case 'site_visit':
          targetRoute = '/requirements?tab=follow-ups&subTab=Today';
          break;
        case 'team_message':
        case 'message':
          targetRoute = '/messages';
          break;
        default:
          targetRoute = '/requirements';
          break;
      }
    }

    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext != null) {
      try {
        navContext.go(targetRoute);
      } catch (e) {
        debugPrint('[AppNotifierService] Navigation failed: $e');
      }
    }
  }

  /// Dispatches both Web/Platform OS notification and an In-App floating toast banner
  static void notify({
    required String title,
    required String message,
    String type = 'general',
    String? route,
    dynamic data,
  }) {
    final notifData = {
      'id': data?['id'] ?? 'toast_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'route': route,
      'data': data,
    };

    // 1. Dispatch platform HTML5 notification with PropKart logo
    PlatformNotifier.showNotification(
      title: title,
      body: message,
      icon: 'assets/assets/logo.png',
      onClick: () => handleNotificationTap(notifData),
      data: notifData,
    );

    // 2. Show floating in-app toast card with logo and deep-link button
    showInAppToast(
      title: title,
      message: message,
      type: type,
      onTap: () => handleNotificationTap(notifData),
    );
  }

  /// Displays an animated in-app toast banner at top-right / top-center
  static void showInAppToast({
    required String title,
    required String message,
    String type = 'general',
    VoidCallback? onTap,
  }) {
    final navState = AppRouter.rootNavigatorKey.currentState;
    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navState == null || navContext == null) return;

    _dismissTimer?.cancel();
    _currentToastEntry?.remove();
    _currentToastEntry = null;

    final overlay = navState.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        Color badgeColor;
        String badgeLabel;
        final typeLower = type.toLowerCase();
        if (typeLower.contains('meta')) {
          badgeColor = const Color(0xFF10B981); // Emerald green
          badgeLabel = 'META CAMPAIGN LEAD';
        } else if (typeLower.contains('assign')) {
          badgeColor = const Color(0xFF3B82F6); // Vibrant Blue
          badgeLabel = 'LEAD ASSIGNED';
        } else if (typeLower.contains('site_visit') || typeLower.contains('visit')) {
          badgeColor = const Color(0xFF8B5CF6); // Purple
          badgeLabel = 'SITE VISIT';
        } else if (typeLower.contains('followup')) {
          badgeColor = const Color(0xFFF59E0B); // Amber
          badgeLabel = 'FOLLOW UP';
        } else if (typeLower.contains('welcome')) {
          badgeColor = const Color(0xFF10B981); // Emerald / Brand green
          badgeLabel = 'WELCOME';
        } else {
          badgeColor = CRMColors.primary;
          badgeLabel = 'NOTIFICATION';
        }

        return Positioned(
          top: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
          left: isMobile ? 16 : null,
          width: isMobile ? null : 390,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - val)),
                  child: Opacity(
                    opacity: val.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(navContext),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PropKart Brand Logo
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CRMColors.borderOf(navContext),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.notifications_active_rounded,
                          color: badgeColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Notification Details
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          dismissToast();
                          onTap?.call();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Category Tag & Time
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Just now',
                                  style: CRMTypography.footnote.copyWith(
                                    color: CRMColors.textMutedOf(navContext),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Title
                            Text(
                              title,
                              style: CRMTypography.captionBold.copyWith(
                                color: CRMColors.textOf(navContext),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                            // Message
                            Text(
                              message,
                              style: CRMTypography.caption.copyWith(
                                color: CRMColors.textSecondaryOf(navContext),
                                fontSize: 12,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // View Action Link
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: badgeColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Close Button
                    GestureDetector(
                      onTap: dismissToast,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, top: 2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: CRMColors.textMutedOf(navContext),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _currentToastEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 7), () {
      dismissToast();
    });
  }

  static void dismissToast() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentToastEntry != null) {
      _currentToastEntry?.remove();
      _currentToastEntry = null;
    }
  }
}
