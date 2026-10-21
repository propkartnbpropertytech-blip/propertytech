import 'dart:async';
import '../storage/performance_logger.dart';
import '../utils/app_logger.dart';

/// Represents a structured, privacy-safe telemetry event emitted after every
/// sync cycle (initial, delta, realtime batch, or outbox replay).
class SyncTelemetryRecord {
  final String syncId;
  final String? tenantId;
  final String syncType; // 'INITIAL', 'DELTA', 'REALTIME', 'OUTBOX'
  final String stateFrom;
  final String stateTo;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationMs;
  final int recordsReceived;
  final int recordsApplied;
  final int recordsSkipped;
  final int recordsFailed;
  final int outboxProcessed;
  final int outboxFailed;
  final int conflictsDetected;
  final int conflictsResolved;
  final int reconnectCount;
  final String? lastCheckpoint;
  final bool success;
  final String? failureReason;

  const SyncTelemetryRecord({
    required this.syncId,
    this.tenantId,
    required this.syncType,
    required this.stateFrom,
    required this.stateTo,
    required this.startedAt,
    required this.completedAt,
    required this.durationMs,
    this.recordsReceived = 0,
    this.recordsApplied = 0,
    this.recordsSkipped = 0,
    this.recordsFailed = 0,
    this.outboxProcessed = 0,
    this.outboxFailed = 0,
    this.conflictsDetected = 0,
    this.conflictsResolved = 0,
    this.reconnectCount = 0,
    this.lastCheckpoint,
    this.success = true,
    this.failureReason,
  });

  /// Serializes to JSON with strict PII / secret scrubbing.
  Map<String, dynamic> toJson() {
    return {
      'syncId': syncId,
      'tenantId': tenantId != null ? _sanitizeTenant(tenantId!) : null,
      'syncType': syncType,
      'stateFrom': stateFrom,
      'stateTo': stateTo,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'durationMs': durationMs,
      'recordsReceived': recordsReceived,
      'recordsApplied': recordsApplied,
      'recordsSkipped': recordsSkipped,
      'recordsFailed': recordsFailed,
      'outboxProcessed': outboxProcessed,
      'outboxFailed': outboxFailed,
      'conflictsDetected': conflictsDetected,
      'conflictsResolved': conflictsResolved,
      'reconnectCount': reconnectCount,
      'lastCheckpoint': lastCheckpoint,
      'success': success,
      'failureReason': failureReason != null ? _sanitizeError(failureReason!) : null,
    };
  }

  static String _sanitizeTenant(String tenant) {
    if (tenant.length <= 8) return tenant;
    return '${tenant.substring(0, 4)}...${tenant.substring(tenant.length - 4)}';
  }

  static String _sanitizeError(String err) {
    // Strip raw SQL queries or sensitive traces if present
    final sanitized = err
        .replaceAll(RegExp(r'SELECT .* FROM .*', caseSensitive: false), '[SQL QUERY REDACTED]')
        .replaceAll(RegExp(r'Bearer \S+', caseSensitive: false), 'Bearer [REDACTED]')
        .replaceAll(RegExp(r'password=\S+', caseSensitive: false), 'password=[REDACTED]');
    return sanitized.length > 200 ? '${sanitized.substring(0, 200)}...' : sanitized;
  }
}

/// Centralized sink and ring buffer for synchronization telemetry records.
class SyncTelemetryLogger {
  static final SyncTelemetryLogger _instance = SyncTelemetryLogger._internal();
  factory SyncTelemetryLogger() => _instance;
  SyncTelemetryLogger._internal();

  static const int maxBufferSize = 50;
  final List<SyncTelemetryRecord> _buffer = [];
  final StreamController<SyncTelemetryRecord> _streamController =
      StreamController<SyncTelemetryRecord>.broadcast();

  List<SyncTelemetryRecord> get recentRecords => List.unmodifiable(_buffer);
  Stream<SyncTelemetryRecord> get telemetryStream => _streamController.stream;

  void record(SyncTelemetryRecord entry) {
    if (_buffer.length >= maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(entry);
    _streamController.add(entry);

    PerformanceLogger().logMetric(
      operation: 'SyncTelemetry: [${entry.syncType}] ${entry.stateFrom} -> ${entry.stateTo} '
          '(${entry.durationMs}ms, applied: ${entry.recordsApplied}, conflicts: ${entry.conflictsResolved})',
      totalMs: entry.durationMs,
    );

    if (!entry.success) {
      AppLogger.w('SyncTelemetry: cycle failed: ${entry.failureReason}');
    }
  }

  void clear() {
    _buffer.clear();
  }
}
