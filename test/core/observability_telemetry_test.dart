import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:propkart/core/api/logging_interceptor.dart';
import 'package:propkart/core/utils/app_logger.dart';
import 'package:propkart/core/network/sync_telemetry.dart';

void main() {
  group('Step 12: Flutter Observability & Telemetry Tests', () {
    test('LoggingInterceptor generates and injects X-Request-Id and X-Correlation-Id', () {
      final interceptor = LoggingInterceptor();
      final options = RequestOptions(path: '/api/v1/properties');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['X-Request-Id'], isNotNull);
      expect(options.headers['X-Correlation-Id'], isNotNull);
      expect(options.headers['X-Request-Id'], equals(options.headers['X-Correlation-Id']));
      expect(options.extra['_requestId'], equals(options.headers['X-Request-Id']));

      // UUIDv4 format check
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
      expect(uuidRegex.hasMatch(options.headers['X-Request-Id']), isTrue);
    });

    test('LoggingInterceptor preserves pre-existing client correlation ID', () {
      final interceptor = LoggingInterceptor();
      const customId = 'custom-correlation-998877';
      final options = RequestOptions(
        path: '/api/v1/requirements',
        headers: {'X-Request-Id': customId},
      );

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['X-Request-Id'], equals(customId));
      expect(options.headers['X-Correlation-Id'], equals(customId));
      expect(options.extra['_requestId'], equals(customId));
    });

    test('AppLogger redacts sensitive tokens, passwords, and authorization headers', () {
      const sensitiveText = 'Authorization: Bearer secret_token_12345 password="supersecret"';
      final redacted = AppLogger.redact(sensitiveText);

      expect(redacted.contains('secret_token_12345'), isFalse);
      expect(redacted.contains('supersecret'), isFalse);
      expect(redacted.contains('[REDACTED]'), isTrue);
    });

    test('SyncTelemetryRecord sanitizes tenant identifiers and scrubs raw SQL and secrets', () {
      final record = SyncTelemetryRecord(
        syncId: 'sync-1001',
        tenantId: 'tenant-enterprise-alpha-999',
        syncType: 'DELTA',
        stateFrom: 'IDLE',
        stateTo: 'SYNCED',
        startedAt: DateTime.now().subtract(const Duration(milliseconds: 250)),
        completedAt: DateTime.now(),
        durationMs: 250,
        recordsReceived: 50,
        recordsApplied: 50,
        success: false,
        failureReason: 'SELECT * FROM users WHERE password=secret123 failed with Bearer abcdef12345',
      );

      final json = record.toJson();

      // Tenant sanitization check
      expect(json['tenantId'], equals('tena...-999'));
      // Error SQL & Secret scrubbing check
      expect(json['failureReason'].toString().contains('secret123'), isFalse);
      expect(json['failureReason'].toString().contains('abcdef12345'), isFalse);
      expect(json['failureReason'].toString().contains('[SQL QUERY REDACTED]'), isTrue);
      expect(json['failureReason'].toString().contains('Bearer [REDACTED]'), isTrue);
    });
  });
}
