import 'package:flutter/material.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../services/telecaller_shift_manager.dart';

class TelecallerAvailabilityToggle extends StatelessWidget {
  final bool compact;
  const TelecallerAvailabilityToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final shiftManager = TelecallerShiftManager.instance;

    return ValueListenableBuilder<String>(
      valueListenable: shiftManager.currentStatusNotifier,
      builder: (context, status, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: shiftManager.isShiftLockedOutNotifier,
          builder: (context, isLockedOut, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: shiftManager.isOffLimitExpiredNotifier,
              builder: (context, isOffLimitExpired, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: shiftManager.remainingOffSecondsNotifier,
                  builder: (context, remainingSec, _) {
                    final isActive = status == 'ACTIVE';

                    if (isLockedOut) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_clock_rounded, size: 15, color: Color(0xFFDC2626)),
                            SizedBox(width: 6),
                            Text(
                              'Shift Limit (9h)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final offLimitReached = isOffLimitExpired || remainingSec <= 0;
                    final tooltipMsg = isActive
                        ? 'Active · Receiving leads (${shiftManager.formatRemainingOffTime()} OFF allowance left today)'
                        : (offLimitReached
                            ? '6-hour OFF allowance expired! Must turn ON to receive leads.'
                            : 'Inactive · ${shiftManager.formatRemainingOffTime()} OFF allowance remaining today');

                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: tooltipMsg,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 2 : 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF059669).withValues(alpha: 0.12)
                                  : (offLimitReached
                                      ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                                      : const Color(0xFF64748B).withValues(alpha: 0.10)),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF10B981).withValues(alpha: 0.45)
                                    : (offLimitReached
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.50)
                                        : const Color(0xFF94A3B8).withValues(alpha: 0.35)),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? const Color(0xFF10B981)
                                        : (offLimitReached
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF94A3B8)),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : (offLimitReached
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isActive
                                      ? 'ACTIVE'
                                      : (status == 'BREAK'
                                          ? 'ON BREAK'
                                          : (offLimitReached ? 'OFF (LIMIT)' : 'OFF')),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                    color: isActive
                                        ? const Color(0xFF065F46)
                                        : (offLimitReached
                                            ? const Color(0xFFB91C1C)
                                            : const Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  height: 24,
                                  width: 38,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Switch(
                                      value: isActive,
                                      activeThumbColor: const Color(0xFF10B981),
                                      activeTrackColor: const Color(0xFFA7F3D0),
                                      inactiveThumbColor: offLimitReached ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                      inactiveTrackColor: offLimitReached ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) async {
                                        if (!val && offLimitReached) {
                                          AppStatusSnackBar.show(
                                            context,
                                            message: '6-hour OFF allowance has expired for this 24-hour cycle. You must turn the toggle ON to receive leads.',
                                            isSuccess: false,
                                          );
                                          return;
                                        }
                                        final success = await shiftManager.toggleAvailability(val);
                                        if (!success && context.mounted) {
                                          AppStatusSnackBar.show(
                                            context,
                                            message: shiftManager.isOffLimitExpiredNotifier.value
                                                ? '6-hour OFF allowance expired. Toggle must remain ON.'
                                                : (shiftManager.isShiftLockedOutNotifier.value
                                                    ? 'Daily 9-hour shift limit reached.'
                                                    : 'Action failed. Please try again.'),
                                            isSuccess: false,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Display countdown timer directly below the Active toggle
                        const SizedBox(height: 2),
                        if (offLimitReached)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: compact ? 9.5 : 10.5,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '00:00:00 · Limit Reached',
                                style: TextStyle(
                                  fontSize: compact ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          )
                        else
                          Builder(
                            builder: (_) {
                              final hours = remainingSec ~/ 3600;
                              final mins = (remainingSec % 3600) ~/ 60;
                              final secs = remainingSec % 60;
                              final formatted =
                                  '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
                              final isPaused = status == 'BREAK';

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaused
                                        ? Icons.pause_circle_outline_rounded
                                        : Icons.timer_outlined,
                                    size: compact ? 9.5 : 10.5,
                                    color: isPaused
                                        ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                                        : (isActive
                                            ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                            : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isPaused
                                        ? '$formatted (Paused)'
                                        : (isActive ? '$formatted (Stopped)' : '$formatted left'),
                                    style: TextStyle(
                                      fontSize: compact ? 9 : 10,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                      color: isPaused
                                          ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                          : (isActive
                                              ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                              : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
