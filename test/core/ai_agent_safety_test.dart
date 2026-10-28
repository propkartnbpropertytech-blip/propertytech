import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 14: AI-Agent Maintainability & Safety Guardrails Test Suite', () {
    test('1. Repository AI Governance & Manifest Discoverability', () {
      final agentsFile = File('AGENTS.md');
      expect(agentsFile.existsSync(), isTrue, reason: 'Root AGENTS.md must exist');
      final agentsContent = agentsFile.readAsStringSync();
      expect(agentsContent.contains('No Isolated Change'), isTrue, reason: 'Must contain the Core Law');
      expect(agentsContent.contains('DISCOVER'), isTrue, reason: 'Must contain DISCOVER lifecycle step');
      expect(agentsContent.contains('PLAN'), isTrue, reason: 'Must contain PLAN lifecycle step');
      expect(agentsContent.contains('STOP'), isTrue, reason: 'Must contain STOP condition');

      final manifestFile = File('docs/ai-agent/project-manifest.json');
      expect(manifestFile.existsSync(), isTrue, reason: 'project-manifest.json must exist');
      final manifestJson = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifestJson['project']?['name'], equals('PropKart'));
      expect(manifestJson['repositories']?['frontend'], isNotNull);
      expect(manifestJson['repositories']?['backend'], isNotNull);
      expect(manifestJson['architecture_layers'], isNotNull);

      final planTemplate = File('docs/ai-agent/templates/CHANGE-PLAN.md');
      final reportTemplate = File('docs/ai-agent/templates/IMPLEMENTATION-REPORT.md');
      expect(planTemplate.existsSync(), isTrue, reason: 'CHANGE-PLAN.md template must exist');
      expect(reportTemplate.existsSync(), isTrue, reason: 'IMPLEMENTATION-REPORT.md template must exist');
    });

    test('2. Generated File Immutability & Codegen Boundaries', () {
      final generatedIsar = File('lib/core/storage/isar_collections.g.dart');
      expect(generatedIsar.existsSync(), isTrue, reason: 'Generated Isar file must exist');
      final content = generatedIsar.readAsStringSync();
      expect(
        content.contains('GENERATED CODE - DO NOT MODIFY BY HAND'),
        isTrue,
        reason: 'Generated files must clearly declare code-generation header to prevent manual editing',
      );
    });

    test('3. Presentation Layer Purity: Modular screens do NOT import Dio directly', () {
      final screens = [
        'lib/features/requirements/screens/requirements_screen.dart',
        'lib/features/campaign/screens/campaign_leads_screen.dart',
        'lib/features/admin/screens/lead_allocation_monitor_screen.dart',
      ];

      final violations = <String>[];
      for (final screenPath in screens) {
        final file = File(screenPath);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.contains('dio_client.dart') || content.contains('package:dio/dio.dart')) {
            violations.add(screenPath);
          }
        }
      }

      expect(violations, isEmpty, reason: 'Screens must not import DioClient directly: $violations');
    });

    test('4. Presentation Layer Purity: Modular widgets do NOT import Isar directly', () {
      final widgets = [
        'lib/features/requirements/widgets/requirement_summary_bar.dart',
        'lib/features/requirements/widgets/requirement_filter_bar.dart',
        'lib/features/requirements/widgets/requirement_action_dialogs.dart',
        'lib/features/campaign/widgets/campaign_column_settings_dialog.dart',
        'lib/features/campaign/widgets/lead_reclassify_dialog.dart',
      ];

      final violations = <String>[];
      for (final widgetPath in widgets) {
        final file = File(widgetPath);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.contains('isar_collections.dart') || content.contains('isar_collections.g.dart')) {
            violations.add(widgetPath);
          }
        }
      }

      expect(violations, isEmpty, reason: 'Widgets must not import Isar schema directly: $violations');
    });

    test('5. State Management Purity: Restructured BLoCs do NOT declare Widget subclasses', () {
      final blocFiles = [
        'lib/features/admin/bloc/lead_allocation_monitor_bloc.dart',
        'lib/features/requirements/bloc/requirements_bloc.dart',
      ];

      final violations = <String>[];
      for (final path in blocFiles) {
        final file = File(path);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.contains('extends StatelessWidget') || content.contains('extends StatefulWidget')) {
            violations.add(path);
          }
        }
      }

      expect(violations, isEmpty, reason: 'BLoCs must not declare UI Widget subclasses: $violations');
    });

    test('6. Security Guardrail: Zero high-confidence live credentials in lib/', () {
      final libDir = Directory('lib');
      final secretPattern = RegExp(r'(AKIA[0-9A-Z]{16}|BEGIN\s+RSA\s+PRIVATE\s+KEY|sk_live_[0-9a-zA-Z]{24})');

      final violations = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          if (secretPattern.hasMatch(content)) {
            violations.add(entity.path);
          }
        }
      }

      expect(violations, isEmpty, reason: 'Zero high-confidence secrets allowed in lib/: $violations');
    });
  });
}
