import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 36: Architectural Guardrails & Separation of Concerns', () {
    test('UI widgets must not directly control SyncEngine, checkpoints, or WebSocket channels', () {
      final uiDir = Directory('lib/features');
      expect(uiDir.existsSync(), isTrue);

      final dartFiles = uiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains(RegExp(r'screens|widgets')) && f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // UI should not be manually computing diffs or manipulating socket sinks
        if (content.contains('SyncEngine.computeDiff') ||
            content.contains('WebSocketChannel.connect') ||
            content.contains('saveCheckpoint')) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty,
          reason: 'UI layer must not bypass repositories to orchestrate sync or checkpoints: $violations');
    });

    test('BLoCs and Cubits must not directly manipulate OutboxLocalRepository', () {
      final blocDir = Directory('lib/features');
      final blocFiles = blocDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => (f.path.contains('bloc') || f.path.contains('cubit')) && f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in blocFiles) {
        final content = file.readAsStringSync();
        if (content.contains('OutboxLocalRepository().queueRequest') ||
            content.contains('outboxLocal.queueRequest')) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty,
          reason: 'BLoCs must route through repositories, not directly queue outbox items: $violations');
    });

    test('SyncManager singleton is the authoritative orchestrator for synchronization', () {
      final syncFile = File('lib/core/network/sync_manager.dart');
      expect(syncFile.existsSync(), isTrue);
      final content = syncFile.readAsStringSync();

      expect(content.contains('class SyncManager'), isTrue);
      expect(content.contains('triggerDeltaSync'), isTrue);
      expect(content.contains('processOutboxQueue'), isTrue);
      expect(content.contains('pingDatabase'), isTrue);
    });
  });
}
