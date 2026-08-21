import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PerformanceLogger {
  static final PerformanceLogger _instance = PerformanceLogger._internal();
  factory PerformanceLogger() => _instance;
  PerformanceLogger._internal();

  final List<Map<String, dynamic>> _inMemoryLogs = [];
  File? _logFile;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/performance_metrics.jsonl');
    } catch (_) {}
  }

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

    _inMemoryLogs.add(entry);
    if (_inMemoryLogs.length > 100) {
      _inMemoryLogs.removeAt(0);
    }

    // Print structured telemetry to developer console
    print("⏱️ [TELEMETRY] $operation | IsarRead: ${isarReadMs}ms | Network: ${networkMs}ms | Parse: ${jsonParseMs}ms | IsarWrite: ${isarWriteMs}ms | Total: ${totalMs}ms");

    // Write to persistent local log file
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> getLogs() => List.unmodifiable(_inMemoryLogs);

  Future<String> readLogFile() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (_) {}
    return '';
  }
}
