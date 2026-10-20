import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/services/periodic_work_coordinator.dart';
import 'package:propkart/core/telemetry/audit_telemetry_service.dart';
import 'package:propkart/features/telecaller/services/telecaller_shift_manager.dart';
import 'package:propkart/features/telecaller/telecaller_heartbeat_service.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PeriodicWorkCoordinator Unit & Lifecycle Tests', () {
    late PeriodicWorkCoordinator coordinator;

    setUp(() {
      coordinator = PeriodicWorkCoordinator.instance;
      coordinator.resetForTesting();
    });

    tearDown(() {
      coordinator.resetForTesting();
    });

    test('registers a periodic task and starts timer', () {
      int executions = 0;
      final task = PeriodicTask(
        id: 'test_task_1',
        interval: const Duration(milliseconds: 50),
        requiresAuth: false,
        action: () async {
          executions++;
        },
      );

      coordinator.registerTask(task);

      expect(coordinator.registeredTaskIds, contains('test_task_1'));
      expect(coordinator.activeTaskCount, 1);
      expect(executions, 0);
    });

    test('re-registering the same task ID cancels old timer and replaces it (no duplicate timers)', () {
      final task1 = PeriodicTask(
        id: 'dup_task',
        interval: const Duration(seconds: 10),
        requiresAuth: false,
        action: () async {},
      );

      final task2 = PeriodicTask(
        id: 'dup_task',
        interval: const Duration(seconds: 20),
        requiresAuth: false,
        action: () async {},
      );

      coordinator.registerTask(task1);
      coordinator.registerTask(task2);

      expect(coordinator.registeredTaskIds.where((id) => id == 'dup_task').length, 1);
      expect(coordinator.activeTaskCount, 1);
    });

    test('unregisterTask cancels timer and removes task', () {
      final task = PeriodicTask(
        id: 'removable_task',
        interval: const Duration(seconds: 5),
        requiresAuth: false,
        action: () async {},
      );

      coordinator.registerTask(task);
      expect(coordinator.activeTaskCount, 1);

      coordinator.unregisterTask('removable_task');
      expect(coordinator.registeredTaskIds, isNot(contains('removable_task')));
      expect(coordinator.activeTaskCount, 0);
    });

    test('in-flight execution guard prevents overlapping async ticks', () async {
      int concurrentExecutions = 0;
      int maxConcurrencyObserved = 0;
      int totalStarts = 0;

      final completer = Completer<void>();

      final task = PeriodicTask(
        id: 'slow_task',
        interval: const Duration(seconds: 10),
        requiresAuth: false,
        action: () async {
          totalStarts++;
          concurrentExecutions++;
          if (concurrentExecutions > maxConcurrencyObserved) {
            maxConcurrencyObserved = concurrentExecutions;
          }
          // Block until released
          await completer.future;
          concurrentExecutions--;
        },
      );

      coordinator.registerTask(task);

      // Trigger first execution
      coordinator.resumeTask('slow_task', triggerIfStale: true);

      // Give a moment for first tick to enter
      await Future.delayed(const Duration(milliseconds: 10));
      expect(task.isRunning, isTrue);

      // Trigger second tick while first is still blocked in async work
      coordinator.resumeTask('slow_task', triggerIfStale: true);
      await Future.delayed(const Duration(milliseconds: 10));

      // Release first execution
      completer.complete();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(maxConcurrencyObserved, 1, reason: 'Concurrency must never exceed 1');
      expect(totalStarts, 1, reason: 'Second execution must be skipped by in-flight guard');
      expect(task.isRunning, isFalse, reason: 'Task isRunning must reset to false');
    });

    test('exception recovery: task isRunning resets to false even if action throws', () async {
      final task = PeriodicTask(
        id: 'failing_task',
        interval: const Duration(milliseconds: 50),
        requiresAuth: false,
        action: () async {
          throw Exception('Simulated network failure');
        },
      );

      coordinator.registerTask(task);
      coordinator.resumeTask('failing_task', triggerIfStale: true);

      await Future.delayed(const Duration(milliseconds: 20));

      expect(task.isRunning, isFalse, reason: 'Task lock must release after unhandled exception');
    });

    test('lifecycle awareness: paused state pauses non-background tasks', () {
      final fgTask = PeriodicTask(
        id: 'fg_task',
        interval: const Duration(seconds: 10),
        canRunInBackground: false,
        requiresAuth: false,
        action: () async {},
      );

      final bgTask = PeriodicTask(
        id: 'bg_task',
        interval: const Duration(seconds: 10),
        canRunInBackground: true,
        requiresAuth: false,
        action: () async {},
      );

      coordinator.registerTask(fgTask);
      coordinator.registerTask(bgTask);
      expect(coordinator.activeTaskCount, 2);

      // Simulate app backgrounding
      coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(coordinator.isBackgrounded, isTrue);
      expect(fgTask.isPaused, isTrue);
      expect(bgTask.isPaused, isFalse);
      expect(coordinator.activeTaskCount, 1);

      // Simulate app resuming
      coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(coordinator.isBackgrounded, isFalse);
      expect(fgTask.isPaused, isFalse);
      expect(coordinator.activeTaskCount, 2);
    });

    test('auth boundaries: unauthenticated tasks do not start until login and stop on logout', () {
      final authTask = PeriodicTask(
        id: 'user_poll',
        interval: const Duration(seconds: 10),
        requiresAuth: true,
        action: () async {},
      );

      // Registered before login
      coordinator.registerTask(authTask);
      expect(authTask.isPaused, isTrue);
      expect(coordinator.activeTaskCount, 0);

      // User logs in
      coordinator.onLogin(userId: 'usr_123', role: 'Agent');
      expect(coordinator.isAuthenticated, isTrue);
      expect(authTask.isPaused, isFalse);
      expect(coordinator.activeTaskCount, 1);

      // User logs out
      coordinator.onLogout();
      expect(coordinator.isAuthenticated, isFalse);
      expect(authTask.isPaused, isTrue);
      expect(coordinator.activeTaskCount, 0);
    });
  });

  group('AuditTelemetryService Demand-Driven Flush Tests', () {
    test('does not run continuous flush timer when queue is empty', () {
      final telemetry = AuditTelemetryService.instance;
      // When newly initialized / disposed, no timer should run
      telemetry.dispose();
      expect(telemetry.isFlushTimerActive, isFalse);
      expect(telemetry.queueLength, 0);
    });

    test('pauseForBackground flushes queue and cancels timer', () {
      final telemetry = AuditTelemetryService.instance;
      telemetry.pauseForBackground();

      expect(telemetry.isFlushTimerActive, isFalse);
    });
  });

  group('Telecaller Heartbeat Consolidation Tests', () {
    test('TelecallerHeartbeatService delegates to TelecallerShiftManager without duplicate timer', () {
      final shiftManager = TelecallerShiftManager.instance;
      shiftManager.dispose();

      final heartbeatService = TelecallerHeartbeatService.instance;
      heartbeatService.stop();

      expect(heartbeatService.isRunning, isFalse);
      expect(shiftManager.isHeartbeatActive, isFalse);

      // For non-telecaller role, heartbeat should not start
      final nonTelecallerState = Authenticated(
        user: const UserModel(
          id: 'user_admin',
          fullName: 'Admin User',
          email: 'admin@test.com',
          role: 'Admin',
          permissions: [],
        ),
      );
      heartbeatService.start(nonTelecallerState);
      expect(heartbeatService.isRunning, isFalse);
      expect(shiftManager.isHeartbeatActive, isFalse);

      heartbeatService.stop();
      shiftManager.dispose();
    });

    test('TelecallerShiftManager pauseForBackground cancels countdown and shift timers', () {
      final shiftManager = TelecallerShiftManager.instance;
      shiftManager.pauseForBackground();

      // Ensure backgrounding does not crash and leaves state consistent
      expect(shiftManager.isShiftLockedOutNotifier.value, isFalse);
    });
  });
}
