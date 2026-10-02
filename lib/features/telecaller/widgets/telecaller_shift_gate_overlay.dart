import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/telecaller_shift_manager.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

class TelecallerShiftGateOverlay extends StatefulWidget {
  final Widget child;
  final bool isTelecaller;

  const TelecallerShiftGateOverlay({
    super.key,
    required this.child,
    required this.isTelecaller,
  });

  @override
  State<TelecallerShiftGateOverlay> createState() => _TelecallerShiftGateOverlayState();
}

class _TelecallerShiftGateOverlayState extends State<TelecallerShiftGateOverlay> {
  bool _hasShownLimitDialog = false;

  @override
  void initState() {
    super.initState();
    if (widget.isTelecaller) {
      final sm = TelecallerShiftManager.instance;
      sm.isOffLimitExpiredNotifier.addListener(_checkLimitExpiredNotification);
      sm.currentStatusNotifier.addListener(_onStatusChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkLimitExpiredNotification();
      });
    }
  }

  @override
  void didUpdateWidget(TelecallerShiftGateOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTelecaller != oldWidget.isTelecaller) {
      final sm = TelecallerShiftManager.instance;
      if (widget.isTelecaller) {
        sm.isOffLimitExpiredNotifier.addListener(_checkLimitExpiredNotification);
        sm.currentStatusNotifier.addListener(_onStatusChanged);
      } else {
        sm.isOffLimitExpiredNotifier.removeListener(_checkLimitExpiredNotification);
        sm.currentStatusNotifier.removeListener(_onStatusChanged);
      }
    }
  }

  @override
  void dispose() {
    if (widget.isTelecaller) {
      final sm = TelecallerShiftManager.instance;
      sm.isOffLimitExpiredNotifier.removeListener(_checkLimitExpiredNotification);
      sm.currentStatusNotifier.removeListener(_onStatusChanged);
    }
    super.dispose();
  }

  void _onStatusChanged() {
    if (TelecallerShiftManager.instance.isActive) {
      _hasShownLimitDialog = false;
    }
  }

  void _checkLimitExpiredNotification() {
    final sm = TelecallerShiftManager.instance;
    if (!sm.isActive && sm.isOffLimitExpiredNotifier.value && !_hasShownLimitDialog) {
      _hasShownLimitDialog = true;
      _showLimitReachedDialog();
    }
  }

  void _showLimitReachedDialog() {
    if (!mounted) return;
    final sm = TelecallerShiftManager.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFEE2E2),
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  size: 26,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '6-Hour OFF Limit Reached',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your 6-hour manual OFF allowance for this 24-hour cycle has completed.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You must turn the Active toggle ON to receive new lead assignments again.\n\nYou can continue using the software normally to work on your current leads, but no new incoming leads will be assigned until your toggle is ON.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continue Using Software'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Turn Active ON', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await sm.toggleAvailability(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTelecaller) return widget.child;

    final shiftManager = TelecallerShiftManager.instance;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => shiftManager.recordUserActivity(),
      onPointerMove: (_) => shiftManager.recordUserActivity(),
      child: Stack(
        children: [
          widget.child,

          // 1. Inactivity Break Blur Overlay (5 minutes of idle)
          ValueListenableBuilder<bool>(
            valueListenable: shiftManager.isOnInactivityBreakNotifier,
            builder: (context, isOnBreak, _) {
              if (!isOnBreak) return const SizedBox.shrink();

              final isPhone = MediaQuery.sizeOf(context).width < 360;
              final content = Container(
                color: Colors.black.withValues(alpha: kIsWeb ? 0.72 : 0.55),
                alignment: Alignment.center,
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: CRMBreakpoints.adaptiveWidth(context, 420),
                    padding: EdgeInsets.all(isPhone ? 20 : 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFEF3C7),
                          ),
                          child: const Icon(
                            Icons.coffee_rounded,
                            size: 36,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'You are on BREAK',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ValueListenableBuilder<bool>(
                          valueListenable: shiftManager.isManualOffNotifier,
                          builder: (context, wasOff, _) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  wasOff
                                      ? 'You were automatically put on break after 5 minutes of inactivity. Your 6-hour OFF timer has been paused.'
                                      : 'You were automatically put on break after 5 minutes of inactivity so no live leads are missed.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                    label: Text(
                                      wasOff ? 'Resume' : 'Resume Active',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () async {
                                      await shiftManager.resumeFromBreak();
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );

              return Positioned.fill(
                child: kIsWeb
                    ? content
                    : BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: content,
                      ),
              );
            },
          ),

          // 2. Daily 9-Hour Shift Lockout Modal
          ValueListenableBuilder<bool>(
            valueListenable: shiftManager.isShiftLockedOutNotifier,
            builder: (context, isLockedOut, _) {
              if (!isLockedOut) return const SizedBox.shrink();

              final isPhone = MediaQuery.sizeOf(context).width < 360;
              final content = Container(
                color: Colors.black.withValues(alpha: kIsWeb ? 0.80 : 0.70),
                alignment: Alignment.center,
                child: Card(
                  elevation: 16,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: CRMBreakpoints.adaptiveWidth(context, 440),
                    padding: EdgeInsets.all(isPhone ? 20 : 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFEE2E2),
                          ),
                          child: const Icon(
                            Icons.lock_clock_rounded,
                            size: 36,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Daily Shift Completed (9 Hours)',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'You have reached the 9-hour daily work limit. Your telecaller session is locked for the remainder of today. Please log back in tomorrow.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              return Positioned.fill(
                child: kIsWeb
                    ? content
                    : BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: content,
                      ),
              );
            },
          ),

          // 3. Non-blocking Top Banner when 6-hour OFF limit is reached
          ValueListenableBuilder<bool>(
            valueListenable: shiftManager.isOffLimitExpiredNotifier,
            builder: (context, isExpired, _) {
              return ValueListenableBuilder<String>(
                valueListenable: shiftManager.currentStatusNotifier,
                builder: (context, status, _) {
                  if (!isExpired || status == 'ACTIVE' || status == 'BREAK') {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 3,
                      color: const Color(0xFFDC2626),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '6-Hour OFF limit reached! New lead assignments are paused until you turn the Active toggle ON.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFDC2626),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                await shiftManager.toggleAvailability(true);
                              },
                              child: const Text('Turn ON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
