import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/telecaller_repository.dart';

/// TelecallerShiftManager controls:
/// 1. 2-State Availability Switch (ACTIVE / INACTIVE)
/// 2. Workspace Login Gate (Pages locked until telecaller goes ACTIVE)
/// 3. Continuous 5-Minute Inactivity Auto-Break (Switches to BREAK with blur overlay)
/// 4. 9-Hour Daily Shift Lockout (Automatically locks shift after 9 hours)
/// 5. 6-Hour Manual OFF Allowance per 24-hour cycle (Auto resets every 24h, locks OFF when 6h exhausted)
class TelecallerShiftManager {
  TelecallerShiftManager._();
  static final TelecallerShiftManager instance = TelecallerShiftManager._();

  final TelecallerRepository _repository = TelecallerRepository();

  final ValueNotifier<String> currentStatusNotifier = ValueNotifier<String>('INACTIVE');
  final ValueNotifier<bool> isShiftLockedOutNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnInactivityBreakNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isInitializedNotifier = ValueNotifier<bool>(false);

  // 6-Hour Manual OFF Allowance per 24-hour cycle
  static const int kMaxManualOffSeconds = 6 * 3600; // 6 hours = 21,600 seconds
  final ValueNotifier<bool> isManualOffNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> remainingOffSecondsNotifier = ValueNotifier<int>(kMaxManualOffSeconds);
  final ValueNotifier<bool> isOffLimitExpiredNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> manualOffStartedAtNotifier = ValueNotifier<DateTime?>(null);

  String? _userId;
  Timer? _inactivityTimer;
  Timer? _shiftCheckTimer;
  Timer? _heartbeatTimer;
  Timer? _manualOffCountdownTimer;
  DateTime? _countdownAnchorTime;
  int _countdownAnchorSeconds = kMaxManualOffSeconds;

  static const int kInactivityTimeoutSeconds = 300; // 5 minutes
  static const int kShiftMaxDurationMillis = 9 * 3600 * 1000; // 9 hours
  static const String _prefPrefix = 'propkart_tc_shift_';

  String _key(String suffix) => '$_prefPrefix${suffix}_${_userId ?? 'default'}';

  bool get isActive => currentStatusNotifier.value == 'ACTIVE';
  bool get isInactive => currentStatusNotifier.value == 'INACTIVE';
  bool get isBreak => currentStatusNotifier.value == 'BREAK';

