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

            return Container(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 2 : 4),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF059669).withValues(alpha: 0.12)
                    : const Color(0xFF64748B).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.45)
                      : const Color(0xFF94A3B8).withValues(alpha: 0.35),
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
                      color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ACTIVE' : (status == 'BREAK' ? 'ON BREAK' : 'INACTIVE'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: isActive ? const Color(0xFF065F46) : const Color(0xFF475569),
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
                        inactiveThumbColor: const Color(0xFF94A3B8),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) async {
                          final success = await shiftManager.toggleAvailability(val);
                          if (!success && context.mounted) {
                            AppStatusSnackBar.show(
                              context,
                              message: 'Daily 9-hour shift limit reached or action failed.',
                              isSuccess: false,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
