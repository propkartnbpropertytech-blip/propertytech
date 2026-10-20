import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/performance_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File testLogFile;
  late PerformanceLogger logger;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('perf_logger_test_');
    testLogFile = File('${tempDir.path}/performance_metrics.jsonl');
    logger = PerformanceLogger();
    logger.resetForTesting(newLogFile: testLogFile);
  });

  tearDown(() async {
    logger.resetForTesting();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('PerformanceLogger Buffered I/O & Concurrency Tests', () {
    test('logMetric enqueues to in-memory pending buffer without synchronous disk write', () async {
      await logger.logMetric(
        operation: 'test_query_1',
        totalMs: 12,
        isarReadMs: 4,
        jsonParseMs: 2,
      );

      // Metric is enqueued in memory
      expect(logger.pendingBufferLength, 1);
      expect(logger.getLogs().length, 1);
      expect(logger.getLogs().first['operation'], 'test_query_1');

      // Delayed timer is active to flush later
      expect(logger.isDelayedTimerActive, isTrue);

      // File should NOT have been created/written synchronously yet
      expect(await testLogFile.exists(), isFalse);
    });

    test('reaches batch threshold (20 entries) and triggers automatic asynchronous flush', () async {
      for (int i = 0; i < PerformanceLogger.batchThreshold; i++) {
        await logger.logMetric(
          operation: 'batch_query_$i',
          totalMs: i + 1,
        );
      }

      // Allow microtask to process flush
      await Future.delayed(const Duration(milliseconds: 50));

      // Pending buffer should be drained
      expect(logger.pendingBufferLength, 0);

      // File should now exist with exactly 20 lines
      expect(await testLogFile.exists(), isTrue);
      final lines = await testLogFile.readAsLines();
      expect(lines.length, PerformanceLogger.batchThreshold);

      // Verify JSON structure of first and last line
      final first = jsonDecode(lines.first) as Map<String, dynamic>;
      final last = jsonDecode(lines.last) as Map<String, dynamic>;
      expect(first['operation'], 'batch_query_0');
      expect(last['operation'], 'batch_query_19');
    });

    test('manual flush drains pending buffer into a single batched JSONL write', () async {
      await logger.logMetric(operation: 'manual_op_1', totalMs: 5);
      await logger.logMetric(operation: 'manual_op_2', totalMs: 8);
      expect(logger.pendingBufferLength, 2);

      await logger.flush();

      expect(logger.pendingBufferLength, 0);
      expect(logger.isDelayedTimerActive, isFalse);

      final content = await testLogFile.readAsString();
      final lines = content.trim().split('\n');
      expect(lines.length, 2);
    });

    test('in-flight execution guard prevents overlapping flush operations', () async {
      for (int i = 0; i < 5; i++) {
        await logger.logMetric(operation: 'inflight_$i', totalMs: 10);
      }

      // Trigger two concurrent flushes
      final flush1 = logger.flush();
      final flush2 = logger.flush();
      await Future.wait([flush1, flush2]);

      expect(logger.pendingBufferLength, 0);
      expect(logger.isWriting, isFalse);

      final lines = await testLogFile.readAsLines();
      expect(lines.length, 5);
    });

    test('bounded buffer cap prevents memory leaks under failed writes (evicts oldest)', () async {
      // Intentionally point to an invalid directory to simulate disk failure
      final invalidFile = File('${tempDir.path}/non_existent_subdir/bad.jsonl');
      logger.resetForTesting(newLogFile: invalidFile);

      // Add more items than maxPendingBufferCap
      for (int i = 0; i < PerformanceLogger.maxPendingBufferCap + 20; i++) {
        await logger.logMetric(operation: 'overflow_$i', totalMs: 1);
      }

      // Buffer length must strictly never exceed maxPendingBufferCap
      expect(logger.pendingBufferLength, lessThanOrEqualTo(PerformanceLogger.maxPendingBufferCap));
    });

    test('storage rotation archives to .old when log file exceeds 1 MB', () async {
      // Create a file slightly larger than 1 MB
      final largeBuffer = StringBuffer();
      for (int i = 0; i < 20000; i++) {
        largeBuffer.writeln('{"op":"prefill","ts":"2026-10-16T12:00:00","total":100,"read":10}');
      }
      await testLogFile.writeAsString(largeBuffer.toString());
      final initialSize = await testLogFile.length();
      expect(initialSize, greaterThan(PerformanceLogger.maxLogFileSizeBytes));

      // Log a new metric and flush
      await logger.logMetric(operation: 'post_rotation_metric', totalMs: 42);
      await logger.flush();

      // Old backup file should now exist
      final backupFile = File('${testLogFile.path}.old');
      expect(await backupFile.exists(), isTrue);
      expect(await backupFile.length(), initialSize);

      // Current log file should now contain only the newly written entry
      final newLines = await testLogFile.readAsLines();
      expect(newLines.length, 1);
      final parsed = jsonDecode(newLines.first) as Map<String, dynamic>;
      expect(parsed['operation'], 'post_rotation_metric');
    });

    test('lifecycle backgrounding triggers automatic flush', () async {
      await logger.logMetric(operation: 'bg_metric_1', totalMs: 10);
      await logger.logMetric(operation: 'bg_metric_2', totalMs: 15);
      expect(logger.pendingBufferLength, 2);

      // Simulate app backgrounding
      logger.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(logger.pendingBufferLength, 0);
      expect(await testLogFile.exists(), isTrue);
      final lines = await testLogFile.readAsLines();
      expect(lines.length, 2);
    });

    test('readLogFile flushes pending buffer before returning complete file content', () async {
      await logger.logMetric(operation: 'read_test_1', totalMs: 5);
      await logger.logMetric(operation: 'read_test_2', totalMs: 7);
      expect(logger.pendingBufferLength, 2);

      final content = await logger.readLogFile();
      expect(content, contains('read_test_1'));
      expect(content, contains('read_test_2'));
      expect(logger.pendingBufferLength, 0);
    });
  });
}
