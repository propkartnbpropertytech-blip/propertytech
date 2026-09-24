import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/telecaller_shift_manager.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

class TelecallerShiftGateOverlay extends StatelessWidget {
  final Widget child;
  final bool isTelecaller;

  const TelecallerShiftGateOverlay({
    super.key,
    required this.child,
    required this.isTelecaller,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTelecaller) return child;

    final shiftManager = TelecallerShiftManager.instance;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => shiftManager.recordUserActivity(),
      onPointerMove: (_) => shiftManager.recordUserActivity(),
      child: Stack(
        children: [
          child,

          // 1. Inactivity Break Blur Overlay (5 minutes of idle)
          ValueListenableBuilder<bool>(
            valueListenable: shiftManager.isOnInactivityBreakNotifier,
            builder: (context, isOnBreak, _) {
              if (!isOnBreak) return const SizedBox.shrink();

              return Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: CRMBreakpoints.adaptiveWidth(context, 420),
                        padding: const EdgeInsets.all(28),
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
                            const Text(
                              'You were automatically put on break after 5 minutes of inactivity so no live leads are missed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                                label: const Text(
                                  'Resume Active',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await shiftManager.resumeActive();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Daily 9-Hour Shift Lockout Modal
          ValueListenableBuilder<bool>(
            valueListenable: shiftManager.isShiftLockedOutNotifier,
            builder: (context, isLockedOut, _) {
              if (!isLockedOut) return const SizedBox.shrink();

              return Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.70),
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 16,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: CRMBreakpoints.adaptiveWidth(context, 440),
                        padding: const EdgeInsets.all(32),
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
                  ),
                ),
              );
            },
          ),

          // 3. Workspace Inactive Blur Gate (Logs in blurred until toggle turned ON)
          ValueListenableBuilder<String>(
            valueListenable: shiftManager.currentStatusNotifier,
            builder: (context, status, _) {
              if (status != 'INACTIVE') return const SizedBox.shrink();
              if (shiftManager.isShiftLockedOutNotifier.value) return const SizedBox.shrink();
              if (shiftManager.isOnInactivityBreakNotifier.value) return const SizedBox.shrink();

              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 16,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      child: Container(
                        width: CRMBreakpoints.adaptiveWidth(context, 440),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEEF2FF),
                              ),
                              child: const Icon(
                                Icons.power_settings_new_rounded,
                                size: 40,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Telecaller Shift Inactive',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your workspace is paused. Turn ON your availability status to activate your workspace and start receiving leads.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Availability Status: OFF',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: false,
                                    activeColor: const Color(0xFF059669),
                                    onChanged: (val) async {
                                      if (val) {
                                        await shiftManager.toggleAvailability(true);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                                label: const Text(
                                  'Start Shift (Turn Active)',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await shiftManager.toggleAvailability(true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
