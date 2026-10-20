import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';

/// Centralized, high-performance structured performance telemetry logger.
///
/// Remediated in Step 8 to eliminate synchronous/forced disk flushing (`flush: true`)
/// that previously caused 5–15ms I/O micro-stalls on the main Dart/UI isolate.
///
/// Features:
/// 1. Bounded In-Memory Queue: Keeps recent 100 entries for in-app debug views.
/// 2. Asynchronous Batched Persistence: Batches up to 20 entries or flushes on a
///    5-second one-shot delayed timer with non-blocking `flush: false`.
/// 3. In-Flight Execution Guard: Prevents concurrent file open/append collisions.
/// 4. Storage Rotation: Enforces a 1 MB file size limit with `.old` rotation.
/// 5. Lifecycle Flush: Listens to [WidgetsBindingObserver] to persist pending
///    logs on background or termination.
/// 6. Zero Periodic Polling: Zero timers active when the queue is idle.
class PerformanceLogger with WidgetsBindingObserver {
  static final PerformanceLogger _instance = PerformanceLogger._internal();
  factory PerformanceLogger() => _instance;

  PerformanceLogger._internal() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  static const int maxInMemoryLogs = 100;
  static const int batchThreshold = 20;
  static const int maxPendingBufferCap = 250;
  static const int maxLogFileSizeBytes = 1024 * 1024; // 1 MB rotation cap
  static const Duration delayedFlushDuration = Duration(seconds: 5);

  final List<Map<String, dynamic>> _inMemoryLogs = [];
  final List<Map<String, dynamic>> _pendingBuffer = [];

  File? _logFile;
  Timer? _delayedFlushTimer;
  bool _isWriting = false;

  /// Initializes the logger and resolves local storage destination.
  Future<void> initialize({File? customLogFile}) async {
    if (customLogFile != null) {
      _logFile = customLogFile;
      return;
    }

    if (kIsWeb) {
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/performance_metrics.jsonl');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PerformanceLogger] Failed to resolve log directory: $e');
      }
    }
  }

  /// Records a structured telemetry metric without blocking the caller on disk I/O.
  Future<void> logMetric({
    required String operation,
    int isarReadMs = 0,
    int networkMs = 0,
    int jsonParseMs = 0,
    int isarWriteMs = 0,
    required int totalMs,
  }) async {
    final entry = {
      'operation': operation,
      'isarReadMs': isarReadMs,
      'networkMs': networkMs,
      'jsonParseMs': jsonParseMs,
      'isarWriteMs': isarWriteMs,
      'totalMs': totalMs,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 1. Maintain bounded in-memory history for Debug Screen
    _inMemoryLogs.add(entry);
    if (_inMemoryLogs.length > maxInMemoryLogs) {
      _inMemoryLogs.removeAt(0);
    }

    // 2. Structured console telemetry in debug mode
    AppLogger.telemetry(
      operation,
      isarReadMs: isarReadMs,
      networkMs: networkMs,
      jsonParseMs: jsonParseMs,
      isarWriteMs: isarWriteMs,
      totalMs: totalMs,
    );

    // 3. Skip disk persistence on Web or before file initialization
    if (kIsWeb || _logFile == null) return;

    // 4. Enqueue to bounded persistent buffer
    if (_pendingBuffer.length >= maxPendingBufferCap) {
      _pendingBuffer.removeAt(0); // Evict oldest on overflow
    }
    _pendingBuffer.add(entry);

    // 5. Trigger immediate batch write or schedule one-shot delayed flush
    if (_pendingBuffer.length >= batchThreshold) {
      unawaited(flush());
    } else {
      _scheduleDelayedFlush();
    }
  }

  /// Flushes all pending in-memory entries to local disk in a single batched append.
  /// Uses non-blocking `flush: false` to allow the OS buffer cache to manage write-back.
  Future<void> flush() async {
    _delayedFlushTimer?.cancel();
    _delayedFlushTimer = null;

    final file = _logFile;
    if (kIsWeb || file == null || _pendingBuffer.isEmpty || _isWriting) {
      return;
    }

    _isWriting = true;
    final batch = List<Map<String, dynamic>>.from(_pendingBuffer);
    _pendingBuffer.clear();

    try {
      await _checkAndRotateLogFile(file);

      // Aggregate all entries into a single string buffer
      final buffer = StringBuffer();
      for (final item in batch) {
        buffer.writeln(jsonEncode(item));
      }

      // Asynchronous append with non-blocking flush: false
      await file.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
        flush: false,
      );
    } catch (e) {
      // Re-queue failed batch up to buffer capacity
      if (_pendingBuffer.length + batch.length <= maxPendingBufferCap) {
        _pendingBuffer.insertAll(0, batch);
      }
      if (kDebugMode) {
        debugPrint('[PerformanceLogger] Failed to flush batch: $e');
      }
    } finally {
      _isWriting = false;
      if (_pendingBuffer.length >= batchThreshold) {
        unawaited(flush());
      } else if (_pendingBuffer.isNotEmpty) {
        _scheduleDelayedFlush();
      }
    }
  }

  void _scheduleDelayedFlush() {
    if (_delayedFlushTimer != null && _delayedFlushTimer!.isActive) {
      return;
    }
    _delayedFlushTimer = Timer(delayedFlushDuration, () {
      unawaited(flush());
    });
  }

  /// Rotates the log file when it exceeds the 1 MB size limit.
  Future<void> _checkAndRotateLogFile(File file) async {
    try {
      if (await file.exists()) {
        final length = await file.length();
        if (length > maxLogFileSizeBytes) {
          final backupFile = File('${file.path}.old');
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
          await file.rename(backupFile.path);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PerformanceLogger] Log rotation exception: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(flush());
    }
  }

  /// Returns recent in-memory log history for debug screen consumption.
  List<Map<String, dynamic>> getLogs() => List.unmodifiable(_inMemoryLogs);

  /// Reads persisted log file contents. Ensures any pending buffer is flushed first.
  Future<String> readLogFile() async {
    try {
      if (_pendingBuffer.isNotEmpty) {
        await flush();
      }
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (_) {}
    return '';
  }

  /// Disposes resources and observer hooks.
  void dispose() {
    _delayedFlushTimer?.cancel();
    _delayedFlushTimer = null;
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Testing Helpers
  // ---------------------------------------------------------------------------

  @visibleForTesting
  int get pendingBufferLength => _pendingBuffer.length;

  @visibleForTesting
  bool get isDelayedTimerActive => _delayedFlushTimer != null && _delayedFlushTimer!.isActive;

  @visibleForTesting
  bool get isWriting => _isWriting;

  @visibleForTesting
  File? get logFile => _logFile;

  @visibleForTesting
  void resetForTesting({File? newLogFile}) {
    _delayedFlushTimer?.cancel();
    _delayedFlushTimer = null;
    _inMemoryLogs.clear();
    _pendingBuffer.clear();
    _isWriting = false;
    _logFile = newLogFile;
  }
}