  String formatRemainingOffTime([int? seconds]) {
    final s = seconds ?? remainingOffSecondsNotifier.value;
    final hours = s ~/ 3600;
    final mins = (s % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  void _startManualOffCountdown({int? initialRemaining}) {
    _countdownAnchorTime = DateTime.now();
    _countdownAnchorSeconds = initialRemaining ?? remainingOffSecondsNotifier.value;
    _manualOffCountdownTimer?.cancel();
    _manualOffCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdownAnchorTime == null) return;
      final elapsed = DateTime.now().difference(_countdownAnchorTime!).inSeconds;
      final currentRemaining = (_countdownAnchorSeconds - elapsed).clamp(0, kMaxManualOffSeconds);
      remainingOffSecondsNotifier.value = currentRemaining;
      if (currentRemaining <= 0) {
        remainingOffSecondsNotifier.value = 0;
        isOffLimitExpiredNotifier.value = true;
        _stopManualOffCountdown();
      }
    });
  }

  void _stopManualOffCountdown() {
    _manualOffCountdownTimer?.cancel();
    _manualOffCountdownTimer = null;
    _countdownAnchorTime = null;
  }

  Future<void> _persistLocalState() async {
    if (_userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key('status'), currentStatusNotifier.value);
      await prefs.setBool(_key('is_manual_off'), isManualOffNotifier.value);
      await prefs.setInt(_key('remaining_seconds'), remainingOffSecondsNotifier.value);
      await prefs.setInt(_key('last_saved_time'), DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_key('limit_expired'), isOffLimitExpiredNotifier.value);
      if (manualOffStartedAtNotifier.value != null) {
        await prefs.setString(_key('off_started_at'), manualOffStartedAtNotifier.value!.toIso8601String());
      } else {
        await prefs.remove(_key('off_started_at'));
      }
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error persisting local state: $e');
    }
  }

  Future<void> _restoreLocalState() async {
    if (_userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getString(_key('status'));
      final savedRemaining = prefs.getInt(_key('remaining_seconds'));
      final savedTimestamp = prefs.getInt(_key('last_saved_time'));
      final savedLimitExpired = prefs.getBool(_key('limit_expired')) ?? false;
      final savedIsManualOff = prefs.getBool(_key('is_manual_off'));
      final savedStartedAt = prefs.getString(_key('off_started_at'));

      if (savedStatus != null && savedStatus.isNotEmpty) {
        currentStatusNotifier.value = savedStatus;
        isOnInactivityBreakNotifier.value = (savedStatus == 'BREAK');
      }

      if (savedIsManualOff != null) {
        isManualOffNotifier.value = savedIsManualOff;
      } else if (savedStatus != null) {
        isManualOffNotifier.value = (savedStatus == 'INACTIVE');
      }

      if (savedStartedAt != null && savedStartedAt.isNotEmpty) {
        manualOffStartedAtNotifier.value = DateTime.tryParse(savedStartedAt);
      }

      if (savedRemaining != null) {
        int liveRemaining = savedRemaining;
        final isOff = currentStatusNotifier.value == 'INACTIVE' || isManualOffNotifier.value;
        if (isOff && savedTimestamp != null && !savedLimitExpired) {
          final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - savedTimestamp) ~/ 1000;
          liveRemaining = (savedRemaining - elapsedSeconds).clamp(0, kMaxManualOffSeconds);
        }
        remainingOffSecondsNotifier.value = liveRemaining;
        isOffLimitExpiredNotifier.value = savedLimitExpired || liveRemaining <= 0;

        if (isOff && !isOffLimitExpiredNotifier.value) {
          _startManualOffCountdown(initialRemaining: liveRemaining);
        } else {
          _stopManualOffCountdown();
        }
      }
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error restoring local state: $e');
    }
  }

  void _updateFromApiResponse(Map<String, dynamic> data) {
    final status = (data['availability'] ?? data['availability_status'] ?? currentStatusNotifier.value).toString().toUpperCase();
    if (status.isNotEmpty) {
      currentStatusNotifier.value = status;
      if (status == 'BREAK') {
        isOnInactivityBreakNotifier.value = true;
      } else {
        isOnInactivityBreakNotifier.value = false;
      }
    }

    final isOff = status == 'INACTIVE' || data['isManuallyOff'] == true;
    isManualOffNotifier.value = isOff;

    if (data.containsKey('remainingOffSeconds')) {
      final rem = (data['remainingOffSeconds'] as num?)?.toInt() ?? kMaxManualOffSeconds;
      remainingOffSecondsNotifier.value = rem.clamp(0, kMaxManualOffSeconds);
      if (rem <= 0 || data['limitReached'] == true) {
        isOffLimitExpiredNotifier.value = true;
      } else {
        isOffLimitExpiredNotifier.value = false;
      }
    }
    if (data.containsKey('manualOffStartedAt')) {
      final str = data['manualOffStartedAt']?.toString();
      manualOffStartedAtNotifier.value = (str != null && str.isNotEmpty) ? DateTime.tryParse(str) : null;
    }

    if (isOff && !isOffLimitExpiredNotifier.value) {
      _startManualOffCountdown(initialRemaining: remainingOffSecondsNotifier.value);
    } else {
      _stopManualOffCountdown();
    }
    unawaited(_persistLocalState());
  }

  Future<void> init(String userId) async {
    _userId = userId;

    // Immediately restore cached state in 0ms before network request to prevent flicker on refresh
    await _restoreLocalState();

    await _checkShiftLockout();

    try {
      final data = await _repository.dashboard();
      _updateFromApiResponse(data);
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Dashboard fetch error: $e');
    }

    if (isActive) {
      _startHeartbeat();
    } else {
      _stopHeartbeat();
    }

    if (!isShiftLockedOutNotifier.value && !isOnInactivityBreakNotifier.value) {
      _resetInactivityTimer();
    }

    _shiftCheckTimer?.cancel();
    _shiftCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkShiftLockout();
      _checkAvailabilityStatus();
    });

    isInitializedNotifier.value = true;
  }

  Future<void> _checkAvailabilityStatus() async {
    if (_userId == null) return;
    try {
      final res = await _repository.getAvailability();
      _updateFromApiResponse(res);
      final status = (res['availability_status'] ?? res['availability'] ?? '').toString().toUpperCase();
      if (status.isNotEmpty && status != currentStatusNotifier.value && !isOnInactivityBreakNotifier.value) {
        currentStatusNotifier.value = status;
      }
      await _persistLocalState();
    } catch (_) {}
  }

  void recordUserActivity() {
    if (_userId == null) return;
    if (isShiftLockedOutNotifier.value) return;

    // If currently on inactivity break:
    // Any user interaction resumes from break!
    if (isOnInactivityBreakNotifier.value) {
      resumeFromBreak();
      return;
    }

    // Inactivity timer applies whether Active OR Inactive (toggle OFF)
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: kInactivityTimeoutSeconds), _onInactivityTriggered);
  }

  Future<void> _onInactivityTriggered() async {
    if (_userId == null) return;
    if (isOnInactivityBreakNotifier.value) return;
    if (isShiftLockedOutNotifier.value) return;

    debugPrint('[TelecallerShiftManager] 5 minutes of inactivity detected. Triggering break.');
    isOnInactivityBreakNotifier.value = true;
    _stopHeartbeat();
    _stopManualOffCountdown(); // Immediately pause the 6-hour timer when break triggers!

    try {
      final res = await _repository.setAvailability('BREAK', isManual: false);
      currentStatusNotifier.value = 'BREAK';
      _updateFromApiResponse(res);
      await _persistLocalState();
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error setting break on inactivity: $e');
    }
  }

  Future<bool> resumeFromBreak() async {
    if (isShiftLockedOutNotifier.value) return false;
    isOnInactivityBreakNotifier.value = false;

    final wasOff = isManualOffNotifier.value;
    final targetStatus = wasOff ? 'INACTIVE' : 'ACTIVE';
    try {
      final res = await _repository.setAvailability(targetStatus, isManual: wasOff);
      currentStatusNotifier.value = targetStatus;
      _updateFromApiResponse(res);

      if (!wasOff) {
        _startHeartbeat();
      }
      _resetInactivityTimer();
      await _persistLocalState();
      return true;
    } catch (e) {
      debugPrint('[TelecallerShiftManager] Error resuming from break: $e');
      return false;
    }
  }

  Future<bool> resumeActive() async {
    return resumeFromBreak();
  }

  Future<void> handleLogout() async {
    _stopManualOffCountdown();
    _stopHeartbeat();
    _inactivityTimer?.cancel();
    _shiftCheckTimer?.cancel();
    try {
      await _repository.setAvailability('LOGGED_OUT', isManual: isManualOffNotifier.value);
    } catch (_) {}
    await _persistLocalState();
  }

  Future<bool> toggleAvailability(bool shouldBeActive) async {
    if (shouldBeActive && isShiftLockedOutNotifier.value) {
      debugPrint('[TelecallerShiftManager] Cannot activate: 9-hour daily shift limit reached.');
      return false;
    }

    if (!shouldBeActive && isOffLimitExpiredNotifier.value) {
      debugPrint('[TelecallerShiftManager] Cannot turn OFF: 6-hour OFF limit reached.');
      return false;
    }

    final targetStatus = shouldBeActive ? 'ACTIVE' : 'INACTIVE';
    try {
      final res = await _repository.setAvailability(targetStatus, isManual: true);
      currentStatusNotifier.value = targetStatus;
      isManualOffNotifier.value = !shouldBeActive;
      _updateFromApiResponse(res);

      if (shouldBeActive) {
        await _recordShiftStartIfNeeded();
        isOnInactivityBreakNotifier.value = false;
        _startHeartbeat();
        _resetInactivityTimer();
      } else {
        _stopHeartbeat();
        isOnInactivityBreakNotifier.value = false;
        _resetInactivityTimer(); // Inactivity timer also runs when OFF!
      }
      await _persistLocalState();
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
              final res = await _repository.setAvailability('INACTIVE', isManual: false);
              currentStatusNotifier.value = 'INACTIVE';
              _updateFromApiResponse(res);
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
    _stopManualOffCountdown();
    _stopHeartbeat();
    _userId = null;
    isInitializedNotifier.value = false;
    currentStatusNotifier.value = 'INACTIVE';
    isShiftLockedOutNotifier.value = false;
    isOnInactivityBreakNotifier.value = false;
    isManualOffNotifier.value = false;
    isOffLimitExpiredNotifier.value = false;
    remainingOffSecondsNotifier.value = kMaxManualOffSeconds;
    manualOffStartedAtNotifier.value = null;
  }
}
