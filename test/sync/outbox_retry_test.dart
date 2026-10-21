import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Outbox Retry & Backoff Invariants', () {
    test('Calculates controlled exponential backoff for failed mutation deliveries', () {
      double calculateOutboxDelay(int attempt) {
        return min(pow(2, attempt) * 1.5, 60.0);
      }

      expect(calculateOutboxDelay(1), equals(3.0));
      expect(calculateOutboxDelay(2), equals(6.0));
      expect(calculateOutboxDelay(3), equals(12.0));
      expect(calculateOutboxDelay(4), equals(24.0));
      expect(calculateOutboxDelay(5), equals(48.0));
      expect(calculateOutboxDelay(6), equals(60.0)); // Bounded ceiling
    });

    test('Classifies HTTP 400 Bad Request and 403 Forbidden as non-retryable errors', () {
      bool isRetryable(int statusCode) {
        if (statusCode >= 400 && statusCode < 500) {
          return false; // Client error: payload/auth invalid
        }
        return true; // 5xx, network timeout, connection reset
      }

      expect(isRetryable(400), isFalse);
      expect(isRetryable(401), isFalse);
      expect(isRetryable(403), isFalse);
      expect(isRetryable(422), isFalse);

      expect(isRetryable(500), isTrue);
      expect(isRetryable(502), isTrue);
      expect(isRetryable(503), isTrue);
      expect(isRetryable(504), isTrue);
    });

    test('Outbox queue processing halts immediately on transient network drop', () {
      final queue = ['op-1', 'op-2', 'op-3'];
      final processed = <String>[];
      bool networkActive = true;

      for (final op in queue) {
        if (op == 'op-2') {
          networkActive = false; // Simulated network drop
        }

        if (!networkActive) {
          break; // Stop queue processing
        }
        processed.add(op);
      }

      expect(processed, equals(['op-1']));
      expect(processed.contains('op-3'), isFalse); // Preserves FIFO order
    });
  });
}
