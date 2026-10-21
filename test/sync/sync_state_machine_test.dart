import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_manager.dart';

void main() {
  group('SyncState Machine Deterministic Invariants', () {
    test('Supports all 10 canonical Step 9 states with uppercase string mapping', () {
      expect(SyncState.initializing.nameUpper, equals('INITIALIZING'));
      expect(SyncState.offline.nameUpper, equals('OFFLINE'));
      expect(SyncState.connecting.nameUpper, equals('CONNECTING'));
      expect(SyncState.syncing.nameUpper, equals('SYNCING'));
      expect(SyncState.live.nameUpper, equals('LIVE'));
      expect(SyncState.degraded.nameUpper, equals('DEGRADED'));
      expect(SyncState.reconnecting.nameUpper, equals('RECONNECTING'));
      expect(SyncState.conflictResolution.nameUpper, equals('CONFLICT_RESOLUTION'));
      expect(SyncState.error.nameUpper, equals('ERROR'));
      expect(SyncState.stopped.nameUpper, equals('STOPPED'));
    });

    test('Validates canonical forward transition pipeline: OFFLINE -> CONNECTING -> SYNCING -> LIVE', () {
      expect(SyncManager.isValidTransition(SyncState.offline, SyncState.connecting), isTrue);
      expect(SyncManager.isValidTransition(SyncState.connecting, SyncState.syncing), isTrue);
      expect(SyncManager.isValidTransition(SyncState.syncing, SyncState.live), isTrue);
    });

    test('Rejects direct shortcut from OFFLINE to LIVE without reconciliation', () {
      expect(SyncManager.isValidTransition(SyncState.offline, SyncState.live), isFalse);
    });

    test('Rejects redundant self-transitions (e.g. LIVE -> LIVE) to prevent concurrent sync loops', () {
      expect(SyncManager.isValidTransition(SyncState.live, SyncState.live), isFalse);
      expect(SyncManager.isValidTransition(SyncState.syncing, SyncState.syncing), isFalse);
      expect(SyncManager.isValidTransition(SyncState.connecting, SyncState.connecting), isFalse);
    });

    test('Handles socket disconnect flow: LIVE -> RECONNECTING -> CONNECTING -> SYNCING -> LIVE', () {
      expect(SyncManager.isValidTransition(SyncState.live, SyncState.reconnecting), isTrue);
      expect(SyncManager.isValidTransition(SyncState.reconnecting, SyncState.connecting), isTrue);
      expect(SyncManager.isValidTransition(SyncState.connecting, SyncState.syncing), isTrue);
      expect(SyncManager.isValidTransition(SyncState.syncing, SyncState.live), isTrue);
    });

    test('Handles conflict flow: SYNCING -> CONFLICT_RESOLUTION -> SYNCING -> LIVE', () {
      expect(SyncManager.isValidTransition(SyncState.syncing, SyncState.conflictResolution), isTrue);
      expect(SyncManager.isValidTransition(SyncState.conflictResolution, SyncState.syncing), isTrue);
      expect(SyncManager.isValidTransition(SyncState.syncing, SyncState.live), isTrue);
    });

    test('Handles degradation flow: SYNCING -> DEGRADED -> SYNCING', () {
      expect(SyncManager.isValidTransition(SyncState.syncing, SyncState.degraded), isTrue);
      expect(SyncManager.isValidTransition(SyncState.degraded, SyncState.syncing), isTrue);
    });

    test('Handles unrecoverable error and stopped states', () {
      expect(SyncManager.isValidTransition(SyncState.connecting, SyncState.error), isTrue);
      expect(SyncManager.isValidTransition(SyncState.reconnecting, SyncState.error), isTrue);
      expect(SyncManager.isValidTransition(SyncState.live, SyncState.stopped), isTrue);
      expect(SyncManager.isValidTransition(SyncState.stopped, SyncState.initializing), isTrue);
    });
  });
}
