import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flutter Architecture Rules — Step 6 Compliance', () {
    final libDir = Directory('lib');

    test('Extracted presentation widgets and use-cases do NOT import isar_collections.dart directly', () {
      final extractedFiles = [
        'lib/features/requirements/widgets/requirement_summary_bar.dart',
        'lib/features/requirements/widgets/requirement_filter_bar.dart',
        'lib/features/requirements/widgets/requirement_action_dialogs.dart',
        'lib/features/campaign/widgets/campaign_column_settings_dialog.dart',
        'lib/features/campaign/widgets/lead_reclassify_dialog.dart',
        'lib/features/admin/screens/lead_allocation_monitor_screen.dart',
        'lib/features/requirements/domain/usecases/load_requirements_usecase.dart',
        'lib/features/requirements/domain/usecases/update_requirement_status_usecase.dart',
        'lib/features/campaign/domain/usecases/reclassify_campaign_lead_usecase.dart',
      ];

      final violations = <String>[];
      for (final path in extractedFiles) {
        final file = File(path);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.contains('isar_collections.dart')) {
            violations.add(path);
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Extracted modular presentation widgets and use cases must NOT depend directly on Isar schema. Violations: $violations',
      );
    });

    test('Primary restructured screens do NOT import dio_client.dart directly', () {
      final targetedScreens = [
        'lib/features/requirements/screens/requirements_screen.dart',
        'lib/features/campaign/screens/campaign_leads_screen.dart',
        'lib/features/admin/screens/lead_allocation_monitor_screen.dart',
      ];

      final violations = <String>[];

      for (final screenPath in targetedScreens) {
        final file = File(screenPath);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.contains('dio_client.dart') || content.contains('package:dio/dio.dart')) {
            violations.add(screenPath);
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Restructured screens must delegate network operations to repositories/services. Violations: $violations',
      );
    });

    test('BLoC files do NOT declare Widget subclasses (StatelessWidget/StatefulWidget)', () {
      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final normalizedPath = entity.path.replaceAll(r'\', '/');
          final isBloc = normalizedPath.contains('/bloc/');

          if (isBloc) {
            final content = entity.readAsStringSync();
            // A pure BLoC must not define UI widgets
            if (content.contains('extends StatelessWidget') ||
                content.contains('extends StatefulWidget')) {
              violations.add(normalizedPath);
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'BLoC layer must remain purely reactive business logic without embedded UI widgets. Found: $violations',
      );
    });

    test('Lead Allocation Monitor BLoC size ceiling (< 350 lines)', () {
      final blocFile = File('lib/features/admin/bloc/lead_allocation_monitor_bloc.dart');
      expect(blocFile.existsSync(), isTrue);

      final lineCount = blocFile.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(350),
        reason: 'LeadAllocationMonitorBloc should be < 350 lines after screen extraction. Current: $lineCount',
      );
    });

    test('Extracted requirements domain use cases and widgets exist', () {
      final requiredFiles = [
        'lib/features/requirements/domain/usecases/load_requirements_usecase.dart',
        'lib/features/requirements/domain/usecases/update_requirement_status_usecase.dart',
        'lib/features/requirements/widgets/requirement_summary_bar.dart',
        'lib/features/requirements/widgets/requirement_filter_bar.dart',
        'lib/features/requirements/widgets/requirement_action_dialogs.dart',
      ];

      for (final p in requiredFiles) {
        expect(File(p).existsSync(), isTrue, reason: 'Expected $p to exist.');
      }
    });

    test('Extracted campaign domain use cases and widgets exist', () {
      final requiredFiles = [
        'lib/features/campaign/domain/usecases/reclassify_campaign_lead_usecase.dart',
        'lib/features/campaign/widgets/campaign_column_settings_dialog.dart',
        'lib/features/campaign/widgets/lead_reclassify_dialog.dart',
      ];

      for (final p in requiredFiles) {
        expect(File(p).existsSync(), isTrue, reason: 'Expected $p to exist.');
      }
    });

    test('Extracted admin screens exist and are decoupled', () {
      final screenFile = File('lib/features/admin/screens/lead_allocation_monitor_screen.dart');
      expect(screenFile.existsSync(), isTrue, reason: 'Extracted LeadAllocationMonitorScreen must exist');
      
      final content = screenFile.readAsStringSync();
      expect(content.contains('class LeadAllocationMonitorScreen'), isTrue);
    });
  });
}
