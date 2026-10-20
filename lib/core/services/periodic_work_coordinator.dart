import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../utils/app_logger.dart';

/// Defines a periodic background or polling task managed by [PeriodicWorkCoordinator].
class PeriodicTask {
  final String id;
  final Duration interval;
  final Future<void> Function() action;
  final bool canRunInBackground;
  final bool requiresAuth;
  final bool immediateOnRegister;

  bool isRunning = false;
  bool isPaused = false;
  DateTime? lastRunAt;
  Timer? _timer;

  PeriodicTask({
    required this.id,
    required this.interval,
    required this.action,
    this.canRunInBackground = false,
    this.requiresAuth = true,
    this.immediateOnRegister = false,
  });
}

/// Centralized coordinator for all periodic operations, polling timers, and background tasks.
///
/// Prevents:
/// - Uncoordinated isolate wakeups
/// - Overlapping execution of asynchronous jobs (in-flight locks)
/// - Duplicate timer registrations
/// - Timers running while the app is backgrounded
/// - Unauthenticated polling loops running after logout
class PeriodicWorkCoordinator with WidgetsBindingObserver {
  PeriodicWorkCoordinator._();
  static final PeriodicWorkCoordinator instance = PeriodicWorkCoordinator._();

  final Map<String, PeriodicTask> _tasks = {};
  bool _isInitialized = false;
  bool _isBackgrounded = false;
  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserRole;

  bool get isBackgrounded => _isBackgrounded;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  int get activeTaskCount => _tasks.values.where((t) => t._timer != null && !t.isPaused).length;
  List<String> get registeredTaskIds => _tasks.keys.toList();

  /// Initialize the coordinator and attach lifecycle observers.
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Headless / unit testing environment safe fallback
    }
  }

  /// Register and start a periodic task.
  /// If a task with the same [id] is already registered, the old timer is cancelled
  /// and replaced cleanly to guarantee zero duplicate timers.
  void registerTask(PeriodicTask task) {
    init();

    // Cancel existing task timer if re-registering
    if (_tasks.containsKey(task.id)) {
      _tasks[task.id]?._timer?.cancel();
    }

    _tasks[task.id] = task;

    // Determine if task should immediately start its timer
    final shouldPause = (_isBackgrounded && !task.canRunInBackground) ||
        (task.requiresAuth && !_isAuthenticated);

    if (shouldPause) {
      task.isPaused = true;
      AppLogger.d('[PeriodicWorkCoordinator] Task "${task.id}" registered in paused state (bg: $_isBackgrounded, auth: $_isAuthenticated)');
      return;
    }

    _startTaskTimer(task);

    if (task.immediateOnRegister) {
      unawaited(_executeTask(task));
    }
  }

  /// Unregister and cancel a task.
  void unregisterTask(String id) {
    final task = _tasks.remove(id);
    if (task != null) {
      task._timer?.cancel();
      task._timer = null;
      task.isPaused = true;
      AppLogger.d('[PeriodicWorkCoordinator] Task "$id" unregistered and cancelled.');
    }
  }

  /// Manually pause a task.
  void pauseTask(String id) {
    final task = _tasks[id];
    if (task != null) {
      task._timer?.cancel();
      task._timer = null;
      task.isPaused = true;
    }
  }

  /// Manually resume a task.
  void resumeTask(String id, {bool triggerIfStale = true}) {
    final task = _tasks[id];
    if (task == null) return;

    if (task.requiresAuth && !_isAuthenticated) return;
    if (_isBackgrounded && !task.canRunInBackground) return;

    task.isPaused = false;
    _startTaskTimer(task);

    if (triggerIfStale && _isTaskStale(task)) {
      unawaited(_executeTask(task));
    }
  }

  void _startTaskTimer(PeriodicTask task) {
    task._timer?.cancel();
    task.isPaused = false;
    task._timer = Timer.periodic(task.interval, (_) {
      _executeTask(task);
    });
  }

  /// Executes a task with in-flight guard protection against concurrent overlap.
  Future<void> _executeTask(PeriodicTask task) async {
    if (task.isRunning) {
      AppLogger.d('[PeriodicWorkCoordinator] Task "${task.id}" is already executing. Skipping overlapping tick.');
      return;
    }

    if (task.isPaused) return;
    if (_isBackgrounded && !task.canRunInBackground) return;
    if (task.requiresAuth && !_isAuthenticated) return;

    task.isRunning = true;
    try {
      await task.action();
      task.lastRunAt = DateTime.now();
    } catch (e, stack) {
      AppLogger.w('[PeriodicWorkCoordinator] Task "${task.id}" encountered error: $e');
      if (kDebugMode) {
        debugPrint('[PeriodicWorkCoordinator] Stack trace: $stack');
      }
    } finally {
      task.isRunning = false;
    }
  }

  bool _isTaskStale(PeriodicTask task) {
    final last = task.lastRunAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= task.interval;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
    }
  }

  void _handleAppBackgrounded() {
    if (_isBackgrounded) return;
    _isBackgrounded = true;
    AppLogger.i('[PeriodicWorkCoordinator] App entered background. Pausing eligible periodic tasks.');

    for (final task in _tasks.values) {
      if (!task.canRunInBackground) {
        task._timer?.cancel();
        task._timer = null;
        task.isPaused = true;
      }
    }
  }

  void _handleAppResumed() {
    if (!_isBackgrounded) return;
    _isBackgrounded = false;
    AppLogger.i('[PeriodicWorkCoordinator] App resumed foreground. Restoring periodic tasks.');

    int delayOffsetMs = 0;
    for (final task in _tasks.values) {
      if (task.requiresAuth && !_isAuthenticated) continue;

      task.isPaused = false;
      _startTaskTimer(task);

      // Stagger stale refreshes to avoid thundering-herd on foreground resume
      if (_isTaskStale(task)) {
        final currentOffset = delayOffsetMs;
        delayOffsetMs += 150; // 150ms stagger between resumes
        Future.delayed(Duration(milliseconds: currentOffset), () {
          if (!_isBackgrounded && !task.isPaused) {
            _executeTask(task);
          }
        });
      }
    }
  }

  /// Hook called when a user successfully logs in.
  void onLogin({required String userId, required String role}) {
    _isAuthenticated = true;
    _currentUserId = userId;
    _currentUserRole = role;
    AppLogger.i('[PeriodicWorkCoordinator] User $userId logged in ($role). Starting authenticated tasks.');

    for (final task in _tasks.values) {
      if (task.requiresAuth) {
        task.isPaused = false;
        if (!_isBackgrounded || task.canRunInBackground) {
          _startTaskTimer(task);
          if (task.immediateOnRegister || _isTaskStale(task)) {
            unawaited(_executeTask(task));
          }
        }
      }
    }
  }

  /// Hook called when user logs out or session is invalidated.
  void onLogout() {
    _isAuthenticated = false;
    _currentUserId = null;
    _currentUserRole = null;
    AppLogger.i('[PeriodicWorkCoordinator] User logged out. Stopping authenticated periodic tasks.');

    for (final task in _tasks.values) {
      if (task.requiresAuth) {
        task._timer?.cancel();
        task._timer = null;
        task.isPaused = true;
      }
    }
  }

  /// Reset all tasks and state for unit tests.
  @visibleForTesting
  void resetForTesting() {
    for (final task in _tasks.values) {
      task._timer?.cancel();
    }
    _tasks.clear();
    _isBackgrounded = false;
    _isAuthenticated = false;
    _currentUserId = null;
    _currentUserRole = null;
    _isInitialized = false;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }
}
