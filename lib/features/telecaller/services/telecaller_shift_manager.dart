import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/telecaller_repository.dart';

/// TelecallerShiftManager controls:
/// 1. 2-State Availability Switch (ACTIVE / INACTIVE)
/// 2. Workspace Login Gate (Pages locked until telecaller goes ACTIVE)
/// 3. Continuous 5-Minute Inactivity Auto-Break (Switches to BREAK with blur overlay)
/// 4. 9-Hour Daily Shift Lockout (Automatically locks shift after 9 hours)
class TelecallerShiftManager {
  TelecallerShiftManager._();
  static final TelecallerShiftManager instance = TelecallerShiftManager._();

  final TelecallerRepository _repository = TelecallerRepository();

  final ValueNotifier<String> currentStatusNotifier = ValueNotifier<String>('INACTIVE');
  final ValueNotifier<bool> isShiftLockedOutNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnInactivityBreakNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isInitializedNotifier = ValueNotifier<bool>(false);

  String? _userId;
  Timer? _inactivityTimer;
  Timer? _shiftCheckTimer;
  Timer? _heartbeatTimer;

  static const int kInactivityTimeoutSeconds = 300; // 5 minutes
  static const int kShiftMaxDurationMillis = 9 * 3600 * 1000; // 9 hours

  bool get isActive => currentStatusNotifier.value == 'ACTIVE';
  bool get isInactive => currentStatusNotifier.value == 'INACTIVE';
  bool get isBreak => currentStatusNotifier.value == 'BREAK';

  Future<void> init(String userId) async {
    if (_userId == userId && isInitializedNotifier.value) return;
    _userId = userId;

    await _checkShiftLockout();

    try {
      final data = await _repository.dashboard();
      final status = (data['availability'] ?? 'INACTIVE').toString().toUpperCase();
      currentStatusNotifier.value = status;
      if (status == 'BREAK') {
        isOnInactivityBreakNotifier.value = true;
      }
    } catch (_) {}

    if (isActive) {
      _startHeartbeat();
      _resetInactivityTimer();
    }

    _shiftCheckTimer?.cancel();
    _shiftCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkShiftLockout());

    isInitializedNotifier.value = true;
  }

  void recordUserActivity() {
    if (_userId == null) return;
    if (isShiftLockedOutNotifier.value) return;
    if (isOnInactivityBreakNotifier.value) return;

    if (isActive) {
      _resetInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: kInactivityTimeoutSeconds), _onInactivityTriggered);
  }

  Future<void> _onInactivityTriggered() async {
    if (!isActive) return;
    debugPrint('[TelecallerShiftManager] 5 minutes of inactivity detected. Triggering auto-break.');
    isOnInactivityBreakNotifier.value = true;
    _stopHeartbeat();
    try {
      await _repository.setAvailability('BREAK');
      currentStatusNotifier.value = 'BREAK';
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error setting break on inactivity: $e');
    }
  }

  Future<bool> resumeActive() async {
    if (isShiftLockedOutNotifier.value) return false;
    try {
      await _repository.setAvailability('ACTIVE');
      currentStatusNotifier.value = 'ACTIVE';
      isOnInactivityBreakNotifier.value = false;
      _startHeartbeat();
      _resetInactivityTimer();
      return true;
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error resuming active: $e');
      return false;
    }
  }

  Future<bool> toggleAvailability(bool shouldBeActive) async {
    if (shouldBeActive && isShiftLockedOutNotifier.value) {
      debugPrint('[TelecallerShiftManager] Cannot activate: 9-hour daily shift limit reached.');
      return false;
    }

    final targetStatus = shouldBeActive ? 'ACTIVE' : 'INACTIVE';
    try {
      await _repository.setAvailability(targetStatus);
      currentStatusNotifier.value = targetStatus;

      if (shouldBeActive) {
        await _recordShiftStartIfNeeded();
        isOnInactivityBreakNotifier.value = false;
        _startHeartbeat();
        _resetInactivityTimer();
      } else {
        _stopHeartbeat();
        _inactivityTimer?.cancel();
        isOnInactivityBreakNotifier.value = false;
      }
      return true;
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error toggling availability: $e');
      return false;
    }
  }

  Future<void> _recordShiftStartIfNeeded() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final storedDateKey = 'tc_shift_date_${_userId!}';
    final storedTimeKey = 'tc_shift_time_${_userId!}';

    final storedDate = prefs.getString(storedDateKey);
    if (storedDate != todayStr) {
      // New day: record shift start
      await prefs.setString(storedDateKey, todayStr);
      await prefs.setInt(storedTimeKey, DateTime.now().millisecondsSinceEpoch);
      isShiftLockedOutNotifier.value = false;
    }
  }

  Future<void> _checkShiftLockout() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final storedDateKey = 'tc_shift_date_${_userId!}';
    final storedTimeKey = 'tc_shift_time_${_userId!}';

    final storedDate = prefs.getString(storedDateKey);
    final storedTime = prefs.getInt(storedTimeKey);

    if (storedDate == todayStr && storedTime != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - storedTime;
      if (elapsed >= kShiftMaxDurationMillis) {
        if (!isShiftLockedOutNotifier.value) {
          debugPrint('[TelecallerShiftManager] 9-hour daily shift reached. Locking telecaller session.');
          isShiftLockedOutNotifier.value = true;
          if (isActive || isBreak) {
            try {
              await _repository.setAvailability('INACTIVE');
              currentStatusNotifier.value = 'INACTIVE';
            } catch (_) {}
          }
          _stopHeartbeat();
          _inactivityTimer?.cancel();
        }
      } else {
        isShiftLockedOutNotifier.value = false;
      }
    } else {
      isShiftLockedOutNotifier.value = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
    _sendHeartbeat();
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    if (!isActive) return;
    try {
      await _repository.heartbeat();
    } catch (_) {}
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _shiftCheckTimer?.cancel();
    _stopHeartbeat();
    _userId = null;
    isInitializedNotifier.value = false;
    currentStatusNotifier.value = 'INACTIVE';
    isShiftLockedOutNotifier.value = false;
    isOnInactivityBreakNotifier.value = false;
  }
}
